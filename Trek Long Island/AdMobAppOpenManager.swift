// Copyright Bryan Carroll. All rights reserved.
import Foundation

@MainActor
final class AdMobAppOpenManager: ObservableObject {
    static let shared = AdMobAppOpenManager()

    @Published private(set) var isReady: Bool = false
    @Published private(set) var isPresenting: Bool = false

    private init() {}

    func appDidBecomeActive() {}
    func preloadIfEligible() {}
}
