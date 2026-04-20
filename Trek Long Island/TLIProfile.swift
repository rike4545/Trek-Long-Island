import Foundation

enum TLIProfileRank: String, CaseIterable, Identifiable {
    case cadet
    case ensign
    case lieutenant
    case commander
    case captain
    case admiral

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cadet:
            "Cadet"
        case .ensign:
            "Ensign"
        case .lieutenant:
            "Lieutenant"
        case .commander:
            "Commander"
        case .captain:
            "Captain"
        case .admiral:
            "Admiral"
        }
    }

    var icon: String {
        switch self {
        case .cadet:
            "star"
        case .ensign:
            "chevron.up"
        case .lieutenant:
            "chevron.up.2"
        case .commander:
            "chevron.up.circle"
        case .captain:
            "star.circle.fill"
        case .admiral:
            "sparkles"
        }
    }

    var description: String {
        switch self {
        case .cadet:
            "A playful training-cruise identity for first-contact energy."
        case .ensign:
            "Clean and classic for guests just getting underway."
        case .lieutenant:
            "Confident bridge-officer energy without going full command."
        case .commander:
            "A seasoned operations vibe for guests who like to stay sharp."
        case .captain:
            "Full command-deck presence for leading your own convention mission."
        case .admiral:
            "Flag-officer flair for guests who want maximum Trek gravitas."
        }
    }
}

enum TLIProfileRole: String, CaseIterable, Identifiable {
    case firstTimer
    case returningFan
    case familyCrew
    case volunteer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstTimer:
            "First Timer"
        case .returningFan:
            "Returning Fan"
        case .familyCrew:
            "Family Crew"
        case .volunteer:
            "Volunteer / Staff"
        }
    }

    var icon: String {
        switch self {
        case .firstTimer:
            "sparkles"
        case .returningFan:
            "star.circle.fill"
        case .familyCrew:
            "figure.2.and.child.holdinghands"
        case .volunteer:
            "person.crop.circle.badge.checkmark"
        }
    }

    var description: String {
        switch self {
        case .firstTimer:
            "You want a confident, low-stress way to learn the convention."
        case .returningFan:
            "You know the vibe and want to optimize your weekend."
        case .familyCrew:
            "You need quick decisions, clear routing, and flexible plans."
        case .volunteer:
            "You want the fastest path to info, updates, and live changes."
        }
    }

    var guidance: String {
        switch self {
        case .firstTimer:
            "Start with Today, then favorite events early. The app becomes your memory when the con starts moving faster than expected."
        case .returningFan:
            "Use favorites and announcements together. That combo is the best way to pivot quickly without missing the moments you came for."
        case .familyCrew:
            "Maps, schedule favorites, and quick answers from Hello, Computer help you adapt without a long planning pause."
        case .volunteer:
            "Keep announcements and route checks close. The app is strongest when you need current information without digging."
        }
    }
}

enum TLIProfileObjective: String, CaseIterable, Identifiable {
    case neverMissPanels
    case meetGuests
    case navigateFast
    case stayUpdated
    case familyFriendly

    static let defaultSet: [TLIProfileObjective] = [.neverMissPanels, .stayUpdated]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neverMissPanels:
            "Never miss panels"
        case .meetGuests:
            "Track favorite guests"
        case .navigateFast:
            "Find my way quickly"
        case .stayUpdated:
            "Stay on top of changes"
        case .familyFriendly:
            "Keep it family-friendly"
        }
    }

    var icon: String {
        switch self {
        case .neverMissPanels:
            "calendar.badge.clock"
        case .meetGuests:
            "person.2.badge.gearshape"
        case .navigateFast:
            "map.circle.fill"
        case .stayUpdated:
            "bell.badge.fill"
        case .familyFriendly:
            "face.smiling"
        }
    }

    var description: String {
        switch self {
        case .neverMissPanels:
            "Use favorites and the live schedule as your personal mission plan."
        case .meetGuests:
            "Quickly jump between guest info, favorites, and the floor experience."
        case .navigateFast:
            "Spend less time decoding the hotel layout when the crowd gets busy."
        case .stayUpdated:
            "Catch changes, alerts, and convention news before they surprise you."
        case .familyFriendly:
            "Spot useful activities and plan smoother transitions with your crew."
        }
    }

    var samplePrompt: String {
        switch self {
        case .neverMissPanels:
            "\"Build my day around the main stage.\""
        case .meetGuests:
            "\"Which guests should I see next?\""
        case .navigateFast:
            "\"How do I get to the vendor area from here?\""
        case .stayUpdated:
            "\"What changed today?\""
        case .familyFriendly:
            "\"Show me family-friendly activities.\""
        }
    }
}

enum TLIProfilePreferences {
    static func objectives(from rawValue: String) -> Set<TLIProfileObjective> {
        Set(
            rawValue
                .split(separator: "|")
                .compactMap { TLIProfileObjective(rawValue: String($0)) }
        )
    }

    static func serialize(_ objectives: Set<TLIProfileObjective>) -> String {
        objectives.map(\.rawValue).sorted().joined(separator: "|")
    }

    static func captainName(from displayName: String) -> String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Captain" : trimmed
    }

    static func commandName(rank: TLIProfileRank, displayName: String) -> String {
        "\(rank.title) \(captainName(from: displayName))"
    }

    static func objectivesSummary(from objectives: Set<TLIProfileObjective>) -> String {
        let resolved = objectives.isEmpty ? Set(TLIProfileObjective.defaultSet) : objectives
        return resolved
            .sorted { $0.title < $1.title }
            .map(\.title)
            .joined(separator: ", ")
    }
}
