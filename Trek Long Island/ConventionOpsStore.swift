// Copyright Bryan Carroll. All rights reserved.
import Foundation
import FirebaseFirestore

@MainActor
final class ConventionOpsStore: ObservableObject {
    static let shared = ConventionOpsStore()

    @Published private(set) var roomStates: [RoomOpsState] = []
    @Published private(set) var supportTickets: [SupportTicket] = []
    @Published private(set) var waitTimesEnabled: Bool = true

    private let roomStatesKey = "TLI.Ops.roomStates.v1"
    private let supportTicketsKey = "TLI.Ops.supportTickets.v1"
    private let waitTimesEnabledKey = "TLI.Ops.waitTimesEnabled.v1"
    private let conventionID = TLIEventInfo.current.conventionID
    private let analytics = TLIAnalyticsStore.shared
    private let db = Firestore.firestore()
    private var roomStatesListener: ListenerRegistration?
    private var supportTicketsListener: ListenerRegistration?
    private var configListener: ListenerRegistration?
    private let defaultRoomCapacities: [String: Int] = [
        "panel c": 90,
        "panel room c": 90,
        "panel d": 90,
        "panel room d": 90,
        "windwatch": 120,
        "vendor hall announcements": 180,
        "vendor room": 180,
        "main hall": 511,
        "main stage": 511
    ]

    private init() {
        loadFromDisk()
        seedIfNeeded()
        startListening()
    }

    deinit {
        roomStatesListener?.remove()
        supportTicketsListener?.remove()
        configListener?.remove()
    }

    func state(for room: String) -> RoomOpsState {
        if let existing = roomStates.first(where: { $0.roomName.caseInsensitiveCompare(room) == .orderedSame }) {
            return existing
        }
        return RoomOpsState(
            roomName: room,
            occupancyLimit: defaultOccupancyLimit(for: room)
        )
    }

    func upsertRoomState(_ state: RoomOpsState) {
        if let idx = roomStates.firstIndex(where: { $0.roomName.caseInsensitiveCompare(state.roomName) == .orderedSame }) {
            roomStates[idx] = state
        } else {
            roomStates.append(state)
        }
        roomStates.sort { $0.roomName.localizedCaseInsensitiveCompare($1.roomName) == .orderedAscending }
        persistRoomStates()
        syncRoomState(state)
        analytics.track(
            name: "room_state_updated",
            domain: "live_ops",
            actor: state.updatedBy.lowercased(),
            metadata: [
                "room": state.roomName.lowercased(),
                "status": state.status.rawValue,
                "wait_enabled": waitTimesEnabled ? "true" : "false"
            ]
        )
    }

    func upsertRoomState(roomName: String, status: RoomLiveStatus, waitMinutes: Int?, note: String, updatedBy: String) {
        var current = state(for: roomName)
        current.status = status
        current.waitMinutes = waitMinutes
        current.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        current.updatedBy = updatedBy
        current.lastUpdated = Date()
        upsertRoomState(current)
    }

    func submitTicket(_ ticket: SupportTicket) {
        supportTickets.insert(ticket, at: 0)
        persistSupportTickets()
        syncSupportTicket(ticket)
        analytics.track(
            name: "support_ticket_created",
            domain: "live_ops",
            actor: ticket.reporter.lowercased(),
            metadata: [
                "category": ticket.category.rawValue.lowercased(),
                "severity": ticket.severity.rawValue.lowercased()
            ]
        )
    }

    func updateTicketStatus(id: UUID, status: SupportTicketStatus) {
        guard let idx = supportTickets.firstIndex(where: { $0.id == id }) else { return }
        supportTickets[idx].status = status
        supportTickets[idx].updatedAt = Date()
        persistSupportTickets()
        syncSupportTicket(supportTickets[idx])
        analytics.track(
            name: "support_ticket_status_updated",
            domain: "live_ops",
            actor: "staff",
            metadata: [
                "status": status.rawValue.lowercased(),
                "ticket_id": id.uuidString.lowercased()
            ]
        )
    }

    func activeTickets(limit: Int = 50) -> [SupportTicket] {
        Array(supportTickets.prefix(limit))
    }

