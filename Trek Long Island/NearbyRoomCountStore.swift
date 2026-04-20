// Copyright Bryan Carroll. All rights reserved.
//
//  NearbyRoomCountStore.swift
//  Trek Long Island
//
//  Nearby active-device counting for a selected room using MultipeerConnectivity.
//

import Foundation
import MultipeerConnectivity
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

final class NearbyRoomCountStore: NSObject, ObservableObject {
    static let shared = NearbyRoomCountStore()

    @Published private(set) var isEnabled: Bool
    @Published private(set) var selectedRoomName: String
    @Published private(set) var nearbyPeerCount: Int = 0
    @Published private(set) var nearbyRooms: [String: Int] = [:]
    @Published private(set) var authorizationMessage: String?

    private struct PeerPresence: Equatable {
        let peerIdentifier: String
        let displayName: String
        let roomToken: String
    }

    private enum StorageKeys {
        static let isEnabled = "TLI.NearbyCount.enabled"
        static let selectedRoom = "TLI.NearbyCount.selectedRoom"
        static let peerID = "TLI.NearbyCount.peerID"
    }

    private static let serviceType = "tlircounter"

    private let defaults: UserDefaults
    private let peerID: MCPeerID
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var discoveredPeers: [String: PeerPresence] = [:]
    private var lastPhase: ScenePhase = .active

    override init() {
        let defaults = UserDefaults.standard
        self.defaults = defaults
        self.isEnabled = defaults.object(forKey: StorageKeys.isEnabled) as? Bool ?? false
        self.selectedRoomName = defaults.string(forKey: StorageKeys.selectedRoom) ?? ""

        let storedPeerID = defaults.string(forKey: StorageKeys.peerID) ?? UUID().uuidString
        defaults.set(storedPeerID, forKey: StorageKeys.peerID)
        self.peerID = MCPeerID(displayName: Self.makePeerDisplayName(from: storedPeerID))

        super.init()
        refreshNetworking()
    }

    func setEnabled(_ enabled: Bool) {
        guard isEnabled != enabled else { return }
        isEnabled = enabled
        defaults.set(enabled, forKey: StorageKeys.isEnabled)
        refreshNetworking()
    }

    func setSelectedRoomName(_ roomName: String) {
        let trimmed = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard selectedRoomName != trimmed else { return }
        selectedRoomName = trimmed
        defaults.set(trimmed, forKey: StorageKeys.selectedRoom)
        refreshNetworking()
    }

    func handleScenePhase(_ phase: ScenePhase) {
        guard lastPhase != phase else { return }
        lastPhase = phase
        refreshNetworking()
    }

    func automaticCount(for roomName: String) -> Int? {
        let token = Self.roomToken(from: roomName)
        guard !token.isEmpty else { return nil }
        let peerCount = nearbyRooms[token] ?? 0
        if token == Self.roomToken(from: selectedRoomName), isEnabled, lastPhase == .active {
            return peerCount + 1
        }
        return peerCount > 0 ? peerCount : nil
    }

    var totalActiveCountForSelectedRoom: Int {
        automaticCount(for: selectedRoomName) ?? (isEnabled && !selectedRoomName.isEmpty ? 1 : 0)
    }

    private func refreshNetworking() {
        guard isEnabled, !selectedRoomName.isEmpty, lastPhase == .active else {
            stopNetworking()
            return
        }

        authorizationMessage = nil

        if advertiser == nil {
            let advertiser = MCNearbyServiceAdvertiser(
                peer: peerID,
                discoveryInfo: discoveryInfo(),
                serviceType: Self.serviceType
            )
            advertiser.delegate = self
            self.advertiser = advertiser
            advertiser.startAdvertisingPeer()
        } else {
            advertiser?.stopAdvertisingPeer()
            advertiser = MCNearbyServiceAdvertiser(
                peer: peerID,
                discoveryInfo: discoveryInfo(),
                serviceType: Self.serviceType
            )
            advertiser?.delegate = self
            advertiser?.startAdvertisingPeer()
        }

        if browser == nil {
            let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
            browser.delegate = self
            self.browser = browser
            browser.startBrowsingForPeers()
        }

        recalculateNearbyCounts()
    }

    private func stopNetworking() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        discoveredPeers.removeAll()
        recalculateNearbyCounts()
    }

    private func discoveryInfo() -> [String: String] {
        [
            "id": defaults.string(forKey: StorageKeys.peerID) ?? peerID.displayName,
            "room": Self.roomToken(from: selectedRoomName)
        ]
    }

    private func recalculateNearbyCounts() {
        let counts = discoveredPeers.values.reduce(into: [String: Int]()) { partialResult, peer in
            guard !peer.roomToken.isEmpty else { return }
            partialResult[peer.roomToken, default: 0] += 1
        }
        nearbyRooms = counts
        nearbyPeerCount = counts[Self.roomToken(from: selectedRoomName)] ?? 0
    }

    private static func makePeerDisplayName(from storedIdentifier: String) -> String {
        #if canImport(UIKit)
        let deviceName = UIDevice.current.name
            .replacingOccurrences(of: " ", with: "")
            .prefix(18)
        #else
        let deviceName = "TLI"
        #endif
        let suffix = storedIdentifier.suffix(6)
        return "\(deviceName)-\(suffix)"
    }

    static func roomToken(from roomName: String) -> String {
        roomName
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            .prefix(24)
            .description
    }
}

extension NearbyRoomCountStore: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    ) {
        DispatchQueue.main.async {
            self.authorizationMessage = error.localizedDescription
        }
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        invitationHandler(false, nil)
    }
}

extension NearbyRoomCountStore: MCNearbyServiceBrowserDelegate {
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String : String]?
    ) {
        DispatchQueue.main.async {
            let identifier = info?["id"] ?? peerID.displayName
            self.discoveredPeers[identifier] = PeerPresence(
                peerIdentifier: identifier,
                displayName: peerID.displayName,
                roomToken: info?["room"] ?? ""
            )
            self.recalculateNearbyCounts()
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            let keysToRemove = self.discoveredPeers
                .filter { $0.value.displayName == peerID.displayName }
                .map(\.key)
            for key in keysToRemove {
                self.discoveredPeers.removeValue(forKey: key)
            }
            self.recalculateNearbyCounts()
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: any Error) {
        DispatchQueue.main.async {
            self.authorizationMessage = error.localizedDescription
        }
    }
}
