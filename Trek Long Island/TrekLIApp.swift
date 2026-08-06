// Copyright Bryan Carroll. All rights reserved.
//
//  TrekLIApp.swift
//  Trek Long Island – Official Convention App
//  Final version · 2026 Ready
//

import SwiftUI
import FirebaseCore
import UserNotifications

private struct TLISmoothScrollModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollBounceBehavior(.basedOnSize, axes: [.vertical, .horizontal])
            .scrollDismissesKeyboard(.interactively)
    }
}

private extension View {
    func tliSmoothScrolling() -> some View {
        modifier(TLISmoothScrollModifier())
    }
}

private enum TLIDeepLinkDestination: String, Identifiable {
    case missionPlan
    case photoAutographs
    case support
    case map
    case schedule
    case alerts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .missionPlan: return "My Mission Plan"
        case .photoAutographs: return "Photo & Autographs"
        case .support: return "Support Center"
        case .map: return "Convention Map"
        case .schedule: return "Schedule"
        case .alerts: return "Announcements"
        }
    }
}

private extension TLIDeepLinkDestination {
    init?(url: URL) {
        let host = url.host?.lowercased()
        let pathParts = url.pathComponents
            .filter { $0 != "/" }
            .map { $0.lowercased() }
        let token = pathParts.first ?? host

        switch token {
        case "mission-plan", "mission", "plan":
            self = .missionPlan
        case "photo-autographs", "photo-autograph", "photos", "autographs":
            self = .photoAutographs
        case "support", "help":
            self = .support
        case "map", "maps":
            self = .map
        case "schedule":
            self = .schedule
        case "alerts", "announcements", "notifications":
            self = .alerts
        default:
            return nil
        }
    }
}

@main
struct TrekLIApp: App {
    @UIApplicationDelegateAdaptor(TLIAppDelegate.self) var delegate

    // ✅ Hello Computer store (shared app-wide)
    @StateObject private var helloComputerStore = HelloComputerStore(
        aiClient: HelloComputerCoreMLClient(),
        allowAIIfUncertain: true
    )
    @StateObject private var preferencesSyncStore = TLIPreferencesSyncStore.shared
    @StateObject private var networkMonitor = TLINetworkMonitor.shared
    @StateObject private var nearbyRoomCountStore = NearbyRoomCountStore.shared
    @StateObject private var usageInsightsStore = TLIUsageInsightsStore.shared
    @State private var isShowingSplash = TrekLIApp.initialSplashPresentationState()
    @State private var isShowingWelcomeNotice = false
    @State private var hasPresentedWelcomeNoticeThisSession = false
    @State private var hasStartedPostLaunchServices = false
    @State private var deepLinkDestination: TLIDeepLinkDestination?

    // Appearance preference
    @AppStorage("appVisualPreset") private var appVisualPresetRaw: String = TLIVisualPreset.defaultPreset.rawValue
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @AppStorage("appColorTheme") private var appColorThemeRaw: String = TLIColorTheme.defaultTheme.rawValue
    @AppStorage(TLITypographyPreference.storageKey) private var typographyRaw: String = TLITypographyPreference.defaultPreference.rawValue

