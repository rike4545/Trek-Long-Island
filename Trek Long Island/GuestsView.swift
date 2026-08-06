// Copyright Bryan Carroll. All rights reserved.
//  GuestsView.swift — Trek Long Island
//  - Dark-mode uniform (TLITheme), no placeholders
//  - Favorites by slug (stable), search, category chips
//  - Built-in celebrity fallback (restores prior list) if guests.json is absent
//  - Bounds-safe UI: fixed image sizes, line limits, truncation, safe lists
//

import SwiftUI

// MARK: - Types

enum GuestCategory: String, CaseIterable, Identifiable, Codable {
    case celebrity     = "Celebrity"
    case author        = "Authors"
    case guestspeakers = "Guest Speakers"
    case artist        = "Artists & Industry Professionals"
    case panelist      = "IDIC Track Guests and Panelists"
    case entertainment = "Entertainment Artists"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .celebrity:     return "Celebrity"
        case .panelist:       return "IDIC Track Guests and Panelists"
        case .guestspeakers: return "Guest Speakers"
        case .author:        return "Authors"
        case .artist:        return "Artists & Industry"
        case .entertainment: return "Entertainment Artists"
        }
    }
}

enum GuestAppearanceFilter: String, CaseIterable, Identifiable {
    case all
    case autographs
    case selfies

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All Access"
        case .autographs: return "Autographs"
        case .selfies: return "Selfies"
        }
    }
}

enum GuestAppearanceDay: String, CaseIterable, Identifiable, Codable, Hashable {
    case friday
    case saturday
    case sunday

    var id: String { rawValue }

    var label: String {
        switch self {
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }

    var shortLabel: String {
        switch self {
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
}

enum GuestStatus: String, CaseIterable, Codable, Hashable {
    case active
    case cancelled
    case replaced

    var label: String {
        switch self {
        case .active:
            return "Active"
        case .cancelled:
            return "Cancelled"
        case .replaced:
            return "Replaced"
        }
    }

    var systemImage: String {
        switch self {
        case .active:
            return "checkmark.circle.fill"
        case .cancelled:
            return "xmark.octagon.fill"
        case .replaced:
            return "arrow.triangle.2.circlepath.circle.fill"
        }
    }
}

enum TLIAutographPricing2026 {
    struct Entry: Identifiable, Hashable {
        let name: String
        let autographPrice: Int

        var id: String { name }
        var priceLabel: String { "$\(autographPrice)" }
        var detailNote: String {
            "2026 autograph price: \(priceLabel). 2027 pricing has not been announced."
        }
    }

    static let sourceURL = URL(string: "https://treklongisland.com/autograph-pricing-2026/")!
    static let sourceDescription = "Autograph pricing from the June 2026 convention, kept for reference. Pricing for \(TLIEventInfo.current.displayRange) has not been posted yet."

    static let entries: [Entry] = [
        .init(name: "Nana Visitor", autographPrice: 50),
        .init(name: "Jeffrey Combs", autographPrice: 50),
        .init(name: "Celia Rose Gooding", autographPrice: 50),
        .init(name: "Karim Diane", autographPrice: 40),
        .init(name: "Nicole de Boer", autographPrice: 50),
        .init(name: "Dan Jeannotte", autographPrice: 40),
        .init(name: "Chris Myers", autographPrice: 40),
        .init(name: "Jennifer Hetrick", autographPrice: 30),
        .init(name: "Stephanie Czajkowski", autographPrice: 40),
        .init(name: "Carolyn McCormick", autographPrice: 30),
        .init(name: "Sachi Parker", autographPrice: 30),
        .init(name: "Musetta Vander", autographPrice: 30),
        .init(name: "Deirdre (Imershein) Haj", autographPrice: 30),
        .init(name: "Tracee Cocco", autographPrice: 40),
        .init(name: "Jesse James Keitel", autographPrice: 40),
        .init(name: "Jackie Cox", autographPrice: 20)
    ]

    static func entry(for guestName: String) -> Entry? {
        let normalized = normalize(guestName)
        return entries.first { entry in
            normalize(entry.name) == normalized || aliases(for: entry.name).contains(normalized)
        }
    }

    static func note(for guestName: String) -> String? {
        entry(for: guestName)?.detailNote
    }

    private static func aliases(for name: String) -> Set<String> {
        switch name {
        case "Deirdre (Imershein) Haj":
            return ["deirdre imershein", "deirdre haj", "deirdre imershein haj"]
        default:
            return []
        }
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "(", with: " ")
            .replacingOccurrences(of: ")", with: " ")
            .replacingOccurrences(of: "'", with: "")
            .split { !$0.isLetter && !$0.isNumber }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct Guest: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let role: String
    let series: String?
    let imageName: String?   // optional to avoid crashes if asset is missing
    let accentHex: String?   // optional; fallback to theme accent
    let bio: String
    let sponsorship: String?
    let category: GuestCategory
    let twitterURL: URL?
    let instagramURL: URL?
    let websiteURL: URL?
    let imdbURL: URL?
    let cameoURL: URL?
    let memoryAlphaURL: URL?
    let tablePricingNote: String?
    let availableDays: [GuestAppearanceDay]?
    let status: GuestStatus
    let statusNote: String?
    let replacementGuestName: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case role
        case series
        case imageName
        case accentHex
        case bio
        case sponsorship
        case category
        case twitterURL
        case instagramURL
        case websiteURL
        case imdbURL
        case cameoURL
        case memoryAlphaURL
        case tablePricingNote
        case availableDays
        case status
        case statusNote
        case replacementGuestName
    }

    init(
        id: UUID = UUID(),
        name: String,
        role: String,
        series: String? = nil,
        imageName: String? = nil,
        accentHex: String? = nil,
        bio: String,
        sponsorship: String,
        category: GuestCategory,
        twitterURL: URL? = nil,
        instagramURL: URL? = nil,
        websiteURL: URL? = nil,
        imdbURL: URL? = nil,
        cameoURL: URL? = nil,
        memoryAlphaURL: URL? = nil,
        tablePricingNote: String? = nil,
        availableDays: [GuestAppearanceDay]? = nil,
        status: GuestStatus = .active,
        statusNote: String? = nil,
        replacementGuestName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.series = series
        self.imageName = imageName
        self.accentHex = accentHex
        self.sponsorship = sponsorship
        self.bio = bio
        self.category = category
        self.twitterURL = twitterURL
        self.instagramURL = instagramURL
        self.websiteURL = websiteURL
        self.imdbURL = imdbURL
        self.cameoURL = cameoURL
        self.memoryAlphaURL = memoryAlphaURL
        self.tablePricingNote = tablePricingNote
        self.availableDays = availableDays
        self.status = status
        self.statusNote = statusNote
        self.replacementGuestName = replacementGuestName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.role = try container.decode(String.self, forKey: .role)
        self.series = try container.decodeIfPresent(String.self, forKey: .series)
        self.imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        self.accentHex = try container.decodeIfPresent(String.self, forKey: .accentHex)
        self.bio = try container.decode(String.self, forKey: .bio)
        self.sponsorship = try container.decodeIfPresent(String.self, forKey: .sponsorship)
        self.category = try container.decode(GuestCategory.self, forKey: .category)
        self.twitterURL = try container.decodeIfPresent(URL.self, forKey: .twitterURL)
        self.instagramURL = try container.decodeIfPresent(URL.self, forKey: .instagramURL)
        self.websiteURL = try container.decodeIfPresent(URL.self, forKey: .websiteURL)
        self.imdbURL = try container.decodeIfPresent(URL.self, forKey: .imdbURL)
        self.cameoURL = try container.decodeIfPresent(URL.self, forKey: .cameoURL)
        self.memoryAlphaURL = try container.decodeIfPresent(URL.self, forKey: .memoryAlphaURL)
        self.tablePricingNote = try container.decodeIfPresent(String.self, forKey: .tablePricingNote)
        self.availableDays = try container.decodeIfPresent([GuestAppearanceDay].self, forKey: .availableDays)
        self.status = try container.decodeIfPresent(GuestStatus.self, forKey: .status) ?? .active
        self.statusNote = try container.decodeIfPresent(String.self, forKey: .statusNote)
        self.replacementGuestName = try container.decodeIfPresent(String.self, forKey: .replacementGuestName)
    }

    /// Stable slug used for persistence (favorites)
    var slug: String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: "-")
    }

    var resolvedTablePricingNote: String? {
        guard !isCancelled else { return nil }

        if let tablePricingNote,
           !tablePricingNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return tablePricingNote
        }

        if let pricingNote = TLIAutographPricing2026.note(for: name) {
            return pricingNote
        }

