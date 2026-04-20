// Copyright Bryan Carroll. All rights reserved.
//
//  CRMView.swift
//  Trek Long Island
//
//  Convention CRM UI:
//  - Dashboard metrics
//  - Contacts
//  - Follow-up tasks
//  - Timeline interactions
//

import SwiftUI

private enum CRMTaskFilter: String, CaseIterable, Identifiable {
    case open
    case today
    case overdue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .open: return "Open"
        case .today: return "Today"
        case .overdue: return "Overdue"
        }
    }
}

private struct CRMContactDraft {
    var name: String
    var organization: String
    var roleTitle: String
    var kind: CRMContactKind
    var email: String
    var phone: String
    var tags: [String]
    var notes: String
}

private struct CRMTaskDraft {
    var title: String
    var details: String
    var dueAt: Date
    var priority: CRMTaskPriority
    var owner: String
    var contactID: UUID?
}

private struct CRMInteractionDraft {
    var contactID: UUID?
    var kind: CRMInteractionKind
    var title: String
    var details: String
    var sessionName: String
    var owner: String
    var timestamp: Date
}

@MainActor
struct CRMView: View {
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var store = CRMStore.shared

    @State private var searchText: String = ""
    @State private var selectedKind: CRMContactKind? = nil
    @State private var taskFilter: CRMTaskFilter = .open

    @State private var showingAddContact = false
    @State private var showingAddTask = false
    @State private var showingAddInteraction = false
    @State private var seedContactForTask: UUID? = nil

