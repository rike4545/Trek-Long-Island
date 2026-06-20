// Copyright Bryan Carroll. All rights reserved.
import SwiftUI
import GoogleMobileAds

enum AdMobConfig {
    static let appID = "ca-app-pub-9917450718827221~7251531255"
    static let bannerAdUnitID = "ca-app-pub-9917450718827221/2651086478"
    static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"
}

enum TLIAdSettings {
    static let adsEnabledKey = "TLI.Ads.enabled"
    static let hideForStaffKey = "TLI.Ads.hideWhenStaffUnlocked"
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
            TLIAdSettings.hideForStaffKey: true
        ])
    }
}

enum TLIAdExperience {
    private static var hasRecordedLaunch = false

    static let onboardingCompletedKey = "TLI.Onboarding.completed"

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

private struct TLIHasBottomAdSlotKey: EnvironmentKey {
    static let defaultValue = false
}

private extension EnvironmentValues {
    var tliHasBottomAdSlot: Bool {
        get { self[TLIHasBottomAdSlotKey.self] }
        set { self[TLIHasBottomAdSlotKey.self] = newValue }
    }
}

@MainActor
struct AdMobBannerView: View {
    private let compactBannerHeight: CGFloat = 50
    @State private var loadState: AdBannerLoadState = .loading
    @State private var bannerHeight: CGFloat = 50

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                BannerAdRepresentable(
                    adUnitID: activeAdUnitID,
                    availableWidth: max(320, proxy.size.width),
                    loadState: $loadState,
                    bannerHeight: $bannerHeight
                )
                .frame(width: 320, height: compactBannerHeight)
                .opacity(loadState == .loaded ? 1 : 0.02)

                if loadState == .loading {
                    adPlaceholder(height: compactBannerHeight)
                }
            }
            .frame(maxWidth: .infinity, minHeight: compactBannerHeight, maxHeight: compactBannerHeight)
        }
        .frame(height: loadState == .failed ? 0 : compactBannerHeight)
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
        .animation(.easeInOut(duration: 0.2), value: bannerHeight)
    }

    private func adPlaceholder(height: CGFloat) -> some View {
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
                            .font(.caption.weight(.bold))
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
            .frame(height: height)
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
            TLIAdSlotView()
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }
}

@MainActor
private struct TLIBottomAdSlotModifier: ViewModifier {
    @Environment(\.tliHasBottomAdSlot) private var hasBottomAdSlot
    @AppStorage(TLIAdSettings.adsEnabledKey) private var adsEnabled: Bool = true
    @AppStorage(TLIAdSettings.hideForStaffKey) private var hideForStaff: Bool = true
    @ObservedObject private var notifications = NotificationManager.shared

    private var shouldShowAdSlot: Bool {
        guard !hasBottomAdSlot else { return false }
        guard !TLIAdAvailability.areAdsDisabledForCurrentTarget else { return false }
        return adsEnabled &&
        !(hideForStaff && notifications.isStaffUnlocked)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if shouldShowAdSlot {
            content.safeAreaInset(edge: .bottom) {
                TLIBottomAdContainer()
            }
            .environment(\.tliHasBottomAdSlot, true)
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

@MainActor
private struct TLIAdSlotView: View {
    var body: some View {
        AdMobBannerView()
    }
}

private struct BannerAdRepresentable: UIViewRepresentable {
    let adUnitID: String
    let availableWidth: CGFloat
    @Binding var loadState: AdBannerLoadState
    @Binding var bannerHeight: CGFloat

    func makeUIView(context: Context) -> BannerView {
        let adSize = AdSizeBanner
        let bannerView = BannerView(adSize: adSize)
        bannerView.backgroundColor = .clear
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = tliAdRootViewController()
        bannerView.delegate = context.coordinator
        context.coordinator.loadState = $loadState
        context.coordinator.bannerHeight = $bannerHeight
        context.coordinator.lastWidth = availableWidth
        bannerHeight = cgSize(for: adSize).height
        loadState = .loading
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ bannerView: BannerView, context: Context) {
        bannerView.rootViewController = tliAdRootViewController()

        let widthChanged = abs(context.coordinator.lastWidth - availableWidth) > 1
        if widthChanged {
            context.coordinator.lastWidth = availableWidth
            bannerHeight = 50
        }

        if context.coordinator.lastAdUnitID != adUnitID || bannerView.adUnitID != adUnitID || widthChanged {
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
        var bannerHeight: Binding<CGFloat>
        var lastAdUnitID: String
        var lastWidth: CGFloat

        init(loadState: Binding<AdBannerLoadState>, adUnitID: String) {
            self.loadState = loadState
            self.bannerHeight = .constant(50)
            self.lastAdUnitID = adUnitID
            self.lastWidth = 0
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            bannerHeight.wrappedValue = 50
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