        guard category == .celebrity else { return nil }
        return "Autograph signings and selfie pricing are available at the guest's table."
    }

    var memoryAlphaNote: MemoryAlphaNote? {
        MemoryAlphaNotes.note(for: name)
    }

    var supportsAutographs: Bool {
        resolvedTablePricingNote != nil
    }

    var supportsSelfies: Bool {
        resolvedTablePricingNote != nil
    }

    var resolvedAvailableDays: [GuestAppearanceDay]? {
        guard !isCancelled else { return nil }

        if let availableDays, !availableDays.isEmpty {
            let order = GuestAppearanceDay.allCases
            return order.filter { availableDays.contains($0) }
        }

        guard category == .celebrity else { return nil }
        return GuestAppearanceDay.allCases
    }

    var availabilityLabel: String? {
        guard let resolvedAvailableDays else { return nil }
        if resolvedAvailableDays.count == GuestAppearanceDay.allCases.count {
            return "Entire Weekend"
        }
        return resolvedAvailableDays.map(\.label).joined(separator: ", ")
    }

    var availabilityPillLabel: String? {
        guard let resolvedAvailableDays else { return nil }
        if resolvedAvailableDays.count == GuestAppearanceDay.allCases.count {
            return "Weekend"
        }
        return resolvedAvailableDays.map(\.shortLabel).joined(separator: " + ")
    }

    var availabilityDetail: String? {
        // Cancellation/replacement messaging is rendered by the status banner,
        // so the availability row only carries real appearance days.
        guard let availabilityLabel else { return nil }
        return "Guest appearance: \(availabilityLabel)"
    }

    var isCancelled: Bool {
        status == .cancelled
    }

    var statusLabel: String? {
        switch status {
        case .active:
            return nil
        case .cancelled:
            return "Cancelled"
        case .replaced:
            return "Guest Update"
        }
    }

    /// Attendee-facing status banner text for both cancelled and replaced guests.
    /// Returns nil for active guests.
    var statusMessage: String? {
        let trimmedReplacement = replacementGuestName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = statusNote?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch status {
        case .active:
            return nil

        case .cancelled:
            var parts = ["Guest appearance cancelled"]
            if let trimmedReplacement, !trimmedReplacement.isEmpty {
                parts.append("Replacement: \(trimmedReplacement)")
            }
            if let trimmedNote, !trimmedNote.isEmpty {
                parts.append(trimmedNote)
            }
            return parts.joined(separator: " • ")

        case .replaced:
            var parts: [String]
            if let trimmedReplacement, !trimmedReplacement.isEmpty {
                parts = ["\(name) replaced by \(trimmedReplacement)"]
            } else {
                parts = ["Guest schedule updated"]
            }
            if let trimmedNote, !trimmedNote.isEmpty {
                parts.append(trimmedNote)
            }
            return parts.joined(separator: " • ")
        }
    }

    /// Back-compat: only non-nil when the guest is fully cancelled.
    var cancellationLabel: String? {
        isCancelled ? statusMessage : nil
    }

    func applying(statusOverride override: GuestStatusOverride) -> Guest {
        Guest(
            id: id,
            name: name,
            role: role,
            series: series,
            imageName: imageName,
            accentHex: accentHex,
            bio: bio,
            sponsorship: sponsorship ?? "",
            category: category,
            twitterURL: twitterURL,
            instagramURL: instagramURL,
            websiteURL: websiteURL,
            imdbURL: imdbURL,
            cameoURL: cameoURL,
            memoryAlphaURL: memoryAlphaURL,
            tablePricingNote: tablePricingNote,
            availableDays: availableDays,
            status: override.status,
            statusNote: override.note,
            replacementGuestName: override.replacementGuestName
        )
    }

    var seriesTags: [String] {
        guard let series = displaySeries?.uppercased() else { return [] }

        let mappings: [(String, String)] = [
            ("STRANGE NEW WORLDS", "SNW"),
            (" SNW", "SNW"),
            ("DEEP SPACE NINE", "DS9"),
            (" DS9", "DS9"),
            ("THE NEXT GENERATION", "TNG"),
            (" TNG", "TNG"),
            ("VOYAGER", "VOY"),
            ("PICARD", "PICARD"),
            ("ORIGINAL SERIES", "TOS"),
            (" TOS", "TOS"),
            ("PRODIGY", "PRODIGY"),
            ("DISCOVERY", "DISCOVERY"),
            ("ENTERPRISE", "ENTERPRISE"),
            ("SECTION 31", "SECTION 31"),
            ("STARFLEET ACADEMY", "ACADEMY")
        ]

        var tags: [String] = []
        for (pattern, tag) in mappings where series.contains(pattern) {
            if !tags.contains(tag) {
                tags.append(tag)
            }
        }

        if tags.isEmpty, let displaySeries {
            tags.append(displaySeries)
        }

        return tags
    }

    var displayRole: String {
        if let parsedRole = parsedCelebrityRoleSeries?.role {
            return parsedRole
        }
        return role
    }

    var displaySeries: String? {
        if let series, !series.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return series.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return parsedCelebrityRoleSeries?.series
    }

    private var parsedCelebrityRoleSeries: (role: String, series: String?)? {
        guard category == .celebrity else { return nil }

        let trimmedRole = role.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRole.isEmpty else { return nil }

        if let separatorRange = trimmedRole.range(of: "–") ?? trimmedRole.range(of: "-") {
            let rolePart = trimmedRole[..<separatorRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            let seriesPart = trimmedRole[separatorRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            return (
                role: rolePart.isEmpty ? trimmedRole : String(rolePart),
                series: seriesPart.isEmpty ? nil : String(seriesPart)
            )
        }

        if let range = trimmedRole.range(of: " from Star Trek: ", options: [.caseInsensitive]) {
            let rolePart = trimmedRole[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            let seriesPart = trimmedRole[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            return (
                role: rolePart.isEmpty ? trimmedRole : String(rolePart),
                series: seriesPart.isEmpty ? nil : "Star Trek: \(seriesPart)"
            )
        }

        if let range = trimmedRole.range(of: " in Star Trek: ", options: [.caseInsensitive]) {
            let rolePart = trimmedRole[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            let seriesPart = trimmedRole[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            return (
                role: rolePart.isEmpty ? trimmedRole : String(rolePart),
                series: seriesPart.isEmpty ? nil : "Star Trek: \(seriesPart)"
            )
        }

        if trimmedRole.localizedCaseInsensitiveContains("star trek") {
            return (role: trimmedRole, series: nil)
        }

        return (role: trimmedRole, series: nil)
    }
}

public struct MemoryAlphaNote: Equatable {
    public let summary: String
    public let sourceURL: String
    public let aliases: Set<String>
}

public enum MemoryAlphaNotes {
    private static let notes: [MemoryAlphaNote] = [
        .init(
            summary: "Best known in Star Trek for portraying Major (later Colonel) Kira Nerys on Deep Space Nine.",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Nana_Visitor",
            aliases: ["nana visitor"]
        ),
        .init(
            summary: "Credited as Nyota Uhura in Strange New Worlds, with additional listed roles including Neve and an Uhura illusion.",
            sourceURL: "https://memory-alpha.fandom.com/de/wiki/Celia_Rose_Gooding",
            aliases: ["celia rose gooding"]
        ),
        .init(
            summary: "Portrayed Derran Tal in the Voyager episode \"The Disease\".",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Musetta_Vander",
            aliases: ["musetta vander"]
        ),
        .init(
            summary: "Played Vash, who appears in TNG episodes \"Captain's Holiday\" and \"Qpid\" and in DS9 \"Q-Less\".",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Vash",
            aliases: ["jennifer hetrick"]
        ),
        .init(
            summary: "Played Joval in TNG \"Captain's Holiday\" and Watley in DS9 \"Trials and Tribble-ations\".",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Deirdre_L._Imershein",
            aliases: ["deirdre imershein haj", "deirdre haj", "deirdre imershein"]
        ),
        .init(
            summary: "Listed as George Samuel Kirk in Strange New Worlds guest and recurring credits.",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Star_Trek:_Strange_New_Worlds",
            aliases: ["dan jeannotte"]
        ),
        .init(
            summary: "Played Ensign Dana Gamble and Zeperez in Strange New Worlds season 3 appearances.",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Chris_Myers",
            aliases: ["chris myers"]
        ),
        .init(
            summary: "Credited as Lt. T'Veen in Star Trek: Picard, including the episode \"Disengage\".",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Disengage_(episode)",
            aliases: ["stephanie czajkowski"]
        ),
        .init(
            summary: "Played Minuet in TNG \"11001001\" and Min Riker in \"Future Imperfect\".",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Carolyn_McCormick",
            aliases: ["carolyn mccormick"]
        ),
        .init(
            summary: "Known for nine Star Trek roles across four series, including Weyoun, Brunt, and Shran.",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Jeffrey_Combs",
            aliases: ["jeffrey combs"]
        ),
        .init(
            summary: "Played Dr. Tava in the TNG episode \"First Contact\".",
            sourceURL: "https://memory-alpha.fandom.com/es/wiki/Sachi_Parker",
            aliases: ["sachi parker"]
        ),
        .init(
            summary: "Portrayed Ezri Dax through DS9 season 7 and appeared in all 25 episodes of that season.",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Nicole_de_Boer",
            aliases: ["nicole de boer"]
        ),
        .init(
            summary: "Portrayed Lieutenant Haile, a Deakohn Starfleet officer who served aboard the USS Athena, alongside other modern Trek roles.",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Avaah_Blackwell",
            aliases: ["avaah blackwell", "avaah b lackwell"]
        ),
        .init(
            summary: "Played Rayna Kapec in the TOS episode \"Requiem for Methuselah\".",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Louise_Sorel",
            aliases: ["louise sorel"]
        ),
        .init(
            summary: "Guest-starred as Captain Angel in the Strange New Worlds episode \"The Serene Squall\".",
            sourceURL: "https://memory-alpha.fandom.com/wiki/The_Serene_Squall_(episode)",
            aliases: ["jesse james keitel"]
        ),
        .init(
            summary: "Worked across TNG, DS9, and Voyager, and is best known as recurring background officer Lieutenant Jae on TNG.",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Tracee_Lee_Cocco",
            aliases: ["tracee cocco"]
        ),
        .init(
            summary: "Performed the USS Protostar ship computer voice in Star Trek: Prodigy and voiced other Trek roles.",
            sourceURL: "https://memory-alpha.fandom.com/wiki/Bonnie_Gordon",
            aliases: ["bonnie gordon"]
        )
    ]

    private static let notesByAlias: [String: MemoryAlphaNote] = {
        Dictionary(
            uniqueKeysWithValues: notes.flatMap { note in
                note.aliases.map { normalizedKey($0) }.map { ($0, note) }
            }
        )
    }()

    public static func note(for guestName: String) -> MemoryAlphaNote? {
        notesByAlias[normalizedKey(guestName)]
    }

    public static func normalizedKey(_ value: String) -> String {
        let folded = value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let sanitized = String(
            folded.map { character in
                character.isLetter || character.isNumber ? character : " "
            }
        )
        return sanitized
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .joined(separator: " ")
    }
}

// MARK: - Animation helper

private extension Animation {
    static var guestsSelection: Animation {
        if #available(iOS 17.0, *) { return .snappy }
        return .default
    }
}

// MARK: - View

@MainActor
struct GuestsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL
    @ObservedObject private var networkMonitor = TLINetworkMonitor.shared
    @ObservedObject private var guestStatusStore = GuestStatusStore.shared
    @ObservedObject private var guestStatusSync = GuestStatusSyncService.shared

    // External injection (optional). If empty we load JSON or fallback.
    private let injectedGuests: [Guest]
    private let showsHeader: Bool
    @State private var guests: [Guest] = []

    init(guests: [Guest] = [], showsHeader: Bool = true) {
        self.injectedGuests = guests
        self.showsHeader = showsHeader
    }

    // Filters
    @State private var searchText: String = ""
    @State private var selectedCategory: GuestCategory? = nil
    @State private var showFavoritesOnly = false
    @State private var selectedAppearanceFilter: GuestAppearanceFilter = .all
    @State private var selectedSeriesTag: String? = nil
    @State private var showCancelledGuests = false

    // Selection
    @State private var selectedGuest: Guest? = nil
    @State private var guestsLastSyncDate: Date?
    @State private var guestsLoadedFromCache = false

    // Favorites (slug-based). Migrate legacy name CSV once.
    @AppStorage("TLI.Guests.favoriteSlugsCSV") private var favoriteSlugsCSV: String = ""
    @AppStorage("TLI.Guests.favoriteNamesCSV") private var legacyNamesCSV: String = ""
    @AppStorage("TLI.Guests.cacheLastSync") private var guestsCacheLastSync: Double = 0

    private var favoriteSlugs: Set<String> {
        Set(favoriteSlugsCSV.split(separator: "|").map(String.init))
    }
    private func setFavoriteSlugs(_ slugs: Set<String>) {
        favoriteSlugsCSV = slugs.sorted().joined(separator: "|")
    }

    var body: some View {
        ZStack {
            // Dark-mode tuned background
            ZStack {
                TLITheme.backgroundGradient(scheme)
                if scheme == .dark {
                    Color.black.opacity(0.30)
                }
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if showsHeader {
                        header
                        guestDisclaimerCard
                            .padding(.horizontal)
                    }

                    if shouldShowOfflineStatusCard {
                        offlineStatusCard
                            .padding(.horizontal)
                    }

                    if !TLIEventInfo.current.isGuestRosterAnnounced {
                        rosterArchiveNotice
                            .padding(.horizontal)
                    }

                    searchAndFilterBar
                        .padding(.horizontal)

                    LazyVStack(spacing: 16) {
                        if filteredGuests.isEmpty {
                            emptyState
                                .padding(.top, 24)
                        } else {
                            ForEach(filteredGuests) { guest in
                                let accent = colorFromHex(guest.accentHex) ?? TLITheme.accent(scheme)
                                GuestCardRow(
                                    guest: guest,
                                    accentColor: accent,
                                    isFavorited: favoriteSlugs.contains(guest.slug),
                                    toggleFavorite: { toggleFavorite(guest) },
                                    onOpen: { openGuestDetail(guest) }
                                )
                                .id(guest.id)
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }
                .padding(.top, showsHeader ? 10 : 2)
                .adaptiveContentWidth()   // 👈 centers on iPad, full-width on iPhone
            }
        }
        .navigationTitle(showsHeader ? TLILCARSLabel.guests : "")
        .navigationBarTitleDisplayMode(showsHeader ? .inline : .automatic)
        .tliNavBarStyle()
        .sheet(item: $selectedGuest) { guest in
            GuestDetailSheet(
                guest: guest,
                accentColor: colorFromHex(guest.accentHex) ?? TLITheme.accent(scheme),
                onToggleFavorite: { toggleFavorite(guest) },
                onGuestUpdated: { updatedGuest in
                    applyGuestUpdate(updatedGuest)
                },
                onDismissRequested: {
                    withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.9)) {
                        selectedGuest = nil
                    }
                }
            )
        }
        .task { reloadGuestsData() }
        .task { guestStatusSync.start() }
        .onChange(of: guestStatusSync.remoteOverrides) {
            reloadGuestsData()
        }
        .onAppear(perform: migrateLegacyFavoritesIfNeeded)
        .animation(.guestsSelection, value: searchText)
        .animation(.guestsSelection, value: selectedCategory)
        .animation(.guestsSelection, value: showFavoritesOnly)
        .animation(.guestsSelection, value: selectedAppearanceFilter)
        .animation(.guestsSelection, value: selectedSeriesTag)
    }

    // MARK: - Derived

    private var categoryFiltered: [Guest] {
        guests
            .filter { !showFavoritesOnly || favoriteSlugs.contains($0.slug) }
            .filter { showCancelledGuests || !$0.isCancelled }
            .filter { selectedCategory == nil || $0.category == selectedCategory }
            .filter { guestMatchesAppearanceFilter($0) }
            .filter { guest in
                guard let selectedSeriesTag else { return true }
                return guest.seriesTags.contains(selectedSeriesTag)
            }
    }

    private var availableSeriesTags: [String] {
        let tags = Set(
            guests
                .filter { selectedCategory == nil || $0.category == selectedCategory }
                .flatMap(\.seriesTags)
        )
        return tags.sorted()
    }

    private var filteredGuests: [Guest] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = categoryFiltered
        guard !q.isEmpty else { return base.sorted(by: sortRule) }

        return base
            .filter {
                $0.name.localizedCaseInsensitiveContains(q) ||
                $0.role.localizedCaseInsensitiveContains(q) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(q) ||
                $0.category.label.localizedCaseInsensitiveContains(q)
            }
            .sorted(by: sortRule)
    }

    private func sortRule(_ a: Guest, _ b: Guest) -> Bool {
        let aFav = favoriteSlugs.contains(a.slug)
        let bFav = favoriteSlugs.contains(b.slug)
        return aFav != bFav ? aFav : (a.name < b.name)
    }

    private var activeFilterCount: Int {
        var count = 0
        if showFavoritesOnly { count += 1 }
        if selectedAppearanceFilter != .all { count += 1 }
        if selectedCategory != nil { count += 1 }
        if selectedSeriesTag != nil { count += 1 }
        if showCancelledGuests { count += 1 }
        return count
    }

    private var shouldShowOfflineStatusCard: Bool {
        !networkMonitor.isConnected || guestsLoadedFromCache
    }

    private var offlineDetail: String {
        if !networkMonitor.isConnected {
            return "You are offline. Guest roster is available from local data and cache."
        }
        if guestsLoadedFromCache {
            return "Loaded guest roster from cache while refreshing source data."
        }
        return "Guest roster is up to date."
    }

    private var offlineStatusCard: some View {
        TLIOfflineStatusCard(
            title: "Guest Roster",
            detail: offlineDetail,
            isOffline: !networkMonitor.isConnected,
            lastSyncDate: guestsLastSyncDate,
            loadedFromCache: guestsLoadedFromCache,
            actionTitle: "Reload Roster",
            action: {
                reloadGuestsData()
            }
        )
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(RisaTheme.isLCARSThemeEnabled ? "Personnel Database" : "Meet Our Guests")
                .font(
                    RisaTheme.isLCARSThemeEnabled
                        ? .system(size: 28, weight: .black, design: .monospaced)
                        : .title2.bold()
                )
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(RisaTheme.isLCARSThemeEnabled ? "Celebrity officers, creative specialists, and allied guests" : "Celebrities, authors, artists & more")
                .font(RisaTheme.isLCARSThemeEnabled ? .system(size: 13, weight: .semibold, design: .monospaced) : .subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            if !guests.isEmpty {
                Text(
                    RisaTheme.isLCARSThemeEnabled
                        ? "\(filteredGuests.count) personnel record\(filteredGuests.count == 1 ? "" : "s") online"
                        : "\(filteredGuests.count) guest\(filteredGuests.count == 1 ? "" : "s") showing"
                )
                    .font(.footnote)
                    .foregroundStyle(Color.primary.opacity(0.72))
            }
        }
        .padding(.horizontal)
        .tliLCARSPanelChrome(accent: RisaTheme.accent(scheme), metadata: "Personnel Database")
    }

    private var guestDisclaimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Guest Appearance Disclaimer", systemImage: "info.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("""
            Guests subject to cancellation or schedule change, due to professional commitments.
            Although most guests are available for the duration of the event, due to limited availability some guests are only available for a portion of the event, i.e. a single day.
            Appearance day(s) will be posted on the website as soon as we know.
            All events have limited seating capacities and are offered on a first come, first served basis.
            """)
            .font(.footnote)
            .lineSpacing(2)
            .foregroundStyle(TLITheme.textSecondary(scheme))
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            TLITheme.cardBackground(scheme).opacity(scheme == .dark ? 0.86 : 0.94),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme).opacity(0.38), lineWidth: TLITheme.hairline)
        )
        .accessibilityElement(children: .combine)
    }

    /// Shown while `isGuestRosterAnnounced` is false. The roster below this notice is
    /// last year's lineup — without this banner the tab reads as the current guest
    /// list, which is the single most misleading thing the app could show.
    private var rosterArchiveNotice: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("\(TLIEventInfo.current.yearText) Guest List Coming Soon", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Guests for \(TLIEventInfo.current.displayRange) have not been announced yet. The names below are the **\(TLIEventInfo.current.archivedRosterYearText) lineup**, kept for reference — they are not confirmed for \(TLIEventInfo.current.yearText).")
                .font(.footnote)
                .lineSpacing(2)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            if let mailingListURL = URL(string: TLIEventInfo.current.mailingListURLString) {
                Button {
                    openURL(mailingListURL)
                } label: {
                    Label("Get notified when guests are announced", systemImage: "envelope.fill")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(
            TLITheme.cardBackground(scheme).opacity(scheme == .dark ? 0.86 : 0.94),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.accent(scheme).opacity(0.55), lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
    }

    private var searchAndFilterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.primary.opacity(0.72))
                TextField(RisaTheme.isLCARSThemeEnabled ? "Search personnel…" : "Search guests…", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.primary.opacity(0.72))
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                TLITheme.cardBackground(scheme),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(TLITheme.border(scheme), lineWidth: 1)
            )

            HStack(spacing: 10) {
                Button {
                    showFavoritesOnly.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                        Text(RisaTheme.isLCARSThemeEnabled ? "Priority Files" : "Favorites")
                    }
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        TLITheme.controlShape(cornerRadius: 14)
                            .fill(showFavoritesOnly ? TLITheme.accent(scheme).opacity(0.9) : TLITheme.cardBackground(scheme))
                    )
                    .overlay(
                        TLITheme.controlShape(cornerRadius: 14)
                            .stroke(TLITheme.border(scheme), lineWidth: 1)
                    )
                    .foregroundStyle(showFavoritesOnly ? Color.black : TLITheme.textPrimary(scheme))
                }
                .buttonStyle(.plain)

                Menu {
                    Button("Clear All Filters") {
                        selectedCategory = nil
                        selectedAppearanceFilter = .all
                        selectedSeriesTag = nil
                        showCancelledGuests = false
                    }

                    Menu("Appearance") {
                        ForEach(GuestAppearanceFilter.allCases) { filter in
                            Button {
                                selectedAppearanceFilter = filter
                            } label: {
                                HStack {
                                    Text(filter.label)
                                    if selectedAppearanceFilter == filter {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }

                    Menu("Category") {
                        Button {
                            selectedCategory = nil
                        } label: {
                            HStack {
                                Text("All Categories")
                                if selectedCategory == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }

                        ForEach(GuestCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack {
                                    Text(category.label)
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }

                    if !availableSeriesTags.isEmpty {
                        Menu("Series") {
                            Button {
                                selectedSeriesTag = nil
                            } label: {
                                HStack {
                                    Text("All Series")
                                    if selectedSeriesTag == nil {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }

                            ForEach(availableSeriesTags, id: \.self) { tag in
                                Button {
                                    selectedSeriesTag = tag
                                } label: {
                                    HStack {
                                        Text(tag)
                                        if selectedSeriesTag == tag {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        showCancelledGuests.toggle()
                    } label: {
                        HStack {
                            Text(showCancelledGuests ? "Hide Cancelled Guests" : "Show Cancelled Guests")
                            if showCancelledGuests {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                        Text(activeFilterCount > 0 ? "Filters (\(activeFilterCount))" : "Filters")
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                    }
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        TLITheme.controlShape(cornerRadius: 14)
                            .fill(TLITheme.cardBackground(scheme))
                    )
                    .overlay(
                        TLITheme.controlShape(cornerRadius: 14)
                            .stroke(TLITheme.border(scheme), lineWidth: 1)
                    )
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                }

                if activeFilterCount > 0 || !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                        selectedCategory = nil
                        showFavoritesOnly = false
                        selectedAppearanceFilter = .all
                        selectedSeriesTag = nil
                        showCancelledGuests = false
                    }
                    .font(.footnote.weight(.semibold))
                    .buttonStyle(.plain)
                    .foregroundStyle(TLITheme.accent(scheme))
                }

                Spacer(minLength: 0)

                Text("\(filteredGuests.count)")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        TLITheme.controlShape(cornerRadius: 14)
                            .fill(TLITheme.cardBackground(scheme))
                    )
                    .overlay(
                        TLITheme.controlShape(cornerRadius: 14)
                            .stroke(TLITheme.border(scheme), lineWidth: 1)
                    )
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .accessibilityLabel(
                        RisaTheme.isLCARSThemeEnabled
                            ? "\(filteredGuests.count) personnel records showing"
                            : "\(filteredGuests.count) guests showing"
                    )
            }

            if activeFilterCount > 0 {
                Text(activeFilterSummary)
                    .font(.caption)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .lineLimit(2)
            }
        }
    }

    private var activeFilterSummary: String {
        var parts: [String] = []
        if selectedAppearanceFilter != .all {
            parts.append(selectedAppearanceFilter.label)
        }
        if let selectedCategory {
            parts.append(selectedCategory.label)
        }
        if let selectedSeriesTag {
            parts.append(selectedSeriesTag)
        }
        if showCancelledGuests {
            parts.append("Showing Cancelled")
        }
        return parts.joined(separator: " • ")
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Chip(
                    title: "⭐ Favorites",
                    isSelected: showFavoritesOnly,
                    scheme: scheme
                ) {
                    showFavoritesOnly.toggle()
                }

                ForEach(GuestAppearanceFilter.allCases) { filter in
                    Chip(
                        title: filter.label,
                        isSelected: selectedAppearanceFilter == filter,
                        scheme: scheme
                    ) {
                        selectedAppearanceFilter = filter
                    }
                }

                ForEach(GuestCategory.allCases) { category in
                    Chip(
                        title: category.label,
                        isSelected: selectedCategory == category,
                        scheme: scheme
                    ) {
                        selectedCategory = (selectedCategory == category) ? nil : category
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var seriesChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Chip(
                    title: "All Series",
                    isSelected: selectedSeriesTag == nil,
                    scheme: scheme
                ) {
                    selectedSeriesTag = nil
                }

                ForEach(availableSeriesTags, id: \.self) { tag in
                    Chip(
                        title: tag,
                        isSelected: selectedSeriesTag == tag,
                        scheme: scheme
                    ) {
                        selectedSeriesTag = selectedSeriesTag == tag ? nil : tag
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .imageScale(.large)
                .foregroundStyle(Color.primary.opacity(0.72))
            Text("No guests match your filters.")
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Actions

    private func toggleFavorite(_ guest: Guest) {
        var slugs = favoriteSlugs
        let s = guest.slug
        if slugs.contains(s) {
            slugs.remove(s)
        } else {
            slugs.insert(s)
        }
        setFavoriteSlugs(slugs)
    }

    private func openGuestDetail(_ guest: Guest) {
        withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.9)) {
            selectedGuest = guest
        }
    }

    private func applyGuestUpdate(_ guest: Guest) {
        if let index = guests.firstIndex(where: { $0.id == guest.id }) {
            guests[index] = guest
        }
        selectedGuest = guest
    }

    private func guestMatchesAppearanceFilter(_ guest: Guest) -> Bool {
        switch selectedAppearanceFilter {
        case .all:
            return true
        case .autographs:
            return guest.supportsAutographs
        case .selfies:
            return guest.supportsSelfies
        }
    }

    private func migrateLegacyFavoritesIfNeeded() {
        guard favoriteSlugsCSV.isEmpty, !legacyNamesCSV.isEmpty else { return }
        let names = legacyNamesCSV.split(separator: "|").map(String.init)
        let migrated = Set(names.map(slugify))
        setFavoriteSlugs(migrated)
        legacyNamesCSV = ""
    }

    // MARK: - Data loading

    private func reloadGuestsData() {
        let result = loadGuests(injected: injectedGuests)
        guests = result.guests.map(resolveOverrides)
        guestsLoadedFromCache = result.loadedFromCache
        if let syncDate = result.lastSyncDate {
            guestsLastSyncDate = syncDate
        } else if guestsCacheLastSync > 0 {
            guestsLastSyncDate = Date(timeIntervalSince1970: guestsCacheLastSync)
        }
    }

    /// Resolve a guest's status using remote sync first, then the local store.
    /// Remote and local carry identical content for any operator action, so the
    /// displayed result is stable regardless of which one is present.
    private func resolveOverrides(_ guest: Guest) -> Guest {
        if let remote = guestStatusSync.override(for: guest) {
            return guest.applying(statusOverride: remote)
        }
        return guestStatusStore.resolvedGuest(guest)
    }

    private func loadGuests(injected: [Guest]) -> GuestLoadResult {
        if !injected.isEmpty {
            let enriched = injected.map(addingMemoryAlphaBlurb)
            saveGuestCache(injected)
            saveGuestsSyncNow()
            return GuestLoadResult(guests: enriched, loadedFromCache: false, lastSyncDate: Date())
        }

        if let url = Bundle.main.url(forResource: "guests", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Guest].self, from: data),
           !decoded.isEmpty {
            let enriched = decoded.map(addingMemoryAlphaBlurb)
            saveGuestCache(decoded)
            saveGuestsSyncNow()
            return GuestLoadResult(guests: enriched, loadedFromCache: false, lastSyncDate: Date())
        }

        if let cached = loadGuestCache(), !cached.isEmpty {
            let enriched = cached.map(addingMemoryAlphaBlurb)
            let syncDate = guestsCacheLastSync > 0 ? Date(timeIntervalSince1970: guestsCacheLastSync) : nil
            return GuestLoadResult(guests: enriched, loadedFromCache: true, lastSyncDate: syncDate)
        }

        // Built-in fallback (restores prior celebrities)
        let fallback = defaultGuests.map(addingMemoryAlphaBlurb)
        return GuestLoadResult(guests: fallback, loadedFromCache: false, lastSyncDate: nil)
    }

    private func saveGuestsSyncNow() {
        guestsCacheLastSync = Date().timeIntervalSince1970
    }

    private var guestCacheURL: URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return cacheDir.appendingPathComponent("tli-guests-cache-v1.json")
    }

    private func saveGuestCache(_ guests: [Guest]) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(guests) else { return }
        try? data.write(to: guestCacheURL, options: [.atomic])
    }

    private func loadGuestCache() -> [Guest]? {
        guard let data = try? Data(contentsOf: guestCacheURL) else { return nil }
        return try? JSONDecoder().decode([Guest].self, from: data)
    }

    // MARK: - Helpers

    private func slugify(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: "-")
    }

    private func colorFromHex(_ hex: String?) -> Color? {
        guard let hex = hex?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: ""),
              let val = UInt64(hex, radix: 16) else { return nil }

        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8)  & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    private func addingMemoryAlphaBlurb(_ guest: Guest) -> Guest {
        let cleanedBio = stripManagedMemoryAlphaContent(from: guest.bio)
        let resolvedMemoryAlphaURL = resolvedMemoryAlphaURL(for: guest.name, detailURL: guest.memoryAlphaNote?.sourceURL)

        return Guest(
            id: guest.id,
            name: guest.name,
            role: guest.role,
            series: guest.series,
            imageName: guest.imageName,
            accentHex: guest.accentHex,
            bio: cleanedBio,
            sponsorship: guest.sponsorship ?? "",
            category: guest.category,
            twitterURL: guest.twitterURL,
            instagramURL: guest.instagramURL,
            websiteURL: guest.websiteURL,
            imdbURL: guest.imdbURL,
            cameoURL: guest.cameoURL,
            memoryAlphaURL: guest.memoryAlphaURL ?? resolvedMemoryAlphaURL,
            tablePricingNote: guest.tablePricingNote,
            availableDays: guest.availableDays,
            status: guest.status,
            statusNote: guest.statusNote,
            replacementGuestName: guest.replacementGuestName
        )
    }

    private struct GuestLoadResult {
        let guests: [Guest]
        let loadedFromCache: Bool
        let lastSyncDate: Date?
    }

    private func resolvedMemoryAlphaURL(for name: String, detailURL: String?) -> URL? {
        if let detailURL, let url = URL(string: detailURL) {
            return url
        }
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://memory-alpha.fandom.com/wiki/Special:Search?query=\(encodedName)")
    }

    private func stripManagedMemoryAlphaContent(from bio: String) -> String {
        let oldBlurb = "Memory Alpha is a fan-maintained Star Trek reference wiki with in-universe and production background details."
        let oldSection = "Memory Alpha details:"
        let newSection = "Star Trek notes (Memory Alpha):"

        var cleaned = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "\n\n\(oldBlurb)", with: "")
        cleaned = cleaned.replacingOccurrences(of: oldBlurb, with: "")

        if let range = cleaned.range(of: oldSection) {
            cleaned = String(cleaned[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let range = cleaned.range(of: newSection) {
            cleaned = String(cleaned[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }

    // MARK: - Built-in fallback guests

    private let defaultGuests: [Guest] = [
        Guest(
            name: "Nana Visitor",
            role: "Kira Nerys",
            series: "DS9 (Deep Space Nine)",
            imageName: "NanaVisitor",
            accentHex: "#FF4C99",
            bio: "Nana Visitor was born on July 26, 1957 in New York City, New York, USA. She is an actress, known for Star Trek: Deep Space Nine (1993), Friday the 13th (2009) and Ted 2 (2015). She was previously married to Matthew Rimmer, Alexander Siddig and Nicholas Miscusi.",
            sponsorship: "",
            category: .celebrity,
            twitterURL: URL(string: "https://x.com/NanaVisitor"),
            instagramURL: URL(string: "https://www.instagram.com/visitornana/"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm0000684/"),
            cameoURL: URL(string: "https://www.cameo.com/nanav")
        ),
        Guest(
            name: "Celia Rose Gooding",
            role: "Nyota Uhura",
            series: "SNW (Strange New Worlds)",
            imageName: "Gooding",
            accentHex: "#FF4C99",
            bio: "Celia Rose Gooding is an American actress and singer. They made their Broadway debut and rose to prominence for the role of Mary Frances Frankie Healy in the rock musical Jagged Little Pill for which they won a 2021 Grammy Award for Best Musical Theater Album and was nominated for a 2020 Tony Award for Best Actress in a Featured Role in a Musical",
            sponsorship: "",
            category: .celebrity,
            twitterURL: URL(string: ""),
            instagramURL: URL(string: "https://www.instagram.com/celiargooding"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm10957503/"),
            cameoURL: URL(string: "https://www.cameo.com/celiargooding")
        ),
        Guest(
            name: "Musetta Vander",
            role: "Derran Tal",
            series: "Voyager",
            imageName: "MusettaVander",
            accentHex: "#FF4C99",
            bio: "A Dutch South African, Musetta Vander was raised without the most basic of modern conveniences--television! Radio programming, childhood books and weekend trips to the drive-in introduced her to the magical world of movies. It was not until the mid-'70s that South Africa finally got television, and the big black box in the family living room miraculously sprang to life. However, as the daughter of a ballet teacher, Musetta was no stranger to the entertainment world and debuted on stage at the age of four. Her childhood was filled with numerous dance performances including Giselle, Coppelia, The Student Prince and Showboat, and, shortly after completing school, she qualified as a ballet teacher herself. After earning a BA in Communications and Psychology, she landed the plum job as anchor host for an MTV-like television show in South Africa. It was her critically acclaimed stage performance in the original South African play Soweto Burning, about the trials of an interracial friendship in that racially segregated country, that provided her transition to the big screen. Musetta has since performed in numerous feature films, including collaborating with her husband on Under the Hula Moon (1995) and Gunshy (1998).",
            sponsorship: "",
            category: .celebrity,
            twitterURL: URL(string: "https://x.com/musettavander"),
            instagramURL: URL(string: "https://www.instagram.com/musettavander"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm0888727/"),
            cameoURL: URL(string: "https://www.cameo.com/musettavander")
        ),
        Guest(
            name: "Jennifer Hetrick",
            role: "Vash",
            series: "TNG & DS9",
            imageName: "JenniferHetrick",
            accentHex: "#FF4C99",
            bio: "Jennifer Hetrick is a veteran character actor. Working steadily for over 30 years (1979 to present), mostly in Television. She is probably most well-known in the Sci-Fi genre for the character Vash on Star Trek: The Next Generation (1987) and Star Trek: Deep Space Nine (1993). She was also on Sliders (1995) for two separate roles. She has only been in 5 movies over the years. Her first movie was also her first major acting role, in 1979, titled Squeeze Play (1979). She had second billing. Her most recent movie was an uncredited part in 500 Days of Summer (2009) in 2009.She has mostly played authoritative and independent figures.",
            sponsorship: "",
            category: .celebrity,
            twitterURL: nil,
            instagramURL: nil,
            imdbURL: URL(string: "https://www.imdb.com/name/nm0381763/")
        ),
        Guest(
            name: "Deirdre (Imershein) Haj",
            role: "Lieutenant Watley; Joval",
            series: "DS9 & TNG",
            imageName: "deirdre imershein",
            accentHex: "#FF4C99",
            bio: "Deirdre Haj Film Streams, Omaha, Executive Director Deirdre Haj joined Film Streams in May 2021 following an outstanding run at the Full Frame Documentary Film Festival, in Durham, NC, which she had led since January 2010. Under her leadership, Full Frame developed into a prized, Oscar-qualifying festival, established year-round programming and community engagement, and prioritized equity, diversity, and inclusion across the organization and its programming. Haj also developed resources to build new Full Frame offices, as well the Full Frame Theater in downtown Durham, and oversaw a consistent annual growth in membership. She is the founding Vice President of the Film Festival Alliance. Deirdre is married to Joseph Haj, Artistic Director of The Guthrie Theater in Minneapolis, Minnesota.",
            sponsorship: "",
            category: .celebrity,
            twitterURL: nil,
            instagramURL: nil,
            imdbURL: URL(string: "https://www.imdb.com/name/nm0408170/")
        ),
        Guest(
            name: "Dan Jeannotte",
            role: "Sam Kirk",
            series: "SNW (Strange New Worlds)",
            imageName: "Jeannotte",
            accentHex: "#FF4C99",
            bio: "Dan Jeannotte is an actor, improviser, voice artist and writer. He is currently featured in the critically-acclaimed series Star Trek: Strange New Worlds as Sam Kirk, brother of James T. Kirk. He is familiar to TV viewers for his role as James Stuart, the Earl of Moray in the CW's period drama Reign and from a major recurring role as Pinstripe Guy, the Mr. Big-type love interest of the main character in the Freeform hit series The Bold Type. Dan is a graduate of the Actors Conservatory at the Canadian Film Center. He has worked extensively in the comedy and theatre scenes in Montreal and Toronto and has toured Canada and the US with his Canadian Comedy Award-nominated comedy troupe, Uncalled For.",
            sponsorship: "",
            category: .celebrity,
            twitterURL: URL(string: "https://twitter.com/dan_jeannotte"),
            instagramURL: URL(string: "https://www.instagram.com/littlespoonman/"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm3005219/")
        ),
        Guest(
            name: "Chris Myers",
            role: "Ensign/Nurse Dana Gamble and Zeperez",
            series: "SNW (Strange New Worlds)",
            imageName: "Myers",
            accentHex: "#FF4C99",
            bio: "Chris Myers is an actor who played Ensign Dana Gamble and Zeperez, a Vezda possessing Gamble in the third season of Star Trek: Strange New Worlds.Myers studied acting at the Julliard School and made guest appearances on series such as The Good Fight (with Paul Guilfoyle and Phumzile Sitole), She's Gotta Have It, and The Resident (with Glenn Morshower and Bruce Greenwood). He also appeared in the independent drama films Evol (2016) and Becks (2017).",
            sponsorship: "",
            category: .celebrity,
            twitterURL: nil,
            instagramURL: URL(string: "https://www.instagram.com/chrismyersinc/"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm6757522/")
        ),
        Guest(
            name: "Stephanie Czajkowski",
            role: "T'Veen",
            series: "Star Trek: Picard",
            imageName: "Czajkowski",
            accentHex: "#FF4C99",
            bio: "Originally from Wisconsin, an early obsession with the Brady Bunch led Stephanie to pursue a career in the Arts. After high school, Czajkowski earned a degree from New York University's Tisch School of The Arts and continued honing her craft at Playwright's Horizon and Steppenwolf Theatre before moving to Los Angeles. Supporting herself working as a fitness instructor and a bartender, her big break came with the role of Paramedic #1 on TLC's I Didn't Know I was Pregnant, where she cut a fake umbilical cord on a very life-like plastic baby. Best known for her roles as the Vulcan Science Officer Lt. T'Veen on the final season on Star Trek: Picard, the bald badass alter-ego Hammerhead on HBO Max's Doom Patrol.",
            sponsorship: "",
            category: .celebrity,
            twitterURL: nil,
            instagramURL: URL(string: "https://www.instagram.com/skisays/"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm1570123/")
        ),
        Guest(
            name: "Carolyn McCormick",
            role: "Minuet",
            series: "TNG (The Next Generation)",
            imageName: "McCormick",
            accentHex: "#FF4C99",
            bio: "Carolyn McCormick was born in Midland, Texas. She holds a BFA from Williams College as well as an MFA from American Conservatory Theater (ACT). She is best known for starring in Law & Order as well as the films Whatever Works and Enemy Mine. Besides film and television, Carolyn's theater credits include: Broadway: Equus, Private Lives, The Dinner Party. Off Broadway: The Open House (Drama Desk Award, Lucille Lortel nomination), Family Furniture, Black Tie, Ten Chimneys,Celebration, Privilege, Biography, EVE-olution, Dinner With Friends, Ancestral Voices.",
            sponsorship: "",
            category: .celebrity,
            
            twitterURL: URL(string: "https://x.com/mslynniemackn"),
            instagramURL: URL(string: "https://www.instagram.com/carolynmccormick_official/?hl=en"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm0566796/")
        ),
        
        Guest(
            name: "Jeffrey Combs",
            role: "Nine onscreen roles",
            series: "DS9 & Enterprise",
            imageName: "combs",
            accentHex: "#FF4C99",
            bio: "Auditioned for the role of Commander Riker on Star Trek: The Next Generation (1987). He is also best known for starring as Herbert West in the H.P. Lovecraft adaptation Re-Animator (1985) and portraying a number of characters in the Star Trek universe, most notably Brunt and the various Weyouns on Star Trek: Deep Space Nine (1994–1999), and Shran on Star Trek: Enterprise (2001–2005).",
            sponsorship: "",
            category: .celebrity,
            twitterURL: URL(string: ""),
            instagramURL: URL(string: "https://www.instagram.com/j_combs1979/"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm0001062/")
        ),
        
        Guest(
            name: "Sachi Parker",
            role: "Malcorian Doctor Tava",
            series: "TNG (The Next Generation)",
            imageName: "parker",
            accentHex: "#FF4C99",
            bio: "Sachi Parker is an American actress, daughter of Shirley MacLaine, known for roles in films like Back to the Future and Scrooged, and for her guest role as Dr. Tava in the Star Trek: The Next Generation episode First Contact though she didn't watch Star Trek growing up in Japan, only discovering it later in America, and also famously inspired Regan MacNeil in The Exorcist. ",
            sponsorship: "",
            category: .celebrity,
            twitterURL: URL(string: ""),
            instagramURL: URL(string: "https://www.instagram.com/thesachiparker"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm0662599/")
        ),
        Guest(
            name: "Nicole de Boer",
            role: "Ezri Dax",
            series: "DS9 (Deep Space Nine)",
            imageName: "boer",
            accentHex: "#FF4C99",
            bio: "She was cast in the seventh and final season of Star Trek: Deep Space Nine (1993), replacing Terry Farrell as the symbiont host Ezri Dax. At age seventeen, she was cast as a series regular in the CBC drama 9B (1988). Nicole's numerous television credits include: Beyond Reality (1991), First Resort, Catwalk (1992), The Kids in the Hall (1988), The Outer Limits (1995), PSI Factor: Chronicles of the Paranormal (1996), Maniac Mansion (1990) and Mission Genesis (1997).",
            sponsorship: "",
            category: .celebrity,
            twitterURL: URL(string: "https://x.com/Nikki_deboer"),
            instagramURL: URL(string: "https://www.instagram.com/nikkibits007/?hl=en"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm0207498/")
        ),
        Guest(
            name: "Louise Sorel",
            role: "Rayna",
            series: "TOS (Original Series)",
            imageName: "sorel",
            accentHex: "#FF4C99",
            bio: "Louise Jacqueline Sorel (née Cohen; born August 6, 1940)[4] is an American actress. She is perhaps best known for her role as Vivian Alamain in Days of Our Lives from 1992-2000, 2009-2011, 2017-2018, 2020, 2023 & 2025; Augusta Lockridge on Santa Barbara from 1984-1991; and Emily Tanner on Beacon Hill since 2014. She also played Rayna, in the episode Requiem for Methuselah, which aired in 1969 of the original series.",
            sponsorship: "",
            category: .celebrity,
            twitterURL: URL(string: ""),
            instagramURL: URL(string: ""),
            imdbURL: URL(string: "https://www.imdb.com/name/nm0814798/"),
            status: .cancelled,
            statusNote: "Louise Sorel will not be joining us this year due to a fur baby emergency. All the xoxo to her pup."
        ),
        Guest(
            name: "Jesse James Keitel",
            role: "Capitan Angel",
            series:"Star Trek: SNW (Strange New Worlds)",
            imageName: "Jesse James Keitel",
            accentHex: "#FF4C99",
            bio: "American actress, writer, and artist,[2] known for starring in Asher Jelinsky's award-winning short film Miller & Son (2019), the ABC crime drama Big Sky (2020) and on Queer as Folk (2022). In 2022, she appeared in an episode of Star Trek: Strange New Worlds, playing a non-binary villain. ",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .celebrity,
            twitterURL: URL(string: ""),
            instagramURL: URL(string: ""),
            imdbURL: URL(string: "https://www.imdb.com/name/nm5740850/")
        ),
        Guest(
            name: "Tracee Cocco",
            role: "TNG/DS9/Voyager",
            imageName: "Tracee Cocco",
            accentHex: "#FF4C99",
            bio: "Tracee Lee Cocco (born 2 March 1961; age 64) is an actress, model and stuntwoman who worked on Star Trek: The Next Generation, Star Trek: Deep Space Nine, and Star Trek: Voyager. She was most visibly seen as Lieutenant Jae, a regular background character on The Next Generation, between the fourth and seventh seasons. She was one of the background performers who also appeared in Star Trek Generations, Star Trek: First Contact, and Star Trek: Insurrection.",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .celebrity,
            imdbURL: URL(string: "https://www.imdb.com/name/nm1006740/")
        ),
        Guest(
            name: "Paul Adams",
            role: "Diversity Cohost",
            imageName: "Paul Michael Adams",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .panelist,
        ),
        Guest(
            name: "Heather Wood",
            role: "Diversity Panelist",
            imageName: "Heather Wood",
            accentHex: "#FF4C99",
            bio: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .panelist,
        ),
        Guest(
            name: "Logan Stone, D'manda Martini, Jessica Crouse",
            role: "Diversity Panelists",
            imageName: "misc",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .panelist,
        ),
        Guest(
            name: "Lucy BlueSkies",
            role: "Performance Artist / Drag Thing",
            imageName: "blueskies",
            accentHex: "#FF4C99",
            bio: "Lucy BlueSkies is a performance artist and drag thing hailing from Boston, MA. Debuting in 2017, she quickly found her home in the spookier parts of Boston’s drag and burlesque scene, joining the cast of Slaughterhouse Movie Club and Walter Sickert and the Army of Broken Toys’ “Something Strange”, later the Slutcracker in 2021. Having grown up a fan of Hellboy, Stargate SG1, and all things horror, Lucy found her true love of Star Trek at a burlesque show in 2017. By the time the show returned one year later, she had watched all of The Original Series, The Animated Series, The Next Generation, and she was in a science officers uniform. For the next several years Lucy continued to grow her love for Star Trek and performance art, training at a circus studio, learning pole dance, and dancing in the club to fund her full time performance career. After starting SciFiStripper, a nerdy meme page inspired by her time at the club, Lucy produced her first show Slut Trek in May of 2023. Considering this her true calling, she has decided to focus her production efforts on making Slut Trek the premiere 18+ live action experience!",
            sponsorship: "",
            category: .entertainment,
            availableDays: [.saturday]
        ),
        Guest(
            name: "Beau Daciuos",
            role: "Diversity Panelist",
            imageName: "Beau Daciuos",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .panelist,
        ),
        Guest(
            name: "Matthew Lawrence Jennings",
            role: "Diversity Panelist",
            imageName: "Jennings",
            accentHex: "#FF4C99",
            bio: "Matthew is part of our diversity track and will be speaking on panels. If you haven't seen his series 1701: a Blerd Story, catch it now on YouTube!",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .panelist,
        ),
        Guest(
            name: "Janera Tiell Manno",
            role: "Diversity Panelist",
            imageName: "Manno",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .panelist,
        ),
        Guest(
            name: "Damian Effler",
            role: "Diversity Panelist",
            imageName: "Effler",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .panelist,
        ),
        Guest(
            name: "Aiyana-Mei Tom",
            role: "Diversity Panelist",
            imageName: "Tom",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .panelist,
        ),
        Guest(
            name: "Leigh Ellen Mitchell",
            role: "Diversity Panelist",
            imageName: "Mitchell",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .panelist,
        ),
        Guest(
            name: "Dr. Brenda Dorsh",
            role: "Diversity Panelist",
            imageName: "Dorsh",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .panelist,
        ),
            Guest(
                name: "Kris Otto",
                role: "Diversity Panelist",
                imageName: "Otto",
                accentHex: "#FF4C99",
                bio: "",
                sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
                category: .panelist,
        ),
        Guest(
            name: "Chad Briggs",
            role: "Diversity Panelist",
            imageName: "Briggs",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .panelist,
        ),
        Guest(
            name: "Adeena Mignogna",
            role: "Diversity Panelist",
            imageName: "Adeena Mignogna",
            accentHex: "#FF4C99",
            bio: "Adeena is a physicist and astronomer (by degree) working in aerospace as a Mission Architect, which just means she's been doing it so long they had to give her a fun title.",
            sponsorship: "IDIC Track Guests and Panelists Sponsored by PMA Consulting",
            category: .panelist,
            twitterURL: URL(string: ""),
            instagramURL: URL(string: "https://www.instagram.com/adeenamig"),
            websiteURL: URL(string: "https://adeenamignogna.com/")
        ),
        Guest(
            name: "Bonnie Gordon",
            role: "Luau Performer and Guest",
            imageName: "Gordon",
            accentHex: "#FF4C99",
            bio: "She is an actress and producer, known for Star Trek: Prodigy (2021), The Quest (2014) and Street Fighter V (2016). ",
            sponsorship: "",
            category: .guestspeakers,
            twitterURL: URL(string: ""),
            instagramURL: URL(string: "https://www.instagram.com/bonniebellg/"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm3239252/"),
            cameoURL: URL(string: "https://www.cameo.com/bonniebellg")
        ),
        Guest(
            name: "Avaah Blackwell",
            role: "Lt. Haile, Lt. Ina, Osnullus + others",
            imageName: "Blackwell",
            accentHex: "#FF4C99",
            bio: "Avaah Blackwell has appeared across multiple modern *Star Trek* series, including Star Trek: Discovery, Star Trek: Strange New Worlds, Star Trek: Section 31, and Star Trek: Starfleet Academy. Throughout the expanding *Star Trek* universe, she has portrayed a wide range of characters including Lt. Ina, Captain Rahma, Lt. Arav, an Osnullus bridge officer and trader, and a Kelpien council member. Fans may also recognize her from *Strange New Worlds*, where she appeared as both a Linnarean guard and a Klingon zombie.",
            sponsorship: "",
            category: .guestspeakers,
            twitterURL: URL(string: ""),
            instagramURL: URL(string: "https://www.instagram.com/avaahblackwell/?hl=en"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm4389000/")
        ),
        Guest(
            name: "Tracy Martinson",
            role: "Award-winning producer and storyteller",
            imageName: "Martinson",
            accentHex: "#FF4C99",
            bio: "Tracy Martinson is an award-winning producer and storyteller known for blending technical innovation with compelling creative vision. With a degree in Electrical Engineering, she began her career as a dialogue and music editor for television and film, earning extensive engineering credits and helping pioneer early digital audio workstations, high-resolution audio tools, and the world’s first DVD-Audio disc. She also produced the first 24-channel DSD recording with Alison Krauss and Union Station’s live album, which won two Grammy Awards. Since 2012, Tracy has collaborated with writer-producer Alex Kurtzman, creating behind-the-scenes content across his projects. She has documented every modern Star Trek series beginning with Star Trek: Discovery and continuing across the expanding franchise. With rare access from the writers’ room through post-production, she captures the creative and technical process behind today’s Star Trek universe.",
            sponsorship: "",
            category: .artist,
            twitterURL: URL(string: ""),
            instagramURL: URL(string: "https://www.instagram.com/tracymmartinson/"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm0554182/")
        ),
        Guest(
            name: "Derek Tyler Attico",
            role: "Author",
            imageName: "Attico",
            accentHex: "#FF4C99",
            bio: "Derek Tyler Attico is a speculative fiction author, essayist, and award-winning photographer. In fiction, Derek has won the Excellence in Playwriting Award from the Dramatist Guild of America, and he is a two-time winner of the Star Trek Strange New Worlds short story contest (“Alpha & Omega,” “The Dreamer and the Dream”) published by Simon and Schuster.",
            sponsorship: "",
            category: .author,
            twitterURL: URL(string: "https://x.com/DAttico"),
            instagramURL: URL(string: "https://www.instagram.com/dattico"),
            websiteURL: URL(string: "https://www.derekattico.com/")
        ),
        Guest(
            name: "Robb Pearlman",
            role: "Author",
            imageName: "Attico",
            accentHex: "#FF4C99",
            bio: "#1 New York Times Bestselling Author. Pop Culturalist. Starfleet Officer. Rebel Alliance Droid. Fellowship of the Ring Fella.",
            sponsorship: "",
            category: .author,
            instagramURL: URL(string: "https://www.instagram.com/robbpearlman/"),
            websiteURL: URL(string: "https://linktr.ee/robbpearlman")
        ),
        Guest(
            name: "Keith R.A. DeCandido",
            role: "Author",
            imageName: "DeCandido",
            accentHex: "#FF4C99",
            bio: "Keith R.A. DeCandido is an American science fiction and fantasy writer, martial artist, and musician, who works on comic books, novels, role-playing games and video games, including numerous media tie-in books for properties such as Star Trek, Buffy the Vampire Slayer, Doctor Who, Supernatural, Andromeda, Farscape, Leverage, Spider-Man, X-Men, Sleepy Hollow, and Stargate SG-1.",
            sponsorship: "",
            category: .author,
            twitterURL: URL(string: "https://x.com/kradec"),
            instagramURL: URL(string: "https://www.instagram.com/krad418"),
            websiteURL: URL(string: "http://decandido.net/")
        ),
        Guest(
            name: "Christopher D. Abbott",
            role: "Author",
            imageName: "abbott",
            accentHex: "#FF4C99",
            bio: "Christopher D. Abbott Is a Reader’s Favorite award-winning author of crime, fantasy, science-fiction, and horror. With over 35 books published, Abbott is also an Amazon Bestseller and publisher of the Sherlock Holmes pastiche series “The Watson Chronicles” along with associated anthologies. Abbott’s Sherlock Holmes novellas have been recognised by readers and peers alike as faithfully authentic to the original Conan Doyle. In 2022, after publishing nine individual Watson Chronicle stories, Abbott teamed up with prolific authors Michael Jan Friedman and Aaron Rosenberg to add a collection of Holmes short stories to the series, under the title “Cases by Candlelight” Later, Keith R.A. DeCandido joined the writing team, adding stories to a second and third volume. In addition, Abbott publishes four Sherlock Holmes pastiche novellas each year, and in 2025 released another anthology, titled “Sherlock Holmes Eliminate the Impossible,” with authors Keith R.A. DeCandido, Mary Fan, and Derek Tyler Attico presenting reimagined versions of Sherlock Holmes stories.",
            sponsorship: "",
            category: .author,
            instagramURL: URL(string: "https://www.instagram.com/CDanAbbott"),
            websiteURL: URL(string: "https://cdanabbott.com/"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm9719151/")
        ),
        Guest(
            name: "Michael Jan Friedman",
            role: "Author",
            imageName: "Friedman",
            accentHex: "#FF4C99",
            bio: "Michael Jan Friedman is a New York City born[1][2] American author of nearly 60 books of fiction and nonfiction, more than half of which are in licensed tie-in products of the Star Trek franchise. Ten of his titles have appeared on The New York Times Best Seller list. Friedman has also written for network and cable television, radio, more than 150 comic books, most of them for DC Comics.",
            sponsorship: "",
            category: .author,
            twitterURL: URL(string: "https://x.com/FriedmanMJ"),
            websiteURL: URL(string: "vcrazy8press.com"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm1232405/")
        ),
        Guest(
            name: "Glenn Greenberg",
            role: "Author",
            imageName: "Greenberg",
            accentHex: "#FF4C99",
            bio: "Glenn Greenberg is an American journalist and comic book and fiction writer. At the beginning of his career, he became a regular Marvel Comics writer, penning stories for The Spectacular Spider-Man, The Rampaging Hulk, The Silver Surfer, and Dracula.",
            sponsorship: "",
            category: .author,
            websiteURL: URL(string: "https://www.linkedin.com/in/glgreenberg/"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm9968215")
        ),
        Guest(
            name: "Karim Diane",
            role: "Jay Den Kraag",
            series: "Star Trek: Starfleet Academy",
            imageName: "Karimdiane",
            accentHex: "#FF4C99",
            bio: "Karim Diane is a West African-American actor, singer, and songwriter who plays the first gay Klingon in Star Trek history.",
            sponsorship: "",
            category: .celebrity,
            instagramURL: URL(string: "vhttps://www.instagram.com/team_karim/"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm7871425/")
        ),
        Guest(
            name: "Glenn Hauman",
            role: "Author",
            imageName: "Hauman",
            accentHex: "#FF4C99",
            bio: "Glenn Hauman writes, edits, colors comics, designs websites, designs books, performs marriages, reaches things on high shelves, changes lightbulbs, bats right, snores loud, sings baritenor, draws to inside straights, drinks too much DMD, and stays up waaay too late at night. People keep trying to kill him, as they do in the anthology They Keep Killing Glenn. You can find out more at https://comicmix.com/author/glenn-hauman/.",
            sponsorship: "",
            category: .author,
            twitterURL: URL(string: "https://x.com/GlennHauman"),
            websiteURL: URL(string: "https://www.glennhauman.com/"),
            imdbURL: URL(string: "https://www.imdb.com/name/nm1079280/")
        ),
        Guest(
            name: "Aaron Rosenberg",
            role: "Author",
            imageName: "Rosenberg",
            accentHex: "#FF4C99",
            bio: "Aaron Rosenberg is the best-selling, award-winning author of almost 60 novels, including the Twin Cities Cryptids urban fantasy/cozy series, the DuckBob SF comedy series, the Relicant Chronicles epic fantasy series, the Areyat Islands fantasy pirate mystery series, and, with David Niall Wilson, the O.C.L.T. occult thriller series. His tie-in work contains novels for Star Trek, Warhammer, World of WarCraft, Stargate: Atlantis, Shadowrun, Mutants &amp; Masterminds, and Eureka and short stories for The X-Files, World of Darkness, Crusader Kings II, Deadlands, Master of Orion, and Europa Universalis IV.",
            sponsorship: "",
            category: .author,
            imdbURL: URL(string: "https://memory-alpha.fandom.com/wiki/Aaron_Rosenberg")
        ),
        Guest(
            name: "Alex Simmons",
            role: "Comedian",
            imageName: "Simmons",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "",
            category: .entertainment,
            availableDays: [.saturday]
            
        ),
        Guest(
            name: "Dani Riedel",
            role: "Comedian",
            imageName: "Riedel",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "",
            category: .entertainment,
            availableDays: [.saturday]
        ),
        Guest(
            name: "David McOwen",
            role: "Comedian",
            imageName: "McOwen",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "",
            category: .entertainment,
            availableDays: [.saturday]
        ),
        Guest(
            name: "Justin Avery Smith",
            role: "Comedian",
            imageName: "Justin Smith",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "",
            category: .entertainment,
            availableDays: [.saturday]
        ),
        Guest(
            name: "Cat Smith",
            role: "Comedian",
            imageName: "Cat Smith",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "",
            category: .entertainment,
            availableDays: [.friday]
        ),
        Guest(
            name: "Lawrence Neals",
            role: "Comedian",
            imageName: "Neals",
            accentHex: "#FF4C99",
            bio: "",
            sponsorship: "",
            category: .entertainment,
            availableDays: [.friday]
        ),
        Guest(
            name: "Jan Fennick",
            role: "Author",
            imageName: "Fennick",
            accentHex: "#FF4C99",
            bio: "Jan Fennick is an author, editor, and contributor to pop-culture analysis works, specifically known for contributing to ATB Publishing's 'Outside In' series and Zepo Publishing's Fantastic! A Celebration of Fans Discovering Doctor Who. She is also working on a project focused on women in fandom titled She Wants to Tell You. She is not known as a primary writer for Star Trek fiction",
            sponsorship: "",
            category: .author,
            websiteURL: URL(string: "https://kozmicpress.com/she-wants-to-tell-you/")
        ),
        Guest(
            name: "Jackie Cox",
            role: "Diversity Guest",
            imageName: "Cox",
            accentHex: "#FF4C99",
            bio: "Jackie Cox (Darius Rose), a professional drag queen known from RuPaul's Drag Race, guest stars in the 2026 series Star Trek: Starfleet Academy. She plays Talon W'Xaria, described as a Violacean barkeep, appearing in the new series set within the Star Trek universe",
            sponsorship: "",
            category: .panelist,
            instagramURL: URL(string: "https://www.instagram.com/jackiecoxnyc/"),
            availableDays: [.sunday]
        ),
        Guest(
            name: "Jake Black",
            role: "Writer/Producer/Author",
            imageName: "Black",
            accentHex: "#FF4C99",
            bio: "Jake Black is a former Writer-Producer for the Star Trek franchise at Paramount+ where he was the head writer for The Ready Room With Wil Wheaton, as well as writer for the Star Trek Day TV specials, The Science of Star Trek With Dr. Erin Macdonald, Engayge With Jackie Cox, Whoopi Goldberg Recaps Discovery, and other projects. In addition, he’s the author of Starfleet Logbook and two short stories in the Star Trek Explorer Anthology “A Year to the Day That I Saw Myself Die,” as well as several articles for the official Star Trek magazine and website, and a dozen Trek trading card sets for Rittenhouse Archives. Non-Trek includes (TV): Smallville, Batman: The Brave and the Bold and Ben 10 Alien Force; (Comics): Supergirl, Rick and Morty, TMNT. He lives in a quiet Connecticut town with his with and their three children.",
            sponsorship: "",
            category: .author,
            twitterURL: URL(string: "https://x.com/jakeboyslim"),
            instagramURL: URL(string: "https://www.instagram.com/jakeboyslim"),
            websiteURL: URL(string: "https://www.jakeblack.com/")
        ),
        
    ]
}

// MARK: - Chip

private struct Chip: View {
    let title: String
    let isSelected: Bool
    let scheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected
                    ? TLITheme.accent(scheme).opacity(0.92)
                    : TLITheme.cardBackground(scheme),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(TLITheme.border(scheme), lineWidth: 1)
                )
                .foregroundColor(isSelected ? .black : TLITheme.textPrimary(scheme))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Card Row (bounds-safe)

private struct GuestCardRow: View {
    @Environment(\.colorScheme) private var scheme

    let guest: Guest
    let accentColor: Color
    let isFavorited: Bool
    let toggleFavorite: () -> Void
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                portrait
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(TLITheme.border(scheme), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    lcarsGuestHeader

                    HStack(alignment: .top, spacing: 8) {
                        Text(guest.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .truncationMode(.tail)

                        Spacer(minLength: 8)

                        FavoriteButton(
                            isFavorited: isFavorited,
                            scheme: scheme,
                            action: toggleFavorite
                        )
                    }

                    Text(guest.displayRole)
                        .font(.subheadline)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .lineLimit(2)
                        .truncationMode(.tail)

                    if let series = guest.displaySeries {
                        Text(series)
                            .font(.caption)
                            .foregroundStyle(Color.primary.opacity(0.72))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    if let statusLabel = guest.statusLabel {
                        Label(statusLabel, systemImage: guest.status.systemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(guest.isCancelled ? .red : accentColor)
                    }

                    if !guestMetadataPills.isEmpty {
                        GuestMetadataPills(items: Array(guestMetadataPills.prefix(2)), accentColor: accentColor)
                            .padding(.top, 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            }
        }
        .padding(10)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.45), lineWidth: 1)
        )
        .overlay(
            LinearGradient(
                colors: [
                    accentColor.opacity(scheme == .dark ? 0.20 : 0.12),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .allowsHitTesting(false)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.95),
                            accentColor.opacity(0.45)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .padding(.vertical, 14)
                .padding(.leading, 6)
                .allowsHitTesting(false)
        }
        .shadow(
            color: TLITheme.cardShadowColor(scheme),
            radius: scheme == .dark ? 4 : 2,
            y: 3
        )
        .contentShape(Rectangle())
        .onTapGesture { onOpen() }
        .contextMenu {
            Button(isFavorited ? "Remove Favorite" : "Add Favorite", action: toggleFavorite)
            Button("View Details", systemImage: "person.text.rectangle") { onOpen() }
        }
        .padding(.horizontal, 12)
    }

    private var lcarsGuestHeader: some View {
        HStack(spacing: 6) {
            Capsule(style: .continuous)
                .fill(accentColor.opacity(0.92))
                .frame(width: 28, height: 6)

            Capsule(style: .continuous)
                .fill(accentColor.opacity(0.35))
                .frame(width: 14, height: 6)

            Text(guestContextLabel.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(accentColor.opacity(0.95))
                .lineLimit(1)
        }
        .padding(.bottom, 1)
    }

    @ViewBuilder
    private var portrait: some View {
        if let name = guest.imageName {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        accentColor.opacity(0.35),
                        accentColor.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text(monogram(from: guest.name))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
    }

    private func monogram(from name: String) -> String {
        let comps = name.split(separator: " ")
        let first = comps.first?.prefix(1) ?? "?"
        let last  = comps.dropFirst().first?.prefix(1) ?? ""
        return String(first + last)
    }

    private var guestMetadataPills: [String] {
        var items: [String] = []
        if let statusLabel = guest.statusLabel { items.append(statusLabel) }
        items.append(contentsOf: guest.seriesTags.prefix(2))
        if let availability = guest.availabilityPillLabel { items.append(availability) }
        if guest.supportsAutographs { items.append("Autographs") }
        if guest.supportsSelfies { items.append("Selfies") }
        return items
    }

    private var guestContextLabel: String {
        if guest.category == .celebrity,
           let firstTag = guest.seriesTags.first,
           !firstTag.isEmpty {
            return firstTag
        }

        return guest.category.label
    }
}

private struct FavoriteButton: View {
    let isFavorited: Bool
    let scheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                action()
            }
        } label: {
            Image(systemName: isFavorited ? "heart.fill" : "heart")
                .font(.title3.weight(.semibold))
                .symbolEffect(.bounce, value: isFavorited)
                .foregroundStyle(isFavorited ? .red : TLITheme.textSecondary(scheme))
                .frame(width: 38, height: 38)
                .background(
                    .thinMaterial,
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(TLITheme.border(scheme), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorited ? "Remove from favorites" : "Add to favorites")
    }
}

private struct GuestMetadataPills: View {
    @Environment(\.colorScheme) private var scheme

    let items: [String]
    let accentColor: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(accentColor.opacity(scheme == .dark ? 0.22 : 0.14))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(TLITheme.border(scheme), lineWidth: 1)
                        )
                }
            }
        }
    }
}

// MARK: - Detail Sheet (local; avoids external dependency)

private struct GuestDetailSheet: View {
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var crmStore = CRMStore.shared
    @ObservedObject private var notifications = NotificationManager.shared
    @ObservedObject private var guestStatusStore = GuestStatusStore.shared
    @ObservedObject private var guestStatusSync = GuestStatusSyncService.shared

    private enum DetailMode {
        case panelist
        case guestProfile
        case themed
    }

    let guest: Guest
    let accentColor: Color
    let onToggleFavorite: () -> Void
    let onGuestUpdated: (Guest) -> Void
    let onDismissRequested: () -> Void
    @State private var showCRMSaveAlert = false
    @State private var crmAlertMessage = ""
    @State private var showStatusEditor = false
    @State private var showOpsAlert = false
    @State private var opsAlertMessage = ""

    /// Always reflects the latest override so the open sheet updates live.
    /// Remote sync wins when present, otherwise the device-local store.
    private var resolved: Guest {
        if let remote = guestStatusSync.override(for: guest) {
            return guest.applying(statusOverride: remote)
        }
        return guestStatusStore.resolvedGuest(guest)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                if let statusMessage = resolved.statusMessage {
                    statusSection(statusMessage, status: resolved.status)
                }

                switch detailMode {
                case .panelist:
                    panelistSponsorshipSection
                case .guestProfile:
                    if let availabilityDetail = guest.availabilityDetail {
                        availabilitySection(availabilityDetail)
                    }
                    if let pricingNote = guest.resolvedTablePricingNote {
                        tablePricingSection(pricingNote)
                    }
                    bioSection
                    if let note = guest.memoryAlphaNote {
                        memoryAlphaSection(note)
                    }
                    linksSection
                case .themed:
                    if let availabilityDetail = guest.availabilityDetail {
                        availabilitySection(availabilityDetail)
                    }
                    if let pricingNote = guest.resolvedTablePricingNote {
                        tablePricingSection(pricingNote)
                    }
                    themedSection
                }
            }
            .padding(.bottom, 24)
        }
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") { onDismissRequested() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onToggleFavorite) {
                    Image(systemName: "heart")
                }
                .accessibilityLabel("Favorite")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: addToCRM) {
                    Image(systemName: "person.crop.circle.badge.plus")
                }
                .accessibilityLabel("Save to CRM")
            }
            if notifications.isSuperAdminUnlocked {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showStatusEditor = true
                    } label: {
                        Image(systemName: resolved.status == .active ? "xmark.octagon" : "checkmark.circle")
                    }
                    .accessibilityLabel("Edit guest status")
                }
            }
        }
        .alert("CRM Updated", isPresented: $showCRMSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(crmAlertMessage)
        }
        .alert("Guest Update", isPresented: $showOpsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(opsAlertMessage)
        }
        .sheet(isPresented: $showStatusEditor) {
            GuestStatusEditorSheet(
                guest: resolved,
                accentColor: accentColor,
                canDraftNotification: notifications.canSubmitNotifications,
                onApply: { status, replacementName, note, draftNotification in
                    applyStatus(
                        status,
                        replacementName: replacementName,
                        note: note,
                        draftNotification: draftNotification
                    )
                    showStatusEditor = false
                },
                onCancel: { showStatusEditor = false }
            )
        }
        .navigationTitle(guest.name)
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
    }

    private var header: some View {
        VStack(spacing: 12) {
            if let name = guest.imageName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(accentColor.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(
                        color: .black.opacity(scheme == .dark ? 0.35 : 0.20),
                        radius: 8,
                        x: 0,
                        y: 6
                    )
            } else {
                LinearGradient(
                    colors: [
                        accentColor.opacity(0.35),
                        accentColor.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(accentColor.opacity(0.5), lineWidth: 2)
                )
                .shadow(
                    color: .black.opacity(scheme == .dark ? 0.35 : 0.20),
                    radius: 8,
                    x: 0,
                    y: 6
                )
            }

            if detailMode == .guestProfile {
                VStack(spacing: 4) {
                    Text(guest.displayRole)
                        .font(.headline)
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .multilineTextAlignment(.center)

                    if let series = guest.displaySeries {
                        Text(series)
                            .font(.subheadline)
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 16)
    }

    private func statusSection(_ statusMessage: String, status: GuestStatus) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Guest Update")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Label(statusMessage, systemImage: status.systemImage)
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke((status == .cancelled ? Color.red : Color.orange).opacity(0.45), lineWidth: 1)
        )
        .padding(.horizontal)
    }


    private var detailMode: DetailMode {
        if guest.category == .panelist {
            return .panelist
        }

        // Prefer actual content availability over category labels so
        // non-celeb guests with real bios/links still render full profiles.
        if hasProfileBio || hasProfileLinks {
            return .guestProfile
        }

        return .themed
    }

    private var panelistSponsorshipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sponsorship")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("IDIC Track Guests and Panelists Sponsored by PMA Consulting")
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func memoryAlphaSection(_ note: MemoryAlphaNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Star Trek Notes")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(note.summary)
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            if let url = URL(string: note.sourceURL) {
                Link(destination: url) {
                    Label("Open Memory Alpha", systemImage: "book")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .tint(TLITheme.accent(scheme))
            }
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func tablePricingSection(_ pricingNote: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Autographs & Selfies")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Label(pricingNote, systemImage: "signature")
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func availabilitySection(_ availabilityDetail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Availability")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Label(availabilityDetail, systemImage: "calendar")
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var themedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(guest.category.label) Spotlight")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("This is a themed guest page. Expanded profile links appear when available.")
                .font(.body)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            if let sponsorship = guest.sponsorship,
               !sponsorship.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(sponsorship)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(TLITheme.accent(scheme))
            }
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(linkedBio(guest.bio))
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func linkedBio(_ bio: String) -> AttributedString {
        var attributed = AttributedString(bio)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return attributed
        }

        let range = NSRange(bio.startIndex..., in: bio)
        for match in detector.matches(in: bio, options: [], range: range) {
            guard let url = match.url,
                  let stringRange = Range(match.range, in: bio),
                  let lower = AttributedString.Index(stringRange.lowerBound, within: attributed),
                  let upper = AttributedString.Index(stringRange.upperBound, within: attributed) else {
                continue
            }
            attributed[lower..<upper].link = url
        }

        return attributed
    }

    private var linksSection: some View {
        let twitter = normalizedURL(guest.twitterURL)
        let instagram = normalizedURL(guest.instagramURL)
        let website = normalizedURL(guest.websiteURL)
        let imdb = normalizedURL(guest.imdbURL)
        let cameo = normalizedURL(guest.cameoURL)
        let memoryAlpha = normalizedURL(guest.memoryAlphaURL)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Links")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            if twitter == nil && instagram == nil && website == nil && imdb == nil && cameo == nil && memoryAlpha == nil {
                Text("No links available yet.")
                    .font(.subheadline)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], alignment: .leading, spacing: 10) {
                    if let twitter {
                        externalLink("X / Twitter", systemImage: "link", destination: twitter)
                    }

                    if let instagram {
                        externalLink("Instagram", systemImage: "camera", destination: instagram)
                    }

                    if let website {
                        externalLink("Website", systemImage: "globe", destination: website)
                    }

                    if let imdb {
                        externalLink("IMDb", systemImage: "film", destination: imdb)
                    }

                    if let cameo {
                        externalLink("Cameo", systemImage: "video", destination: cameo)
                    }

                    if let memoryAlpha {
                        externalLink("Memory Alpha", systemImage: "book", destination: memoryAlpha)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private func externalLink(_ title: String, systemImage: String, destination: URL) -> some View {
        Link(destination: destination) {
            Label(title, systemImage: systemImage)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private func normalizedURL(_ url: URL?) -> URL? {
        guard let url else { return nil }
        let raw = url.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return nil }
        return url
    }

    private var hasProfileBio: Bool {
        !guest.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasProfileLinks: Bool {
        normalizedURL(guest.twitterURL) != nil ||
        normalizedURL(guest.instagramURL) != nil ||
        normalizedURL(guest.websiteURL) != nil ||
        normalizedURL(guest.imdbURL) != nil ||
        normalizedURL(guest.cameoURL) != nil ||
        normalizedURL(guest.memoryAlphaURL) != nil
    }

    private func addToCRM() {
        let existed = crmStore.contactNamed(guest.name) != nil
        _ = crmStore.importGuest(
            name: guest.name,
            role: guest.role,
            categoryLabel: guest.category.label,
            sponsorship: guest.sponsorship,
            bio: guest.bio
        )
        crmAlertMessage = existed
            ? "Updated existing CRM contact and added a timeline note."
            : "Added guest to CRM and created a timeline note."
        showCRMSaveAlert = true
    }

    private func applyStatus(
        _ status: GuestStatus,
        replacementName: String?,
        note: String?,
        draftNotification: Bool
    ) {
        switch status {
        case .active:
            // Local first (instant on this device), then publish if master.
            guestStatusStore.clearStatus(for: guest)
            guestStatusSync.clearStatus(for: guest)
        case .cancelled, .replaced:
            guestStatusStore.setStatus(
                for: guest,
                status: status,
                note: note,
                replacementGuestName: replacementName
            )
            guestStatusSync.setStatus(
                for: guest,
                status: status,
                note: note,
                replacementGuestName: replacementName
            )
        }

        let updatedGuest = resolved
        onGuestUpdated(updatedGuest)

        let willQueueAlert = draftNotification
            && notifications.canSubmitNotifications
            && status != .active

        if willQueueAlert {
            notifications.addNotification(
                RisaNotification(
                    title: "\(guest.name) update",
                    message: notificationMessage(for: status, replacementName: replacementName, note: note),
                    role: "guest",
                    category: "Schedule",
                    timestamp: .now,
                    isPriority: true
                )
            )
        }

        switch status {
        case .active:
            opsAlertMessage = "Restored \(guest.name) to the active roster."
        case .cancelled:
            opsAlertMessage = willQueueAlert
                ? "Marked \(guest.name) cancelled and queued an attendee alert."
                : "Marked \(guest.name) cancelled. No attendee alert was queued."
        case .replaced:
            opsAlertMessage = willQueueAlert
                ? "Recorded a replacement for \(guest.name) and queued an attendee alert."
                : "Recorded a replacement for \(guest.name). No attendee alert was queued."
        }

        showOpsAlert = true
    }

    private func notificationMessage(
        for status: GuestStatus,
        replacementName: String?,
        note: String?
    ) -> String {
        let trimmedReplacement = replacementName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)

        var message: String
        switch status {
        case .cancelled:
            message = "\(guest.name) can no longer appear at Trek Long Island."
            if let trimmedReplacement, !trimmedReplacement.isEmpty {
                message += " Replacement: \(trimmedReplacement)."
            }
        case .replaced:
            if let trimmedReplacement, !trimmedReplacement.isEmpty {
                message = "Schedule update: \(guest.name) is being replaced by \(trimmedReplacement)."
            } else {
                message = "Schedule update for \(guest.name)."
            }
        case .active:
            message = "\(guest.name) is back on the active roster."
        }

        if let trimmedNote, !trimmedNote.isEmpty {
            message += " \(trimmedNote)"
        } else {
            message += " Please check the latest schedule and guest alerts for details."
        }
        return message
    }
}

// MARK: - Guest Status Editor (operator-only)

private struct GuestStatusEditorSheet: View {
    @Environment(\.colorScheme) private var scheme

    let guest: Guest
    let accentColor: Color
    let canDraftNotification: Bool
    let onApply: (GuestStatus, String?, String?, Bool) -> Void
    let onCancel: () -> Void

    @State private var selectedStatus: GuestStatus
    @State private var replacementName: String
    @State private var note: String
    @State private var draftNotification: Bool

    init(
        guest: Guest,
        accentColor: Color,
        canDraftNotification: Bool,
        onApply: @escaping (GuestStatus, String?, String?, Bool) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.guest = guest
        self.accentColor = accentColor
        self.canDraftNotification = canDraftNotification
        self.onApply = onApply
        self.onCancel = onCancel
        _selectedStatus = State(initialValue: guest.status)
        _replacementName = State(initialValue: guest.replacementGuestName ?? "")
        _note = State(initialValue: guest.statusNote ?? "")
        _draftNotification = State(initialValue: canDraftNotification)
    }

    private var showsDetailFields: Bool {
        selectedStatus == .cancelled || selectedStatus == .replaced
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Picker("Guest status", selection: $selectedStatus) {
                        Text("Active").tag(GuestStatus.active)
                        Text("Cancelled").tag(GuestStatus.cancelled)
                        Text("Replaced").tag(GuestStatus.replaced)
                    }
                    .pickerStyle(.segmented)
                }

                if showsDetailFields {
                    Section("Replacement Guest (optional)") {
                        TextField("e.g. Jane Doe", text: $replacementName)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                    }

                    Section("Note (optional)") {
                        TextField(
                            "Shown to attendees in the guest update",
                            text: $note,
                            axis: .vertical
                        )
                        .lineLimit(2...5)
                    }

                    Section {
                        Toggle("Draft attendee notification", isOn: $draftNotification)
                            .disabled(!canDraftNotification)
                        if !canDraftNotification {
                            Text("This session can't submit notifications, so no attendee alert will be queued.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Section {
                        Text("Setting status to Active restores \(guest.name) to the roster and clears any cancellation note.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(guest.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let trimmedReplacement = replacementName
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedNote = note
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        onApply(
                            selectedStatus,
                            trimmedReplacement.isEmpty ? nil : trimmedReplacement,
                            trimmedNote.isEmpty ? nil : trimmedNote,
                            selectedStatus == .active ? false : draftNotification
                        )
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .tint(accentColor)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        GuestsView()
    }
    .environment(\.colorScheme, .dark)
}
#endif
