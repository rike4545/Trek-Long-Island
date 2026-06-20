// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

/// Trek Long Island – Notification Card
/// - Dark-mode aware via TLITheme
/// - PRIORITY banner
/// - Optional role/category chips + timestamp
/// - Subtle unread accent wash
struct NotificationCardView: View {
    @Environment(\.colorScheme) private var scheme

    let notification: RisaNotification

    /// Show the "Role" chip at the bottom.
    let showRoleChip: Bool
    /// Show the "Category" chip at the bottom.
    let showCategoryChip: Bool
    /// Show the timestamp on the trailing edge.
    let showTimestamp: Bool

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 30
    @ScaledMetric(relativeTo: .body) private var corner: CGFloat = 16

    init(
        notification: RisaNotification,
        showRoleChip: Bool = true,
        showCategoryChip: Bool = true,
        showTimestamp: Bool = true
    ) {
        self.notification = notification
        self.showRoleChip = showRoleChip
        self.showCategoryChip = showCategoryChip
        self.showTimestamp = showTimestamp
    }

    // MARK: - Derived

    private var accentColor: Color {
        TLITheme.accent(scheme)
    }

    private var isPriority: Bool { notification.isPriority }
    private var isRead: Bool { notification.isRead }

    private var categoryText: String? {
        let trimmed = notification.category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var roleText: String {
        let trimmed = notification.role.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Guest" : trimmed.capitalized
    }

    private var a11ySummary: String {
        var parts: [String] = [notification.title]
        if !notification.message.isEmpty { parts.append(notification.message) }
        if let cat = categoryText { parts.append("Category \(cat).") }
        parts.append("Role \(roleText).")
        parts.append(isRead ? "Read." : "Unread.")
        if isPriority { parts.append("Priority.") }
        return parts.joined(separator: " ")
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow

            if !notification.message.isEmpty {
                messageText
            }

            metaRow
        }
        .padding(11)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: corner, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(
                    accentColor.opacity(isPriority ? 0.55 : 0.28),
                    lineWidth: isPriority ? 1.4 : 1
                )
        )
        .overlay(unreadAccentWash)
        .shadow(
            color: TLITheme.cardShadowColor(scheme),
            radius: scheme == .dark ? 6 : 3,
            y: 3
        )
        .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(a11ySummary))
        .accessibilityHint(Text("Opens notification details"))
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            // Icon block
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor.opacity(isRead ? 0.10 : 0.22))
                    .frame(width: iconSize, height: iconSize)

                Image(systemName: isPriority
                      ? "bell.badge.fill"
                      : (isRead ? "bell" : "bell.fill"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(notification.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 8)

                    if isPriority {
                        Text("PRIORITY")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.red, in: Capsule())
                            .foregroundStyle(.white)
                            .accessibilityLabel("Priority")
                    }
                }
            }
        }
    }

    private var messageText: some View {
        Text(notification.message)
            .font(.subheadline)
            .foregroundStyle(TLITheme.textSecondary(scheme))
            .lineLimit(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            if showRoleChip {
                metaChip(text: roleText, systemImage: "person.crop.circle")
            }

            if showCategoryChip, let cat = categoryText {
                metaChip(text: cat, systemImage: "tag")
            }

            Spacer(minLength: 8)

            if showTimestamp {
                Text(notification.timestamp, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
            }
        }
        .padding(.top, 2)
    }

    private func metaChip(text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .imageScale(.small)
            Text(text)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            TLITheme.cardBackground(scheme),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .foregroundStyle(TLITheme.textPrimary(scheme))
    }

    private var unreadAccentWash: some View {
        LinearGradient(
            colors: [
                accentColor.opacity(isRead ? 0.06 : 0.22),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .allowsHitTesting(false)
    }
}

#if DEBUG
#Preview {
    Group {
        // Dark mode – priority + unread
        NavigationStack {
            VStack(spacing: 16) {
                NotificationCardView(
                    notification: RisaNotification(
                        id: UUID(),
                        title: "Shuttlecraft Departure Delay",
                        message: "Due to unexpected tribble activity near the docking ring, all shuttle departures are delayed by 15 minutes.",
                        role: "guest",
                        category: "Operations",
                        timestamp: Date(),
                        isRead: false,
                        isPriority: true
                    )
                )

                NotificationCardView(
                    notification: RisaNotification(
                        id: UUID(),
                        title: "Vendor Hall Open",
                        message: "The vendor hall is now open on Deck 3. Stop by for artists, authors, and more!",
                        role: "guest",
                        category: "General",
                        timestamp: Date(),
                        isRead: true,
                        isPriority: false
                    )
                )
            }
            .padding()
            .background(TLITheme.backgroundGradient(.dark).ignoresSafeArea())
        }
        .environment(\.colorScheme, .dark)

        // Light mode example
        NavigationStack {
            NotificationCardView(
                notification: RisaNotification(
                    id: UUID(),
                    title: "Quiet Hours Reminder",
                    message: "Please remember that quiet hours begin at 11:00 PM on all guest room decks.",
                    role: "guest",
                    category: "Reminder",
                    timestamp: Date(),
                    isRead: false,
                    isPriority: false
                )
            )
            .padding()
            .background(TLITheme.backgroundGradient(.light).ignoresSafeArea())
        }
        .environment(\.colorScheme, .light)
    }
}
#endif
