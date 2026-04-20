import Foundation
import FirebaseFirestore

private struct TLISyncedPreferencesPayload: Equatable {
    var appVisualPresetRaw: String = TLIVisualPreset.defaultPreset.rawValue
    var hasCompletedOnboarding: Bool = false
    var displayName: String = ""
    var rankRaw: String = TLIProfileRank.captain.rawValue
    var roleRaw: String = TLIProfileRole.firstTimer.rawValue
    var objectivesRaw: String = ""
    var appAppearanceRaw: String = AppAppearance.system.rawValue
    var appColorThemeRaw: String = TLIColorTheme.defaultTheme.rawValue
    var digestMode: Bool = false
    var quietStartHour: Int = 22
    var quietEndHour: Int = 7
    var priorityOverridesQuiet: Bool = true
    var highContrastMode: Bool = false
    var largeTypeBoost: Bool = false
    var largeTapTargets: Bool = false
    var reduceAnimations: Bool = false
    var typographyRaw: String = TLITypographyPreference.defaultPreference.rawValue
    var favoriteEventIDsCSV: String = ""
    var favoriteGuestSlugsCSV: String = ""
    var exploreExpandedSections: String = ""
    var lastViewedExploreURL: String = ""
    var exploreFavoriteLinksCSV: String = ""
    var trackedRoomsCSV: String = ""
    var showMissionControl: Bool = true
    var notificationReadIDs: [String] = []

    func firestoreData(profileID: String) -> [String: Any] {
        [
            "profileID": profileID,
            "appVisualPresetRaw": appVisualPresetRaw,
            "hasCompletedOnboarding": hasCompletedOnboarding,
            "displayName": displayName,
            "rankRaw": rankRaw,
            "roleRaw": roleRaw,
            "objectivesRaw": objectivesRaw,
            "appAppearanceRaw": appAppearanceRaw,
            "appColorThemeRaw": appColorThemeRaw,
            "digestMode": digestMode,
            "quietStartHour": quietStartHour,
            "quietEndHour": quietEndHour,
            "priorityOverridesQuiet": priorityOverridesQuiet,
            "highContrastMode": highContrastMode,
            "largeTypeBoost": largeTypeBoost,
            "largeTapTargets": largeTapTargets,
            "reduceAnimations": reduceAnimations,
            "typographyRaw": typographyRaw,
            "favoriteEventIDsCSV": favoriteEventIDsCSV,
            "favoriteGuestSlugsCSV": favoriteGuestSlugsCSV,
            "exploreExpandedSections": exploreExpandedSections,
            "lastViewedExploreURL": lastViewedExploreURL,
            "exploreFavoriteLinksCSV": exploreFavoriteLinksCSV,
            "trackedRoomsCSV": trackedRoomsCSV,
            "showMissionControl": showMissionControl,
            "notificationReadIDs": notificationReadIDs,
            "updatedAt": Timestamp(date: .now)
        ]
    }

    static func from(_ data: [String: Any]) -> TLISyncedPreferencesPayload {
        var payload = TLISyncedPreferencesPayload()
        payload.appVisualPresetRaw = data["appVisualPresetRaw"] as? String ?? TLIVisualPreset.defaultPreset.rawValue
        payload.hasCompletedOnboarding = data["hasCompletedOnboarding"] as? Bool ?? false
        payload.displayName = data["displayName"] as? String ?? ""
        payload.rankRaw = data["rankRaw"] as? String ?? TLIProfileRank.captain.rawValue
        payload.roleRaw = data["roleRaw"] as? String ?? TLIProfileRole.firstTimer.rawValue
        payload.objectivesRaw = data["objectivesRaw"] as? String ?? ""
        payload.appAppearanceRaw = data["appAppearanceRaw"] as? String ?? AppAppearance.system.rawValue
        payload.appColorThemeRaw = data["appColorThemeRaw"] as? String ?? TLIColorTheme.defaultTheme.rawValue
        payload.digestMode = data["digestMode"] as? Bool ?? false
        payload.quietStartHour = data["quietStartHour"] as? Int ?? 22
        payload.quietEndHour = data["quietEndHour"] as? Int ?? 7
        payload.priorityOverridesQuiet = data["priorityOverridesQuiet"] as? Bool ?? true
        payload.highContrastMode = data["highContrastMode"] as? Bool ?? false
        payload.largeTypeBoost = data["largeTypeBoost"] as? Bool ?? false
        payload.largeTapTargets = data["largeTapTargets"] as? Bool ?? false
        payload.reduceAnimations = data["reduceAnimations"] as? Bool ?? false
        payload.typographyRaw = data["typographyRaw"] as? String ?? TLITypographyPreference.defaultPreference.rawValue
        payload.favoriteEventIDsCSV = data["favoriteEventIDsCSV"] as? String ?? ""
        payload.favoriteGuestSlugsCSV = data["favoriteGuestSlugsCSV"] as? String ?? ""
        payload.exploreExpandedSections = data["exploreExpandedSections"] as? String ?? ""
        payload.lastViewedExploreURL = data["lastViewedExploreURL"] as? String ?? ""
        payload.exploreFavoriteLinksCSV = data["exploreFavoriteLinksCSV"] as? String ?? ""
        payload.trackedRoomsCSV = data["trackedRoomsCSV"] as? String ?? ""
        payload.showMissionControl = data["showMissionControl"] as? Bool ?? true
        payload.notificationReadIDs = (data["notificationReadIDs"] as? [String] ?? []).sorted()
        return payload
    }
}

