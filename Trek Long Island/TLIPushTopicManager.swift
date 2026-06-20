// Copyright Bryan Carroll. All rights reserved.

import Foundation
import FirebaseMessaging

enum TLIPushTopicManager {
    static let broadcastTopic = "trekli_2026"
    static let guestTopic = "trekli_2026_guest"
    static let vipTopic = "trekli_2026_qvip"
    static let vendorTopic = "trekli_2026_vendor"
    static let staffTopic = "trekli_2026_staff"
    static let opsTopic = "trekli_2026_ops"

    private static let adminUnlockTimeKey = "TrekLI.adminUnlockedAt"
    private static let adminLevelDefaultsKey = "TrekLI.adminLevel"
    private static let adminTimeout: TimeInterval = 3 * 60

    static func syncTopicsFromStoredAdminState() async {
        await syncTopics(isAdminUnlocked: hasStoredActiveAdminSession)
    }

    static func syncTopics(isAdminUnlocked: Bool) async {
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
