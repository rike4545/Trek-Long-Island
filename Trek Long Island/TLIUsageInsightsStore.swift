// Copyright Bryan Carroll. All rights reserved.
//
//  TLIUsageInsightsStore.swift
//  Trek Long Island
//
//  Local operator-facing app usage telemetry.
//

import Foundation
import SwiftUI
import FirebaseFirestore
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Darwin)
import Darwin
#endif

struct TLIUsageSessionRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let durationSeconds: TimeInterval
    let lastActiveTab: String

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        durationSeconds: TimeInterval,
        lastActiveTab: String
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.lastActiveTab = lastActiveTab
    }
}

struct TLIUsageSnapshot {
    let totalLaunches: Int
    let sessionCount: Int
    let averageSessionSeconds: TimeInterval
    let longestSessionSeconds: TimeInterval
    let totalForegroundSeconds: TimeInterval
    let mostUsedTab: String
    let tabCounts: [(tab: String, count: Int)]
    let lastActiveAt: Date?
    let deviceModel: String
    let systemVersion: String
    let appVersion: String
    let buildNumber: String

    var averageSessionLabel: String { Self.durationLabel(for: averageSessionSeconds) }
    var longestSessionLabel: String { Self.durationLabel(for: longestSessionSeconds) }
    var totalForegroundLabel: String { Self.durationLabel(for: totalForegroundSeconds) }

    private static func durationLabel(for duration: TimeInterval) -> String {
        guard duration > 0 else { return "0m" }
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(max(1, minutes))m"
    }
}

@MainActor
final class TLIUsageInsightsStore: ObservableObject {
    static let shared = TLIUsageInsightsStore()

    @Published private(set) var sessions: [TLIUsageSessionRecord] = []
    @Published private(set) var tabSelections: [String: Int] = [:]
    @Published private(set) var totalLaunches: Int = 0
    @Published private(set) var lastActiveAt: Date?
    @Published private(set) var currentTab: String = "today"

    private enum StorageKeys {
        static let sessions = "TLI.UsageInsights.sessions.v1"
        static let tabSelections = "TLI.UsageInsights.tabSelections.v1"
        static let totalLaunches = "TLI.UsageInsights.totalLaunches.v1"
        static let lastActiveAt = "TLI.UsageInsights.lastActiveAt.v1"
    }

    private let maxSessions = 120
    private let defaults = UserDefaults.standard
    private let db = Firestore.firestore()
    private let conventionID = "trekli-2026"
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private var activeSessionStart: Date?
    private var listener: ListenerRegistration?
    private var isApplyingRemoteSnapshot = false
    private var lastSyncedSessionsBlob = ""
    private var lastSyncedTabSelections: [String: Int] = [:]
    private var lastSyncedLaunches: Int = 0
    private var lastSyncedLastActiveAt: Date?

    private init() {
        load()
        startListening()
    }

    deinit {
        listener?.remove()
    }

    func noteLaunch() {
        totalLaunches += 1
        defaults.set(totalLaunches, forKey: StorageKeys.totalLaunches)
        sync()
    }

