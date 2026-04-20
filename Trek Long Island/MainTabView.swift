// Copyright Bryan Carroll. All rights reserved.
//  MainTabView.swift
//  Trek Long Island
//
//  Top-level navigation for the convention app.
//  Tabs = clear "places": Bridge, Schedule, Explore, Map, More.
//  Swift 6 • iOS 17+
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
enum TrekTab: String, Hashable {
    case today
    case schedule
    case guests
    case map
    case more
}

@MainActor
struct MainTabView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @EnvironmentObject private var usageInsightsStore: TLIUsageInsightsStore
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var interstitialAds = AdMobInterstitialManager.shared
    @AppStorage(TLITypographyPreference.storageKey) private var typographyRaw: String = TLITypographyPreference.defaultPreference.rawValue
    private let sfx = ZenSFX.shared
    @SceneStorage("MainTabView.selectedTab") private var selectedTabRaw: String = TrekTab.today.rawValue
    @SceneStorage("MainTabView.splitVisibility") private var splitVisibilityRaw: String = "all"
    @State private var splitVisibility: NavigationSplitViewVisibility = .all

    private var selectedTab: TrekTab {
        get { TrekTab(rawValue: selectedTabRaw) ?? .today }
        nonmutating set { selectedTabRaw = newValue.rawValue }
    }

    private var selectedTabBinding: Binding<TrekTab> {
        Binding(
            get: { selectedTab },
            set: { selectedTab = $0 }
        )
    }

    private var selectedTypography: TLITypographyPreference {
        TLITypographyPreference.fromStoredRawValue(typographyRaw)
    }

    var body: some View {
        Group {
            if hSizeClass == .regular {
                ipadSplitLayout
            } else {
                phoneTabLayout
            }
        }
        // Use RisaTheme accent to keep tab + controls consistent app-wide.
        .tint(RisaTheme.accent(scheme))
        .onAppear {
            interstitialAds.preloadIfEligible()
            usageInsightsStore.noteSelectedTab(selectedTab.rawValue)
        }
        .onChange(of: selectedTabRaw) { oldValue, newValue in
            let oldTab = TrekTab(rawValue: oldValue) ?? .today
            let newTab = TrekTab(rawValue: newValue) ?? .today
            guard oldTab != newTab else { return }
            usageInsightsStore.noteSelectedTab(newTab.rawValue)
            playNavigationFeedback()
            interstitialAds.noteTopLevelNavigationEvent()

            // Policy-safe placement: only after user-driven transitions
            // into non-critical browsing tabs.
            if newTab == .guests || newTab == .map {
                interstitialAds.maybePresentAfterTopLevelNavigation()
            }
        }
        .onAppear {
            syncSplitVisibility(for: hSizeClass)
        }
        .onChange(of: splitVisibility) { _, newValue in
            splitVisibilityRaw = navigationSplitViewVisibilityString(newValue)
        }
        .onChange(of: hSizeClass) { _, newValue in
            syncSplitVisibility(for: newValue)
        }
    }

    private var phoneTabLayout: some View {
        TabView(selection: selectedTabBinding) {

            // TODAY / HOME
            NavigationStack {
                HomeView()
                    .toolbar(.hidden, for: .navigationBar)
                    .tliNavBarStyle()
            }
            .accessibilityLabel(TLILCARSLabel.bridge)
            .accessibilityHint("Shows your command deck with convention highlights, quick actions, and announcements")
            .tabItem { Label(TLILCARSLabel.bridgeTab, systemImage: "sparkles") }
            .tag(TrekTab.today)

            // SCHEDULE
            NavigationStack {
                ScheduleView()
                    .tliNavBarStyle()
            }
            .accessibilityLabel(TLILCARSLabel.schedule)
            .accessibilityHint("Browse sessions by day, room, and favorites")
            .tabItem { Label(TLILCARSLabel.scheduleTab, systemImage: "calendar") }
            .tag(TrekTab.schedule)

            // GUESTS & VENDORS (Explore)
            NavigationStack {
                ExploreView()
                    .tliNavBarStyle()
            }
            .accessibilityLabel(TLILCARSLabel.explore)
            .accessibilityHint("Browse guests, exhibitors, maps, sponsors, and fan support")
            .tabItem { Label(TLILCARSLabel.exploreTab, systemImage: "person.2.fill") }
            .tag(TrekTab.guests)

            // MAP
            NavigationStack {
                MapsView()
                    .tliNavBarStyle()
            }
            .accessibilityLabel(TLILCARSLabel.map)
            .accessibilityHint("Open venue maps and route assistance")
            .tabItem { Label(TLILCARSLabel.mapTab, systemImage: "map") }
            .tag(TrekTab.map)

            // MORE (Hub)
            NavigationStack {
                MoreHubView()
                    .navigationTitle(TLILCARSLabel.more)
                    .navigationBarTitleDisplayMode(.inline)            // removes the big “empty” header space
                    .toolbar(.visible, for: .navigationBar)           // counteracts destinations that hide it
                    .toolbarBackground(.visible, for: .navigationBar) // avoids odd blank transitions
                    .tliNavBarStyle()
            }
            .accessibilityLabel(TLILCARSLabel.more)
            .accessibilityHint("Open settings, support tools, and additional features")
            .tabItem { Label(TLILCARSLabel.moreTab, systemImage: "ellipsis.circle") }
            .tag(TrekTab.more)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(RisaTheme.tabBarBackground(scheme), for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
    }

    private var ipadSplitLayout: some View {
        NavigationSplitView(columnVisibility: $splitVisibility) {
            List {
                Section(RisaTheme.isLCARSThemeEnabled ? "Primary Rails" : "Navigate") {
                    sidebarButton(TLILCARSLabel.bridge, icon: "sparkles", tab: .today)
                    sidebarButton(TLILCARSLabel.schedule, icon: "calendar", tab: .schedule)
                    sidebarButton(TLILCARSLabel.explore, icon: "person.2.fill", tab: .guests)
                    sidebarButton(TLILCARSLabel.map, icon: "map", tab: .map)
                    sidebarButton(TLILCARSLabel.more, icon: "ellipsis.circle", tab: .more)
                }

                Section(RisaTheme.isLCARSThemeEnabled ? "Active Feed" : "Now") {
                    HStack {
                        Label(RisaTheme.isLCARSThemeEnabled ? "Priority Alerts" : "Unread Alerts", systemImage: "bell.badge.fill")
                        Spacer(minLength: 8)
                        Text("\(notificationManager.unreadCount)")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(TLITheme.lcarsPanelFill(scheme).opacity(0.92), in: Capsule())
                    }

                    Text(
                        RisaTheme.isLCARSThemeEnabled
                            ? "Select a primary rail to keep your station active without losing panel context."
                            : "Pick any section from the sidebar and keep moving without losing your place."
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
            .navigationTitle(RisaTheme.isLCARSThemeEnabled ? "LCARS" : TLIBrandIdentity.heroTitle)
        } detail: {
            tabDetailView(for: selectedTab)
                .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func tabDetailView(for tab: TrekTab) -> some View {
        switch tab {
        case .today:
            NavigationStack {
                HomeView()
                    .toolbar(.hidden, for: .navigationBar)
                    .tliNavBarStyle()
            }
        case .schedule:
            NavigationStack {
                ScheduleView()
                    .tliNavBarStyle()
            }
        case .guests:
            NavigationStack {
                ExploreView()
                    .tliNavBarStyle()
            }
        case .map:
            NavigationStack {
                MapsView()
                    .tliNavBarStyle()
            }
        case .more:
            NavigationStack {
                MoreHubView()
                    .navigationTitle(TLILCARSLabel.more)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar(.visible, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .tliNavBarStyle()
            }
        }
    }

    private func sidebarButton(_ title: String, icon: String, tab: TrekTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                    .font(
                        RisaTheme.isLCARSThemeEnabled
                            ? .system(size: 14, weight: .bold, design: .monospaced)
                            : selectedTypography.font(.subheadline, weight: .semibold)
                    )
                Spacer(minLength: 8)
                if tab == .today && notificationManager.unreadCount > 0 {
                    Text("\(notificationManager.unreadCount)")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(TLITheme.lcarsPanelFill(scheme).opacity(0.92), in: Capsule())
                } else if differentiateWithoutColor {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(isSelected ? Color.black : TLITheme.textTertiary(scheme))
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(isSelected ? Color.black : TLITheme.textPrimary(scheme))
            .padding(.vertical, 9)
            .padding(.horizontal, 10)
            .background(
                TLITheme.controlShape(cornerRadius: 14)
                    .fill(isSelected ? TLITheme.accent(scheme).opacity(0.9) : .clear)
            )
            .overlay {
                TLITheme.controlShape(cornerRadius: 14)
                    .stroke(TLITheme.border(scheme).opacity(isSelected ? 0 : 0.55), lineWidth: 0.8)
            }
        }
        .buttonStyle(.plain)
    }

    private func playNavigationFeedback() {
        sfx.play("lcars_tap_soft", ext: "wav", volume: 0.12)
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    private func syncSplitVisibility(for sizeClass: UserInterfaceSizeClass?) {
        if sizeClass != .regular {
            splitVisibility = .detailOnly
        } else {
            splitVisibility = navigationSplitViewVisibility(from: splitVisibilityRaw)
        }
    }

    private func navigationSplitViewVisibility(from rawValue: String) -> NavigationSplitViewVisibility {
        switch rawValue {
        case "detailOnly":
            return .detailOnly
        case "doubleColumn":
            return .doubleColumn
        case "automatic":
            return .automatic
        default:
            return .all
        }
    }

    private func navigationSplitViewVisibilityString(_ visibility: NavigationSplitViewVisibility) -> String {
        switch visibility {
        case .detailOnly:
            return "detailOnly"
        case .doubleColumn:
            return "doubleColumn"
        case .automatic:
            return "automatic"
        default:
            return "all"
        }
    }
}

@MainActor
private struct MoreHubView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var isShowingZen = false

    private var sections: [MoreHubSection] {
        [
            .init(
                title: "Holodeck",
                subtitle: "Low-stakes relaxation and personal log tools between missions.",
                items: [
                    .init(title: "Captain’s Chair", subtitle: "A calm ambient bridge escape with zero admin energy.", icon: "moon.stars.fill", accent: .indigo, destination: nil, triggersZen: true),
                    .init(title: "Mini Journal", subtitle: "Capture thoughts, sightings, and con memories quickly.", icon: "book.closed", accent: .mint, destination: .journal)
                ]
            ),
            .init(
                title: "Features",
                subtitle: "Browse extras, fandom culture, and convention-side reading.",
                items: [
                    .init(title: "USS Long Island", subtitle: "Open the ship view and explore the local fleet flavor.", icon: "building.columns.circle", accent: .cyan, destination: .ussLongIsland),
                    .init(title: "Trek News", subtitle: "Catch up on headlines and franchise updates.", icon: "newspaper", accent: .blue, destination: .trekNews),
                    .init(title: "Discounts & Deals", subtitle: "Quick access to partner offers and related savings.", icon: "tag.fill", accent: .teal, destination: .discounts),
                    .init(title: "Fan Media & Culture", subtitle: "Podcasts, media, and behind-the-scenes community energy.", icon: "film.stack", accent: .pink, destination: .fanMedia),
                    .init(title: "Ferengi Rules", subtitle: "A playful lore detour when the promenade gets chaotic.", icon: "list.number", accent: .orange, destination: .ferengiRules),
                    .init(title: "Convention Economics", subtitle: "Read the business side of events, fandom, and sustainability.", icon: "dollarsign.circle", accent: .yellow, destination: .conEconomics)
                ]
            ),
            .init(
                title: "Convention Ops",
                subtitle: "Operational tools for support, staffing, and floor awareness.",
                items: [
                    .init(title: "Ops Center", subtitle: "Mission-control tools for staffing, issues, and response.", icon: "person.crop.rectangle.stack.fill", accent: .red, destination: .opsCenter),
                    .init(title: "Crowd Measurement", subtitle: "Check attendance pressure points and room flow quickly.", icon: "person.3.fill", accent: .purple, destination: .crowdMeasurement),
                    .init(title: "Support Center", subtitle: "Reach the help surface for logistics and attendee care.", icon: "cross.case.fill", accent: .green, destination: .supportCenter),
                    .init(title: "Settings", subtitle: "Tune theme, identity, notifications, and app behavior.", icon: "gearshape", accent: .gray, destination: .settings)
                ]
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                moreHeaderCard

                ForEach(sections) { section in
                    MoreHubSectionCard(section: section, scheme: scheme) { item in
                        if item.triggersZen {
                            isShowingZen = true
                        }
                    }
                }
            }
            .adaptiveContentWidth(
                maxWidth: TLILayout.defaultContentMaxWidth,
                horizontalPadding: hSizeClass == .regular ? 24 : 16,
                verticalPadding: 12
            )
        }
        .scrollIndicators(.hidden)
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        .tint(RisaTheme.accent(scheme))
        .sheet(isPresented: $isShowingZen) {
            ZenCaptainsChairRisaView()
                .tint(RisaTheme.accent(scheme))
        }
    }

    private var moreHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Command Extras")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("More Ways To Explore Trek Long Island")
                        .font(hSizeClass == .regular ? .largeTitle.bold() : .title.bold())
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Drop into holodeck calm, fandom extras, and ops tools without digging through a generic utility list.")
                        .font(.callout)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: hSizeClass == .regular ? 36 : 30, weight: .semibold))
                    .foregroundStyle(TLITheme.accent(scheme))
                    .padding(12)
                    .background(TLITheme.controlShape(cornerRadius: 22).fill(TLITheme.chipBackground(scheme).opacity(0.92)))
            }
        }
        .padding(18)
        .tliPanelSurface(
            cornerRadius: 28,
            fillOpacity: 0.98,
            borderOpacity: 0.92,
            shadowRadius: 16,
            shadowY: 8
        )
    }
}

private struct MoreHubSection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let items: [MoreHubItem]
}

private struct MoreHubItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let destination: MoreHubDestination?
    let triggersZen: Bool

    init(
        title: String,
        subtitle: String,
        icon: String,
        accent: Color,
        destination: MoreHubDestination?,
        triggersZen: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accent = accent
        self.destination = destination
        self.triggersZen = triggersZen
    }
}

