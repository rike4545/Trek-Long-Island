// Copyright Bryan Carroll. All rights reserved.
//
//  PhotoAutographTrackerView.swift
//  Trek Long Island
//
//  Local tracker for photo ops, autographs, selfies, and table stops.
//

import SwiftUI
import UserNotifications

private let trackerTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

private struct PhotoAutographTask: Identifiable, Hashable, Codable {
    enum Kind: String, CaseIterable, Identifiable, Codable {
        case photoOp
        case autograph
        case selfie
        case tableVisit

        var id: String { rawValue }

        var title: String {
            switch self {
            case .photoOp: return "Photo Op"
            case .autograph: return "Autograph"
            case .selfie: return "Selfie"
            case .tableVisit: return "Table Visit"
            }
        }

        var icon: String {
            switch self {
            case .photoOp: return "camera.fill"
            case .autograph: return "pencil.and.scribble"
            case .selfie: return "person.crop.square"
            case .tableVisit: return "rectangle.grid.1x2.fill"
            }
        }
    }

    let id: UUID
    var guestName: String
    var kind: Kind
    var time: Date
    var location: String
    var note: String
    var isComplete: Bool

    init(
        id: UUID = UUID(),
        guestName: String,
        kind: Kind,
        time: Date,
        location: String,
        note: String,
        isComplete: Bool = false
    ) {
        self.id = id
        self.guestName = guestName
        self.kind = kind
        self.time = time
        self.location = location
        self.note = note
        self.isComplete = isComplete
    }
}

