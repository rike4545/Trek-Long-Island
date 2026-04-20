// Copyright Bryan Carroll. All rights reserved.
//
//  RisaScheduleEvent.swift
//  Trek Long Island
//
//  Created by Bryan on 6/28/25.
//

import Foundation

struct RisaScheduleEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let location: String
    let room: String
    let startDate: Date
    let endDate: Date
    let day: String
    var isFavorite: Bool

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String = "",
        location: String,
        room: String,
        startDate: Date,
        endDate: Date,
        day: String,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.location = location
        self.room = room
        self.startDate = startDate
        self.endDate = endDate
        self.day = day
        self.isFavorite = isFavorite
    }
}
