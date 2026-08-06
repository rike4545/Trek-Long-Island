// Copyright Bryan Carroll. All rights reserved.
//
//  TLIConventionDates.swift
//  Trek Long Island
//
//  Date helpers for the current convention.
//
//  This type no longer owns any dates — it derives everything from
//  `TLIEventInfo.current` so the year lives in exactly one place. The public API is
//  unchanged so existing call sites keep working.
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

    private static var info: TLIEventInfo { .current }

    /// e.g. "June 11–13, 2027"
    static var displayRange: String { info.displayRange }

    /// The day after the convention ends, when the thank-you notice appears.
    static var postConventionThankYouDate: Date {
        calendar.startOfDay(for: info.endDate)
    }

    /// Runs from the first morning through the end of the final day.
    static var launchSplashInterval: DateInterval { info.dateInterval }

    static func shouldShowLaunchSplash(on date: Date = .now) -> Bool {
        launchSplashInterval.contains(date)
    }

    static func isCaptainPicardDay(_ date: Date = .now) -> Bool {
        let components = calendar.dateComponents([.month, .day], from: date)
        return components.month == 6 && components.day == 16
    }

    /// Journal prompts, keyed by position in the run rather than by weekday, so the
    /// copy survives the convention shifting days year to year.
    private static let dayPrompts = [
        "Opening night log, first impressions, and must-hit missions.",
        "Best panels, guest moments, and discoveries from the busiest day.",
        "Final memories, last finds, and what you want to remember later."
    ]

    static var conventionDays: [ConventionDay] {
        let info = self.info
        return (0..<info.dayCount).map { offset in
            let date = info.date(forDayOffset: offset)
            return ConventionDay(
                id: offset + 1,
                title: "Day \(offset + 1)",
                subtitle: Self.weekdayAndDay(for: date),
                date: date,
                prompt: dayPrompts.indices.contains(offset)
                    ? dayPrompts[offset]
                    : "Log what you want to remember from today."
            )
        }
    }

    /// "Friday, June 11"
    private static func weekdayAndDay(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE MMMM d")
        return formatter.string(from: date)
    }
}
