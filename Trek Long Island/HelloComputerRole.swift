// Copyright Bryan Carroll. All rights reserved.
//
//  HelloComputerRole.swift
//  Trek Long Island
//
//  Created by Bryan on 1/31/26.
//


import Foundation


enum HelloComputerAudience: String, CaseIterable, Codable {
    case attendee
    case staff

    var title: String {
        switch self {
        case .attendee: return "Attendee"
        case .staff: return "Staff"
        }
    }
}

enum HelloComputerMode: String, CaseIterable, Codable {
    case computer
    case assistant

    var title: String {
        switch self {
        case .computer: return "Computer"
        case .assistant: return "AI Agent"
        }
    }
}

enum HelloComputerPersona: String, CaseIterable, Codable {
    case computer
    case scotty

    var title: String {
        switch self {
        case .computer: return "Computer"
        case .scotty: return "Scotty"
        }
    }

    var systemImage: String {
        switch self {
        case .computer: return "cpu"
        case .scotty: return "wrench.and.screwdriver.fill"
        }
    }
}

enum HelloComputerRole: String, Codable {
    case user
    case assistant
    case system
}

struct HelloComputerMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let role: HelloComputerRole
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), role: HelloComputerRole, text: String, timestamp: Date = .now) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}

enum HelloComputerAnswerSource: String, Codable {
    case officialFAQ
    case generalGuidance
    case aiAssist
}

struct HelloComputerAnswer: Hashable, Codable {
    let text: String
    let source: HelloComputerAnswerSource
    let confidence: Double // 0...1
}

struct HelloComputerFAQ: Identifiable, Hashable, Codable {
    let id: UUID
    let question: String
    let answer: String
    let tags: [String]
    let source: HelloComputerAnswerSource

    init(id: UUID = UUID(), question: String, answer: String, tags: [String], source: HelloComputerAnswerSource = .officialFAQ) {
        self.id = id
        self.question = question
        self.answer = answer
        self.tags = tags
        self.source = source
    }
}

enum HelloComputerAssistantActionKind: Hashable {
    case addFavorite(eventID: String, title: String)
    case removeFavorite(eventID: String, title: String)
    case scheduleReminder(title: String, room: String, startDate: Date, minutesBefore: Int)
}

struct HelloComputerPendingAction: Identifiable, Hashable {
    let id: UUID
    let kind: HelloComputerAssistantActionKind
    let prompt: String

    init(id: UUID = UUID(), kind: HelloComputerAssistantActionKind, prompt: String) {
        self.id = id
        self.kind = kind
        self.prompt = prompt
    }
}
