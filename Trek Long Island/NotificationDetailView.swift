// Copyright Bryan Carroll. All rights reserved.
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Detail

struct NotificationDetailView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL
    @ObservedObject private var manager = NotificationManager.shared

    let notification: RisaNotification

    @State private var copiedToast = false

    private let merchandiseURL = URL(string: "https://made-in-ny-shop.fourthwall.com/")!
    private let conventionBundleURL = URL(string: "https://made-in-ny-shop.fourthwall.com/products/convention-bundle")!
    private let etsyShopURL = URL(string: "https://www.etsy.com/shop/TrekLongIsland")!

    private var resolved: RisaNotification {
        // Prefer the live copy from the manager so read/unread toggles reflect instantly.
        if let docID = notification.documentID,
           let match = manager.notifications.first(where: { $0.documentID == docID }) {
            return match
        }
        if let match = manager.notifications.first(where: { $0.id == notification.id }) {
            return match
        }
        return notification
    }

    var body: some View {
        let note = resolved

        ZStack {
            // Background: themed gradient + subtle wash for better contrast
            ZStack {
                TLITheme.backgroundGradient(scheme)
                if scheme == .dark {
                    Color.black.opacity(0.30)
                } else {
                    Color.black.opacity(0.06)
                }
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header(note)
                    Divider().overlay(TLITheme.border(scheme))
                    messageSection(note)
                    if isPostConventionThankYou(note) {
                        postConventionLinksSection
                    }
                    if let appStoreURL = softwareUpdateURL(for: note) {
                        softwareUpdateActionSection(appStoreURL)
                    }
                    metaSection(note)

                    if copiedToast {
                        copiedPill
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Alert Detail")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .toolbar { toolbar(note) }
        .onAppear {
            // Mark as read when opened (published only).
            if !note.isRead { manager.markAsRead(note) }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func toolbar(_ note: RisaNotification) -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                manager.toggleRead(note)
            } label: {
                Image(systemName: note.isRead ? "envelope.badge" : "envelope.open")
            }
            .accessibilityLabel(note.isRead ? "Mark as unread" : "Mark as read")

            Button {
                copyToClipboard(note)
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .accessibilityLabel("Copy")

            ShareLink(item: shareText(note)) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share")
        }
    }

    // MARK: - Sections

    private func header(_ note: RisaNotification) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(TLITheme.accent(scheme).opacity(note.isRead ? 0.18 : 0.26))
                        .frame(width: 44, height: 44)

                    Image(systemName: note.isPriority
                            ? "bell.badge.fill"
                            : (note.isRead ? "bell" : "bell.fill"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(TLITheme.accent(scheme))
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(note.title)
                        .font(.title2.bold())
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        if !note.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            metaChip(text: note.category, systemImage: "tag")
                        }

                        metaChip(
                            text: note.role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? "Guest"
                                : note.role.capitalized,
                            systemImage: "person.crop.circle"
                        )

                        Spacer(minLength: 8)

                        if note.isPriority {
                            Text("PRIORITY")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red, in: Capsule())
                                .foregroundStyle(.white)
                                .accessibilityLabel("Priority notification")
                        }
                    }
                }
            }
        }
    }

    private func messageSection(_ note: RisaNotification) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Message")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(note.message.isEmpty ? "—" : note.message)
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .shadow(
            color: TLITheme.cardShadowColor(scheme),
            radius: scheme == .dark ? 6 : 4,
            y: 3
        )
    }

    private var postConventionLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keep Exploring")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            NavigationLink {
                DiscountsView()
            } label: {
                notificationActionRow(
                    title: "Discounts & Deals",
                    detail: "Open partner offers, convention supplies, and app support links.",
                    systemImage: "tag.fill",
                    trailingImage: "chevron.right"
                )
            }
            .buttonStyle(.plain)

            Button {
                openURL(merchandiseURL)
            } label: {
                notificationActionRow(
                    title: "Made in NY Shop",
                    detail: "Shop merchandise and support the community after the convention.",
                    systemImage: "bag.fill",
                    trailingImage: "arrow.up.right"
                )
            }
            .buttonStyle(.plain)

            Button {
                openURL(conventionBundleURL)
            } label: {
                notificationActionRow(
                    title: "Convention Swag Bundle",
                    detail: "Open the Fourthwall bundle for convention swag.",
                    systemImage: "gift.fill",
                    trailingImage: "arrow.up.right"
                )
            }
            .buttonStyle(.plain)

            Button {
                openURL(etsyShopURL)
            } label: {
                notificationActionRow(
                    title: "Trek Long Island Etsy Shop",
                    detail: "Browse additional Trek Long Island swag on Etsy.",
                    systemImage: "sparkles",
                    trailingImage: "arrow.up.right"
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .shadow(
            color: TLITheme.cardShadowColor(scheme),
            radius: scheme == .dark ? 5 : 3,
            y: 3
        )
    }

    private func notificationActionRow(title: String, detail: String, systemImage: String, trailingImage: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(TLITheme.accent(scheme).opacity(0.18))
                    .frame(width: 42, height: 42)

                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLITheme.accent(scheme))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: trailingImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(TLITheme.textTertiary(scheme))
        }
        .padding(14)
        .background(
            TLITheme.accentSoft(scheme).opacity(scheme == .dark ? 0.34 : 0.46),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TLITheme.border(scheme).opacity(0.52), lineWidth: 1)
        )
    }

    private func softwareUpdateActionSection(_ appStoreURL: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Update")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Button {
                openURL(appStoreURL)
            } label: {
                notificationActionRow(
                    title: "Open App Store",
                    detail: "Install the newest available version of the app.",
                    systemImage: "arrow.down.circle.fill",
                    trailingImage: "arrow.up.right"
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .shadow(
            color: TLITheme.cardShadowColor(scheme),
            radius: scheme == .dark ? 5 : 3,
            y: 3
        )
    }

    private func metaSection(_ note: RisaNotification) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Details")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            VStack(spacing: 10) {
                HStack {
                    Label {
                        Text(note.timestamp, style: .time)
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .foregroundStyle(TLITheme.textSecondary(scheme))

                    Spacer()

                    Label {
                        Text(note.timestamp, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                }
                .font(.subheadline)

                HStack {
                    Label {
                        Text(note.timestamp, style: .relative)
                            .foregroundStyle(Color.primary.opacity(0.72))
                    } icon: {
                        Image(systemName: "timer")
                    }

                    Spacer()

                    Label {
                        Text(note.isRead ? "Read" : "Unread")
                            .foregroundStyle(note.isRead ? .secondary : TLITheme.accent(scheme))
                            .fontWeight(note.isRead ? .regular : .semibold)
                    } icon: {
                        Image(systemName: note.isRead ? "checkmark.circle" : "circle")
                    }
                }
                .font(.footnote)
            }
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .shadow(
            color: TLITheme.cardShadowColor(scheme),
            radius: scheme == .dark ? 5 : 3,
            y: 3
        )
    }

    // MARK: - Helpers

    private func metaChip(text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .imageScale(.small)
            Text(text)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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

    private func shareText(_ note: RisaNotification) -> String {
        var lines: [String] = [note.title]
        if !note.message.isEmpty { lines.append(note.message) }
        if isPostConventionThankYou(note) {
            lines.append("Discounts & Deals: available in the app")
            lines.append("Made in NY Shop: \(merchandiseURL.absoluteString)")
            lines.append("Convention Swag Bundle: \(conventionBundleURL.absoluteString)")
            lines.append("Trek Long Island Etsy Shop: \(etsyShopURL.absoluteString)")
        }
        if let appStoreURL = softwareUpdateURL(for: note) {
            lines.append("Update: \(appStoreURL.absoluteString)")
        }
        lines.append("Role: \(note.role)")
        lines.append("Category: \(note.category)")
        lines.append(note.timestamp.formatted(date: .abbreviated, time: .shortened))
        return lines.joined(separator: "\n")
    }

    private func isPostConventionThankYou(_ note: RisaNotification) -> Bool {
        note.documentID == "local-llnp-thank-you-2026" ||
            (
                note.title == "LLNP Note: Thank You, Away Team" &&
                note.category == "LLNP Note"
            )
    }

    private func softwareUpdateURL(for note: RisaNotification) -> URL? {
        guard note.documentID?.hasPrefix("local-software-update-") == true ||
                note.category.localizedCaseInsensitiveContains("Software Update") else {
            return nil
        }

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }

        let range = NSRange(note.message.startIndex..<note.message.endIndex, in: note.message)
        return detector
            .matches(in: note.message, options: [], range: range)
            .compactMap(\.url)
            .first
    }

    private func copyToClipboard(_ note: RisaNotification) {
        #if canImport(UIKit)
        UIPasteboard.general.string = shareText(note)
        #endif
        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            copiedToast = true
        }
        Task {
            try? await Task.sleep(for: .milliseconds(1400))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    copiedToast = false
                }
            }
        }
    }

    private var copiedPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(TLITheme.accent(scheme))
            Text("Copied")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        NotificationDetailView(
            notification: RisaNotification(
                id: UUID(),
                title: "Shuttlecraft Departure Delay",
                message: "Due to unexpected tribble activity near the docking ring, all shuttle departures are delayed by 15 minutes. Please remain in the promenade area until further notice.",
                role: "guest",
                category: "Operations",
                timestamp: Date(),
                isRead: false,
                isPriority: true
            )
        )
    }
    .environment(\.colorScheme, .dark)
}
#endif