@MainActor
struct PhotoAutographTrackerView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @AppStorage("TLI.PhotoAutographTracker.itemsJSON") private var itemsJSON: String = ""

    @State private var items: [PhotoAutographTask] = []
    @State private var isShowingAddSheet = false

    private let reminderLeadTime: TimeInterval = 15 * 60

    private var sortedItems: [PhotoAutographTask] {
        items.sorted {
            if $0.isComplete != $1.isComplete {
                return !$0.isComplete
            }
            return $0.time < $1.time
        }
    }

    private var openItemsCount: Int {
        items.filter { !$0.isComplete }.count
    }

    private var completedItemsCount: Int {
        items.filter(\.isComplete).count
    }

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    autographPricingCard
                    addButton
                    trackerList
                }
                .adaptiveContentWidth(
                    maxWidth: TLILayout.defaultContentMaxWidth,
                    horizontalPadding: hSizeClass == .regular ? 24 : 16,
                    verticalPadding: 12
                )
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Photo & Autographs")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddSheet = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .onAppear(perform: loadItems)
        .onChange(of: items) { _, newValue in
            saveItems(newValue)
        }
        .sheet(isPresented: $isShowingAddSheet) {
            PhotoAutographEditorView { task in
                items.append(task)
                scheduleReminder(for: task)
                isShowingAddSheet = false
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
            if scheme == .dark {
                Color.black.opacity(0.30)
            }
        }
        .ignoresSafeArea()
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(RisaTheme.accent(scheme).opacity(0.15))

                    Image(systemName: "camera.on.rectangle.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RisaTheme.accent(scheme))
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Photo & Autograph Tracker")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))

                    Text("Keep purchased ops, signing stops, and table notes together while you move through the con.")
                        .font(.subheadline)
                        .foregroundStyle(RisaTheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                metricPill(title: "Open", value: "\(openItemsCount)", icon: "clock")
                metricPill(title: "Done", value: "\(completedItemsCount)", icon: "checkmark.circle.fill")
                metricPill(title: "Total", value: "\(items.count)", icon: "list.bullet")
            }
        }
        .padding(16)
        .tliPanelSurface(cornerRadius: 24, fillOpacity: 0.98, borderOpacity: 0.88, shadowRadius: 14, shadowY: 7)
    }

    private func metricPill(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .imageScale(.small)
                Text(title)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(RisaTheme.textSecondary(scheme))

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(TLITheme.controlShape(cornerRadius: 16).fill(TLITheme.chipBackground(scheme).opacity(0.82)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 16)
                .stroke(TLITheme.border(scheme).opacity(0.45), lineWidth: TLITheme.hairline)
        )
    }

    private var addButton: some View {
        Button {
            isShowingAddSheet = true
        } label: {
            Label("Add Photo Op or Autograph", systemImage: "plus.circle.fill")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(RisaTheme.accent(scheme))
    }

    private var autographPricingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "signature")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(RisaTheme.accent(scheme))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Autograph Pricing")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))

                    Text(TLIAutographPricing2026.sourceDescription)
                        .font(.footnote)
                        .foregroundStyle(RisaTheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            LazyVGrid(columns: pricingColumns, alignment: .leading, spacing: 8) {
                ForEach(TLIAutographPricing2026.entries) { entry in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(entry.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RisaTheme.textPrimary(scheme))
                            .lineLimit(2)
                            .minimumScaleFactor(0.88)

                        Spacer(minLength: 8)

                        Text(entry.priceLabel)
                            .font(.subheadline.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(RisaTheme.accent(scheme))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minHeight: 44)
                    .background(
                        TLITheme.controlShape(cornerRadius: 14)
                            .fill(TLITheme.cardBackground(scheme).opacity(0.70))
                    )
                    .overlay(
                        TLITheme.controlShape(cornerRadius: 14)
                            .stroke(TLITheme.border(scheme).opacity(0.32), lineWidth: TLITheme.hairline)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(entry.name), autograph \(entry.priceLabel)")
                }
            }

            Link(destination: TLIAutographPricing2026.sourceURL) {
                Label("Open official pricing page", systemImage: "arrow.up.forward.square")
                    .font(.footnote.weight(.semibold))
            }
            .tint(RisaTheme.accent(scheme))
        }
        .padding(16)
        .tliPanelSurface(cornerRadius: 24, fillOpacity: 0.98, borderOpacity: 0.84, shadowRadius: 12, shadowY: 6)
    }

    private var pricingColumns: [GridItem] {
        let minimum: CGFloat = hSizeClass == .regular ? 240 : 220
        return [GridItem(.adaptive(minimum: minimum), spacing: 8)]
    }

    private var trackerList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .foregroundStyle(RisaTheme.accent(scheme))
                Text("Tracked Items")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))
            }

            if sortedItems.isEmpty {
                emptyState
            } else {
                ForEach(sortedItems) { task in
                    trackerRow(task)
                }
            }
        }
        .padding(16)
        .tliPanelSurface(cornerRadius: 24, fillOpacity: 0.98, borderOpacity: 0.84, shadowRadius: 12, shadowY: 6)
    }

    private var emptyState: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.headline.weight(.bold))
                .foregroundStyle(RisaTheme.accent(scheme))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text("Nothing tracked yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))

                Text("Add photo ops, autographs, selfies, or table visits so they stay visible on con day.")
                    .font(.footnote)
                    .foregroundStyle(RisaTheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.cardBackground(scheme).opacity(0.78)))
    }

    private func trackerRow(_ task: PhotoAutographTask) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                toggleComplete(task)
            } label: {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(task.isComplete ? .green : RisaTheme.accent(scheme))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isComplete ? "Mark incomplete" : "Mark complete")

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Image(systemName: task.kind.icon)
                        .imageScale(.small)
                        .foregroundStyle(RisaTheme.accent(scheme))

                    Text(task.kind.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RisaTheme.accent(scheme))

                    Spacer(minLength: 0)
                }

                Text(task.guestName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))
                    .strikethrough(task.isComplete, color: RisaTheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                Label(trackerTimeFormatter.string(from: task.time), systemImage: "calendar")
                    .font(.footnote)
                    .foregroundStyle(RisaTheme.textSecondary(scheme))

                if !task.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Label(task.location, systemImage: "mappin.and.ellipse")
                        .font(.footnote)
                        .foregroundStyle(RisaTheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if reminderDate(for: task) != nil, !task.isComplete {
                    Label("Reminder 15 minutes before", systemImage: "bell.badge.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RisaTheme.accentSecondary(scheme))
                }

                if !task.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(task.note)
                        .font(.footnote)
                        .foregroundStyle(RisaTheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(role: .destructive) {
                delete(task)
            } label: {
                Image(systemName: "trash")
                    .imageScale(.small)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Delete tracked item")
        }
        .padding(14)
        .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.cardBackground(scheme).opacity(task.isComplete ? 0.55 : 0.88)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 18)
                .stroke(TLITheme.border(scheme).opacity(0.55), lineWidth: TLITheme.hairline)
        )
    }

    private func loadItems() {
        guard let data = itemsJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([PhotoAutographTask].self, from: data) else {
            items = []
            return
        }
        items = decoded
    }

    private func saveItems(_ newValue: [PhotoAutographTask]) {
        guard let data = try? JSONEncoder().encode(newValue),
              let json = String(data: data, encoding: .utf8) else {
            return
        }
        itemsJSON = json
    }

    private func toggleComplete(_ task: PhotoAutographTask) {
        guard let index = items.firstIndex(where: { $0.id == task.id }) else { return }
        items[index].isComplete.toggle()
        if items[index].isComplete {
            cancelReminder(for: task)
        } else {
            scheduleReminder(for: items[index])
        }
    }

    private func delete(_ task: PhotoAutographTask) {
        items.removeAll { $0.id == task.id }
        cancelReminder(for: task)
    }

    private func reminderIdentifier(for task: PhotoAutographTask) -> String {
        "TLI.PhotoAutographTracker.\(task.id.uuidString)"
    }

    private func reminderDate(for task: PhotoAutographTask) -> Date? {
        let date = task.time.addingTimeInterval(-reminderLeadTime)
        return date > Date() ? date : nil
    }

    private func scheduleReminder(for task: PhotoAutographTask) {
        guard !task.isComplete, let reminderDate = reminderDate(for: task) else {
            cancelReminder(for: task)
            return
        }

        let identifier = reminderIdentifier(for: task)
        Task {
            let status = await NotificationPermissionCoordinator.requestAuthorizationIfNeeded()
            guard NotificationPermissionCoordinator.isAuthorizedLike(status) else { return }

            let content = UNMutableNotificationContent()
            content.title = "\(task.kind.title): \(task.guestName)"
            content.body = task.location.isEmpty
                ? "This stop starts in 15 minutes."
                : "This stop starts in 15 minutes at \(task.location)."
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    private func cancelReminder(for task: PhotoAutographTask) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderIdentifier(for: task)])
    }
}

private struct PhotoAutographEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    let onSave: (PhotoAutographTask) -> Void

    @State private var guestName = ""
    @State private var kind: PhotoAutographTask.Kind = .photoOp
    @State private var time = Date()
    @State private var location = ""
    @State private var note = ""

    private var canSave: Bool {
        !guestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Guest or group name", text: $guestName)
                    Picker("Type", selection: $kind) {
                        ForEach(PhotoAutographTask.Kind.allCases) { kind in
                            Label(kind.title, systemImage: kind.icon)
                                .tag(kind)
                        }
                    }
                    DatePicker("Time", selection: $time, displayedComponents: [.date, .hourAndMinute])
                    TextField("Location", text: $location)
                }

                Section("Notes") {
                    TextField("Ticket number, table note, or reminder", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(TLITheme.backgroundGradient(scheme))
            .navigationTitle("Add Tracker Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let task = PhotoAutographTask(
                            guestName: guestName.trimmingCharacters(in: .whitespacesAndNewlines),
                            kind: kind,
                            time: time,
                            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onSave(task)
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PhotoAutographTrackerView()
    }
}
