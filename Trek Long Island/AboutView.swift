// Copyright Bryan Carroll. All rights reserved.
//
//  AboutView.swift
//  Trek Long Island
//
//  About Trek Long Island + this app
//  • Risa gradient (no starfield)
//  • Glass cards for convention info, app details, links, and credits
//

import SwiftUI

@MainActor
struct AboutView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL
    @AppStorage(TLITypographyPreference.storageKey) private var typographyRaw: String = TLITypographyPreference.defaultPreference.rawValue

    // MARK: - Links (update as needed)

    private let websiteURL        = URL(string: "https://www.treklongisland.com")!
    // /schedule and /code-of-conduct both 404 — the live site uses /programs/ for
    // programming and a /policies/ hub that links harassment, refund, children's,
    // and weapon-and-prop policy pages.
    private let scheduleURL       = URL(string: "https://treklongisland.com/programs/")!
    private let codeOfConductURL  = URL(string: "https://treklongisland.com/policies/")!
    private let feedbackURL       = URL(string: "https://qualtricsxmm8q5gxrhq.qualtrics.com/jfe/form/SV_1TvkCrIKgaEYHPM")!
    private let shopURL           = URL(string: "https://made-in-ny-shop.fourthwall.com/")!
    private let conventionBundleURL = URL(string: "https://made-in-ny-shop.fourthwall.com/products/convention-bundle")!
    private let punkShopURL              = URL(string: "https://punkarmy.net/store/treklongisland/")!

    // MARK: - App Info

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "v\(version) (\(build))"
    }

    private var selectedTypography: TLITypographyPreference {
        TLITypographyPreference.fromStoredRawValue(typographyRaw)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TLITheme.backgroundGradient(scheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header

                        conventionCard
                        appCard
                        legalCard
                        linksCard
                        creditsCard
                        footerMeta
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            TLIBrandHeader(
                title: TLIAppBranding.appDisplayName,
                subtitle: "A fan-built guide for Trek Long Island weekend.",
                supportingText: "Distinctive by design, accessible by default, and tuned for quick convention navigation."
            )

            Text("A fan-run Star Trek convention on Long Island, celebrating the shows, films, and the community that has grown around them.")
                .font(selectedTypography.font(.footnote))
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var conventionCard: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(RisaTheme.accentSoft(scheme))
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(RisaTheme.accent(scheme))
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 8) {
                    Text("About the Convention")
                        .font(selectedTypography.font(.title3, weight: .semibold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))

                    Text("Trek Long Island brings together fans, guests, vendors, artists, and community groups for a weekend of panels, photo ops, cosplay, and conversation.")
                        .font(selectedTypography.font(.footnote))
                        .foregroundStyle(RisaTheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Programming, guests, and policies can change. Always follow posted signage and official announcements on-site for the most current information.")
                        .font(selectedTypography.font(.footnote))
                        .foregroundStyle(RisaTheme.textTertiary(scheme))
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var appCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("About this App")
                    .font(selectedTypography.font(.title3, weight: .semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))

                Text("\(TLIAppBranding.appDisplayName) is the iPhone companion for Trek Long Island. It’s designed to help you browse guests, view the schedule, find locations, and stay informed about convention updates.")
                    .font(selectedTypography.font(.footnote))
                    .foregroundStyle(RisaTheme.textSecondary(scheme))

                VStack(alignment: .leading, spacing: 6) {
                    bullet(icon: "calendar.badge.clock",
                           title: "Check programming quickly",
                           text: "Browse the schedule and guest listings from your device.")
                    bullet(icon: "map",
                           title: "Find your way around",
                           text: "Use maps and room names to get to panels, vendors, and photo ops.")
                    bullet(icon: "bell.badge",
                           title: "Stay informed",
                           text: "See important updates and messages from the convention team.")
                    bullet(icon: "ticket",
                           title: "Not a ticket or credential",
                           text: "This app does not replace your physical or digital badge and is not proof of purchase.")
                }
                .padding(.top, 4)
            }
        }
    }

    private var legalCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Legal & Ownership Notes")
                    .font(selectedTypography.font(.headline, weight: .semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))

                Text("The mobile app codebase and original app artwork are protected copyrighted works. All rights reserved.")
                    .font(selectedTypography.font(.footnote))
                    .foregroundStyle(RisaTheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                Text("Star Trek and related marks, characters, and franchise elements belong to their respective owners, including Paramount Global. References are used in a fan-celebratory convention context.")
                    .font(selectedTypography.font(.footnote))
                    .foregroundStyle(RisaTheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                Text("This app is a companion guide and does not replace tickets, credentials, posted signage, event policies, or on-site instructions.")
                    .font(selectedTypography.font(.caption))
                    .foregroundStyle(RisaTheme.textTertiary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var linksCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Official Links")
                    .font(selectedTypography.font(.headline, weight: .semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))

                Text("For the most accurate and up-to-date information, always refer to the official Trek Long Island website and announcements.")
                    .font(selectedTypography.font(.footnote))
                    .foregroundStyle(RisaTheme.textSecondary(scheme))

                VStack(spacing: 10) {
                    linkButton(
                        icon: "globe",
                        title: "Trek Long Island Website",
                        subtitle: "News, updates, and general info",
                        url: websiteURL
                    )

                    linkButton(
                        icon: "calendar",
                        title: "Schedule (Web)",
                        subtitle: "Latest programming grid",
                        url: scheduleURL
                    )

                    linkButton(
                        icon: "hand.raised.fill",
                        title: "Policies",
                        subtitle: "Harassment, refunds, children's, and weapon/prop policies",
                        url: codeOfConductURL
                    )

                    linkButton(
                        icon: "bag.fill",
                        title: "Made in NY Shop",
                        subtitle: "Official merch and shop items",
                        url: shopURL
                    )

                    linkButton(
                        icon: "gift.fill",
                        title: "Convention Swag Bundle",
                        subtitle: "Quick link to the Fourthwall bundle",
                        url: conventionBundleURL
                    )

                    linkButton(
                        icon: "sparkles",
                        title: "Trek Long Island Punk Shop",
                        subtitle: "Additional Trek Long Island swag",
                        url: punkShopURL
                    )

                    linkButton(
                        icon: "envelope.fill",
                        title: "Feedback & Support Form",
                        subtitle: "Send app questions, corrections, or support requests",
                        url: feedbackURL
                    )
                }
                .padding(.top, 4)
            }
        }
    }

    private var creditsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Credits & Thanks")
                    .font(selectedTypography.font(.headline, weight: .semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))

                Text("Trek Long Island is possible thanks to the convention organizers, volunteers, guests, vendors, and the Star Trek fan community.")
                    .font(selectedTypography.font(.footnote))
                    .foregroundStyle(RisaTheme.textSecondary(scheme))

                VStack(alignment: .leading, spacing: 4) {
                    Text("• Convention staff & volunteers")
                    Text("• Guests, panelists, and moderators")
                    Text("• Vendors, artists, and community groups")
                    Text("• Everyone who attends, shares, and supports the event")
                }
                .font(selectedTypography.font(.footnote))
                .foregroundStyle(RisaTheme.textSecondary(scheme))

                Text("Star Trek and all related marks are trademarks of Paramount Global and used here in a fan-celebratory context.")
                    .font(selectedTypography.font(.caption))
                    .foregroundStyle(RisaTheme.textTertiary(scheme))
                    .padding(.top, 4)
            }
        }
    }

    private var footerMeta: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("App Info")
                .font(selectedTypography.font(.caption, weight: .semibold))
                .foregroundStyle(RisaTheme.textSecondary(scheme))

            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RisaTheme.textSecondary(scheme))

                Text(appVersion)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(RisaTheme.textSecondary(scheme))

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    // MARK: - Helpers

    private func bullet(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(RisaTheme.accent(scheme))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))

                Text(text)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(RisaTheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private func linkButton(icon: String, title: String, subtitle: String, url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(RisaTheme.accentSoft(scheme))
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(RisaTheme.accent(scheme))
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))

                    Text(subtitle)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(RisaTheme.textSecondary(scheme))
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RisaTheme.textSecondary(scheme))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RisaTheme.cardBackground(scheme).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(RisaTheme.cardBorder(scheme).opacity(0.8), lineWidth: 0.5)
        )
    }
}

// MARK: - Local Glass Card

private struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        ZStack {
            if reduceTransparency {
                shape
                    .fill(RisaTheme.cardBackground(scheme))
            } else {
                shape
                    .fill(.regularMaterial)
            }
        }
        .overlay(
            shape
                .strokeBorder(RisaTheme.cardBorder(scheme).opacity(0.9), lineWidth: 1)
        )
        .overlay(
            content
                .padding(18)
        )
    }
}

// MARK: - Previews

#Preview("About – Dark") {
    AboutView()
        .environment(\.colorScheme, .dark)
}

#Preview("About – Light") {
    AboutView()
        .environment(\.colorScheme, .light)
}