    func setWaitTimesEnabled(_ isEnabled: Bool) {
        waitTimesEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: waitTimesEnabledKey)
        syncOpsConfig()
        analytics.track(
            name: "wait_times_toggled",
            domain: "live_ops",
            actor: "master",
            metadata: ["enabled": isEnabled ? "true" : "false"]
        )
    }

    private func seedIfNeeded() {
        if roomStates.isEmpty {
            let loader = ICSLoader()
            let roomNames = loader.labeledRoomURLs.keys.sorted()
            if roomNames.isEmpty { return }
            roomStates = roomNames.map {
                RoomOpsState(roomName: $0, occupancyLimit: defaultOccupancyLimit(for: $0))
            }
            persistRoomStates()
            return
        }

        var didUpdate = false
        for index in roomStates.indices {
            guard roomStates[index].occupancyLimit == 0 else { continue }
            let seededLimit = defaultOccupancyLimit(for: roomStates[index].roomName)
            guard seededLimit > 0 else { continue }
            roomStates[index].occupancyLimit = seededLimit
            didUpdate = true
        }

        if didUpdate {
            persistRoomStates()
        }
    }

    private func loadFromDisk() {
        let defaults = UserDefaults.standard
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let roomData = defaults.data(forKey: roomStatesKey),
           let decoded = try? decoder.decode([RoomOpsState].self, from: roomData) {
            roomStates = decoded
        }

        if let ticketData = defaults.data(forKey: supportTicketsKey),
           let decoded = try? decoder.decode([SupportTicket].self, from: ticketData) {
            supportTickets = decoded
        }

        if defaults.object(forKey: waitTimesEnabledKey) == nil {
            waitTimesEnabled = true
        } else {
            waitTimesEnabled = defaults.bool(forKey: waitTimesEnabledKey)
        }
    }

    private var roomStatesCollection: CollectionReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("room_states")
    }

    private var supportTicketsCollection: CollectionReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("support_tickets")
    }

    private var configDocument: DocumentReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("ops")
            .document("config")
    }

    private func startListening() {
        startListeningRoomStates()
        startListeningSupportTickets()
        startListeningConfig()
    }

    private func startListeningRoomStates() {
        roomStatesListener?.remove()
        roomStatesListener = roomStatesCollection
            .order(by: "roomName")
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        print("❌ Firestore room states error: \(error.localizedDescription)")
                        return
                    }

                    guard let docs = snapshot?.documents else {
                        self.roomStates = []
                        self.persistRoomStates()
                        return
                    }

                    self.roomStates = docs.compactMap(Self.makeRoomState(from:))
                    self.seedIfNeeded()
                    self.persistRoomStates()
                }
            }
    }

    private func startListeningSupportTickets() {
        supportTicketsListener?.remove()
        supportTicketsListener = supportTicketsCollection
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        print("❌ Firestore support tickets error: \(error.localizedDescription)")
                        return
                    }

                    guard let docs = snapshot?.documents else {
                        self.supportTickets = []
                        self.persistSupportTickets()
                        return
                    }

                    self.supportTickets = docs.compactMap(Self.makeSupportTicket(from:))
                    self.persistSupportTickets()
                }
            }
    }

    private func startListeningConfig() {
        configListener?.remove()
        configListener = configDocument.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("❌ Firestore ops config error: \(error.localizedDescription)")
                    return
                }

                guard let data = snapshot?.data() else { return }
                if let enabled = data["waitTimesEnabled"] as? Bool {
                    self.waitTimesEnabled = enabled
                    UserDefaults.standard.set(enabled, forKey: self.waitTimesEnabledKey)
                }
            }
        }
    }

    private func syncRoomState(_ state: RoomOpsState) {
        roomStatesCollection.document(state.id).setData(Self.makeFirestoreData(from: state), merge: true) { error in
            if let error {
                print("❌ Firestore room state sync error: \(error.localizedDescription)")
            }
        }
    }

    private func syncSupportTicket(_ ticket: SupportTicket) {
        supportTicketsCollection.document(ticket.id.uuidString.lowercased()).setData(Self.makeFirestoreData(from: ticket), merge: true) { error in
            if let error {
                print("❌ Firestore support ticket sync error: \(error.localizedDescription)")
            }
        }
    }

    private func syncOpsConfig() {
        configDocument.setData(["waitTimesEnabled": waitTimesEnabled], merge: true) { error in
            if let error {
                print("❌ Firestore ops config sync error: \(error.localizedDescription)")
            }
        }
    }

    private static func makeFirestoreData(from state: RoomOpsState) -> [String: Any] {
        [
            "roomName": state.roomName,
            "status": state.status.rawValue,
            "waitMinutes": state.waitMinutes as Any,
            "occupancyCount": state.occupancyCount,
            "occupancyLimit": state.occupancyLimit,
            "note": state.note,
            "updatedBy": state.updatedBy,
            "lastUpdated": Timestamp(date: state.lastUpdated)
        ]
    }

    private static func makeRoomState(from doc: QueryDocumentSnapshot) -> RoomOpsState? {
        let data = doc.data()
        guard let roomName = data["roomName"] as? String else { return nil }

        var state = RoomOpsState(
            roomName: roomName,
            occupancyLimit: max(0, data["occupancyLimit"] as? Int ?? 0)
        )
        state.status = RoomLiveStatus(rawValue: data["status"] as? String ?? "") ?? .open
        state.waitMinutes = data["waitMinutes"] as? Int
        state.occupancyCount = max(0, data["occupancyCount"] as? Int ?? 0)
        state.note = data["note"] as? String ?? ""
        state.updatedBy = data["updatedBy"] as? String ?? "System"
        if let timestamp = data["lastUpdated"] as? Timestamp {
            state.lastUpdated = timestamp.dateValue()
        }
        return state
    }

    private static func makeFirestoreData(from ticket: SupportTicket) -> [String: Any] {
        [
            "id": ticket.id.uuidString.lowercased(),
            "category": ticket.category.rawValue,
            "severity": ticket.severity.rawValue,
            "privacy": ticket.privacy.rawValue,
            "title": ticket.title,
            "location": ticket.location,
            "details": ticket.details,
            "reporter": ticket.reporter,
            "status": ticket.status.rawValue,
            "createdAt": Timestamp(date: ticket.createdAt),
            "updatedAt": Timestamp(date: ticket.updatedAt)
        ]
    }

    private static func makeSupportTicket(from doc: QueryDocumentSnapshot) -> SupportTicket? {
        let data = doc.data()
        guard
            let idString = data["id"] as? String,
            let id = UUID(uuidString: idString),
            let categoryRaw = data["category"] as? String,
            let category = SupportTicketCategory(rawValue: categoryRaw),
            let severityRaw = data["severity"] as? String,
            let severity = SupportTicketSeverity(rawValue: severityRaw),
            let title = data["title"] as? String,
            let location = data["location"] as? String,
            let details = data["details"] as? String,
            let reporter = data["reporter"] as? String,
            let statusRaw = data["status"] as? String,
            let status = SupportTicketStatus(rawValue: statusRaw)
        else {
            return nil
        }

        let privacy = SupportTicketPrivacy(rawValue: data["privacy"] as? String ?? "") ?? .staffOnly
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .now
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? createdAt

        return SupportTicket(
            id: id,
            category: category,
            severity: severity,
            privacy: privacy,
            title: title,
            location: location,
            details: details,
            reporter: reporter,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func persistRoomStates() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(roomStates) {
            UserDefaults.standard.set(data, forKey: roomStatesKey)
        }
    }

    private func persistSupportTickets() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(supportTickets) {
            UserDefaults.standard.set(data, forKey: supportTicketsKey)
        }
    }

    private func defaultOccupancyLimit(for roomName: String) -> Int {
        let normalized = roomName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return defaultRoomCapacities[normalized] ?? 0
    }
}

