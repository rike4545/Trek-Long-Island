// Copyright Bryan Carroll. All rights reserved.
//
//  AdminCreateNotificationView.swift
//  Trek Long Island
//
//  Admin composer for new alerts.
//  • Title + message + optional location/track/link
//  • Audience role + category + priority
//  • Optional start/end window note for event alignment
//  • Submits to NotificationManager pending queue for reviewer approval
//

import SwiftUI

struct AdminCreateNotificationSeed {
    var title: String
    var message: String
    var location: String
    var track: String
    var deepLinkURL: String
    var audienceRaw: String
    var categoryRaw: String
    var priorityRaw: String
    var showAsBanner: Bool
    var limitToWindow: Bool
    var startDate: Date
    var endDate: Date

    static func roomEscalation(roomName: String, now: Date = .now) -> AdminCreateNotificationSeed {
        let room = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeRoom = room.isEmpty ? "Main Hall" : room
        return AdminCreateNotificationSeed(
            title: "\(safeRoom) reached capacity",
            message: "This room is at capacity. Use overflow rooms and follow staff queue guidance.",
            location: safeRoom,
            track: "Operations",
            deepLinkURL: "",
            audienceRaw: "guest",
            categoryRaw: "Operations",
            priorityRaw: "high",
            showAsBanner: true,
            limitToWindow: false,
            startDate: now,
            endDate: Calendar.current.date(byAdding: .hour, value: 2, to: now) ?? now.addingTimeInterval(2 * 3600)
        )
    }
}

