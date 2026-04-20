// Copyright Bryan Carroll. All rights reserved.
import Foundation

struct NotificationPreferences {
    static var shared = NotificationPreferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let digestMode = "TLI.NotificationPrefs.digestMode"
        static let quietStartHour = "TLI.NotificationPrefs.quietStartHour"
        static let quietEndHour = "TLI.NotificationPrefs.quietEndHour"
        static let priorityOverridesQuiet = "TLI.NotificationPrefs.priorityOverridesQuiet"
        static let trackedRoomsCSV = "TLI.NotificationPrefs.trackedRoomsCSV"
    }

    var digestMode: Bool {
        get { defaults.object(forKey: Keys.digestMode) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.digestMode) }
    }

    var quietStartHour: Int {
        get {
            if defaults.object(forKey: Keys.quietStartHour) == nil { return 22 }
            return defaults.integer(forKey: Keys.quietStartHour)
        }
        set { defaults.set(min(max(newValue, 0), 23), forKey: Keys.quietStartHour) }
    }

    var quietEndHour: Int {
        get {
            if defaults.object(forKey: Keys.quietEndHour) == nil { return 7 }
            return defaults.integer(forKey: Keys.quietEndHour)
        }
        set { defaults.set(min(max(newValue, 0), 23), forKey: Keys.quietEndHour) }
    }

    var priorityOverridesQuiet: Bool {
        get { defaults.object(forKey: Keys.priorityOverridesQuiet) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.priorityOverridesQuiet) }
    }

    var trackedRooms: Set<String> {
        get {
            let csv = defaults.string(forKey: Keys.trackedRoomsCSV) ?? ""
            return Set(csv.split(separator: "|").map(String.init))
        }
        set {
            defaults.set(newValue.sorted().joined(separator: "|"), forKey: Keys.trackedRoomsCSV)
        }
    }

    func isWithinQuietHours(at date: Date = .now, calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: date)
        let start = quietStartHour
        let end = quietEndHour

        if start == end {
            return false
        }

        if start < end {
            return hour >= start && hour < end
        }

        return hour >= start || hour < end
    }
}
