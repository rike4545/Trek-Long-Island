// Copyright Bryan Carroll. All rights reserved.
import SwiftUI
import GoogleMobileAds
import StoreKit

enum AdMobConfig {
    static let appID = "ca-app-pub-9917450718827221~7251531255"
    static let bannerAdUnitID = "ca-app-pub-9917450718827221/2651086478"
    static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"
    static let interstitialAdUnitID = "ca-app-pub-9917450718827221/7770755052" // InterstitialABC
    static let testInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    static let appOpenAdUnitID = "ca-app-pub-9917450718827221/2862547886" // AppOpenFlood
    static let testAppOpenAdUnitID = "ca-app-pub-3940256099942544/5575463023"
}

enum TLIAdSettings {
    static let adsEnabledKey = "TLI.Ads.enabled"
    static let hideForStaffKey = "TLI.Ads.hideWhenStaffUnlocked"
    static let interstitialEnabledKey = "TLI.Ads.interstitialEnabled"
    static let interstitialCooldownSecondsKey = "TLI.Ads.interstitialCooldownSeconds"
    static let lastInterstitialShownAtKey = "TLI.Ads.lastInterstitialShownAt"
    static let appOpenEnabledKey = "TLI.Ads.appOpenEnabled"
    static let appOpenCooldownSecondsKey = "TLI.Ads.appOpenCooldownSeconds"
    static let lastAppOpenShownAtKey = "TLI.Ads.lastAppOpenShownAt"
    static let removeAdsPurchasedKey = "TLI.Ads.removeAdsPurchased"
    static let removeAdsProductID = "com.treklongisland.removeads.lifetime"
    static let launchCountKey = "TLI.Ads.launchCount"
    static let lastLaunchAtKey = "TLI.Ads.lastLaunchAt"
}

enum TLIAdAvailability {
    static var areAdsDisabledForCurrentTarget: Bool {
        TLIAppFeatureFlags.areAdsDisabled
    }
}

enum TLIAdDefaults {
    static func register() {
        UserDefaults.standard.register(defaults: [
            TLIAdSettings.adsEnabledKey: !TLIAdAvailability.areAdsDisabledForCurrentTarget,
            TLIAdSettings.hideForStaffKey: true,
            TLIAdSettings.interstitialEnabledKey: !TLIAdAvailability.areAdsDisabledForCurrentTarget,
            TLIAdSettings.interstitialCooldownSecondsKey: 180.0,
            TLIAdSettings.appOpenEnabledKey: !TLIAdAvailability.areAdsDisabledForCurrentTarget,
            TLIAdSettings.appOpenCooldownSecondsKey: 900.0,
            TLIAdSettings.removeAdsPurchasedKey: false
        ])
    }
}

enum TLIAdExperience {
    private static var hasRecordedLaunch = false

    static let onboardingCompletedKey = "TLI.Onboarding.completed"
    static let minimumSecondsBeforeFullscreenAds: TimeInterval = 30
    static let recommendedInterstitialCooldown: TimeInterval = 150
    static let recommendedAppOpenCooldown: TimeInterval = 900
    static let minimumLaunchCountForAppOpenAds = 2

    static func noteAppLaunch(defaults: UserDefaults = .standard, now: Date = .now) {
        guard !hasRecordedLaunch else { return }
        hasRecordedLaunch = true
        let nextLaunchCount = defaults.integer(forKey: TLIAdSettings.launchCountKey) + 1
        defaults.set(nextLaunchCount, forKey: TLIAdSettings.launchCountKey)
        defaults.set(now, forKey: TLIAdSettings.lastLaunchAtKey)
    }

    static func markOnboardingCompleted(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: onboardingCompletedKey)
    }

    static func hasCompletedOnboarding(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: onboardingCompletedKey)
    }

    static func secondsSinceLaunch(defaults: UserDefaults = .standard, now: Date = .now) -> TimeInterval {
        guard let lastLaunchAt = defaults.object(forKey: TLIAdSettings.lastLaunchAtKey) as? Date else {
            return 0
        }
        return max(0, now.timeIntervalSince(lastLaunchAt))
    }

    static func canPrepareFullscreenAds(defaults: UserDefaults = .standard, now: Date = .now) -> Bool {
        hasCompletedOnboarding(defaults: defaults) &&
        secondsSinceLaunch(defaults: defaults, now: now) >= minimumSecondsBeforeFullscreenAds
    }

    static func canShowAppOpenAds(defaults: UserDefaults = .standard, now: Date = .now) -> Bool {
        canPrepareFullscreenAds(defaults: defaults, now: now) &&
        defaults.integer(forKey: TLIAdSettings.launchCountKey) >= minimumLaunchCountForAppOpenAds
    }

    static func effectiveInterstitialCooldown(defaults: UserDefaults = .standard) -> TimeInterval {
        let configured = defaults.double(forKey: TLIAdSettings.interstitialCooldownSecondsKey)
        return configured > 0 ? max(configured, recommendedInterstitialCooldown) : recommendedInterstitialCooldown
    }

    static func effectiveAppOpenCooldown(defaults: UserDefaults = .standard) -> TimeInterval {
        let configured = defaults.double(forKey: TLIAdSettings.appOpenCooldownSecondsKey)
        return configured > 0 ? max(configured, recommendedAppOpenCooldown) : recommendedAppOpenCooldown
    }
}

