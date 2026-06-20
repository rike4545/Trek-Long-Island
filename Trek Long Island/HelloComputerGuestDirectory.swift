import Foundation

enum HelloComputerGuestDirectory {
    struct Profile: Sendable {
        let name: String
        let category: String
        let roleSummary: String
        let series: String?
        let bioSummary: String
        let guestAliases: [String]
        let characterAliases: [String]
        let autographNote: String?
    }

    static func answer(for query: String) -> HelloComputerAnswer? {
        let normalized = normalize(query)
        guard !normalized.isEmpty else { return nil }

        if isRosterListQuery(normalized) {
            return HelloComputerAnswer(
                text: rosterSummary(),
                source: .generalGuidance,
                confidence: 0.97
            )
        }

        if let profile = matchedGuestProfile(in: normalized) {
            return HelloComputerAnswer(
                text: profileSummary(profile),
                source: .generalGuidance,
                confidence: 0.95
            )
        }

        if let profile = matchedCharacterProfile(in: normalized),
           isGuestCastingQuery(normalized) {
            return HelloComputerAnswer(
                text: castingSummary(profile),
                source: .generalGuidance,
                confidence: 0.94
            )
        }

        return nil
    }

    static func loreLookupQuery(for query: String) -> String? {
        let normalized = normalize(query)
        guard !normalized.isEmpty else { return nil }

        guard let profile = matchedCharacterProfile(in: normalized) else { return nil }
        guard !isGuestCastingQuery(normalized), !matchedGuestNameOnly(in: normalized) else { return nil }
        return profile.characterAliases.first
    }

    static func containsLoreSignal(in query: String) -> Bool {
        matchedCharacterProfile(in: normalize(query)) != nil
    }

    private static func rosterSummary() -> String {
        let celebrities = profiles.filter { $0.category == "Celebrity" }.map(\.name)
        let otherGuests = profiles.filter { $0.category != "Celebrity" }

        return """
        Trek Long Island guests currently include \(celebrities.joined(separator: ", ")).

        Additional featured guests and panelists include \(otherGuests.prefix(8).map(\.name).joined(separator: ", ")).

        Ask about any specific guest by name, or ask about a character they portray, such as Kira Nerys, Uhura, Ezri Dax, Vash, Minuet, Weyoun, Shran, or Captain Angel.
        """
    }

    private static func profileSummary(_ profile: Profile) -> String {
        let seriesLine = profile.series.map { " Series: \($0)." } ?? ""
        let autographNote = TLIAutographPricing2026.note(for: profile.name) ?? profile.autographNote
        let autographLine = autographNote.map { " \($0)" } ?? ""
        let cancellationLine = cancellationNote(for: profile.name).map { "\n\n\($0)" } ?? ""
        let loreLine = if let firstCharacter = profile.characterAliases.first {
            "\n\nFor character lore, ask about \(firstCharacter) by name."
        } else {
            ""
        }
        return """
        \(profile.name) is a Trek Long Island guest in the \(profile.category) lineup. Known for: \(profile.roleSummary).\(seriesLine)

        \(profile.bioSummary)\(cancellationLine)\(autographLine)\(loreLine)
        """
    }

    private static func cancellationNote(for guestName: String) -> String? {
        switch normalize(guestName) {
        case "louise sorel":
            "Louise Sorel will not be joining us this year due to a fur baby emergency. All the xoxo to her pup."
        default:
            nil
        }
    }

    private static func castingSummary(_ profile: Profile) -> String {
        "\(profile.name) is coming to Trek Long Island and is known for \(profile.roleSummary)."
    }

    private static func matchedGuestNameOnly(in query: String) -> Bool {
        profiles.contains { profile in
            profile.guestAliases.contains(where: { query == $0 })
        }
    }

    private static func matchedGuestProfile(in query: String) -> Profile? {
        profiles.first { profile in
            profile.guestAliases.contains(where: { query.contains($0) })
        }
    }

    private static func matchedCharacterProfile(in query: String) -> Profile? {
        profiles.first { profile in
            profile.characterAliases.contains(where: { query.contains($0) })
        }
    }

    private static func isRosterListQuery(_ query: String) -> Bool {
        let patterns = [
            "who is coming", "who s coming", "whos coming", "who are the guests",
            "guest list", "which guests", "which celebrities", "who is attending",
            "who s attending", "who will be there", "guests coming"
        ]
        return patterns.contains(where: { query.contains($0) })
    }

    private static func isGuestCastingQuery(_ query: String) -> Bool {
        let patterns = [
            "who plays", "who played", "who portrayed", "who is coming as",
            "who is attending as", "which guest plays", "which guest portrayed",
            "is coming", "attending", "guest"
        ]
        return patterns.contains(where: { query.contains($0) })
    }

