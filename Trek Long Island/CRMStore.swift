// Copyright Bryan Carroll. All rights reserved.
//
//  CRMStore.swift
//  Trek Long Island
//
//  Lightweight convention CRM store:
//  - Contacts (people/org context)
//  - Follow-up tasks
//  - Timeline interactions
//

import Foundation
import FirebaseFirestore

// MARK: - Contact

enum CRMContactKind: String, Codable, CaseIterable, Identifiable {
    case guest
    case attendee
    case vendor
    case sponsor
    case press
    case volunteer
    case staff
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .guest: return "Guest"
        case .attendee: return "Attendee"
        case .vendor: return "Vendor"
        case .sponsor: return "Sponsor"
        case .press: return "Press"
        case .volunteer: return "Volunteer"
        case .staff: return "Staff"
        case .other: return "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .guest: return "star.fill"
        case .attendee: return "person.fill"
        case .vendor: return "storefront.fill"
        case .sponsor: return "banknote.fill"
        case .press: return "newspaper.fill"
        case .volunteer: return "hands.sparkles.fill"
        case .staff: return "person.2.badge.gearshape.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

struct CRMContact: Codable, Identifiable, Hashable {
    var id: UUID
    var fullName: String
    var organization: String
    var roleTitle: String
    var kind: CRMContactKind
    var email: String
    var phone: String
    var squareCustomerID: String?
    var tags: [String]
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var lastInteractionAt: Date?

    init(
        id: UUID = UUID(),
        fullName: String,
        organization: String = "",
        roleTitle: String = "",
        kind: CRMContactKind,
        email: String = "",
        phone: String = "",
        squareCustomerID: String? = nil,
        tags: [String] = [],
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastInteractionAt: Date? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.organization = organization
        self.roleTitle = roleTitle
        self.kind = kind
        self.email = email
        self.phone = phone
        self.squareCustomerID = squareCustomerID
        self.tags = tags
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastInteractionAt = lastInteractionAt
    }

    var displayOrganization: String {
        let clean = organization.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? "Independent" : clean
    }

    var initials: String {
        let comps = fullName
            .split(whereSeparator: { $0.isWhitespace })
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
        if comps.isEmpty { return "?" }
        return comps.joined()
    }

    var searchableBlob: String {
        [
            fullName,
            organization,
            roleTitle,
            email,
            phone,
            squareCustomerID ?? "",
            tags.joined(separator: " "),
            notes,
            kind.title
        ]
            .joined(separator: " ")
            .lowercased()
    }
}

// MARK: - Task

enum CRMTaskPriority: Int, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high
    case urgent

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }

    var symbolName: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .normal: return "minus.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}

struct CRMTask: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var details: String
    var dueAt: Date
    var priority: CRMTaskPriority
    var owner: String
    var contactID: UUID?
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        details: String = "",
        dueAt: Date,
        priority: CRMTaskPriority = .normal,
        owner: String = "Staff",
        contactID: UUID? = nil,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.dueAt = dueAt
        self.priority = priority
        self.owner = owner
        self.contactID = contactID
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    var isOverdue: Bool {
        !isCompleted && dueAt < .now
    }
}

// MARK: - Interaction

enum CRMInteractionKind: String, Codable, CaseIterable, Identifiable {
    case note
    case meeting
    case panel
    case issue
    case purchase
    case message
    case checkIn

    var id: String { rawValue }

    var title: String {
        switch self {
        case .note: return "Note"
        case .meeting: return "Meeting"
        case .panel: return "Panel"
        case .issue: return "Issue"
        case .purchase: return "Purchase"
        case .message: return "Message"
        case .checkIn: return "Check-In"
        }
    }

    var symbolName: String {
        switch self {
        case .note: return "note.text"
        case .meeting: return "person.2.fill"
        case .panel: return "rectangle.on.rectangle.angled"
        case .issue: return "exclamationmark.bubble.fill"
        case .purchase: return "cart.fill"
        case .message: return "message.fill"
        case .checkIn: return "checkmark.seal.fill"
        }
    }
}

struct CRMInteraction: Codable, Identifiable, Hashable {
    var id: UUID
    var contactID: UUID?
    var kind: CRMInteractionKind
    var title: String
    var details: String
    var sessionName: String
    var owner: String
    var timestamp: Date