@MainActor
final class TLIPreferencesSyncStore: ObservableObject {
    static let shared = TLIPreferencesSyncStore()

    private let defaults = UserDefaults.standard
    private let db = Firestore.firestore()
    private let conventionID = "trekli-2026"
    private let profileIDKey = "TLI.Profile.syncProfileID.v1"
    private let legacyFeedbackAttendeeIDKey = "TLI.PanelFeedback.attendeeID.v1"

    private let onboardingCompletedKey = "TLI.Onboarding.completed"
    private let appVisualPresetKey = "appVisualPreset"
    private let displayNameKey = "TLI.Profile.displayName"
    private let rankKey = "TLI.Profile.rank"
    private let roleKey = "TLI.Profile.role"
    private let objectivesKey = "TLI.Profile.objectives"
    private let appAppearanceKey = "appAppearance"
    private let appColorThemeKey = "appColorTheme"
    private let digestModeKey = "TLI.NotificationPrefs.digestMode"
    private let quietStartHourKey = "TLI.NotificationPrefs.quietStartHour"
    private let quietEndHourKey = "TLI.NotificationPrefs.quietEndHour"
    private let priorityOverridesQuietKey = "TLI.NotificationPrefs.priorityOverridesQuiet"
    private let highContrastModeKey = "TLI.Accessibility.highContrast"
    private let largeTypeBoostKey = "TLI.Accessibility.largeTypeBoost"
    private let largeTapTargetsKey = "TLI.Accessibility.largeTapTargets"
    private let reduceAnimationsKey = "TLI.Accessibility.reduceAnimations"
    private let typographyKey = TLITypographyPreference.storageKey
    private let favoriteEventsKey = "TLI.Schedule.favoriteIDsCSV"
    private let favoriteGuestsKey = "TLI.Guests.favoriteSlugsCSV"
    private let exploreExpandedSectionsKey = "exploreExpandedSections"
    private let lastViewedExploreURLKey = "lastViewedExploreURL"
    private let exploreFavoriteLinksKey = "exploreFavoriteLinksCSV"
    private let trackedRoomsKey = "TLI.NotificationPrefs.trackedRoomsCSV"
    private let showMissionControlKey = "TLI.Home.showMissionControl"
    private let notificationReadIDsKey = "TrekLI.readNotificationIDs"

    private var listener: ListenerRegistration?
    private var defaultsObserver: NSObjectProtocol?
    private var isApplyingRemoteSnapshot = false
    private var lastSyncedPayload = TLISyncedPreferencesPayload()

    let profileID: String

    private init() {
        profileID = Self.resolveProfileID(defaults: defaults, profileIDKey: profileIDKey, legacyKey: legacyFeedbackAttendeeIDKey)
        defaults.register(defaults: [
            showMissionControlKey: true,
            quietStartHourKey: 22,
            quietEndHourKey: 7,
            priorityOverridesQuietKey: true
        ])
        observeDefaults()
        startListening()
    }

    deinit {
        listener?.remove()
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    private var document: DocumentReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("crew_preferences")
            .document(profileID.lowercased())
    }

    private func startListening() {
        listener?.remove()
        listener = document.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("❌ Firestore crew preferences error: \(error.localizedDescription)")
                    return
                }

                guard let data = snapshot?.data(), !data.isEmpty else {
                    self.syncCurrentPreferences()
                    return
                }

                let remotePayload = TLISyncedPreferencesPayload.from(data)
                guard remotePayload != self.currentPayload() else {
                    self.lastSyncedPayload = remotePayload
                    return
                }