    // First-launch tracking
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @AppStorage("TLI.Accessibility.largeTypeBoost") private var largeTypeBoost = false
    @AppStorage("TLI.Accessibility.largeTapTargets") private var largeTapTargets = false
    @AppStorage("TLI.Accessibility.reduceAnimations") private var reduceAnimations = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some Scene {
        WindowGroup {
            appContent
                .onAppear {
                    normalizeStoredThemeStateIfNeeded()
                    normalizeStoredTypographyIfNeeded()
                    TLIAdDefaults.register()
                    TLIAdExperience.noteAppLaunch()
                    UIKitAppearance.configure(for: resolvedUIKitColorScheme, typography: selectedTypography)
                    trackAnalytics(name: "app_opened", domain: "app")
                    usageInsightsStore.noteLaunch()
                    usageInsightsStore.noteScenePhase(.active)
                    syncWelcomeNoticePresentation()
                    startPostLaunchServicesIfNeeded()

                    if !hasLaunchedBefore {
                        hasLaunchedBefore = true
                        trackAnalytics(name: "app_first_launch", domain: "app")
                    }
                }
                .onChange(of: appAppearanceRaw) { _, _ in
                    UIKitAppearance.configure(for: resolvedUIKitColorScheme, typography: selectedTypography)
                }
                .onChange(of: appColorThemeRaw) { _, _ in
                    normalizeStoredThemeStateIfNeeded()
                    UIKitAppearance.configure(for: resolvedUIKitColorScheme, typography: selectedTypography)
                }
                .onChange(of: appVisualPresetRaw) { _, _ in
                    normalizeStoredThemeStateIfNeeded()
                    UIKitAppearance.configure(for: resolvedUIKitColorScheme, typography: selectedTypography)
                }
                .onChange(of: typographyRaw) { _, _ in
                    normalizeStoredTypographyIfNeeded()
                    UIKitAppearance.configure(for: resolvedUIKitColorScheme, typography: selectedTypography)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        UIKitAppearance.configure(for: resolvedUIKitColorScheme, typography: selectedTypography)
                        startPostLaunchServicesIfNeeded()
                        trackAnalytics(name: "app_became_active", domain: "app")
                        syncWelcomeNoticePresentation()
                    }
                    nearbyRoomCountStore.handleScenePhase(phase)
                    usageInsightsStore.noteScenePhase(phase)
                }
        }
    }

    private func trackAnalytics(name: String, domain: String) {
        Task { @MainActor in
            TLIAnalyticsStore.shared.track(name: name, domain: domain, actor: "system")
        }
    }

    private func normalizeStoredThemeStateIfNeeded() {
        let normalizedPreset = TLIVisualPreset.fromStoredRawValue(appVisualPresetRaw)
        if normalizedPreset.rawValue != appVisualPresetRaw {
            appVisualPresetRaw = normalizedPreset.rawValue
        }
        if appColorThemeRaw != normalizedPreset.theme.rawValue {
            appColorThemeRaw = normalizedPreset.theme.rawValue
        }
        if appAppearanceRaw != normalizedPreset.appearance.rawValue {
            appAppearanceRaw = normalizedPreset.appearance.rawValue
        }
    }

    private var appContent: some View {
        SecureContentView {
            ZStack {
                TLITheme.backgroundGradient(resolvedRootColorScheme)
                    .ignoresSafeArea()

                Group {
                    MainTabView()
                }
            }
                .fullScreenCover(isPresented: $isShowingSplash, onDismiss: {
                    handleSplashDismissed()
                }) {
                    SplashScreenView {
                        finishSplashPresentation()
                    }
                }
                .sheet(isPresented: $isShowingWelcomeNotice, onDismiss: {
                    handleWelcomeNoticeDismissed()
                }) {
                    TLIWelcomeNoticeView {
                        hasPresentedWelcomeNoticeThisSession = true
                        isShowingWelcomeNotice = false
                    }
                }
                .sheet(item: $deepLinkDestination) { destination in
                    NavigationStack {
                        deepLinkView(for: destination)
                            .navigationTitle(destination.title)
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .tliSmoothScrolling()
                .tliWebLinkOpening()
                .tliAppTypography(selectedTypography)
                .environmentObject(helloComputerStore) // ✅ inject once at the top
                .environmentObject(preferencesSyncStore)
                .environmentObject(networkMonitor)
                .environmentObject(nearbyRoomCountStore)
                .environmentObject(usageInsightsStore)
                .preferredColorScheme(currentColorScheme)
                .dynamicTypeSize(largeTypeBoost ? .large ... .accessibility5 : .small ... .accessibility5)
                .environment(\.controlSize, largeTapTargets ? .large : .regular)
                .environment(\.defaultMinListRowHeight, largeTapTargets ? 52 : 44)
                .environment(\.defaultMinListHeaderHeight, largeTapTargets ? 34 : 28)
                .transaction { transaction in
                    if reduceAnimations || accessibilityReduceMotion {
                        transaction.animation = nil
                    }
                }
        }
    }

    @ViewBuilder
    private func deepLinkView(for destination: TLIDeepLinkDestination) -> some View {
        switch destination {
        case .missionPlan:
            MyMissionPlanView()
        case .photoAutographs:
            PhotoAutographTrackerView()
        case .support:
            SupportCenterView()
        case .map:
            MapsView()
        case .schedule:
            ScheduleView()
        case .alerts:
            NotificationsView()
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let destination = TLIDeepLinkDestination(url: url) else { return }
        deepLinkDestination = destination
    }

    // The splash is now the only thing standing between launch and the app, so
    // it presents on every launch unless the build disables it outright.
    private static func initialSplashPresentationState() -> Bool {
        !TLIAppFeatureFlags.isCustomSplashDisabled
    }

    private var currentColorScheme: ColorScheme? {
        AppAppearance(rawValue: appAppearanceRaw)?.colorScheme
    }

    private var selectedTypography: TLITypographyPreference {
        // Pure read. Normalization of a stale/invalid stored value happens in
        // onAppear / onChange, never inside body evaluation.
        TLITypographyPreference.fromStoredRawValue(typographyRaw)
    }

    private func normalizeStoredTypographyIfNeeded() {
        let normalized = TLITypographyPreference.fromStoredRawValue(typographyRaw)
        if normalized.rawValue != typographyRaw {
            typographyRaw = normalized.rawValue
        }
    }

    private var resolvedUIKitColorScheme: ColorScheme {
        if let explicit = currentColorScheme {
            return explicit
        }
        #if canImport(UIKit)
        let style = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .traitCollection.userInterfaceStyle ?? .unspecified
        return style == .dark ? .dark : .light
        #else
        return .dark
        #endif
    }

    private var resolvedRootColorScheme: ColorScheme {
        currentColorScheme ?? resolvedUIKitColorScheme
    }

    private func syncWelcomeNoticePresentation() {
        guard !TLIAppFeatureFlags.isWelcomePopupDisabled else {
            isShowingWelcomeNotice = false
            hasPresentedWelcomeNoticeThisSession = true
            return
        }
        let shouldShow = !isShowingSplash && !hasPresentedWelcomeNoticeThisSession
        isShowingWelcomeNotice = shouldShow
    }

    private func startPostLaunchServicesIfNeeded() {
        guard !hasStartedPostLaunchServices else { return }
        hasStartedPostLaunchServices = true

        Task { @MainActor in
            // Attach ahead of the settle delay: dates and venue drive the splash,
            // the map pin, and every assistant answer, so a corrected event document
            // should land as early in the launch as possible.
            TLIEventInfoRemoteStore.shared.start()

            try? await Task.sleep(for: .seconds(1.25))
            guard !Task.isCancelled else { return }

            preferencesSyncStore.startRemoteSyncIfNeeded()
            usageInsightsStore.startRemoteSyncIfNeeded()

            NotificationManager.shared.ensureAdminTimeout()
            NotificationManager.shared.startBackendIfNeeded()
            await NotificationManager.shared.refreshNow()
            await AppUpdateMonitor.shared.checkForAvailableUpdate()
        }
    }

    private func finishSplashPresentation() {
        // Only dismiss here. Presenting the next cover/sheet is deferred to the
        // splash cover's onDismiss (handleSplashDismissed) so we never present a
        // new full-screen cover while this one is still animating away.
        isShowingSplash = false
    }

    private func handleSplashDismissed() {
        syncWelcomeNoticePresentation()
    }

    private func handleWelcomeNoticeDismissed() {
        hasPresentedWelcomeNoticeThisSession = true
    }

    // NOTE: launch deliberately never asks for notification permission.
    //
    // The system permission alert is a modal presented over the app, and firing it
    // during launch -- while the splash cover is dismissing or the welcome sheet is
    // animating -- left the app looking frozen. Enabling notifications is now
    // entirely user-initiated from Settings > Notification Access, which shows the
    // live permission state and drives the same request. Nothing on the launch path
    // presents a modal on top of the app.
}

// MARK: - Appearance Options
enum AppAppearance: String, CaseIterable {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}

// MARK: - UIKit Appearance
@MainActor
enum UIKitAppearance {
    private static var lastConfiguredScheme: ColorScheme?
    private static var lastConfiguredTypography: TLITypographyPreference?

    static func configure(
        for scheme: ColorScheme,
        typography: TLITypographyPreference,
        force: Bool = false
    ) {
        // Rebuilding every global appearance proxy is comparatively expensive and
        // was happening on every launch, every theme/typography write, and every
        // foreground. Skip when nothing relevant actually changed.
        if !force,
           lastConfiguredScheme == scheme,
           lastConfiguredTypography == typography {
            return
        }
        lastConfiguredScheme = scheme
        lastConfiguredTypography = typography

        let accent = RisaTheme.accentUIColor(for: scheme)
        let navTitle = RisaTheme.navTitleUIColor(for: scheme)
        let border = UIColor(RisaTheme.cardStroke(scheme)).withAlphaComponent(0.34)

        // Scrolling defaults tuned for responsive gesture handoff and smooth dismissal.
        let scrollView = UIScrollView.appearance()
        scrollView.decelerationRate = .normal
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.indicatorStyle = scheme == .dark ? .white : .black

        // Navigation Bar
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundEffect = UIBlurEffect(
            style: scheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
        )
        nav.backgroundColor = RisaTheme.navBarBackgroundUIColor(for: scheme).withAlphaComponent(0.80)
        nav.shadowColor = border
        nav.titleTextAttributes = [
            .foregroundColor: navTitle,
            .font: typography.uiFont(size: 17, weight: .semibold)
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: navTitle,
            .font: typography.uiFont(size: 34, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = accent
        UINavigationBar.appearance().shadowImage = UIImage()

        // Tab Bar
        let tab = UITabBarAppearance()
        tab.configureWithTransparentBackground()
        tab.backgroundEffect = UIBlurEffect(
            style: scheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
        )
        tab.backgroundColor = RisaTheme.tabBarBackgroundUIColor(for: scheme).withAlphaComponent(0.84)
        tab.shadowColor = border

        let item = tab.stackedLayoutAppearance
        item.normal.iconColor = RisaTheme.tabIconInactiveUIColor(for: scheme)
        item.normal.titleTextAttributes = [
            .foregroundColor: RisaTheme.tabLabelInactiveUIColor(for: scheme),
            .font: typography.uiFont(size: 11, weight: .medium)
        ]
        item.selected.iconColor = RisaTheme.tabIconActiveUIColor(for: scheme)
        item.selected.titleTextAttributes = [
            .foregroundColor: RisaTheme.tabLabelActiveUIColor(for: scheme),
            .font: typography.uiFont(size: 11, weight: .semibold)
        ]
        item.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
        item.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
        tab.stackedLayoutAppearance = item
        tab.inlineLayoutAppearance = item
        tab.compactInlineLayoutAppearance = item

        UITabBar.appearance().standardAppearance = tab
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tab
        }
        UITabBar.appearance().tintColor = accent
        UITabBar.appearance().unselectedItemTintColor = RisaTheme.tabIconInactiveUIColor(for: scheme)
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()

        // Lists / grouped containers
        let table = UITableView.appearance()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.separatorColor = border
        table.sectionHeaderTopPadding = 6

        UITableViewCell.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear

        // Shared controls
        UIBarButtonItem.appearance().tintColor = accent

        let segmented = UISegmentedControl.appearance()
        segmented.selectedSegmentTintColor = accent.withAlphaComponent(0.22)
        segmented.setTitleTextAttributes(
            [.foregroundColor: navTitle, .font: typography.uiFont(size: 13, weight: .regular)],
            for: .normal
        )
        segmented.setTitleTextAttributes(
            [.foregroundColor: navTitle, .font: typography.uiFont(size: 13, weight: .semibold)],
            for: .selected
        )

        let uiSwitch = UISwitch.appearance()
        uiSwitch.onTintColor = accent.withAlphaComponent(0.72)
        uiSwitch.thumbTintColor = .white

        let pageControl = UIPageControl.appearance()
        pageControl.currentPageIndicatorTintColor = accent
        pageControl.pageIndicatorTintColor = RisaTheme.tabIconInactiveUIColor(for: scheme).withAlphaComponent(0.45)
    }
}
