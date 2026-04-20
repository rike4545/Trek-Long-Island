// Copyright Bryan Carroll. All rights reserved.
//  RisaNotification.swift
//  Trek Long Island
//
//  Local notification model used by the app UI.
//  - `documentID` is the Firestore document ID (optional)
//  - `id` stays as a UUID for SwiftUI Identifiable
//

import Foundation

struct RisaNotification: Identifiable, Hashable {
    /// Local identifier for SwiftUI (not the Firestore ID)
    let id: UUID

    /// Firestore document ID (used by NotificationManager for delete, read state)
    let documentID: String?

    let title: String
    let message: String
    let role: String          // "guest", "qvip", "staff", "ops", "vendor", "all"
    let category: String      // e.g. "General", "Schedule", "Operations"
    let timestamp: Date       // when this notification is considered active

    /// Per-device read state (not written back to Firestore)
    var isRead: Bool
    var isPriority: Bool

    init(
        id: UUID = UUID(),
        documentID: String? = nil,
        title: String,
        message: String,
        role: String,
        category: String = "",
        timestamp: Date = Date(),
        isRead: Bool = false,
        isPriority: Bool = false
    ) {
        self.id = id
        self.documentID = documentID
        self.title = title
        self.message = message
        self.role = role
        self.category = category
        self.timestamp = timestamp
        self.isRead = isRead
        self.isPriority = isPriority
    }

    /// Convenience for sample / preview data
    static func sample(
        title: String,
        message: String,
        role: String,
        category: String = "General",
        isPriority: Bool = false
    ) -> RisaNotification {
        RisaNotification(
            title: title,
            message: message,
            role: role,
            category: category,
            timestamp: Date(),
            isRead: false,
            isPriority: isPriority
        )
    }
}
