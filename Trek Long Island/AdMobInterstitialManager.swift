// Copyright Bryan Carroll. All rights reserved.
import Foundation

@MainActor
final class AdMobInterstitialManager: ObservableObject {
    static let shared = AdMobInterstitialManager()

    @Published private(set) var isReady: Bool = false
    @Published private(set) var isPresenting: Bool = false

    private init() {}

    func appDidBecomeActive() {}
    func preloadIfEligible() {}
    func noteTopLevelNavigationEvent() {}
    func maybePresentAfterTopLevelNavigation() {}
}
