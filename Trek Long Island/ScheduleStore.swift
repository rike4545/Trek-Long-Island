// Copyright Bryan Carroll. All rights reserved.
//
//  ScheduleStore.swift
//  Trek Long Island
//
//  Shared store and models for schedule events.
//  Created by Bryan on 6/7/25.
//

import Foundation

// MARK: — 1) Event Model

/// A single schedule event; conforms to Identifiable & Equatable.
struct ScheduleEvent: Identifiable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var room: String
    var time: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        room: String,
        time: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.room = room
        self.time = time
    }
}

// MARK: — 2) ScheduleStore

/// A shared ObservableObject that holds all schedule events.
/// In a real app, you’d persist to disk or a backend. Here, everything is in‐memory.
final class ScheduleStore: ObservableObject {
    @Published var events: [ScheduleEvent] = [
        // Sample data; adjust as needed
        ScheduleEvent(
            title: "Opening Ceremonies",
            description: "Welcome remarks, keynote, and orientation.",
            room: "Main Stage",
            time: Date().addingTimeInterval(3600) // 1 hr from now
        ),
        ScheduleEvent(
            title: "Starship Engineering Panel",
            description: "Discussion on how warp cores actually work in canon.",
            room: "Room A",
            time: Date().addingTimeInterval(7200) // 2 hrs from now
        ),
        ScheduleEvent(
            title: "Vulcan Philosophy Q&A",
            description: "An in‐depth Q&A on logic, emotion, and Vulcan meditation.",
            room: "Room B",
            time: Date().addingTimeInterval(10800) // 3 hrs from now
        ),
        ScheduleEvent(
            title: "Cosplay 101: Making Your Own Costume",
            description: "Step‐by‐step guide to building foam armor and sewing.",
            room: "Room C",
            time: Date().addingTimeInterval(14400) // 4 hrs from now
        )
    ]

    /// Helper to get all unique room names, sorted alphabetically
    var allRooms: [String] {
        let rooms = Set(events.map { $0.room })
        return rooms.sorted()
    }

    /// Add a new event
    func addEvent(_ event: ScheduleEvent) {
        events.append(event)
        sortEvents()
    }

    /// Update an existing event
    func updateEvent(_ event: ScheduleEvent) {
        guard let idx = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[idx] = event
        sortEvents()
    }

    /// Delete one or more events
    func deleteEvents(at offsets: IndexSet) {
        events.remove(atOffsets: offsets)
        sortEvents()
    }

    /// Sort events by time ascending
    private func sortEvents() {
        events.sort { $0.time < $1.time }
    }
}