enum TLIAdSchedule {
    private static var conventionCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }

    static func isFullscreenAdBlackoutActive(referenceDate: Date = Date()) -> Bool {
        guard
            let start = conventionCalendar.date(from: DateComponents(year: 2026, month: 6, day: 10)),
            let end = conventionCalendar.date(from: DateComponents(year: 2026, month: 6, day: 17))
        else {
            return false
        }

        return referenceDate >= start && referenceDate < end
    }
}

enum TLIAdEntitlements {
    static func hasRemoveAds(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: TLIAdSettings.removeAdsPurchasedKey)
    }

    static func setRemoveAdsPurchased(_ isPurchased: Bool, defaults: UserDefaults = .standard) {
        defaults.set(isPurchased, forKey: TLIAdSettings.removeAdsPurchasedKey)
    }
}

@MainActor
final class TLIRemoveAdsPurchaseManager: ObservableObject {
    static let shared = TLIRemoveAdsPurchaseManager()

    @Published private(set) var removeAdsProduct: Product?
    @Published private(set) var isPurchased: Bool = TLIAdEntitlements.hasRemoveAds()
    @Published private(set) var isBusy: Bool = false
    @Published var purchaseErrorMessage: String?

    private var startupTask: Task<Void, Never>?
    private var updatesTask: Task<Void, Never>?
    private var hasStarted = false

    private init() {}

    var displayPrice: String {
        removeAdsProduct?.displayPrice ?? "$1.99"
    }

    func start() {
        guard !TLIAdAvailability.areAdsDisabledForCurrentTarget else { return }
        guard !hasStarted else { return }
        hasStarted = true
        observeTransactionUpdates()
        startupTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshProducts()
            await self.refreshEntitlements()
        }
    }

    func refreshEntitlements() async {
        guard !TLIAdAvailability.areAdsDisabledForCurrentTarget else { return }
        var entitlementActive = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == TLIAdSettings.removeAdsProductID else { continue }
            if transaction.revocationDate == nil {
                entitlementActive = true
                break
            }
        }

        applyEntitlementState(entitlementActive)
    }

    func refreshProducts() async {
        guard !TLIAdAvailability.areAdsDisabledForCurrentTarget else { return }
        do {
            let products = try await Product.products(for: [TLIAdSettings.removeAdsProductID])
            removeAdsProduct = products.first
        } catch {
            purchaseErrorMessage = "Could not load purchase options. Try again later."
        }
    }

    func purchaseRemoveAds() async {
        guard !TLIAdAvailability.areAdsDisabledForCurrentTarget else { return }
        purchaseErrorMessage = nil
        isBusy = true
        defer { isBusy = false }

        if removeAdsProduct == nil {
            await refreshProducts()
        }
        guard let product = removeAdsProduct else {
            purchaseErrorMessage = "Remove Ads is currently unavailable."
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    purchaseErrorMessage = "Purchase verification failed."
                    return
                }
                let entitlementActive = transaction.revocationDate == nil
                applyEntitlementState(entitlementActive)
                await transaction.finish()
            case .pending:
                purchaseErrorMessage = "Purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                purchaseErrorMessage = "Purchase did not complete."
            }
        } catch {
            purchaseErrorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        guard !TLIAdAvailability.areAdsDisabledForCurrentTarget else { return }
        purchaseErrorMessage = nil
        isBusy = true
        defer { isBusy = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseErrorMessage = "Could not restore purchases."
        }
    }

    private func observeTransactionUpdates() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                guard transaction.productID == TLIAdSettings.removeAdsProductID else {
                    await transaction.finish()
                    continue
                }
                let entitlementActive = transaction.revocationDate == nil
                await MainActor.run {
                    self.applyEntitlementState(entitlementActive)
                }
                await transaction.finish()
            }
        }
    }

    private func applyEntitlementState(_ isEntitled: Bool) {
        isPurchased = isEntitled
        TLIAdEntitlements.setRemoveAdsPurchased(isEntitled)

        // Refresh ad managers so loaded ads are dropped immediately if purchased.
        AdMobInterstitialManager.shared.preloadIfEligible()
        AdMobAppOpenManager.shared.preloadIfEligible()
    }
}