    init(
        id: UUID = UUID(),
        contactID: UUID? = nil,
        kind: CRMInteractionKind,
        title: String,
        details: String = "",
        sessionName: String = "",
        owner: String = "Staff",
        timestamp: Date = .now
    ) {
        self.id = id
        self.contactID = contactID
        self.kind = kind
        self.title = title
        self.details = details
        self.sessionName = sessionName
        self.owner = owner
        self.timestamp = timestamp
    }
}

// MARK: - Store

@MainActor
final class CRMStore: ObservableObject {
    static let shared = CRMStore()

    @Published private(set) var contacts: [CRMContact] = []
    @Published private(set) var tasks: [CRMTask] = []
    @Published private(set) var interactions: [CRMInteraction] = []

    private let contactsKey = "TLI.CRM.contacts.v1"
    private let tasksKey = "TLI.CRM.tasks.v1"
    private let interactionsKey = "TLI.CRM.interactions.v1"
    private let analytics = TLIAnalyticsStore.shared
    private let db = Firestore.firestore()
    private let conventionID = TLIEventInfo.current.conventionID
    private var listener: ListenerRegistration?
    private var isApplyingRemoteSnapshot = false
    private var lastContactsBlob = ""
    private var lastTasksBlob = ""
    private var lastInteractionsBlob = ""

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

    // MARK: Derived

    var openTasks: [CRMTask] {
        tasks
            .filter { !$0.isCompleted }
            .sorted {
                if $0.dueAt != $1.dueAt {
                    return $0.dueAt < $1.dueAt
                }
                if $0.priority.rawValue != $1.priority.rawValue {
                    return $0.priority.rawValue > $1.priority.rawValue
                }
                return $0.updatedAt > $1.updatedAt
            }
    }