    func noteScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            if activeSessionStart == nil {
                activeSessionStart = .now
            }
            lastActiveAt = .now
            persistLastActiveAt()
            sync()
        case .background, .inactive:
            finalizeActiveSessionIfNeeded()
        @unknown default:
            finalizeActiveSessionIfNeeded()
        }
    }

    func noteSelectedTab(_ tab: String) {
        let normalized = normalizedTab(tab)
        currentTab = normalized
        tabSelections[normalized, default: 0] += 1
        persistTabSelections()
        sync()
    }

    func snapshot() -> TLIUsageSnapshot {
        let averageSessionSeconds: TimeInterval = {
            guard !sessions.isEmpty else { return 0 }
            let total = sessions.reduce(0) { $0 + $1.durationSeconds }
            return total / Double(sessions.count)
        }()

        let longestSessionSeconds = sessions.map(\.durationSeconds).max() ?? 0
        let totalForegroundSeconds = sessions.reduce(0) { $0 + $1.durationSeconds }

        let orderedTabs = tabSelections
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .map { (tab: prettifiedTabName($0.key), count: $0.value) }

        return TLIUsageSnapshot(
            totalLaunches: totalLaunches,
            sessionCount: sessions.count,
            averageSessionSeconds: averageSessionSeconds,
            longestSessionSeconds: longestSessionSeconds,
            totalForegroundSeconds: totalForegroundSeconds,
            mostUsedTab: orderedTabs.first?.tab ?? "Today",
            tabCounts: Array(orderedTabs.prefix(5)),
            lastActiveAt: lastActiveAt,
            deviceModel: Self.deviceModelName(),
            systemVersion: Self.systemVersionName(),
            appVersion: Self.appVersion(),
            buildNumber: Self.buildNumber()
        )
    }

    private func finalizeActiveSessionIfNeeded(endDate: Date = .now) {
        guard let start = activeSessionStart else { return }
        activeSessionStart = nil

        let duration = max(0, endDate.timeIntervalSince(start))
        guard duration >= 3 else { return }

        let session = TLIUsageSessionRecord(
            startedAt: start,
            endedAt: endDate,
            durationSeconds: duration,
            lastActiveTab: currentTab
        )

        sessions.insert(session, at: 0)
        sessions = Array(sessions.prefix(maxSessions))
        persistSessions()
        lastActiveAt = endDate
        persistLastActiveAt()
    }

    private func load() {
        totalLaunches = defaults.integer(forKey: StorageKeys.totalLaunches)
        if let rawTabs = defaults.dictionary(forKey: StorageKeys.tabSelections) as? [String: Int] {
            tabSelections = rawTabs
        }
        if let data = defaults.data(forKey: StorageKeys.sessions),
           let decoded = try? decoder.decode([TLIUsageSessionRecord].self, from: data) {
            sessions = decoded
        }
        if let lastActiveAt = defaults.object(forKey: StorageKeys.lastActiveAt) as? Date {
            self.lastActiveAt = lastActiveAt
        }
    }

    private func persistSessions() {
        guard let data = try? encoder.encode(sessions) else { return }
        defaults.set(data, forKey: StorageKeys.sessions)
    }

    private func persistTabSelections() {
        defaults.set(tabSelections, forKey: StorageKeys.tabSelections)
    }

    private func persistLastActiveAt() {
        defaults.set(lastActiveAt, forKey: StorageKeys.lastActiveAt)
    }

    private var document: DocumentReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("usage_profiles")
            .document(TLIPreferencesSyncStore.shared.profileID.lowercased())
    }

    private func startListening() {
        listener?.remove()
        listener = document.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("❌ Firestore usage insights error: \(error.localizedDescription)")
                    return
                }

                guard let data = snapshot?.data() else {
                    self.sync()
                    return
                }

                let remoteBlob = data["sessionsBlob"] as? String ?? ""
                let remoteTabSelections = data["tabSelections"] as? [String: Int] ?? [:]
                let remoteLaunches = data["totalLaunches"] as? Int ?? 0
                let remoteLastActiveAt = (data["lastActiveAt"] as? Timestamp)?.dateValue()

                guard
                    remoteBlob != self.lastSyncedSessionsBlob ||
                    remoteTabSelections != self.lastSyncedTabSelections ||
                    remoteLaunches != self.lastSyncedLaunches ||
                    remoteLastActiveAt != self.lastSyncedLastActiveAt
                else { return }

                self.applyRemote(
                    sessionsBlob: remoteBlob,
                    tabSelections: remoteTabSelections,
                    totalLaunches: remoteLaunches,
                    lastActiveAt: remoteLastActiveAt
                )
            }
        }
    }

    private func sync() {
        guard !isApplyingRemoteSnapshot else { return }
        let sessionsBlob = encodedSessionsBlob(from: sessions)
        let tabSelections = self.tabSelections
        let totalLaunches = self.totalLaunches
        let lastActiveAt = self.lastActiveAt

        guard
            sessionsBlob != lastSyncedSessionsBlob ||
            tabSelections != lastSyncedTabSelections ||
            totalLaunches != lastSyncedLaunches ||
            lastActiveAt != lastSyncedLastActiveAt
        else { return }

        lastSyncedSessionsBlob = sessionsBlob
        lastSyncedTabSelections = tabSelections
        lastSyncedLaunches = totalLaunches
        lastSyncedLastActiveAt = lastActiveAt

        var data: [String: Any] = [
            "sessionsBlob": sessionsBlob,
            "tabSelections": tabSelections,
            "totalLaunches": totalLaunches,
            "updatedAt": Timestamp(date: .now)
        ]
        if let lastActiveAt {
            data["lastActiveAt"] = Timestamp(date: lastActiveAt)
        }

        document.setData(data, merge: true) { error in
            if let error {
                print("❌ Firestore usage insights sync error: \(error.localizedDescription)")
            }
        }
    }

    private func applyRemote(
        sessionsBlob: String,
        tabSelections: [String: Int],
        totalLaunches: Int,
        lastActiveAt: Date?
    ) {
        isApplyingRemoteSnapshot = true
        if let data = Data(base64Encoded: sessionsBlob),
           let decoded = try? decoder.decode([TLIUsageSessionRecord].self, from: data) {
            sessions = decoded
            defaults.set(data, forKey: StorageKeys.sessions)
            lastSyncedSessionsBlob = sessionsBlob
        }
        self.tabSelections = tabSelections
        defaults.set(tabSelections, forKey: StorageKeys.tabSelections)
        self.totalLaunches = totalLaunches
        defaults.set(totalLaunches, forKey: StorageKeys.totalLaunches)
        self.lastActiveAt = lastActiveAt
        defaults.set(lastActiveAt, forKey: StorageKeys.lastActiveAt)
        lastSyncedTabSelections = tabSelections
        lastSyncedLaunches = totalLaunches
        lastSyncedLastActiveAt = lastActiveAt
        isApplyingRemoteSnapshot = false
    }

    private func encodedSessionsBlob(from sessions: [TLIUsageSessionRecord]) -> String {
        guard let data = try? encoder.encode(sessions) else { return "" }
        return data.base64EncodedString()
    }

    private func normalizedTab(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .ifEmpty("today")
    }

    private func prettifiedTabName(_ raw: String) -> String {
        raw
            .split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private static func appVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    private static func buildNumber() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }

    private static func systemVersionName() -> String {
        #if canImport(UIKit)
        return "iOS \(UIDevice.current.systemVersion)"
        #else
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }

    private static func deviceModelName() -> String {
        #if canImport(UIKit)
        let identifier = hardwareIdentifier()
        let localizedName = UIDevice.current.model
        return identifier.isEmpty ? localizedName : "\(localizedName) (\(identifier))"
        #else
        return hardwareIdentifier()
        #endif
    }

    private static func hardwareIdentifier() -> String {
        #if canImport(Darwin)
        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
        #else
        return ""
        #endif
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
