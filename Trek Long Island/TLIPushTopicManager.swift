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

    static func syncTopics(isAdminUnlocked: Bool) {
        let desiredTopics: Set<String> = isAdminUnlocked
            ? [guestTopic, vipTopic, vendorTopic, staffTopic, opsTopic]
            : [guestTopic, vipTopic]
        let roleTopics: [String] = [guestTopic, vipTopic, vendorTopic, staffTopic, opsTopic]

        Messaging.messaging().subscribe(toTopic: broadcastTopic)
        for topic in roleTopics {
            if desiredTopics.contains(topic) {
                Messaging.messaging().subscribe(toTopic: topic)
            } else {
                Messaging.messaging().unsubscribe(fromTopic: topic)
            }
        }
    }
}
