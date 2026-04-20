// Copyright Bryan Carroll. All rights reserved.
// AppNotification.swift

import Foundation

/// Represents a notification throughout the app.
struct AppNotification: Identifiable, Equatable {
    let id: UUID
    var title: String
    var body: String
    var date: Date
    var priority: Bool

    /// By default, approved notifications are visible to both user and admin.
    var visibleToUser: Bool = true
    var visibleToAdmin: Bool = true

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        date: Date = Date(),
        priority: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.priority = priority
    }
}