struct RoomOpsState: Codable, Identifiable, Hashable {
    var id: String { roomName.lowercased() }
    var roomName: String
    var status: RoomLiveStatus = .open
    var waitMinutes: Int? = nil
    var occupancyCount: Int = 0
    var occupancyLimit: Int = 0
    var note: String = ""
    var updatedBy: String = "System"
    var lastUpdated: Date = .now

    var waitLabel: String {
        guard let waitMinutes else { return "No wait posted" }
        if waitMinutes == 0 { return "Walk-in" }
        return "~\(waitMinutes)m wait"
    }

    var occupancyLabel: String {
        guard occupancyLimit > 0 else { return "Capacity not set" }
        return "\(occupancyCount)/\(occupancyLimit)"
    }

    var occupancyState: OccupancyComplianceState {
        guard occupancyLimit > 0 else { return .unset }
        return occupancyCount > occupancyLimit ? .overLimit : .compliant
    }

    enum CodingKeys: String, CodingKey {
        case roomName
        case status
        case waitMinutes
        case occupancyCount
        case occupancyLimit
        case note
        case updatedBy
        case lastUpdated
    }

    init(roomName: String, occupancyLimit: Int = 0) {
        self.roomName = roomName
        self.occupancyLimit = max(0, occupancyLimit)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        roomName = try container.decode(String.self, forKey: .roomName)
        status = try container.decodeIfPresent(RoomLiveStatus.self, forKey: .status) ?? .open
        waitMinutes = try container.decodeIfPresent(Int.self, forKey: .waitMinutes)
        occupancyCount = max(0, try container.decodeIfPresent(Int.self, forKey: .occupancyCount) ?? 0)
        occupancyLimit = max(0, try container.decodeIfPresent(Int.self, forKey: .occupancyLimit) ?? 0)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy) ?? "System"
        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? .now
    }
}

