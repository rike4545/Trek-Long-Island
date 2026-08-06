// Copyright Bryan Carroll. All rights reserved.

import Foundation
import FirebaseMessaging

enum TLIPushTopicManager {

    /// Topic names are derived from `TLIEventInfo`, so rolling the app to a new
    /// convention year moves the topics with it instead of leaving them hardcoded.
    private static var stem: String { TLIEventInfo.current.pushTopicStem }

    static var broadcastTopic: String { stem }
    static var guestTopic: String { "\(stem)_guest" }
    static var vipTopic: String { "\(stem)_qvip" }
    static var vendorTopic: String { "\(stem)_vendor" }
    static var staffTopic: String { "\(stem)_staff" }
    static var opsTopic: String { "\(stem)_ops" }

    /// Stems used by shipped versions of the app before the 2027 migration.
    ///
    /// FCM topic subscriptions are stored server-side against the device token and
    /// persist across app updates. Without an explicit unsubscribe, every device that
    /// ever ran the 2026 build stays subscribed to `trekli_2026*` forever — so a stray
    /// or mistaken send on an old topic would still reach real attendees. We clear
    /// them once, then remember that we did.
    private static let legacyTopicStems = ["trekli_2026"]

    private static let legacyCleanupKey = "TLI.Push.legacyTopicsCleared.v1"

    private static let adminUnlockTimeKey = "TrekLI.adminUnlockedAt"
    private static let adminLevelDefaultsKey = "TrekLI.adminLevel"
    private static let adminTimeout: TimeInterval = 3 * 60

    static func syncTopicsFromStoredAdminState() async {
        await syncTopics(isAdminUnlocked: hasStoredActiveAdminSession)
    }

    static func syncTopics(isAdminUnlocked: Bool) async {
        await unsubscribeFromLegacyTopicsIfNeeded()

        let desiredTopics: Set<String> = isAdminUnlocked
            ? [guestTopic, vipTopic, vendorTopic, staffTopic, opsTopic]
            : [guestTopic, vipTopic]
        let roleTopics: [String] = [guestTopic, vipTopic, vendorTopic, staffTopic, opsTopic]

        try? await Messaging.messaging().subscribe(toTopic: broadcastTopic)
        for topic in roleTopics {
            if desiredTopics.contains(topic) {
                try? await Messaging.messaging().subscribe(toTopic: topic)
            } else {
                try? await Messaging.messaging().unsubscribe(fromTopic: topic)
            }
        }
    }

    /// One-time cleanup of prior-year topic subscriptions. Idempotent, and only marks
    /// itself done once every unsubscribe call has been issued.
    private static func unsubscribeFromLegacyTopicsIfNeeded() async {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: legacyCleanupKey) else { return }

        let currentStem = stem
        for legacyStem in legacyTopicStems where legacyStem != currentStem {
            let topics = [
                legacyStem,
                "\(legacyStem)_guest",
                "\(legacyStem)_qvip",
                "\(legacyStem)_vendor",
                "\(legacyStem)_staff",
                "\(legacyStem)_ops"
            ]
            for topic in topics {
                try? await Messaging.messaging().unsubscribe(fromTopic: topic)
            }
        }

        defaults.set(true, forKey: legacyCleanupKey)
    }

    private static var hasStoredActiveAdminSession: Bool {
        let defaults = UserDefaults.standard
        guard
            let unlockedAt = defaults.object(forKey: adminUnlockTimeKey) as? Date,
            Date().timeIntervalSince(unlockedAt) < adminTimeout
        else {
            defaults.removeObject(forKey: adminUnlockTimeKey)
            defaults.removeObject(forKey: adminLevelDefaultsKey)
            return false
        }
        return true
    }
}
