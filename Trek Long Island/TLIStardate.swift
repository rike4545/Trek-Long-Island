// Copyright Bryan Carroll. All rights reserved.
//
//  TLIStardate.swift
//  Trek Long Island
//

import Foundation

enum TLIStardate {
    private static let baseYear = 1987
    private static let baseStardate = 41000.0

    static func formatted(for date: Date = .now) -> String {
        String(format: "%.1f", value(for: date))
    }

    static func value(for date: Date) -> Double {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let dayOfYear = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        let daysInYear = Double(calendar.range(of: .day, in: .year, for: date)?.count ?? 365)
        let fraction = (dayOfYear / daysInYear) * 1000.0
        return baseStardate + Double(year - baseYear) * 1000.0 + fraction
    }
}
