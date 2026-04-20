// Copyright Bryan Carroll. All rights reserved.
//
//  OpsAuditStore.swift
//  Trek Long Island
//
//  Lightweight on-device audit trail for operator/master actions.
//

import Foundation
import FirebaseFirestore

struct OpsAuditEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let timestamp: Date
    let actor: String
    let action: String
    let details: String

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        actor: String,
        action: String,
        details: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.actor = actor
        self.action = action
        self.details = details
    }
}

@MainActor
final class OpsAuditStore: ObservableObject {
    static let shared = OpsAuditStore()

    @Published private(set) var entries: [OpsAuditEntry] = []

    private let key = "TLI.OpsAudit.entries.v1"
    private let maxEntries = 250
    private let db = Firestore.firestore()
    private let conventionID = "trekli-2026"
    private var listener: ListenerRegistration?
    private var isApplyingRemoteSnapshot = false
    private var lastSyncedBlob = ""

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        load()
        startListening()
    }

    deinit {
        listener?.remove()
    }

    func log(actor: String, action: String, details: String = "") {
        let entry = OpsAuditEntry(actor: actor, action: action, details: details)
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        persist()
        sync()
    }

    func clear() {
        entries = []
        UserDefaults.standard.removeObject(forKey: key)
        sync()
    }

    private var document: DocumentReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("ops")
            .document("audit_log")
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? decoder.decode([OpsAuditEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded.sorted { $0.timestamp > $1.timestamp }
    }

    private func persist() {
        guard let data = try? encoder.encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func startListening() {
        listener?.remove()
        listener = document.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("❌ Firestore ops audit error: \(error.localizedDescription)")
                    return
                }

                guard let data = snapshot?.data(),
                      let blob = data["entriesBlob"] as? String else {
                    self.sync()
                    return
                }

                guard blob != self.lastSyncedBlob else { return }
                self.applyRemote(blob)
            }
        }
    }

    private func sync() {
        guard !isApplyingRemoteSnapshot else { return }
        let blob = encodedBlob(from: entries)
        guard blob != lastSyncedBlob else { return }
        lastSyncedBlob = blob
        document.setData(
            [
                "entriesBlob": blob,
                "updatedAt": Timestamp(date: .now)
            ],
            merge: true
        ) { error in
            if let error {
                print("❌ Firestore ops audit sync error: \(error.localizedDescription)")
            }
        }
    }

    private func applyRemote(_ blob: String) {
        guard let data = Data(base64Encoded: blob),
              let decoded = try? decoder.decode([OpsAuditEntry].self, from: data) else { return }
        isApplyingRemoteSnapshot = true
        entries = decoded.sorted { $0.timestamp > $1.timestamp }
        UserDefaults.standard.set(data, forKey: key)
        isApplyingRemoteSnapshot = false
        lastSyncedBlob = blob
    }

    private func encodedBlob(from entries: [OpsAuditEntry]) -> String {
        guard let data = try? encoder.encode(entries) else { return "" }
        return data.base64EncodedString()
    }
}
