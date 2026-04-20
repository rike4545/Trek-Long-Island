// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

@MainActor
struct SupportCenterView: View {
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var opsStore = ConventionOpsStore.shared

    @State private var selectedCategory: SupportTicketCategory = .medical
    @State private var severity: SupportTicketSeverity = .medium
    @State private var privacy: SupportTicketPrivacy = .staffOnly
    @State private var title: String = ""
    @State private var location: String = ""
    @State private var details: String = ""
    @State private var reporter: String = "Attendee"
    @State private var didSubmit = false

    private var publicRecentTickets: [SupportTicket] {
        opsStore.activeTickets(limit: 20)
            .filter { $0.privacy == .publicBoard }
    }

    private var hiddenTicketCount: Int {
        max(0, opsStore.activeTickets(limit: 20).count - publicRecentTickets.count)
    }

    var body: some View {
        List {
            Section("Quick Help") {
                quickHelpRow(icon: "cross.case.fill", title: "Medical help", body: "Find the nearest staff member immediately. In a life-threatening emergency, call 911.")
                quickHelpRow(icon: "exclamationmark.shield.fill", title: "Safety concern", body: "Move to a staffed area and report details. Staff can escalate to venue security.")
                quickHelpRow(icon: "person.crop.circle.badge.exclamationmark", title: "Harassment report", body: "Report to Information Desk or staff immediately. Include where and when it happened.")
                quickHelpRow(icon: "figure.2.and.child.holdinghands", title: "Lost person", body: "Notify staff with last known location, description, and contact details.")
                quickHelpRow(icon: "shippingbox.fill", title: "Lost item", body: "Check Information Desk / Lost & Found and file a ticket below.")
            }

            Section("Submit Support Ticket") {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(SupportTicketCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }

                Picker("Severity", selection: $severity) {
                    ForEach(SupportTicketSeverity.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }

                Picker("Privacy", selection: $privacy) {
                    ForEach(SupportTicketPrivacy.allCases) { option in
                        Label(option.title, systemImage: option.symbolName).tag(option)
                    }
                }

                Text(privacy.helpText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Short title", text: $title)
                TextField("Location", text: $location)
                TextField("Your name/role", text: $reporter)
                TextField("Details", text: $details, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)

                Button("Submit Ticket") {
                    opsStore.submitTicket(
                        SupportTicket(
                            category: selectedCategory,
                            severity: severity,
                            privacy: privacy,
                            title: title.trimmedOrFallback("\(selectedCategory.title) request"),
                            location: location.trimmedOrFallback("Location not provided"),
                            details: details.trimmedOrFallback("No additional details provided."),
                            reporter: reporter.trimmedOrFallback("Attendee")
                        )
                    )
                    title = ""
                    location = ""
                    details = ""
                    privacy = .staffOnly
                    didSubmit = true
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("Recent Tickets (Public)") {
                if publicRecentTickets.isEmpty {
                    Text("No public tickets yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(publicRecentTickets.prefix(10)) { ticket in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(ticket.title)
                                    .font(.headline)
                                Spacer(minLength: 8)
                                Text(ticket.status.title)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }

                            Text("\(ticket.category.title) • \(ticket.location)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(ticket.updatedAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 3)
                    }
                }

                if hiddenTicketCount > 0 {
                    Text("\(hiddenTicketCount) ticket(s) are private and only visible to staff operations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        .navigationTitle("Support Center")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ticket submitted", isPresented: $didSubmit) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Thanks. Staff can now track this in Live Ops.")
        }
    }

    @ViewBuilder
    private func quickHelpRow(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }
}

private extension String {
    func trimmedOrFallback(_ fallback: String) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

#Preview {
    NavigationStack {
        SupportCenterView()
    }
}