private enum MoreHubDestination {
    case journal
    case ussLongIsland
    case trekNews
    case discounts
    case fanMedia
    case ferengiRules
    case conEconomics
    case opsCenter
    case crowdMeasurement
    case supportCenter
    case settings
}

private struct MoreHubSectionCard: View {
    let section: MoreHubSection
    let scheme: ColorScheme
    let zenAction: (MoreHubItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(section.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text(section.subtitle)
                    .font(.footnote)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }

            VStack(spacing: 10) {
                ForEach(section.items) { item in
                    row(for: item)
                }
            }
        }
        .padding(16)
        .tliPanelSurface(
            cornerRadius: 24,
            fillOpacity: 0.98,
            borderOpacity: 0.84,
            shadowRadius: 12,
            shadowY: 6
        )
    }

    @ViewBuilder
    private func row(for item: MoreHubItem) -> some View {
        if item.triggersZen {
            Button {
                zenAction(item)
            } label: {
                MoreHubRowLabel(item: item, scheme: scheme)
            }
            .buttonStyle(.plain)
        } else if let destination = item.destination {
            NavigationLink {
                destinationView(for: destination)
            } label: {
                MoreHubRowLabel(item: item, scheme: scheme)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: MoreHubDestination) -> some View {
        switch destination {
        case .journal:
            MiniJournalView()
        case .ussLongIsland:
            TLUSSLongIslandView()
        case .trekNews:
            TrekNewsView()
        case .discounts:
            DiscountsView()
        case .fanMedia:
            TrekFanMediaView()
        case .ferengiRules:
            FerengiRulesView()
        case .conEconomics:
            ConEconomicsPressurePointsView()
        case .opsCenter:
            OpsCenterView()
        case .crowdMeasurement:
            CrowdMeasurementView()
        case .supportCenter:
            SupportCenterView()
        case .settings:
            SettingsView()
        }
    }
}

private struct MoreHubRowLabel: View {
    let item: MoreHubItem
    let scheme: ColorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(item.accent)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text(item.subtitle)
                    .font(.footnote)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.cardBackground(scheme).opacity(0.84)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 18)
                .stroke(TLITheme.border(scheme).opacity(0.55), lineWidth: TLITheme.hairline)
        )
        .contentShape(TLITheme.controlShape(cornerRadius: 18))
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(TLIUsageInsightsStore.shared)
}