enum OccupancyComplianceState {
    case unset
    case compliant
    case overLimit

    var title: String {
        switch self {
        case .unset: return "Unset"
        case .compliant: return "Compliant"
        case .overLimit: return "Over Limit"
        }
    }

    var symbolName: String {
        switch self {
        case .unset: return "questionmark.circle"
        case .compliant: return "checkmark.seal.fill"
        case .overLimit: return "exclamationmark.octagon.fill"
        }
    }
}

enum RoomLiveStatus: String, Codable, CaseIterable, Identifiable {
    case open
    case filling
    case atCapacity
    case cleared

    var id: String { rawValue }

    var title: String {
        switch self {
        case .open: return "Open"
        case .filling: return "Filling"
        case .atCapacity: return "At Capacity"
        case .cleared: return "Cleared"
        }
    }

    var symbolName: String {
        switch self {
        case .open: return "checkmark.circle.fill"
        case .filling: return "clock.fill"
        case .atCapacity: return "exclamationmark.triangle.fill"
        case .cleared: return "sparkles"
        }
    }
}

struct SupportTicket: Codable, Identifiable, Hashable {
    var id: UUID
    var category: SupportTicketCategory
    var severity: SupportTicketSeverity
    var privacy: SupportTicketPrivacy
    var title: String
    var location: String
    var details: String
    var reporter: String
    var status: SupportTicketStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        category: SupportTicketCategory,
        severity: SupportTicketSeverity,
        privacy: SupportTicketPrivacy = .staffOnly,
        title: String,
        location: String,
        details: String,
        reporter: String,
        status: SupportTicketStatus = .new,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.category = category
        self.severity = severity
        self.privacy = privacy
        self.title = title
        self.location = location
        self.details = details
        self.reporter = reporter
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case severity
        case privacy
        case title
        case location
        case details
        case reporter
        case status
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        category = try container.decode(SupportTicketCategory.self, forKey: .category)
        severity = try container.decode(SupportTicketSeverity.self, forKey: .severity)
        privacy = try container.decodeIfPresent(SupportTicketPrivacy.self, forKey: .privacy) ?? .staffOnly
        title = try container.decode(String.self, forKey: .title)
        location = try container.decode(String.self, forKey: .location)
        details = try container.decode(String.self, forKey: .details)
        reporter = try container.decode(String.self, forKey: .reporter)
        status = try container.decode(SupportTicketStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

enum SupportTicketCategory: String, Codable, CaseIterable, Identifiable {
    case medical
    case safety
    case harassment
    case lostPerson
    case lostItem
    case accessibility
    case operations

    var id: String { rawValue }

    var title: String {
        switch self {
        case .medical: return "Medical"
        case .safety: return "Safety"
        case .harassment: return "Harassment"
        case .lostPerson: return "Lost Person"
        case .lostItem: return "Lost Item"
        case .accessibility: return "Accessibility"
        case .operations: return "Operations"
        }
    }
}

enum SupportTicketSeverity: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high
    case emergency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .emergency: return "Emergency"
        }
    }
}

enum SupportTicketPrivacy: String, Codable, CaseIterable, Identifiable {
    case publicBoard
    case staffOnly
    case confidential

    var id: String { rawValue }

    var title: String {
        switch self {
        case .publicBoard: return "Public Board"
        case .staffOnly: return "Staff Only"
        case .confidential: return "Confidential"
        }
    }

    var helpText: String {
        switch self {
        case .publicBoard:
            return "Visible in public recent ticket list without personal details."
        case .staffOnly:
            return "Visible to staff operations only."
        case .confidential:
            return "Restricted handling for sensitive reports."
        }
    }

    var symbolName: String {
        switch self {
        case .publicBoard: return "megaphone.fill"
        case .staffOnly: return "lock.fill"
        case .confidential: return "lock.shield.fill"
        }
    }
}

enum SupportTicketStatus: String, Codable, CaseIterable, Identifiable {
    case new
    case inProgress
    case resolved

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: return "New"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        }
    }
}
