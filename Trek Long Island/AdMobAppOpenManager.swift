// Copyright Bryan Carroll. All rights reserved.
import Foundation
import UIKit
import GoogleMobileAds

@MainActor
final class AdMobAppOpenManager: NSObject, ObservableObject {
    static let shared = AdMobAppOpenManager()

    @Published private(set) var isReady: Bool = false
    @Published private(set) var isPresenting: Bool = false

    private var appOpenAd: AppOpenAd?
    private var isLoading: Bool = false
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

    func preloadIfEligible() {
        guard shouldAllowAppOpen else {
            appOpenAd = nil
            isReady = false
            return
        }

        guard appOpenAd == nil, !isLoading else { return }
        guard activeAdUnitID != nil else { return }

        isLoading = true
        AppOpenAd.load(
            with: activeAdUnitID ?? "",
            request: Request()
        ) { [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false

                if let error {
                    self.appOpenAd = nil
                    self.isReady = false
#if DEBUG
                    print("App Open load failed:", error.localizedDescription)
#endif
                    return
                }

                self.appOpenAd = ad
                self.appOpenAd?.fullScreenContentDelegate = self
                self.isReady = (ad != nil)
            }
        }
    }

    private func maybePresentOnForeground() {
        guard shouldShowNow else { return }
        guard let appOpenAd, let rootViewController = rootViewController() else { return }
        appOpenAd.present(from: rootViewController)
    }

    private var shouldShowNow: Bool {
        let defaults = UserDefaults.standard

        guard shouldAllowAppOpen else { return false }
        guard !isPresenting else { return false }
        guard !AdMobInterstitialManager.shared.isPresenting else { return false }
        guard appOpenAd != nil else { return false }
        guard rootViewController() != nil else { return false }

        let effectiveCooldown = TLIAdExperience.effectiveAppOpenCooldown(defaults: defaults)
        let lastShown = defaults.object(forKey: TLIAdSettings.lastAppOpenShownAtKey) as? Date
        if let lastShown, Date().timeIntervalSince(lastShown) < effectiveCooldown {
            return false
        }

        return true
    }

    private var shouldAllowAppOpen: Bool {
        guard !TLIAdAvailability.areAdsDisabledForCurrentTarget else { return false }
        let defaults = UserDefaults.standard
        let adsEnabled = defaults.object(forKey: TLIAdSettings.adsEnabledKey) as? Bool ?? true
        let appOpenEnabled = defaults.object(forKey: TLIAdSettings.appOpenEnabledKey) as? Bool ?? true
        let hideForStaff = defaults.object(forKey: TLIAdSettings.hideForStaffKey) as? Bool ?? true

        if TLIAdEntitlements.hasRemoveAds(defaults: defaults) {
            return false
        }

        if !adsEnabled || !appOpenEnabled {
            return false
        }

        if !TLIAdExperience.canShowAppOpenAds(defaults: defaults) {
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

    private var activeAdUnitID: String? {
#if targetEnvironment(simulator)
        return AdMobConfig.testAppOpenAdUnitID
#else
        let id = AdMobConfig.appOpenAdUnitID.trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? nil : id
#endif
    }

    private func finalizeAppOpenPresentation() {
        UserDefaults.standard.set(Date(), forKey: TLIAdSettings.lastAppOpenShownAtKey)
        appOpenAd = nil
        isReady = false
        isPresenting = false
        preloadIfEligible()
    }
}

extension AdMobAppOpenManager: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        isPresenting = true
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finalizeAppOpenPresentation()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
#if DEBUG
        print("App Open failed to present:", error.localizedDescription)
#endif
        appOpenAd = nil
        isReady = false
        isPresenting = false
        preloadIfEligible()
    }
}
