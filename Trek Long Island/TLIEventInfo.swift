// Copyright Bryan Carroll. All rights reserved.
//
//  TLIEventInfo.swift
//  Trek Long Island
//
//  SINGLE SOURCE OF TRUTH for "which convention is this, when, and where".
//
//  Why this exists:
//  Before this type, the year and the venue were retyped by hand across ~20 files —
//  including free-text FAQ answers consumed by the Hello Computer assistant, the
//  MapKit pin coordinates, and 11 separate hardcoded `conventionID` string
//  declarations. When the convention moved from the Hyatt in Hauppauge (2026) to the
//  Marriott in Melville (2027), every one of those had to be found by grep, and the
//  assistant was left confidently giving attendees directions to the wrong hotel in
//  the wrong town.
//
//  Rule going forward: nothing in the app hardcodes a year, a venue name, an address,
//  or a coordinate. Read it from `TLIEventInfo.current`.
//
//  Layering:
//    • `.bundled`  — compiled-in defaults, always correct at ship time, works offline.
//    • `.current`  — `.bundled` unless a remote override has been cached by
//                    `TLIEventInfoRemoteStore` (Firestore). Safe to call from any
//                    isolation context; backed by UserDefaults so it survives launch
//                    and is readable before Firebase finishes connecting.
//
//  See `TLIEventInfoRemoteStore` for the fetch/cache side.
//

import Foundation
import CoreLocation

struct TLIEventInfo: Codable, Equatable {

    // MARK: - Venue

    struct Venue: Codable, Equatable {
        var name: String
        var street: String
        var city: String
        var state: String
        var postalCode: String
        var phone: String
        var latitude: Double
        var longitude: Double

        /// "1350 Walt Whitman Rd, Melville, NY 11747"
        var singleLineAddress: String {
            "\(street), \(city), \(state) \(postalCode)"
        }

        /// Two-line form for cards and map callouts.
        var multiLineAddress: String {
            "\(street)\n\(city), \(state) \(postalCode)"
        }

        /// "Melville, New York" — used by the splash screen.
        var cityState: String {
            "\(city), \(stateLongName)"
        }

        var stateLongName: String {
            state == "NY" ? "New York" : state
        }

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        /// Digits-only form for `tel:` links.
        var dialablePhone: String {
            phone.filter { $0.isNumber }
        }
    }

    // MARK: - Hours

    struct DayHours: Codable, Equatable, Identifiable {
        var day: String
        var hours: String
        var note: String?

        var id: String { day }
    }

    // MARK: - Stored

    /// Firestore document id and push-topic stem, e.g. "trekli-2027".
    var conventionID: String
    /// Underscored variant used for FCM topics, e.g. "trekli_2027".
    var pushTopicStem: String
    var year: Int
    /// "June 11–13, 2027"
    var displayRange: String

    /// First day of the convention, as calendar components.
    var startMonth: Int
    var startDay: Int
    /// Last day, inclusive. Assumed to be in the same month/year as the start.
    var endDay: Int

    var venue: Venue
    var conventionHours: [DayHours]
    var vendorHallHours: [DayHours]

    var hotelBookingURLString: String
    /// Human-readable cutoff for the discounted room block, e.g. "May 7, 2027".
    var hotelGroupRateDeadline: String

    /// False until the current year's guest list is public. While false the Guests tab
    /// leads with a coming-soon state and presents the prior year's roster as a clearly
    /// labelled archive, rather than implying last year's guests are attending.
    /// Flip this from the Firestore document the day the lineup is announced.
    var isGuestRosterAnnounced: Bool
    /// The year the archived roster belongs to, shown on the archive header.
    var archivedRosterYear: Int
    var mailingListURLString: String

    // MARK: - Bundled defaults (Trek Long Island 2027)