    private var filteredContacts: [CRMContact] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return store.contacts.filter { contact in
            let kindMatch = selectedKind == nil || contact.kind == selectedKind
            let queryMatch = query.isEmpty || contact.searchableBlob.contains(query)
            return kindMatch && queryMatch
        }
    }

    private var filteredTasks: [CRMTask] {
        let calendar = Calendar.current
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let base: [CRMTask]
        switch taskFilter {
        case .open:
            base = store.openTasks
        case .today:
            base = store.openTasks.filter { calendar.isDateInToday($0.dueAt) }
        case .overdue:
            base = store.openTasks.filter { $0.isOverdue }
        }

        guard !query.isEmpty else { return base }

        return base.filter { task in
            let contactName = store.contactName(for: task.contactID).lowercased()
            return task.title.lowercased().contains(query)
                || task.details.lowercased().contains(query)
                || contactName.contains(query)
                || task.owner.lowercased().contains(query)
        }
    }

    var body: some View {
        List {
            overviewSection
            tasksSection
            contactsSection
            timelineSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        .navigationTitle("Convention CRM")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .searchable(text: $searchText, prompt: "Search contacts, tags, tasks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddContact = true
                    } label: {
                        Label("New Contact", systemImage: "person.badge.plus")
                    }

                    Button {
                        seedContactForTask = nil
                        showingAddTask = true
                    } label: {
                        Label("New Task", systemImage: "checklist")
                    }

                    Button {
                        showingAddInteraction = true
                    } label: {
                        Label("New Timeline Note", systemImage: "note.text.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddContact) {
            NavigationStack {
                CRMContactEditorView(existing: nil) { draft in
                    _ = store.upsertContact(
                        name: draft.name,
                        organization: draft.organization,
                        roleTitle: draft.roleTitle,
                        kind: draft.kind,
                        email: draft.email,
                        phone: draft.phone,
                        tags: draft.tags,
                        notes: draft.notes
                    )
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingAddTask) {
            NavigationStack {
                CRMTaskEditorView(existing: nil, contacts: store.contacts, seedContactID: seedContactForTask) { draft in
                    _ = store.upsertTask(
                        title: draft.title,
                        details: draft.details,
                        dueAt: draft.dueAt,
                        priority: draft.priority,
                        owner: draft.owner,
                        contactID: draft.contactID
                    )
                }
            }
            .presentationDetents([.medium, .large])
            .onDisappear { seedContactForTask = nil }
        }
        .sheet(isPresented: $showingAddInteraction) {
            NavigationStack {
                CRMInteractionEditorView(contacts: store.contacts, seedContactID: nil) { draft in
                    _ = store.addInteraction(
                        contactID: draft.contactID,
                        kind: draft.kind,
                        title: draft.title,
                        details: draft.details,
                        sessionName: draft.sessionName,
                        owner: draft.owner,
                        timestamp: draft.timestamp
                    )
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var overviewSection: some View {
        Section("Today") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CRMStatCard(
                        title: "Contacts",
                        value: "\(store.contacts.count)",
                        symbolName: "person.2.fill",
                        tint: TLITheme.accent(scheme)
                    )
                    CRMStatCard(
                        title: "Open Tasks",
                        value: "\(store.openTasks.count)",
                        symbolName: "checklist",
                        tint: .blue
                    )
                    CRMStatCard(
                        title: "Due Today",
                        value: "\(store.dueTodayTasksCount)",
                        symbolName: "calendar.badge.clock",
                        tint: .orange
                    )
                    CRMStatCard(
                        title: "Overdue",
                        value: "\(store.overdueTasksCount)",
                        symbolName: "exclamationmark.triangle.fill",
                        tint: .red
                    )
                    CRMStatCard(
                        title: "24h Touches",
                        value: "\(store.recentTouchCount)",
                        symbolName: "waveform.path.ecg",
                        tint: .green
                    )
                }
                .padding(.vertical, 4)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }

    private var tasksSection: some View {
        Section("Follow-Ups") {
            Picker("Task Filter", selection: $taskFilter) {
                ForEach(CRMTaskFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            if filteredTasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checkmark.circle",
                    description: Text("Add a follow-up task to keep sponsor, guest, and attendee conversations moving.")
                )
            } else {
                ForEach(filteredTasks.prefix(12)) { task in
                    CRMTaskRow(
                        task: task,
                        contactName: store.contactName(for: task.contactID)
                    )
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            store.toggleTaskCompletion(id: task.id)
                        } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            store.deleteTask(id: task.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var contactsSection: some View {
        Section("People & Organizations") {
            HStack(spacing: 10) {
                Text("Type")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textSecondary(scheme))

                Spacer(minLength: 8)

                Menu {
                    Button {
                        selectedKind = nil
                    } label: {
                        Label("All", systemImage: "line.3.horizontal.decrease.circle")
                    }

                    ForEach(CRMContactKind.allCases) { kind in
                        Button {
                            selectedKind = kind
                        } label: {
                            Label(kind.title, systemImage: kind.symbolName)
                        }
                    }
                } label: {
                    Label(
                        selectedKind?.title ?? "All",
                        systemImage: selectedKind?.symbolName ?? "line.3.horizontal.decrease.circle"
                    )
                    .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
            }

            if filteredContacts.isEmpty {
                ContentUnavailableView(
                    "No Contacts",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("Create a contact or save guests into CRM to start tracking relationships.")
                )
            } else {
                ForEach(filteredContacts) { contact in
                    NavigationLink {
                        CRMContactDetailView(contactID: contact.id)
                    } label: {
                        CRMContactRow(
                            contact: contact,
                            openTaskCount: store.tasks(forContactID: contact.id, includeCompleted: false).count
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            store.deleteContact(id: contact.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            seedContactForTask = contact.id
                            showingAddTask = true
                        } label: {
                            Label("Task", systemImage: "checklist")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
    }

    private var timelineSection: some View {
        Section("Recent Timeline") {
            let recent = store.recentInteractions(limit: 10)

            if recent.isEmpty {
                ContentUnavailableView(
                    "No Timeline Events",
                    systemImage: "clock.badge.questionmark",
                    description: Text("Log meetings, panel interactions, and follow-up notes as they happen.")
                )
            } else {
                ForEach(recent) { interaction in
                    CRMInteractionRow(
                        interaction: interaction,
                        contactName: store.contactName(for: interaction.contactID)
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            store.deleteInteraction(id: interaction.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

@MainActor
private struct CRMContactDetailView: View {
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var store = CRMStore.shared
    @ObservedObject private var squareIntegration = SquareIntegrationStore.shared

    let contactID: UUID

    @State private var showingEditContact = false
    @State private var showingAddTask = false
    @State private var showingAddInteraction = false
    @State private var isSyncingSquare = false
    @State private var showingSquareSyncAlert = false
    @State private var squareSyncMessage = ""

    private var contact: CRMContact? {
        store.contact(id: contactID)
    }

    var body: some View {
        Group {
            if let contact {
                List {
                    profileSection(contact)
                    tasksSection(contact)
                    timelineSection(contact)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showingEditContact = true
                            } label: {
                                Label("Edit Contact", systemImage: "pencil")
                            }

                            Button {
                                showingAddTask = true
                            } label: {
                                Label("Add Task", systemImage: "checklist")
                            }

                            Button {
                                showingAddInteraction = true
                            } label: {
                                Label("Add Timeline Note", systemImage: "note.text.badge.plus")
                            }

                            Button {
                                Task { await syncContactToSquare(contact) }
                            } label: {
                                Label(
                                    isSyncingSquare ? "Syncing with Square..." : squareSyncActionTitle,
                                    systemImage: "creditcard.and.123"
                                )
                            }
                            .disabled(isSyncingSquare || !squareSyncEnabled)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingEditContact) {
                    NavigationStack {
                        CRMContactEditorView(existing: contact) { draft in
                            _ = store.upsertContact(
                                id: contact.id,
                                name: draft.name,
                                organization: draft.organization,
                                roleTitle: draft.roleTitle,
                                kind: draft.kind,
                                email: draft.email,
                                phone: draft.phone,
                                tags: draft.tags,
                                notes: draft.notes
                            )
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $showingAddTask) {
                    NavigationStack {
                        CRMTaskEditorView(existing: nil, contacts: store.contacts, seedContactID: contact.id) { draft in
                            _ = store.upsertTask(
                                title: draft.title,
                                details: draft.details,
                                dueAt: draft.dueAt,
                                priority: draft.priority,
                                owner: draft.owner,
                                contactID: draft.contactID
                            )
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $showingAddInteraction) {
                    NavigationStack {
                        CRMInteractionEditorView(contacts: store.contacts, seedContactID: contact.id) { draft in
                            _ = store.addInteraction(
                                contactID: draft.contactID,
                                kind: draft.kind,
                                title: draft.title,
                                details: draft.details,
                                sessionName: draft.sessionName,
                                owner: draft.owner,
                                timestamp: draft.timestamp
                            )
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
                .alert("Square Sync", isPresented: $showingSquareSyncAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(squareSyncMessage)
                }
            } else {
                ContentUnavailableView(
                    "Contact Not Found",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("This CRM record may have been deleted.")
                )
            }
        }
        .navigationTitle(contact?.fullName ?? "Contact")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
    }

    private func profileSection(_ contact: CRMContact) -> some View {
        Section("Profile") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(TLITheme.accentSoft(scheme))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Text(contact.initials)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(TLITheme.textPrimary(scheme))
                        }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(contact.fullName)
                            .font(.headline)
                            .foregroundStyle(TLITheme.textPrimary(scheme))

                        Text(contact.roleTitle.isEmpty ? contact.kind.title : contact.roleTitle)
                            .font(.subheadline)
                            .foregroundStyle(TLITheme.textSecondary(scheme))

                        Text(contact.displayOrganization)
                            .font(.caption)
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                    }
                }

                if !contact.email.isEmpty {
                    Label(contact.email, systemImage: "envelope")
                        .font(.footnote)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }

                if !contact.phone.isEmpty {
                    Label(contact.phone, systemImage: "phone")
                        .font(.footnote)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }

                if let squareCustomerID = contact.squareCustomerID,
                   !squareCustomerID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Label("Square ID: \(squareCustomerID)", systemImage: "checkmark.seal.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label(squareIntegration.connection.status.title, systemImage: squareConnectionSymbol)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(squareConnectionColor)

                    Text(squareIntegration.connection.statusSummary)
                        .font(.footnote)
                        .foregroundStyle(TLITheme.textSecondary(scheme))

                    if !squareIntegration.connection.capabilities.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(squareIntegration.connection.capabilities) { capability in
                                    Text(capability.title)
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(TLITheme.accentSoft(scheme), in: Capsule())
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }
                }

                if !contact.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(contact.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(TLITheme.accentSoft(scheme), in: Capsule())
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                if !contact.notes.isEmpty {
                    Text(contact.notes)
                        .font(.subheadline)
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func tasksSection(_ contact: CRMContact) -> some View {
        Section("Open Tasks") {
            let tasks = store.tasks(forContactID: contact.id, includeCompleted: false)

            if tasks.isEmpty {
                Text("No open tasks for this contact.")
                    .font(.subheadline)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            } else {
                ForEach(tasks) { task in
                    CRMTaskRow(task: task, contactName: contact.fullName)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                store.toggleTaskCompletion(id: task.id)
                            } label: {
                                Label("Done", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.deleteTask(id: task.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private func timelineSection(_ contact: CRMContact) -> some View {
        Section("Timeline") {
            let items = store.interactions(forContactID: contact.id, limit: 25)

            if items.isEmpty {
                Text("No timeline entries yet.")
                    .font(.subheadline)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            } else {
                ForEach(items) { item in
                    CRMInteractionRow(interaction: item, contactName: contact.fullName)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.deleteInteraction(id: item.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private func syncContactToSquare(_ contact: CRMContact) async {
        isSyncingSquare = true
        defer { isSyncingSquare = false }

        do {
            let result = try await SquareCustomersClient.shared.sync(contact: contact)
            store.setSquareCustomerID(result.customerID, for: contact.id)

            switch result.action {
            case .created:
                squareSyncMessage = "Created Square customer \(result.customerID)."
            case .updated:
                squareSyncMessage = "Updated Square customer \(result.customerID)."
            }
        } catch {
            squareSyncMessage = error.localizedDescription
        }

        showingSquareSyncAlert = true
    }

    private var squareSyncEnabled: Bool {
        squareIntegration.connection.canSyncCustomers || SquareCustomersClient.isDirectAccessEnabledForDebug
    }

    private var squareSyncActionTitle: String {
        if squareIntegration.connection.canSyncCustomers {
            return "Sync to Square"
        }
        if SquareCustomersClient.isDirectAccessEnabledForDebug {
            return "Debug Sync to Square"
        }
        return "Square Not Connected"
    }

    private var squareConnectionSymbol: String {
        switch squareIntegration.connection.status {
        case .connected: return "link.circle.fill"
        case .pending: return "hourglass.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .disconnected: return "link.badge.minus"
        }
    }

    private var squareConnectionColor: Color {
        switch squareIntegration.connection.status {
        case .connected: return .green
        case .pending: return .orange
        case .error: return .red
        case .disconnected: return TLITheme.textSecondary(scheme)
        }
    }
}

private struct CRMStatCard: View {
    @Environment(\.colorScheme) private var scheme

    let title: String
    let value: String
    let symbolName: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbolName)
                .font(.headline)
                .foregroundStyle(tint)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(title)
                .font(.caption)
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
        .frame(width: 120, alignment: .leading)
        .padding(12)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }
}

private struct CRMTaskRow: View {
    @Environment(\.colorScheme) private var scheme

    let task: CRMTask
    let contactName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: task.priority.symbolName)
                    .foregroundStyle(priorityColor)

                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .strikethrough(task.isCompleted, color: .secondary)

                Spacer(minLength: 6)

                if task.isOverdue {
                    Text("Overdue")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.red.opacity(0.16), in: Capsule())
                        .foregroundStyle(.red)
                }
            }

            HStack(spacing: 10) {
                Label(contactName, systemImage: "person")
                    .lineLimit(1)

                Label(task.dueAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .lineLimit(1)
            }
            .font(.caption)
            .foregroundStyle(TLITheme.textSecondary(scheme))

            if !task.details.isEmpty {
                Text(task.details)
                    .font(.footnote)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low: return .green
        case .normal: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

private struct CRMContactRow: View {
    @Environment(\.colorScheme) private var scheme

    let contact: CRMContact
    let openTaskCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(TLITheme.accentSoft(scheme))
                .frame(width: 42, height: 42)
                .overlay {
                    Text(contact.initials)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(contact.fullName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text(contact.roleTitle.isEmpty ? contact.kind.title : contact.roleTitle)
                    .font(.caption)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .lineLimit(1)

                Text(contact.displayOrganization)
                    .font(.caption2)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(contact.kind.title)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(TLITheme.accentSoft(scheme), in: Capsule())
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                if openTaskCount > 0 {
                    Text("\(openTaskCount) open")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 3)
    }
}

private struct CRMInteractionRow: View {
    @Environment(\.colorScheme) private var scheme

    let interaction: CRMInteraction
    let contactName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: interaction.kind.symbolName)
                    .foregroundStyle(TLITheme.accent(scheme))

                Text(interaction.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Spacer(minLength: 8)

                Text(interaction.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }

            HStack(spacing: 10) {
                Label(contactName, systemImage: "person")
                if !interaction.sessionName.isEmpty {
                    Label(interaction.sessionName, systemImage: "calendar")
                }
                Label(interaction.owner, systemImage: "person.crop.circle")
            }
            .font(.caption)
            .foregroundStyle(TLITheme.textSecondary(scheme))
            .lineLimit(1)

            if !interaction.details.isEmpty {
                Text(interaction.details)
                    .font(.footnote)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CRMContactEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let existing: CRMContact?
    private let onSave: (CRMContactDraft) -> Void

    @State private var name: String
    @State private var organization: String
    @State private var roleTitle: String
    @State private var kind: CRMContactKind
    @State private var email: String
    @State private var phone: String
    @State private var tagsInput: String
    @State private var notes: String

    init(existing: CRMContact?, onSave: @escaping (CRMContactDraft) -> Void) {
        self.existing = existing
        self.onSave = onSave
        _name = State(initialValue: existing?.fullName ?? "")
        _organization = State(initialValue: existing?.organization ?? "")
        _roleTitle = State(initialValue: existing?.roleTitle ?? "")
        _kind = State(initialValue: existing?.kind ?? .attendee)
        _email = State(initialValue: existing?.email ?? "")
        _phone = State(initialValue: existing?.phone ?? "")
        _tagsInput = State(initialValue: existing?.tags.joined(separator: ", ") ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Full Name", text: $name)
                TextField("Role", text: $roleTitle)
                TextField("Organization", text: $organization)

                Picker("Type", selection: $kind) {
                    ForEach(CRMContactKind.allCases) { option in
                        Label(option.title, systemImage: option.symbolName).tag(option)
                    }
                }
            }

            Section("Contact") {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
            }

            Section("Ops") {
                TextField("Tags (comma separated)", text: $tagsInput)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(4...8)
            }
        }
        .navigationTitle(existing == nil ? "New Contact" : "Edit Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(
                        CRMContactDraft(
                            name: name,
                            organization: organization,
                            roleTitle: roleTitle,
                            kind: kind,
                            email: email,
                            phone: phone,
                            tags: tagsInput
                                .split(separator: ",")
                                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty },
                            notes: notes
                        )
                    )
                    dismiss()
                }
                .disabled(!canSave)
            }
        }
    }
}

private struct CRMTaskEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let existing: CRMTask?
    private let contacts: [CRMContact]
    private let onSave: (CRMTaskDraft) -> Void

    @State private var title: String
    @State private var details: String
    @State private var dueAt: Date
    @State private var priority: CRMTaskPriority
    @State private var owner: String
    @State private var contactID: UUID?

    init(
        existing: CRMTask?,
        contacts: [CRMContact],
        seedContactID: UUID?,
        onSave: @escaping (CRMTaskDraft) -> Void
    ) {
        self.existing = existing
        self.contacts = contacts
        self.onSave = onSave

        _title = State(initialValue: existing?.title ?? "")
        _details = State(initialValue: existing?.details ?? "")
        _dueAt = State(initialValue: existing?.dueAt ?? Date().addingTimeInterval(2 * 60 * 60))
        _priority = State(initialValue: existing?.priority ?? .normal)
        _owner = State(initialValue: existing?.owner ?? "Staff")
        _contactID = State(initialValue: existing?.contactID ?? seedContactID)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("Task") {
                TextField("Title", text: $title)
                TextField("Details", text: $details, axis: .vertical)
                    .lineLimit(3...6)
                DatePicker("Due", selection: $dueAt)
            }

            Section("Assignment") {
                Picker("Priority", selection: $priority) {
                    ForEach(CRMTaskPriority.allCases) { option in
                        Label(option.title, systemImage: option.symbolName).tag(option)
                    }
                }

                TextField("Owner", text: $owner)

                Picker("Related Contact", selection: $contactID) {
                    Text("None").tag(UUID?.none)
                    ForEach(contacts) { contact in
                        Text(contact.fullName).tag(Optional(contact.id))
                    }
                }
            }
        }
        .navigationTitle(existing == nil ? "New Task" : "Edit Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(
                        CRMTaskDraft(
                            title: title,
                            details: details,
                            dueAt: dueAt,
                            priority: priority,
                            owner: owner,
                            contactID: contactID
                        )
                    )
                    dismiss()
                }
                .disabled(!canSave)
            }
        }
    }
}

private struct CRMInteractionEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let contacts: [CRMContact]
    private let onSave: (CRMInteractionDraft) -> Void

    @State private var contactID: UUID?
    @State private var kind: CRMInteractionKind = .note
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var sessionName: String = ""
    @State private var owner: String = "Staff"
    @State private var timestamp: Date = .now

    init(
        contacts: [CRMContact],
        seedContactID: UUID?,
        onSave: @escaping (CRMInteractionDraft) -> Void
    ) {
        self.contacts = contacts
        self.onSave = onSave
        _contactID = State(initialValue: seedContactID)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("Timeline Entry") {
                Picker("Type", selection: $kind) {
                    ForEach(CRMInteractionKind.allCases) { option in
                        Label(option.title, systemImage: option.symbolName).tag(option)
                    }
                }

                TextField("Title", text: $title)
                TextField("Details", text: $details, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section("Context") {
                TextField("Session / Panel (optional)", text: $sessionName)
                TextField("Owner", text: $owner)
                DatePicker("Time", selection: $timestamp)

                Picker("Related Contact", selection: $contactID) {
                    Text("None").tag(UUID?.none)
                    ForEach(contacts) { contact in
                        Text(contact.fullName).tag(Optional(contact.id))
                    }
                }
            }
        }
        .navigationTitle("New Timeline Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(
                        CRMInteractionDraft(
                            contactID: contactID,
                            kind: kind,
                            title: title,
                            details: details,
                            sessionName: sessionName,
                            owner: owner,
                            timestamp: timestamp
                        )
                    )
                    dismiss()
                }
                .disabled(!canSave)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CRMView()
    }
}
