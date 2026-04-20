// Copyright Bryan Carroll. All rights reserved.
//
//  TrekLIApp.swift
//  Trek Long Island – Official Convention App
//  Final version · 2026 Ready
//

import SwiftUI
import FirebaseCore
import UserNotifications

private let tliForceOnboardingForTesting = true

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
    @State private var isShowingSplash = !TLIAppFeatureFlags.isCustomSplashDisabled && TLIConventionDates.shouldShowLaunchSplash()
    @State private var isShowingOnboarding = false
    @State private var isShowingWelcomeNotice = false
    @State private var hasPresentedWelcomeNoticeThisSession = false

    // Appearance preference
    @AppStorage("appVisualPreset") private var appVisualPresetRaw: String = TLIVisualPreset.defaultPreset.rawValue
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @AppStorage("appColorTheme") private var appColorThemeRaw: String = TLIColorTheme.defaultTheme.rawValue
    @AppStorage(TLITypographyPreference.storageKey) private var typographyRaw: String = TLITypographyPreference.defaultPreference.rawValue

    // First-launch tracking
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @AppStorage("TLI.Onboarding.completed") private var hasCompletedOnboarding = false
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
                    TLIAdDefaults.register()
                    TLIAdExperience.noteAppLaunch()
                    if !TLIAdAvailability.areAdsDisabledForCurrentTarget {
                        TLIRemoveAdsPurchaseManager.shared.start()
                    }
                    UIKitAppearance.configure(for: resolvedUIKitColorScheme, typography: selectedTypography)
                    trackAnalytics(name: "app_opened", domain: "app")
                    usageInsightsStore.noteLaunch()
                    usageInsightsStore.noteScenePhase(.active)
                    syncOnboardingPresentation()
                    syncWelcomeNoticePresentation()

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
                    UIKitAppearance.configure(for: resolvedUIKitColorScheme, typography: selectedTypography)
                }
                .onChange(of: hasCompletedOnboarding) { _, _ in
                    syncOnboardingPresentation()
                    syncWelcomeNoticePresentation()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        UIKitAppearance.configure(for: resolvedUIKitColorScheme, typography: selectedTypography)
                        if !TLIAdAvailability.areAdsDisabledForCurrentTarget {
                            Task { await TLIRemoveAdsPurchaseManager.shared.refreshEntitlements() }
                        }
                        Task { @MainActor in
                            NotificationManager.shared.ensureAdminTimeout()
                            await NotificationManager.shared.refreshNow()
                        }
                        if !TLIAdAvailability.areAdsDisabledForCurrentTarget {
                            AdMobInterstitialManager.shared.appDidBecomeActive()
                            AdMobAppOpenManager.shared.appDidBecomeActive()
                        }
                        trackAnalytics(name: "app_became_active", domain: "app")
                        syncOnboardingPresentation()
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
                .fullScreenCover(isPresented: $isShowingOnboarding) {
                    TLIOnboardingView {
                        requestNotificationPermissionIfNeeded()
                    }
                    .id("onboarding")
                }
                .fullScreenCover(isPresented: $isShowingSplash) {
                    SplashScreenView {
                        finishSplashPresentation()
                    }
                }
                .sheet(isPresented: $isShowingWelcomeNotice, onDismiss: {
                    hasPresentedWelcomeNoticeThisSession = true
                }) {
                    TLIWelcomeNoticeView {
                        hasPresentedWelcomeNoticeThisSession = true
                        isShowingWelcomeNotice = false
                    }
                }
                .tliSmoothScrolling()
                .tliAppTypography(selectedTypography)
                .environmentObject(helloComputerStore) // ✅ inject once at the top
                .environmentObject(preferencesSyncStore)
                .environmentObject(networkMonitor)
                .environmentObject(nearbyRoomCountStore)
                .environmentObject(usageInsightsStore)
                .preferredColorScheme(currentColorScheme)
                .dynamicTypeSize(largeTypeBoost ? .large ... .accessibility5 : .xSmall ... .accessibility5)
                .environment(\.controlSize, largeTapTargets ? .large : .regular)
                .environment(\.defaultMinListRowHeight, largeTapTargets ? 52 : 44)
                .environment(\.defaultMinListHeaderHeight, largeTapTargets ? 34 : 28)
                .transaction { transaction in
                    if reduceAnimations || accessibilityReduceMotion {
                        transaction.animation = nil
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }

    private var shouldPresentOnboarding: Bool {
        !isShowingSplash &&
        !hasCompletedOnboarding &&
        (tliForceOnboardingForTesting || isOnOrAfterOnboardingStartDate)
    }

    private var isOnOrAfterOnboardingStartDate: Bool {
        let calendar = Calendar.current
        let onboardingStartDate = DateComponents(
            calendar: calendar,
            timeZone: .current,
            year: 2026,
            month: 6,
            day: 11
        ).date ?? .distantFuture

        return calendar.startOfDay(for: .now) >= calendar.startOfDay(for: onboardingStartDate)
    }

    private var currentColorScheme: ColorScheme? {
        AppAppearance(rawValue: appAppearanceRaw)?.colorScheme
    }

    private var selectedTypography: TLITypographyPreference {
        let normalized = TLITypographyPreference.fromStoredRawValue(typographyRaw)
        if normalized.rawValue != typographyRaw {
            typographyRaw = normalized.rawValue
        }
        return normalized
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

    private func requestNotificationPermissionIfNeeded() {
        Task {
            _ = await NotificationPermissionCoordinator.requestAuthorizationIfNeeded()
        }
    }

    private func syncOnboardingPresentation() {
        isShowingOnboarding = shouldPresentOnboarding
    }

    private func syncWelcomeNoticePresentation() {
        guard !TLIAppFeatureFlags.isWelcomePopupDisabled else {
            isShowingWelcomeNotice = false
            hasPresentedWelcomeNoticeThisSession = true
            return
        }
        let shouldShow = !isShowingSplash && !isShowingOnboarding && !hasPresentedWelcomeNoticeThisSession
        isShowingWelcomeNotice = shouldShow
    }

    private func finishSplashPresentation() {
        isShowingSplash = false
        Task { @MainActor in
            await Task.yield()
            syncOnboardingPresentation()
            syncWelcomeNoticePresentation()
        }
    }
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
enum UIKitAppearance {
    static func configure(for scheme: ColorScheme, typography: TLITypographyPreference) {
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
