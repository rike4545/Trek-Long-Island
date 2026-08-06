// Copyright Bryan Carroll. All rights reserved.
//
//  TLISafeMath.swift
//  Trek Long Island
//
//  `Int(_:)` on a floating-point value is a trapping conversion: it crashes the app
//  outright on NaN, on ±infinity, and on anything outside `Int`'s representable
//  range. Several screens derive numbers from remote documents, parsed calendar
//  feeds, and live audio, so any of those inputs can produce a value that traps.
//  These helpers make the conversion total.
//

import Foundation

enum TLISafeMath {
    /// Converts to `Int`, returning `fallback` instead of trapping on NaN,
    /// infinity, or a value outside `Int`'s range.
    static func int(_ value: Double, fallback: Int = 0) -> Int {
        guard value.isFinite else { return fallback }
        guard value > -9.2e18, value < 9.2e18 else { return fallback }
        return Int(value)
    }

    static func int(_ value: Float, fallback: Int = 0) -> Int {
        int(Double(value), fallback: fallback)
    }

    /// Rounds to the nearest `Int` without trapping.
    static func rounded(_ value: Double, fallback: Int = 0) -> Int {
        guard value.isFinite else { return fallback }
        return int(value.rounded(), fallback: fallback)
    }

    /// A `0...100` percentage from a `0...1` ratio. Non-finite ratios read as 0.
    static func percent(_ ratio: Double) -> Int {
        guard ratio.isFinite else { return 0 }
        return min(100, max(0, rounded(ratio * 100)))
    }

    static func percent(_ ratio: Float) -> Int {
        percent(Double(ratio))
    }

    /// Whole minutes in a time interval, clamped to a sane range so a corrupt or
    /// absurdly distant date from a feed can't trap the conversion.
    ///
    /// An infinite interval clamps to the bound rather than collapsing to zero —
    /// an unreachably distant event reads as "very far away", never as "starting now".
    static func minutes(_ interval: TimeInterval) -> Int {
        guard !interval.isNaN else { return 0 }
        let clampedSeconds = min(max(interval, -maxRepresentableSeconds), maxRepresentableSeconds)
        return int(clampedSeconds / 60)
    }

    /// ~100 years, comfortably beyond any convention countdown.
    private static let maxRepresentableSeconds: TimeInterval = 60 * 60 * 24 * 365 * 100
}
