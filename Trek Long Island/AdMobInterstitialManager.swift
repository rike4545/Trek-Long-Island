// Copyright Bryan Carroll. All rights reserved.
import Foundation
import UIKit
import GoogleMobileAds

@MainActor
final class AdMobInterstitialManager: NSObject, ObservableObject {
    static let shared = AdMobInterstitialManager()

    @Published private(set) var isReady: Bool = false
    @Published private(set) var isPresenting: Bool = false

    private var interstitialAd: InterstitialAd?
    private var isLoading: Bool = false
    private var navigationEventsSinceLastInterstitial: Int = 0
    private let minimumNavigationEventsBetweenAds: Int = 4

    private static var hasStartedSDK = false

    private override init() {
        super.init()
        guard !TLIAdAvailability.areAdsDisabledForCurrentTarget else { return }
        ensureSDKStarted()
        preloadIfEligible()
    }

    func appDidBecomeActive() {
        preloadIfEligible()
    }

    func noteTopLevelNavigationEvent() {
        preloadIfEligible()
    }

    func maybePresentAfterTopLevelNavigation() {
        // Fullscreen ad popups are disabled; keep preload support for other ad surfaces.
    }

    func preloadIfEligible() {
        guard shouldAllowInterstitials else {
            interstitialAd = nil
            isReady = false
            return
        }

        guard interstitialAd == nil, !isLoading else { return }

        isLoading = true
        InterstitialAd.load(with: activeAdUnitID, request: Request()) { [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false

                if let error {
                    self.interstitialAd = nil
                    self.isReady = false
#if DEBUG
                    print("Interstitial load failed:", error.localizedDescription)
#endif
                    return
                }

                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
                self.isReady = (ad != nil)
            }
        }
    }

    private var shouldShowInterstitialNow: Bool {
        let defaults = UserDefaults.standard

        guard shouldAllowInterstitials else { return false }
        guard !isPresenting else { return false }
        guard interstitialAd != nil else { return false }
        guard navigationEventsSinceLastInterstitial >= minimumNavigationEventsBetweenAds else { return false }
        guard TLIAdExperience.canPrepareFullscreenAds(defaults: defaults) else { return false }

        let effectiveCooldown = TLIAdExperience.effectiveInterstitialCooldown(defaults: defaults)
        let lastShown = defaults.object(forKey: TLIAdSettings.lastInterstitialShownAtKey) as? Date
        if let lastShown, Date().timeIntervalSince(lastShown) < effectiveCooldown {
            return false
        }

        return rootViewController() != nil
    }

    private var shouldAllowInterstitials: Bool {
        guard !TLIAdAvailability.areAdsDisabledForCurrentTarget else { return false }
        let defaults = UserDefaults.standard
        let adsEnabled = defaults.object(forKey: TLIAdSettings.adsEnabledKey) as? Bool ?? true
        let interstitialEnabled = defaults.object(forKey: TLIAdSettings.interstitialEnabledKey) as? Bool ?? true
        let hideForStaff = defaults.object(forKey: TLIAdSettings.hideForStaffKey) as? Bool ?? true

        if TLIAdEntitlements.hasRemoveAds(defaults: defaults) {
            return false
        }

        if !adsEnabled || !interstitialEnabled {
            return false
        }

        if !TLIAdExperience.canPrepareFullscreenAds(defaults: defaults) {
            return false
        }

        if TLIAdSchedule.isFullscreenAdBlackoutActive() {
            return false
        }

        if hideForStaff && NotificationManager.shared.isStaffUnlocked {
            return false
        }

        return true
    }

    private func presentInterstitial() {
        guard let ad = interstitialAd, let rootViewController = rootViewController() else { return }
        ad.present(from: rootViewController)
    }

    private func rootViewController() -> UIViewController? {
        let scenes = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        for scene in scenes {
            let windows = scene.windows
                .filter { !$0.isHidden && $0.alpha > 0 && $0.windowLevel == .normal }
            let candidateWindow = windows.first(where: \.isKeyWindow) ?? windows.first

            guard let root = candidateWindow?.rootViewController else { continue }
            guard root.viewIfLoaded?.window != nil else { continue }
            return topViewController(from: root)
        }

        return nil
    }

    private func topViewController(from root: UIViewController) -> UIViewController {
        if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        if let presented = root.presentedViewController, !presented.isBeingDismissed {
            return topViewController(from: presented)
        }
        return root
    }

    private func ensureSDKStarted() {
        guard !Self.hasStartedSDK else { return }
        Self.hasStartedSDK = true

#if targetEnvironment(simulator)
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["SIMULATOR"]
#endif
        MobileAds.shared.start(completionHandler: nil)
    }

    private var activeAdUnitID: String {
#if targetEnvironment(simulator)
        AdMobConfig.testInterstitialAdUnitID
#else
        AdMobConfig.interstitialAdUnitID
#endif
    }

    private func finalizeInterstitialPresentation() {
        UserDefaults.standard.set(Date(), forKey: TLIAdSettings.lastInterstitialShownAtKey)
        navigationEventsSinceLastInterstitial = 0
        interstitialAd = nil
        isReady = false
        isPresenting = false
        preloadIfEligible()
    }
}

extension AdMobInterstitialManager: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        isPresenting = true
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finalizeInterstitialPresentation()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
#if DEBUG
        print("Interstitial failed to present:", error.localizedDescription)
#endif
        interstitialAd = nil
        isReady = false
        isPresenting = false
        preloadIfEligible()
    }
}