    var completedTasks: [CRMTask] {
        tasks
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? $0.updatedAt) > ($1.completedAt ?? $1.updatedAt) }
    }

    var overdueTasksCount: Int {
        openTasks.filter { $0.isOverdue }.count
    }

    var dueTodayTasksCount: Int {
        let calendar = Calendar.current
        return openTasks.filter { calendar.isDateInToday($0.dueAt) }.count
    }

    var recentTouchCount: Int {
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        return interactions.filter { $0.timestamp >= cutoff }.count
    }

    // MARK: Queries

    func contact(id: UUID?) -> CRMContact? {
        guard let id else { return nil }
        return contacts.first(where: { $0.id == id })
    }

    func contactNamed(_ name: String) -> CRMContact? {
        let key = canonicalName(name)
        guard !key.isEmpty else { return nil }
        return contacts.first(where: { canonicalName($0.fullName) == key })
    }

    func contactName(for id: UUID?) -> String {
        contact(id: id)?.fullName ?? "Unassigned"
    }

    func tasks(forContactID contactID: UUID, includeCompleted: Bool = true) -> [CRMTask] {
        tasks
            .filter { $0.contactID == contactID && (includeCompleted || !$0.isCompleted) }
            .sorted {
                if $0.isCompleted != $1.isCompleted {
                    return !$0.isCompleted
                }
                return $0.dueAt < $1.dueAt
            }
    }

    func interactions(forContactID contactID: UUID, limit: Int? = nil) -> [CRMInteraction] {
        let filtered = interactions
            .filter { $0.contactID == contactID }
            .sorted { $0.timestamp > $1.timestamp }
        guard let limit else { return filtered }
        return Array(filtered.prefix(max(0, limit)))
    }

    func recentInteractions(limit: Int = 20) -> [CRMInteraction] {
        Array(interactions.sorted { $0.timestamp > $1.timestamp }.prefix(max(0, limit)))
    }

    // MARK: Contact CRUD

    @discardableResult
    func upsertContact(
        id: UUID? = nil,
        name: String,
        organization: String,
        roleTitle: String,
        kind: CRMContactKind,
        email: String,
        phone: String,
        tags: [String],
        notes: String
    ) -> CRMContact? {
        let cleanName = cleaned(name)
        guard !cleanName.isEmpty else { return nil }

        let targetID = id ?? contactNamed(cleanName)?.id
        if let targetID,
           let index = contacts.firstIndex(where: { $0.id == targetID }) {
            var current = contacts[index]
            current.fullName = cleanName
            current.organization = cleaned(organization)
            current.roleTitle = cleaned(roleTitle)
            current.kind = kind
            current.email = cleaned(email)
            current.phone = cleaned(phone)
            current.tags = normalizedTags(from: tags)
            current.notes = cleaned(notes)
            current.updatedAt = .now
            contacts[index] = current
            sortAndPersistContacts()
            sync()
            analytics.track(
                name: "crm_contact_updated",
                domain: "crm",
                actor: "staff",
                metadata: ["kind": kind.rawValue.lowercased()]
            )
            return current
        }

        let contact = CRMContact(
            fullName: cleanName,
            organization: cleaned(organization),
            roleTitle: cleaned(roleTitle),
            kind: kind,
            email: cleaned(email),
            phone: cleaned(phone),
            tags: normalizedTags(from: tags),
            notes: cleaned(notes)
        )
        contacts.append(contact)
        sortAndPersistContacts()
        sync()
        analytics.track(
            name: "crm_contact_created",
            domain: "crm",
            actor: "staff",
            metadata: ["kind": kind.rawValue.lowercased()]
        )
        return contact
    }

    @discardableResult
    func upsertContact(_ contact: CRMContact) -> CRMContact {
        let isUpdate = contacts.contains(where: { $0.id == contact.id })
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index] = contact
        } else {
            contacts.append(contact)
        }
        sortAndPersistContacts()
        sync()
        analytics.track(
            name: isUpdate ? "crm_contact_updated" : "crm_contact_created",
            domain: "crm",
            actor: "staff",
            metadata: ["kind": contact.kind.rawValue.lowercased()]
        )
        return contact
    }

    func deleteContact(id: UUID) {
        contacts.removeAll(where: { $0.id == id })
        tasks.removeAll(where: { $0.contactID == id })
        interactions.removeAll(where: { $0.contactID == id })
        sortAndPersistContacts()
        persistTasks()
        persistInteractions()
        sync()
        analytics.track(
            name: "crm_contact_deleted",
            domain: "crm",
            actor: "staff",
            metadata: ["contact_id": id.uuidString.lowercased()]
        )
    }

    func setSquareCustomerID(_ squareCustomerID: String, for contactID: UUID) {
        guard let index = contacts.firstIndex(where: { $0.id == contactID }) else { return }
        contacts[index].squareCustomerID = squareCustomerID
        contacts[index].updatedAt = .now
        sortAndPersistContacts()
        sync()
        analytics.track(
            name: "crm_square_customer_linked",
            domain: "crm",
            actor: "staff",
            metadata: ["contact_id": contactID.uuidString.lowercased()]
        )
    }

    // MARK: Task CRUD

    @discardableResult
    func upsertTask(
        id: UUID? = nil,
        title: String,
        details: String,
        dueAt: Date,
        priority: CRMTaskPriority,
        owner: String,
        contactID: UUID?
    ) -> CRMTask? {
        let cleanTitle = cleaned(title)
        guard !cleanTitle.isEmpty else { return nil }

        if let id,
           let index = tasks.firstIndex(where: { $0.id == id }) {
            var current = tasks[index]
            current.title = cleanTitle
            current.details = cleaned(details)
            current.dueAt = dueAt
            current.priority = priority
            current.owner = cleaned(owner).isEmpty ? "Staff" : cleaned(owner)
            current.contactID = contactID
            current.updatedAt = .now
            tasks[index] = current
            persistTasks()
            sync()
            analytics.track(
                name: "crm_task_updated",
                domain: "crm",
                actor: "staff",
                metadata: ["priority": priority.title.lowercased()]
            )
            return current
        }

        let task = CRMTask(
            title: cleanTitle,
            details: cleaned(details),
            dueAt: dueAt,
            priority: priority,
            owner: cleaned(owner).isEmpty ? "Staff" : cleaned(owner),
            contactID: contactID
        )
        tasks.append(task)
        persistTasks()
        sync()
        analytics.track(
            name: "crm_task_created",
            domain: "crm",
            actor: "staff",
            metadata: ["priority": priority.title.lowercased()]
        )
        return task
    }

    func toggleTaskCompletion(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted.toggle()
        tasks[index].updatedAt = .now
        tasks[index].completedAt = tasks[index].isCompleted ? .now : nil
        persistTasks()
        sync()
        analytics.track(
            name: tasks[index].isCompleted ? "crm_task_completed" : "crm_task_reopened",
            domain: "crm",
            actor: "staff",
            metadata: ["task_id": id.uuidString.lowercased()]
        )
    }

    func deleteTask(id: UUID) {
        tasks.removeAll(where: { $0.id == id })
        persistTasks()
        sync()
        analytics.track(
            name: "crm_task_deleted",
            domain: "crm",
            actor: "staff",
            metadata: ["task_id": id.uuidString.lowercased()]
        )
    }

    // MARK: Timeline CRUD

    @discardableResult
    func addInteraction(
        contactID: UUID? = nil,
        kind: CRMInteractionKind,
        title: String,
        details: String,
        sessionName: String,
        owner: String,
        timestamp: Date = .now
    ) -> CRMInteraction? {
        let cleanTitle = cleaned(title)
        guard !cleanTitle.isEmpty else { return nil }

        let interaction = CRMInteraction(
            contactID: contactID,
            kind: kind,
            title: cleanTitle,
            details: cleaned(details),
            sessionName: cleaned(sessionName),
            owner: cleaned(owner).isEmpty ? "Staff" : cleaned(owner),
            timestamp: timestamp
        )
        interactions.append(interaction)
        persistInteractions()

        if let contactID,
           let index = contacts.firstIndex(where: { $0.id == contactID }) {
            contacts[index].lastInteractionAt = timestamp
            contacts[index].updatedAt = .now
            sortAndPersistContacts()
        }
        sync()

        analytics.track(
            name: "crm_interaction_added",
            domain: "crm",
            actor: interaction.owner.lowercased(),
            metadata: ["kind": kind.rawValue.lowercased()]
        )

        return interaction
    }

    func deleteInteraction(id: UUID) {
        interactions.removeAll(where: { $0.id == id })
        persistInteractions()
        sync()
        analytics.track(
            name: "crm_interaction_deleted",
            domain: "crm",
            actor: "staff",
            metadata: ["interaction_id": id.uuidString.lowercased()]
        )
    }

    // MARK: Guest Import

    @discardableResult
    func importGuest(
        name: String,
        role: String,
        categoryLabel: String,
        sponsorship: String?,
        bio: String
    ) -> CRMContact? {
        let existing = contactNamed(name)
        var tags = ["Guest", categoryLabel]
        if let sponsorship,
           !cleaned(sponsorship).isEmpty {
            tags.append("Sponsored")
        }

        let mergedNotes: String
        if let existing,
           !cleaned(existing.notes).isEmpty {
            mergedNotes = existing.notes
        } else {
            mergedNotes = cleaned(bio)
        }

        guard let contact = upsertContact(
            id: existing?.id,
            name: name,
            organization: sponsorship ?? "",
            roleTitle: role,
            kind: .guest,
            email: existing?.email ?? "",
            phone: existing?.phone ?? "",
            tags: Array(Set((existing?.tags ?? []) + tags)).sorted(),
            notes: mergedNotes
        ) else {
            return nil
        }

        _ = addInteraction(
            contactID: contact.id,
            kind: .note,
            title: existing == nil ? "Added from Guests" : "Updated from Guests",
            details: "Imported guest profile details from in-app guest directory.",
            sessionName: "",
            owner: "App"
        )

        return contact
    }

    // MARK: Persistence

    private func load() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: contactsKey),
           let decoded = try? decoder.decode([CRMContact].self, from: data) {
            contacts = decoded
        }

        if let data = defaults.data(forKey: tasksKey),
           let decoded = try? decoder.decode([CRMTask].self, from: data) {
            tasks = decoded
        }

        if let data = defaults.data(forKey: interactionsKey),
           let decoded = try? decoder.decode([CRMInteraction].self, from: data) {
            interactions = decoded
        }

        sortAndPersistContacts(persist: false)
    }

    private func sortAndPersistContacts(persist: Bool = true) {
        contacts.sort { lhs, rhs in
            lhs.fullName.localizedCaseInsensitiveCompare(rhs.fullName) == .orderedAscending
        }
        if persist { persistContacts() }
    }

    private func persistContacts() {
        if let data = try? encoder.encode(contacts) {
            UserDefaults.standard.set(data, forKey: contactsKey)
        }
    }

    private func persistTasks() {
        if let data = try? encoder.encode(tasks) {
            UserDefaults.standard.set(data, forKey: tasksKey)
        }
    }

    private func persistInteractions() {
        if let data = try? encoder.encode(interactions) {
            UserDefaults.standard.set(data, forKey: interactionsKey)
        }
    }

    private var document: DocumentReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("crm")
            .document("shared_state")
    }

    private func startListening() {
        listener?.remove()
        listener = document.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("❌ Firestore CRM error: \(error.localizedDescription)")
                    return
                }

                guard let data = snapshot?.data() else {
                    self.sync()
                    return
                }

                let contactsBlob = data["contactsBlob"] as? String ?? ""
                let tasksBlob = data["tasksBlob"] as? String ?? ""
                let interactionsBlob = data["interactionsBlob"] as? String ?? ""

                guard
                    contactsBlob != self.lastContactsBlob ||
                    tasksBlob != self.lastTasksBlob ||
                    interactionsBlob != self.lastInteractionsBlob
                else { return }

                self.applyRemote(
                    contactsBlob: contactsBlob,
                    tasksBlob: tasksBlob,
                    interactionsBlob: interactionsBlob
                )
            }
        }
    }

    private func sync() {
        guard !isApplyingRemoteSnapshot else { return }
        let contactsBlob = encodedBlob(from: contacts)
        let tasksBlob = encodedBlob(from: tasks)
        let interactionsBlob = encodedBlob(from: interactions)

        guard
            contactsBlob != lastContactsBlob ||
            tasksBlob != lastTasksBlob ||
            interactionsBlob != lastInteractionsBlob
        else { return }

        lastContactsBlob = contactsBlob
        lastTasksBlob = tasksBlob
        lastInteractionsBlob = interactionsBlob

        document.setData(
            [
                "contactsBlob": contactsBlob,
                "tasksBlob": tasksBlob,
                "interactionsBlob": interactionsBlob,
                "updatedAt": Timestamp(date: .now)
            ],
            merge: true
        ) { error in
            if let error {
                print("❌ Firestore CRM sync error: \(error.localizedDescription)")
            }
        }
    }

    private func applyRemote(
        contactsBlob: String,
        tasksBlob: String,
        interactionsBlob: String
    ) {
        isApplyingRemoteSnapshot = true
        if let contactsData = Data(base64Encoded: contactsBlob),
           let decoded = try? decoder.decode([CRMContact].self, from: contactsData) {
            contacts = decoded
            UserDefaults.standard.set(contactsData, forKey: contactsKey)
            lastContactsBlob = contactsBlob
        }
        if let tasksData = Data(base64Encoded: tasksBlob),
           let decoded = try? decoder.decode([CRMTask].self, from: tasksData) {
            tasks = decoded
            UserDefaults.standard.set(tasksData, forKey: tasksKey)
            lastTasksBlob = tasksBlob
        }
        if let interactionsData = Data(base64Encoded: interactionsBlob),
           let decoded = try? decoder.decode([CRMInteraction].self, from: interactionsData) {
            interactions = decoded
            UserDefaults.standard.set(interactionsData, forKey: interactionsKey)
            lastInteractionsBlob = interactionsBlob
        }
        sortAndPersistContacts(persist: false)
        isApplyingRemoteSnapshot = false
    }

    private func encodedBlob<T: Encodable>(from value: T) -> String {
        guard let data = try? encoder.encode(value) else { return "" }
        return data.base64EncodedString()
    }

    // MARK: Helpers

    private func cleaned(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func canonicalName(_ value: String) -> String {
        cleaned(value)
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    private func normalizedTags(from rawTags: [String]) -> [String] {
        let parts = rawTags
            .flatMap { $0.split(separator: ",") }
            .map { cleaned(String($0)) }
            .filter { !$0.isEmpty }

        var seen = Set<String>()
        var result: [String] = []
        for tag in parts {
            let key = tag.lowercased()
            if seen.insert(key).inserted {
                result.append(tag)
            }
        }
        return result.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}