@MainActor
struct AdminCreateNotificationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var manager = NotificationManager.shared

    // MARK: - Form State

    @State private var title: String
    @State private var message: String
    @State private var location: String
    @State private var track: String
    @State private var deepLinkURL: String

    @State private var audience: AdminNotificationAudience
    @State private var category: AdminNotificationCategory
    @State private var priority: AdminNotificationPriority
    @State private var showAsBanner: Bool

    @State private var limitToWindow: Bool
    @State private var startDate: Date
    @State private var endDate: Date

    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    init(seed: AdminCreateNotificationSeed? = nil) {
        let now = Date()
        let defaultEnd = Calendar.current.date(byAdding: .hour, value: 4, to: now) ?? now.addingTimeInterval(4 * 3600)

        _title = State(initialValue: seed?.title ?? "")
        _message = State(initialValue: seed?.message ?? "")
        _location = State(initialValue: seed?.location ?? "")
        _track = State(initialValue: seed?.track ?? "")
        _deepLinkURL = State(initialValue: seed?.deepLinkURL ?? "")

        let audience = AdminNotificationAudience(rawValue: seed?.audienceRaw ?? "") ?? .guest
        let category = AdminNotificationCategory(rawValue: seed?.categoryRaw ?? "") ?? .specialEvent
        let priority = AdminNotificationPriority(rawValue: seed?.priorityRaw ?? "") ?? .high
        _audience = State(initialValue: audience)
        _category = State(initialValue: category)
        _priority = State(initialValue: priority)
        _showAsBanner = State(initialValue: seed?.showAsBanner ?? true)

        _limitToWindow = State(initialValue: seed?.limitToWindow ?? false)
        _startDate = State(initialValue: seed?.startDate ?? now)
        _endDate = State(initialValue: seed?.endDate ?? defaultEnd)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                TLITheme.backgroundGradient(scheme)
                    .ignoresSafeArea()

                Form {
                    contentSection
                    audienceSection
                    timingSection
                    infoSection

                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(Color.red)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .disabled(isSaving)

                if isSaving {
                    savingOverlay
                }
            }
            .navigationTitle("New Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: submit) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Submit")
                        }
                    }
                    .disabled(!canSubmit || isSaving)
                }
            }
        }
    }

    // MARK: - Sections

    private var contentSection: some View {
        Section(header: Text("Content")) {
            TextField("Title", text: $title)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)

            TextField("Short message", text: $message, axis: .vertical)
                .lineLimit(2...5)
                .textInputAutocapitalization(.sentences)

            TextField("Location / Room (optional)", text: $location)
                .textInputAutocapitalization(.words)

            TextField("Track / Type (optional)", text: $track)
                .textInputAutocapitalization(.words)

            TextField("Deep link / URL (optional)", text: $deepLinkURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)

            Toggle("Treat as priority banner", isOn: $showAsBanner)
        }
    }

    private var audienceSection: some View {
        Section(header: Text("Audience, Category & Priority")) {
            Picker("Audience", selection: $audience) {
                ForEach(AdminNotificationAudience.allCases) { role in
                    Text(role.label).tag(role)
                }
            }

            Picker("Category", selection: $category) {
                ForEach(AdminNotificationCategory.allCases) { value in
                    Text(value.label).tag(value)
                }
            }

            Picker("Priority", selection: $priority) {
                ForEach(AdminNotificationPriority.allCases) { p in
                    HStack {
                        Text(p.label)
                        if let note = p.note {
                            Text("- \(note)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(p)
                }
            }
        }
    }

    private var timingSection: some View {
        Section(header: Text("Timing")) {
            Toggle("Limit to a schedule window", isOn: $limitToWindow.animation())

            if limitToWindow {
                DatePicker("Starts", selection: $startDate)
                DatePicker("Ends", selection: $endDate)
            }
        }
    }

    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("How this works")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))

                Text("""
                New alerts are submitted to **Pending** in Notification Manager. Reviewer or Master can edit, approve, and publish.
                """)
                .font(.footnote)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
            }
            .padding(.vertical, 4)
        }
    }

    private var savingOverlay: some View {
        VStack {
            ProgressView("Submitting to pending queue…")
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(radius: 10)
        }
    }

    // MARK: - Validation

    private var canSubmit: Bool {
        !title.trimmed.isEmpty &&
        !message.trimmed.isEmpty
    }

    // MARK: - Submit

    private func submit() {
        errorMessage = nil

        guard manager.canSubmitNotifications else {
            errorMessage = "Notifier or Master access is required to submit alerts."
            return
        }

        guard canSubmit else {
            errorMessage = "Please enter at least a title and message."
            return
        }

        if limitToWindow && endDate < startDate {
            errorMessage = "End time must be later than start time."
            return
        }

        isSaving = true

        let composedMessage = buildMessage()
        let isPriority = showAsBanner || priority != .normal
        let timestamp = limitToWindow ? startDate : Date()

        let notification = RisaNotification(
            title: title.trimmed,
            message: composedMessage,
            role: audience.rawValue,
            category: category.rawValue,
            timestamp: timestamp,
            isRead: false,
            isPriority: isPriority
        )

        manager.addNotification(notification)
        isSaving = false
        dismiss()
    }

    private func buildMessage() -> String {
        var lines: [String] = [message.trimmed]

        if !location.trimmed.isEmpty {
            lines.append("Location: \(location.trimmed)")
        }

        if !track.trimmed.isEmpty {
            lines.append("Track: \(track.trimmed)")
        }

        if limitToWindow {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            lines.append("Window: \(formatter.string(from: startDate)) - \(formatter.string(from: endDate))")
        }

        if !deepLinkURL.trimmed.isEmpty {
            lines.append("More info: \(deepLinkURL.trimmed)")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Supporting Types

private enum AdminNotificationAudience: String, CaseIterable, Identifiable {
    case guest
    case qvip
    case staff
    case ops
    case vendor

    var id: String { rawValue }

    var label: String {
        switch self {
        case .guest:  return "Attendees (general)"
        case .qvip:   return "QVIP / Premium"
        case .staff:  return "Staff"
        case .ops:    return "Operations"
        case .vendor: return "Vendors"
        }
    }
}

private enum AdminNotificationCategory: String, CaseIterable, Identifiable {
    case specialEvent = "Special Event"
    case schedule = "Schedule"
    case operations = "Operations"
    case safety = "Safety"
    case qvip = "QVIP"
    case general = "General"

    var id: String { rawValue }

    var label: String { rawValue }
}

private enum AdminNotificationPriority: String, CaseIterable, Identifiable {
    case normal
    case high
    case critical

    var id: String { rawValue }

    var label: String {
        switch self {
        case .normal:   return "Normal"
        case .high:     return "High"
        case .critical: return "Critical"
        }
    }

    var note: String? {
        switch self {
        case .normal:   return "Standard updates"
        case .high:     return "Time-sensitive"
        case .critical: return "Emergency / safety"
        }
    }
}

// MARK: - String Trim Helper

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
