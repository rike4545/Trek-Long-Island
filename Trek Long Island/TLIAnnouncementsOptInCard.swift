// Copyright Bryan Carroll. All rights reserved.
//
//  TLIAnnouncementsOptInCard.swift
//  Trek Long Island
//
//  Launch deliberately never asks for notification permission -- the system alert
//  landing on top of the dismissing splash/welcome covers is what made the app look
//  frozen. This card is the replacement: it sits on the Bridge, asks nothing on its
//  own, and only raises the system prompt when the user taps it. By then the app is
//  fully loaded and idle, so there is no modal collision to freeze on.
//

import SwiftUI
import UserNotifications

@MainActor
struct TLIAnnouncementsOptInCard: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase

    /// Once dismissed the card stays gone. Settings > Notification Access remains
    /// the permanent home for enabling alerts.
    @AppStorage(TLIAnnouncementsOptIn.dismissedKey) private var isDismissed = false

    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var hasResolvedStatus = false
    @State private var isRequesting = false

    /// Shown only while the decision is genuinely still open. Granting, denying, or
    /// dismissing all hide it for good -- a permission card that reappears after
    /// "Don't Allow" is nagging, not helpful.
    private var isVisible: Bool {
        hasResolvedStatus && !isDismissed && status == .notDetermined
    }

    var body: some View {
        Group {
            if isVisible {
                card
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .task {
            await refreshStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            // The user may have granted permission in iOS Settings while away.
            guard phase == .active else { return }
            Task { await refreshStatus() }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(TLITheme.accentSoft(scheme))
                        .frame(width: 38, height: 38)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.accent(scheme))
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Turn on announcements")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    Text("Get schedule changes, room moves, and day-of updates the moment they happen.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button {
                    dismissCard()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textTertiary(scheme))
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss announcements prompt")
            }

            Button {
                Task { await requestPermission() }
            } label: {
                HStack(spacing: 8) {
                    if isRequesting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "bell.and.waves.left.and.right.fill")
                    }
                    Text(isRequesting ? "Requesting…" : "Allow Notifications")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SettingsPrimaryButtonStyle(accent: TLITheme.accent(scheme)))
            .disabled(isRequesting)

            Text("You can change this any time in Settings › Notification Access.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(TLITheme.textTertiary(scheme))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tliPanelSurface(
            cornerRadius: 20,
            fillOpacity: scheme == .dark ? 0.90 : 0.96,
            borderOpacity: 0.72,
            shadowRadius: 6,
            shadowY: 3
        )
        .accessibilityElement(children: .contain)
    }

    private func refreshStatus() async {
        // Read-only: this reports the current setting and never raises a prompt.
        let current = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        status = current
        hasResolvedStatus = true
    }

    private func requestPermission() async {
        guard !isRequesting else { return }
        isRequesting = true
        defer { isRequesting = false }

        // User-initiated, from a fully loaded and idle app -- nothing is animating
        // underneath, so the system alert has no cover to collide with.
        status = await NotificationPermissionCoordinator.requestAuthorizationIfNeeded()

        if NotificationPermissionCoordinator.isAuthorizedLike(status) {
            await NotificationManager.shared.refreshNow()
        }
    }

    private func dismissCard() {
        isDismissed = true
    }
}

enum TLIAnnouncementsOptIn {
    static let dismissedKey = "TLI.Home.dismissedAnnouncementsPrompt"
}
