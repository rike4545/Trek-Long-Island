import Foundation

enum TLIProfileRank: String, CaseIterable, Identifiable {
    case none
    case recruit
    case crewman
    case crewmanThirdClass
    case crewmanSecondClass
    case crewmanFirstClass
    case ableSeaman
    case pettyOfficerThirdClass
    case pettyOfficerSecondClass
    case pettyOfficerFirstClass
    case chiefPettyOfficer
    case seniorChiefPettyOfficer
    case masterChiefPettyOfficer
    case cadetFourthClass
    case cadetThirdClass
    case cadetSecondClass
    case cadetFirstClass
    case cadet
    case midshipman
    case officerCandidate
    case warrantOfficer
    case ensign
    case lieutenantJuniorGrade
    case lieutenant
    case lieutenantCommander
    case commander
    case captain
    case fleetCaptain
    case commodore
    case rearAdmiral
    case viceAdmiral
    case admiral
    case fleetAdmiral

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            "No rank"
        case .recruit:
            "Recruit"
        case .crewman:
            "Crewman"
        case .crewmanThirdClass:
            "Crewman third class"
        case .crewmanSecondClass:
            "Crewman second class"
        case .crewmanFirstClass:
            "Crewman first class"
        case .ableSeaman:
            "Able seaman"
        case .pettyOfficerThirdClass:
            "Petty officer third class"
        case .pettyOfficerSecondClass:
            "Petty officer second class"
        case .pettyOfficerFirstClass:
            "Petty officer first class"
        case .chiefPettyOfficer:
            "Chief petty officer"
        case .seniorChiefPettyOfficer:
            "Senior chief petty officer"
        case .masterChiefPettyOfficer:
            "Master chief petty officer"
        case .cadetFourthClass:
            "Cadet 4th class"
        case .cadetThirdClass:
            "Cadet 3rd class"
        case .cadetSecondClass:
            "Cadet 2nd class"
        case .cadetFirstClass:
            "Cadet 1st class"
        case .cadet:
            "Cadet"
        case .midshipman:
            "Midshipman"
        case .officerCandidate:
            "Officer candidate"
        case .warrantOfficer:
            "Warrant officer"
        case .ensign:
            "Ensign"
        case .lieutenantJuniorGrade:
            "Lieutenant junior grade"
        case .lieutenant:
            "Lieutenant"
        case .lieutenantCommander:
            "Lieutenant commander"
        case .commander:
            "Commander"
        case .captain:
            "Captain"
        case .fleetCaptain:
            "Fleet captain"
        case .commodore:
            "Commodore"
        case .rearAdmiral:
            "Rear admiral"
        case .viceAdmiral:
            "Vice admiral"
        case .admiral:
            "Admiral"
        case .fleetAdmiral:
            "Fleet admiral"
        }
    }

    var icon: String {
        switch self {
        case .none:
            "person.crop.circle"
        case .recruit:
            "person.badge.plus"
        case .crewman, .crewmanThirdClass, .crewmanSecondClass, .crewmanFirstClass, .ableSeaman:
            "person.fill"
        case .pettyOfficerThirdClass, .pettyOfficerSecondClass, .pettyOfficerFirstClass:
            "chevron.up"
        case .chiefPettyOfficer, .seniorChiefPettyOfficer, .masterChiefPettyOfficer:
            "chevron.up.2"
        case .cadetFourthClass, .cadetThirdClass, .cadetSecondClass, .cadetFirstClass:
            "graduationcap"
        case .cadet:
            "star"
        case .midshipman:
            "person.text.rectangle"
        case .officerCandidate:
            "person.crop.circle.badge.questionmark"
        case .warrantOfficer:
            "shield.lefthalf.filled"
        case .ensign:
            "chevron.up"
        case .lieutenantJuniorGrade:
            "chevron.up.circle"
        case .lieutenant:
            "chevron.up.2"
        case .lieutenantCommander:
            "chevron.up.2.circle"
        case .commander:
            "chevron.up.circle"
        case .captain:
            "star.circle.fill"
        case .fleetCaptain:
            "star.square.on.square.fill"
        case .commodore:
            "star.square.fill"
        case .rearAdmiral:
            "star.leadinghalf.filled"
        case .viceAdmiral:
            "star.fill"
        case .admiral:
            "sparkles"
        case .fleetAdmiral:
            "sparkles.rectangle.stack.fill"
        }
    }

    var description: String {
        switch self {
        case .none:
            "Use your name without a Starfleet rank."
        case .recruit:
            "The entry point below the crewman grades."
        case .crewman:
            "A general enlisted Starfleet identity."
        case .crewmanThirdClass:
            "An early enlisted crew grade from the NX-era structure."
        case .crewmanSecondClass:
            "An enlisted crew grade used in early Starfleet service."
        case .crewmanFirstClass:
            "The senior crewman grade before non-commissioned officer ranks."
        case .ableSeaman:
            "A listed enlisted-era equivalent seen in comparative rank tables."
        case .pettyOfficerThirdClass:
            "A junior non-commissioned officer grade."
        case .pettyOfficerSecondClass:
            "A non-commissioned officer grade listed in Starfleet rank tables."
        case .pettyOfficerFirstClass:
            "A senior petty officer grade for experienced enlisted personnel."
        case .chiefPettyOfficer:
            "A senior non-commissioned officer rank."
        case .seniorChiefPettyOfficer:
            "A higher non-commissioned officer rank, also associated with senior specialists."
        case .masterChiefPettyOfficer:
            "The highest listed non-commissioned officer rank."
        case .cadetFourthClass:
            "First-year Starfleet Academy cadet."
        case .cadetThirdClass:
            "Second-year Starfleet Academy cadet."
        case .cadetSecondClass:
            "Third-year Starfleet Academy cadet."
        case .cadetFirstClass:
            "Fourth-year Starfleet Academy cadet, typically nearing graduation."
        case .cadet:
            "A playful training-cruise identity for first-contact energy."
        case .midshipman:
            "A training rank occasionally used interchangeably with cadet."
        case .officerCandidate:
            "A candidate track before a commissioned officer rank."
        case .warrantOfficer:
            "A specialist rank listed separately from commissioned officers."
        case .ensign:
            "Clean and classic for guests just getting underway."
        case .lieutenantJuniorGrade:
            "A junior commissioned officer rank between ensign and lieutenant."
        case .lieutenant:
            "Confident bridge-officer energy without going full command."
        case .lieutenantCommander:
            "A senior commissioned officer rank between lieutenant and commander."
        case .commander:
            "A seasoned operations vibe for guests who like to stay sharp."
        case .captain:
            "Full command-deck presence for leading your own convention mission."
        case .fleetCaptain:
            "A rare distinction for captains commanding more than one facility."
        case .commodore:
            "A flag officer rank below admiral grades."
        case .rearAdmiral:
            "A flag officer rank in the admiralty."
        case .viceAdmiral:
            "A senior flag officer rank above rear admiral."
        case .admiral:
            "Flag-officer flair for guests who want maximum Trek gravitas."
        case .fleetAdmiral:
            "The highest listed Starfleet flag officer rank."
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

enum TLIProfileDivision: String, CaseIterable, Identifiable {
    case command
    case science
    case medical
    case operations

    var id: String { rawValue }

    var title: String {
        switch self {
        case .command:
            "Command"
        case .science:
            "Science"
        case .medical:
            "Medical"
        case .operations:
            "Operations"
        }
    }

    var icon: String {
        switch self {
        case .command:
            "star.circle.fill"
        case .science:
            "atom"
        case .medical:
            "cross.case.fill"
        case .operations:
            "gearshape.2.fill"
        }
    }

    var description: String {
        switch self {
        case .command:
            "Leadership, navigation, and mission decisions."
        case .science:
            "Research, analysis, discovery, and strange new worlds."
        case .medical:
            "Care, wellness, triage, and crew support."
        case .operations:
            "Engineering, logistics, systems, and keeping the ship moving."
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
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if rank == .none {
            return trimmed.isEmpty ? "Guest" : trimmed
        }
        guard !trimmed.isEmpty else { return rank.title }
        guard trimmed.localizedCaseInsensitiveCompare(rank.title) != .orderedSame else { return rank.title }
        return "\(rank.title) \(trimmed)"
    }

    static func objectivesSummary(from objectives: Set<TLIProfileObjective>) -> String {
        let resolved = objectives.isEmpty ? Set(TLIProfileObjective.defaultSet) : objectives
        return resolved
            .sorted { $0.title < $1.title }
            .map(\.title)
            .joined(separator: ", ")
    }
}