private enum AdMobRuntime {
    private static var hasStarted = false

    static func ensureStarted() {
        guard !TLIAdAvailability.areAdsDisabledForCurrentTarget else { return }
        guard !hasStarted else { return }
        hasStarted = true
        #if targetEnvironment(simulator)
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["SIMULATOR"]
        #endif
        MobileAds.shared.start(completionHandler: nil)
    }
}

private func tliAdRootViewController() -> UIViewController? {
    UIApplication.shared
        .connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
        .first(where: \.isKeyWindow)?
        .rootViewController
}

private enum AdBannerLoadState {
    case loading
    case loaded
    case failed
}

@MainActor
struct AdMobBannerView: View {
    @State private var loadState: AdBannerLoadState = .loading

    var body: some View {
        ZStack {
            BannerAdRepresentable(
                adUnitID: activeAdUnitID,
                loadState: $loadState
            )
            .opacity(loadState == .loaded ? 1 : 0.02)

            if loadState == .loading {
                nativePlaceholder
            }
        }
        .frame(height: loadState == .failed ? 0 : preferredBannerHeight)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sponsored advertisement")
        .onAppear {
            AdMobRuntime.ensureStarted()
            if loadState == .failed {
                loadState = .loading
            }
        }
        .animation(.easeInOut(duration: 0.2), value: loadState == .failed)
    }

    private var nativePlaceholder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.primary.opacity(0.06))
            .overlay {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "megaphone.fill")
                            .font(.caption.weight(.semibold))
                        Text("Sponsored")
                            .font(.caption.weight(.semibold))
                        Text("Ad")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.primary.opacity(0.08)))
                    }

                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .overlay {
                            ProgressView()
                                .controlSize(.small)
                        }
                }
                .padding(14)
            }
    }

    private var preferredBannerHeight: CGFloat {
        66
    }

    private var activeAdUnitID: String {
        #if targetEnvironment(simulator)
        AdMobConfig.testBannerAdUnitID
        #elseif DEBUG
        AdMobConfig.testBannerAdUnitID
        #else
        AdMobConfig.bannerAdUnitID
        #endif
    }
}

struct TLIBottomAdContainer: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill((scheme == .dark ? Color.white : Color.black).opacity(0.10))
                .frame(height: 1)
            AdMobBannerView()
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }
}

@MainActor
private struct TLIBottomAdSlotModifier: ViewModifier {
    @AppStorage(TLIAdSettings.adsEnabledKey) private var adsEnabled: Bool = true
    @AppStorage(TLIAdSettings.hideForStaffKey) private var hideForStaff: Bool = true
    @ObservedObject private var notifications = NotificationManager.shared

    private var shouldShowAdSlot: Bool {
        guard !TLIAdAvailability.areAdsDisabledForCurrentTarget else { return false }
        return adsEnabled &&
        !TLIAdEntitlements.hasRemoveAds() &&
        !(hideForStaff && notifications.isStaffUnlocked)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if shouldShowAdSlot {
            content.safeAreaInset(edge: .bottom) {
                TLIBottomAdContainer()
            }
        } else {
            content
        }
    }
}

@MainActor
extension View {
    @ViewBuilder
    func tliFixedBottomAdSlot() -> some View {
        self.modifier(TLIBottomAdSlotModifier())
    }
}

private struct BannerAdRepresentable: UIViewRepresentable {
    let adUnitID: String
    @Binding var loadState: AdBannerLoadState

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.backgroundColor = .clear
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = tliAdRootViewController()
        bannerView.delegate = context.coordinator
        context.coordinator.loadState = $loadState
        loadState = .loading
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ bannerView: BannerView, context: Context) {
        bannerView.rootViewController = tliAdRootViewController()

        if context.coordinator.lastAdUnitID != adUnitID || bannerView.adUnitID != adUnitID {
            context.coordinator.lastAdUnitID = adUnitID
            bannerView.adUnitID = adUnitID
            loadState = .loading
            bannerView.load(Request())
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(loadState: $loadState, adUnitID: adUnitID)
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var loadState: Binding<AdBannerLoadState>
        var lastAdUnitID: String

        init(loadState: Binding<AdBannerLoadState>, adUnitID: String) {
            self.loadState = loadState
            self.lastAdUnitID = adUnitID
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            loadState.wrappedValue = .loaded
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            loadState.wrappedValue = .failed
            #if DEBUG
            print("AdMob banner ad failed:", error.localizedDescription)
            #endif
        }
    }
}

#if DEBUG
#Preview {
    AdMobBannerView()
        .padding()
        .background(Color.black)
}
#endif