    private static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let cleaned = String(folded.map { character in
            character.isLetter || character.isNumber ? character : " "
        })
        let parts = cleaned.split(whereSeparator: \.isWhitespace).map(String.init)
        return parts.joined(separator: " ")
    }

    private static let profiles: [Profile] = [
        .init(name: "Nana Visitor", category: "Celebrity", roleSummary: "portraying Kira Nerys", series: "Deep Space Nine", bioSummary: "A fan-favorite DS9 lead actor and one of the signature faces of the Bajoran resistance storyline.", guestAliases: ["nana visitor"], characterAliases: ["kira nerys", "kira"], autographNote: "Autograph signings and selfies are available at the guest's table."),
        .init(name: "Celia Rose Gooding", category: "Celebrity", roleSummary: "portraying Nyota Uhura", series: "Strange New Worlds", bioSummary: "An award-winning performer bringing a new generation of Uhura to the Enterprise.", guestAliases: ["celia rose gooding", "celia gooding"], characterAliases: ["nyota uhura", "uhura"], autographNote: "Autograph signings and selfies are available at the guest's table."),
        .init(name: "Musetta Vander", category: "Celebrity", roleSummary: "portraying Derran Tal", series: "Voyager", bioSummary: "Best known in Trek for appearing as Derran Tal in the Voyager episode \"The Disease.\"", guestAliases: ["musetta vander"], characterAliases: ["derran tal"], autographNote: "Autograph signings and selfies are available at the guest's table."),
        .init(name: "Jennifer Hetrick", category: "Celebrity", roleSummary: "portraying Vash", series: "The Next Generation and Deep Space Nine", bioSummary: "Known in Trek for the memorable archaeologist Vash and her Q-adjacent adventures.", guestAliases: ["jennifer hetrick"], characterAliases: ["vash"], autographNote: "Autograph signings and selfies are available at the guest's table."),
        .init(name: "Deirdre (Imershein) Haj", category: "Celebrity", roleSummary: "portraying Lieutenant Watley and Joval", series: "Deep Space Nine and The Next Generation", bioSummary: "Appeared in both TNG and DS9, giving her a two-era Trek connection.", guestAliases: ["deirdre imershein haj", "deirdre haj", "deirdre imershein"], characterAliases: ["lieutenant watley", "watley", "joval"], autographNote: "Autograph signings and selfies are available at the guest's table."),
        .init(name: "Dan Jeannotte", category: "Celebrity", roleSummary: "portraying Sam Kirk", series: "Strange New Worlds", bioSummary: "Known to modern Trek fans as George Samuel \"Sam\" Kirk on Strange New Worlds.", guestAliases: ["dan jeannotte"], characterAliases: ["sam kirk", "george samuel kirk"], autographNote: "Autograph signings and selfies are available at the guest's table."),
        .init(name: "Chris Myers", category: "Celebrity", roleSummary: "portraying Ensign Dana Gamble and Zeperez", series: "Strange New Worlds", bioSummary: "Appeared in Strange New Worlds as Dana Gamble and as Zeperez while possessing Gamble.", guestAliases: ["chris myers"], characterAliases: ["dana gamble", "ensign dana gamble", "zeperez"], autographNote: "Autograph signings and selfies are available at the guest's table."),
        .init(name: "Stephanie Czajkowski", category: "Celebrity", roleSummary: "portraying Lieutenant T'Veen", series: "Star Trek: Picard", bioSummary: "Played the Vulcan science officer T'Veen in Picard.", guestAliases: ["stephanie czajkowski", "stephanie czajkowsi"], characterAliases: ["t veen", "t'veen", "lt t veen", "lieutenant t veen"], autographNote: "Autograph signings and selfies are available at the guest's table."),
        .init(name: "Carolyn McCormick", category: "Celebrity", roleSummary: "portraying Minuet", series: "The Next Generation", bioSummary: "Known to TNG fans as Minuet, the holodeck character from \"11001001.\"", guestAliases: ["carolyn mccormick"], characterAliases: ["minuet"], autographNote: "Autograph signings and selfies are available at the guest's table."),
        .init(name: "Jeffrey Combs", category: "Celebrity", roleSummary: "playing multiple Trek roles including Weyoun, Brunt, and Shran", series: "Deep Space Nine and Enterprise", bioSummary: "One of Star Trek's most celebrated recurring actors, known for multiple standout alien roles.", guestAliases: ["jeffrey combs", "jeff combs"], characterAliases: ["weyoun", "brunt", "shran"], autographNote: "Autograph signings and selfies are available at the guest's table."),
        .init(name: "Sachi Parker", category: "Celebrity", roleSummary: "portraying Doctor Tava", series: "The Next Generation", bioSummary: "Appeared in the TNG episode \"First Contact\" as Doctor Tava.", guestAliases: ["sachi parker"], characterAliases: ["doctor tava", "dr tava", "tava"], autographNote: "Autograph signings and selfies are available at the guest's table."),
        .init(name: "Nicole de Boer", category: "Celebrity", roleSummary: "portraying Ezri Dax", series: "Deep Space Nine", bioSummary: "Joined DS9 in its final season as Ezri Dax, the next host of the Dax symbiont.", guestAliases: ["nicole de boer", "nicole deboer"], characterAliases: ["ezri dax", "ezri"], autographNote: "Autograph signings and selfies are available at the guest's table."),
        .init(name: "Louise Sorel", category: "Celebrity", roleSummary: "portraying Rayna Kapec", series: "The Original Series", bioSummary: "Known in Trek for Rayna Kapec from the TOS episode \"Requiem for Methuselah.\"", guestAliases: ["louise sorel"], characterAliases: ["rayna", "rayna kapec"], autographNote: nil),
        .init(name: "Jesse James Keitel", category: "Panelist", roleSummary: "portraying Captain Angel", series: "Strange New Worlds", bioSummary: "Known to Strange New Worlds viewers as the pirate Captain Angel.", guestAliases: ["jesse james keitel", "jesse keitel"], characterAliases: ["captain angel", "angel"], autographNote: nil),
        .init(name: "Tracee Cocco", category: "Panelist", roleSummary: "appearing as a featured Trek panel guest with credits across TNG, DS9, and Voyager", series: "The Next Generation, Deep Space Nine, and Voyager", bioSummary: "A familiar face from background and recurring appearances across multiple Trek series.", guestAliases: ["tracee cocco"], characterAliases: [], autographNote: nil),
        .init(name: "Paul Adams", category: "Panelist", roleSummary: "appearing as a diversity cohost and featured guest", series: nil, bioSummary: "Part of the IDIC track programming at Trek Long Island.", guestAliases: ["paul adams", "paul michael adams"], characterAliases: [], autographNote: nil),
        .init(name: "Heather Wood", category: "Panelist", roleSummary: "appearing as a diversity panelist", series: nil, bioSummary: "Featured as part of the IDIC track guest and panelist lineup.", guestAliases: ["heather wood"], characterAliases: [], autographNote: nil),
        .init(name: "Lucy BlueSkies", category: "Entertainment Guest", roleSummary: "appearing as a performance artist and Slut Trek creator", series: nil, bioSummary: "A performance artist known for Trek-inspired burlesque and live entertainment.", guestAliases: ["lucy blueskies", "lucy blue skies"], characterAliases: [], autographNote: nil),
        .init(name: "Beau Daciuos", category: "Panelist", roleSummary: "appearing as a diversity panelist", series: nil, bioSummary: "Featured in the convention's panelist lineup.", guestAliases: ["beau daciuos"], characterAliases: [], autographNote: nil),
        .init(name: "Matthew Lawrence Jennings", category: "Panelist", roleSummary: "appearing as a diversity panelist", series: nil, bioSummary: "Known for the series \"1701: A Blerd Story\" and participating in the diversity track.", guestAliases: ["matthew lawrence jennings", "matthew jennings"], characterAliases: [], autographNote: nil),
        .init(name: "Adeena Mignogna", category: "Panelist", roleSummary: "appearing as a diversity panelist", series: nil, bioSummary: "A physicist and astronomer working in aerospace as a mission architect.", guestAliases: ["adeena mignogna"], characterAliases: [], autographNote: nil),
        .init(name: "Bonnie Gordon", category: "Guest Speaker", roleSummary: "appearing as a luau performer and Trek guest", series: "Star Trek: Prodigy", bioSummary: "Known for voice and performance work including Star Trek: Prodigy.", guestAliases: ["bonnie gordon"], characterAliases: [], autographNote: nil),
        .init(name: "Avaah Blackwell", category: "Guest Speaker", roleSummary: "appearing with credits including Lt. Ina, Captain Rahma, Lt. Arav, and other modern Trek roles", series: "Discovery, Strange New Worlds, Section 31, and Starfleet Academy", bioSummary: "A modern Trek performer with credits across multiple current series.", guestAliases: ["avaah blackwell"], characterAliases: ["lt ina", "ina", "captain rahma", "rahma", "lt arav", "arav"], autographNote: nil),
        .init(name: "Tracy Martinson", category: "Artist", roleSummary: "appearing as an award-winning producer and behind-the-scenes Star Trek documentarian", series: "Modern Star Trek productions", bioSummary: "Known for documenting the making of the modern Star Trek era with rare behind-the-scenes access.", guestAliases: ["tracy martinson"], characterAliases: [], autographNote: nil)
    ]
}