    /// Verified against treklongisland.com on 2026-08-03.
    /// Coordinates from OpenStreetMap for "Marriott Melville Long Island".
    static let bundled = TLIEventInfo(
        conventionID: "trekli-2027",
        pushTopicStem: "trekli_2027",
        year: 2027,
        displayRange: "June 11–13, 2027",
        startMonth: 6,
        startDay: 11,
        endDay: 13,
        venue: Venue(
            name: "Melville Marriott Long Island",
            street: "1350 Walt Whitman Rd",
            city: "Melville",
            state: "NY",
            postalCode: "11747",
            phone: "(631) 423-1600",
            latitude: 40.7834033,
            longitude: -73.4218567
        ),
        conventionHours: [
            DayHours(day: "Friday", hours: "5:00 PM – 11:00 PM", note: nil),
            DayHours(day: "Saturday", hours: "10:00 AM – 12:00 AM", note: nil),
            DayHours(day: "Sunday", hours: "10:00 AM – 6:00 PM", note: nil)
        ],
        vendorHallHours: [
            DayHours(day: "Friday", hours: "5:00 PM – 9:00 PM", note: nil),
            DayHours(day: "Saturday", hours: "10:00 AM – 6:00 PM", note: "Early entry 9:30 AM for VIP"),
            DayHours(day: "Sunday", hours: "10:00 AM – 5:00 PM", note: "Early entry 9:30 AM for VIP")
        ],
        hotelBookingURLString: "https://www.marriott.com/event-reservations/reservation-link.mi?id=1779216746294&key=GRP&app=resvlink",
        hotelGroupRateDeadline: "May 7, 2027",
        isGuestRosterAnnounced: false,
        archivedRosterYear: 2026,
        mailingListURLString: "https://treklongisland.beehiiv.com/"
    )

    // MARK: - Current (bundled, or remote override if one has been cached)

    private static let cacheDefaultsKey = "TLI.EventInfo.remoteOverride.v1"

    /// The event info the app should display. Reads a cached remote override when one
    /// is present, otherwise the compiled-in defaults. Never throws, never blocks.
    static var current: TLIEventInfo {
        guard let data = UserDefaults.standard.data(forKey: cacheDefaultsKey),
              let decoded = try? JSONDecoder().decode(TLIEventInfo.self, from: data) else {
            return .bundled
        }
        return decoded
    }

    /// Persist a remote override so it is available on the next cold launch, before
    /// Firestore has had a chance to connect.
    static func cacheRemoteOverride(_ info: TLIEventInfo) {
        guard let data = try? JSONEncoder().encode(info) else { return }
        UserDefaults.standard.set(data, forKey: cacheDefaultsKey)
    }

    /// Drop any cached override and fall back to `.bundled`.
    static func clearRemoteOverride() {
        UserDefaults.standard.removeObject(forKey: cacheDefaultsKey)
    }

    // MARK: - Derived dates

    private static var calendar: Calendar { Calendar(identifier: .gregorian) }

    func date(forDayOffset offset: Int) -> Date {
        var components = DateComponents()
        components.calendar = Self.calendar
        components.timeZone = .current
        components.year = year
        components.month = startMonth
        components.day = startDay + offset
        components.hour = 0
        components.minute = 0
        components.second = 0
        return components.date ?? .distantFuture
    }

    var startDate: Date { date(forDayOffset: 0) }

    /// Midnight at the *end* of the final day, so "is the con still running" checks
    /// include all of Sunday.
    var endDate: Date {
        Self.calendar.date(byAdding: .day, value: 1, to: date(forDayOffset: endDay - startDay))
            ?? date(forDayOffset: endDay - startDay)
    }

    var dayCount: Int { max(1, endDay - startDay + 1) }

    var dateInterval: DateInterval { DateInterval(start: startDate, end: endDate) }

    func isDuringConvention(_ date: Date = .now) -> Bool {
        dateInterval.contains(date)
    }

    // MARK: - Year display
    //
    // SwiftUI's `Text("\(someInt)")` formats through the current locale, which renders
    // 2027 as "2,027". Always interpolate these string forms into UI copy, never the
    // raw Int.

    var yearText: String { String(year) }
    var archivedRosterYearText: String { String(archivedRosterYear) }

    // MARK: - Formatted hours

    /// "• Friday: 5:00 PM – 11:00 PM\n• Saturday: …" for use in assistant answers.
    private static func bulletList(_ entries: [DayHours]) -> String {
        entries.map { entry in
            if let note = entry.note {
                return "• \(entry.day): \(entry.hours) (\(note))"
            }
            return "• \(entry.day): \(entry.hours)"
        }
        .joined(separator: "\n")
    }

    var conventionHoursBulletList: String { Self.bulletList(conventionHours) }
    var vendorHallHoursBulletList: String { Self.bulletList(vendorHallHours) }

    // MARK: - Push topics

    var broadcastTopic: String { pushTopicStem }
    func topic(_ suffix: String) -> String { "\(pushTopicStem)_\(suffix)" }
}