                self.apply(remotePayload)
            }
        }
    }

    private func observeDefaults() {
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.syncCurrentPreferences()
            }
        }
    }

    private func currentPayload() -> TLISyncedPreferencesPayload {
        var payload = TLISyncedPreferencesPayload()
        payload.hasCompletedOnboarding = defaults.bool(forKey: onboardingCompletedKey)
        payload.appVisualPresetRaw = defaults.string(forKey: appVisualPresetKey) ?? TLIVisualPreset.defaultPreset.rawValue
        payload.displayName = defaults.string(forKey: displayNameKey) ?? ""
        payload.rankRaw = defaults.string(forKey: rankKey) ?? TLIProfileRank.captain.rawValue
        payload.roleRaw = defaults.string(forKey: roleKey) ?? TLIProfileRole.firstTimer.rawValue
        payload.objectivesRaw = defaults.string(forKey: objectivesKey) ?? ""
        payload.appAppearanceRaw = defaults.string(forKey: appAppearanceKey) ?? AppAppearance.system.rawValue
        payload.appColorThemeRaw = defaults.string(forKey: appColorThemeKey) ?? TLIColorTheme.defaultTheme.rawValue
        payload.digestMode = defaults.bool(forKey: digestModeKey)
        payload.quietStartHour = defaults.object(forKey: quietStartHourKey) as? Int ?? 22
        payload.quietEndHour = defaults.object(forKey: quietEndHourKey) as? Int ?? 7
        payload.priorityOverridesQuiet = defaults.object(forKey: priorityOverridesQuietKey) as? Bool ?? true
        payload.highContrastMode = defaults.bool(forKey: highContrastModeKey)
        payload.largeTypeBoost = defaults.bool(forKey: largeTypeBoostKey)
        payload.largeTapTargets = defaults.bool(forKey: largeTapTargetsKey)
        payload.reduceAnimations = defaults.bool(forKey: reduceAnimationsKey)
        payload.typographyRaw = defaults.string(forKey: typographyKey) ?? TLITypographyPreference.defaultPreference.rawValue
        payload.favoriteEventIDsCSV = defaults.string(forKey: favoriteEventsKey) ?? ""
        payload.favoriteGuestSlugsCSV = defaults.string(forKey: favoriteGuestsKey) ?? ""
        payload.exploreExpandedSections = defaults.string(forKey: exploreExpandedSectionsKey) ?? ""
        payload.lastViewedExploreURL = defaults.string(forKey: lastViewedExploreURLKey) ?? ""
        payload.exploreFavoriteLinksCSV = defaults.string(forKey: exploreFavoriteLinksKey) ?? ""
        payload.trackedRoomsCSV = defaults.string(forKey: trackedRoomsKey) ?? ""
        payload.showMissionControl = defaults.object(forKey: showMissionControlKey) as? Bool ?? true
        payload.notificationReadIDs = (defaults.stringArray(forKey: notificationReadIDsKey) ?? []).sorted()
        return payload
    }

    private func apply(_ payload: TLISyncedPreferencesPayload) {
        isApplyingRemoteSnapshot = true
        defaults.set(payload.hasCompletedOnboarding, forKey: onboardingCompletedKey)
        defaults.set(payload.appVisualPresetRaw, forKey: appVisualPresetKey)
        defaults.set(payload.displayName, forKey: displayNameKey)
        defaults.set(payload.rankRaw, forKey: rankKey)
        defaults.set(payload.roleRaw, forKey: roleKey)
        defaults.set(payload.objectivesRaw, forKey: objectivesKey)
        defaults.set(payload.appAppearanceRaw, forKey: appAppearanceKey)
        defaults.set(payload.appColorThemeRaw, forKey: appColorThemeKey)
        defaults.set(payload.digestMode, forKey: digestModeKey)
        defaults.set(payload.quietStartHour, forKey: quietStartHourKey)
        defaults.set(payload.quietEndHour, forKey: quietEndHourKey)
        defaults.set(payload.priorityOverridesQuiet, forKey: priorityOverridesQuietKey)
        defaults.set(payload.highContrastMode, forKey: highContrastModeKey)
        defaults.set(payload.largeTypeBoost, forKey: largeTypeBoostKey)
        defaults.set(payload.largeTapTargets, forKey: largeTapTargetsKey)
        defaults.set(payload.reduceAnimations, forKey: reduceAnimationsKey)
        defaults.set(payload.typographyRaw, forKey: typographyKey)
        defaults.set(payload.favoriteEventIDsCSV, forKey: favoriteEventsKey)
        defaults.set(payload.favoriteGuestSlugsCSV, forKey: favoriteGuestsKey)
        defaults.set(payload.exploreExpandedSections, forKey: exploreExpandedSectionsKey)
        if payload.lastViewedExploreURL.isEmpty {
            defaults.removeObject(forKey: lastViewedExploreURLKey)
        } else {
            defaults.set(payload.lastViewedExploreURL, forKey: lastViewedExploreURLKey)
        }
        defaults.set(payload.exploreFavoriteLinksCSV, forKey: exploreFavoriteLinksKey)
        defaults.set(payload.trackedRoomsCSV, forKey: trackedRoomsKey)
        defaults.set(payload.showMissionControl, forKey: showMissionControlKey)
        defaults.set(payload.notificationReadIDs, forKey: notificationReadIDsKey)
        isApplyingRemoteSnapshot = false
        lastSyncedPayload = payload
    }

    private func syncCurrentPreferences() {
        guard !isApplyingRemoteSnapshot else { return }
        let payload = currentPayload()
        guard payload != lastSyncedPayload else { return }

        lastSyncedPayload = payload
        document.setData(payload.firestoreData(profileID: profileID), merge: true) { error in
            if let error {
                print("❌ Firestore crew preferences sync error: \(error.localizedDescription)")
            }
        }
    }

    private static func resolveProfileID(
        defaults: UserDefaults,
        profileIDKey: String,
        legacyKey: String
    ) -> String {
        if let existing = defaults.string(forKey: profileIDKey), !existing.isEmpty {
            return existing
        }

        if let legacy = defaults.string(forKey: legacyKey), !legacy.isEmpty {
            defaults.set(legacy, forKey: profileIDKey)
            return legacy
        }

        let created = UUID().uuidString.lowercased()
        defaults.set(created, forKey: profileIDKey)
        return created
    }
}
