// Copyright Bryan Carroll. All rights reserved.
//
//  TLIConventionDates.swift
//  Trek Long Island
//

import Foundation

enum TLIConventionDates {
    private static let calendar = Calendar(identifier: .gregorian)

    struct ConventionDay: Identifiable, Hashable {
        let id: Int
        let title: String
        let subtitle: String
        let date: Date
        let prompt: String

        var stardate: String {
            TLIStardate.formatted(for: date)
        }
    }

    static let displayRange = "June 12–14, 2026"
    static let postConventionThankYouDate = date(year: 2026, month: 6, day: 15)

    static let launchSplashInterval: DateInterval = {
        let start = date(year: 2026, month: 6, day: 12)
        let end = date(year: 2026, month: 6, day: 15)
        return DateInterval(start: start, end: end)
    }()

    static func shouldShowLaunchSplash(on date: Date = .now) -> Bool {
        launchSplashInterval.contains(date)
    }

    static func isCaptainPicardDay(_ date: Date = .now) -> Bool {
        let components = calendar.dateComponents([.month, .day], from: date)
        return components.month == 6 && components.day == 16
    }

    static let conventionDays: [ConventionDay] = [
        ConventionDay(
            id: 1,
            title: "Day 1",
            subtitle: "Friday, June 12",
            date: date(year: 2026, month: 6, day: 12),
            prompt: "Opening night log, first impressions, and must-hit missions."
        ),
        ConventionDay(
            id: 2,
            title: "Day 2",
            subtitle: "Saturday, June 13",
            date: date(year: 2026, month: 6, day: 13),
            prompt: "Best panels, guest moments, and discoveries from the busiest day."
        ),
        ConventionDay(
            id: 3,
            title: "Day 3",
            subtitle: "Sunday, June 14",
            date: date(year: 2026, month: 6, day: 14),
            prompt: "Final memories, last finds, and what you want to remember later."
        )
    ]

    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = .current
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        components.second = 0
        return components.date ?? .distantFuture
    }
}
