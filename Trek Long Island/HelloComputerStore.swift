// Copyright Bryan Carroll. All rights reserved.
//
//  HelloComputerStore.swift
//  Trek Long Island
//
//  Created by Bryan on 1/31/26.
//  Regenerated: fixes UI freeze by running local engine work off the main actor.
//  Swift 6 • iOS 17+
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class HelloComputerStore: ObservableObject {
    @Published var messages: [HelloComputerMessage] = []
    @Published var inputText: String = ""
    @Published var isThinking: Bool = false
    @Published var lastSource: HelloComputerAnswerSource? = nil
    @Published var audience: HelloComputerAudience = .attendee
    @Published var mode: HelloComputerMode = .computer
    @Published var persona: HelloComputerPersona = .scotty
    @Published var pendingAction: HelloComputerPendingAction? = nil

    private let aiClient: HelloComputerAIClient
    private let allowAIIfUncertain: Bool
    private let agent: HelloComputerAgent

    init(aiClient: HelloComputerAIClient = HelloComputerNoAIClient(),
         allowAIIfUncertain: Bool = false,
         agent: HelloComputerAgent = HelloComputerAgent()) {
        self.aiClient = aiClient
        self.allowAIIfUncertain = allowAIIfUncertain
        self.agent = agent

        // Seed a friendly greeting
        messages = [
            HelloComputerMessage(
                role: .assistant,
                text: greeting(for: persona)
            )
        ]
    }

    func resetConversation() {
        messages = [
            HelloComputerMessage(
                role: .assistant,
                text: greeting(for: persona)
            )
        ]
        inputText = ""
        isThinking = false
        lastSource = nil
        pendingAction = nil
    }

    func setPersona(_ newPersona: HelloComputerPersona) {
        guard persona != newPersona else { return }
        persona = newPersona
        if messages.count == 1, messages.first?.role == .assistant {
            messages = [.init(role: .assistant, text: greeting(for: newPersona))]
        }
    }

    /// Public entry point from the UI.
    /// - Appends the user's message immediately for instant feedback.
    /// - Runs local FAQ matching off the main actor to avoid UI stalls.
    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Immediate UI feedback
        messages.append(.init(role: .user, text: trimmed))
        inputText = ""
        isThinking = true

        // Snapshot conversation for any non-main work (AI client, etc.)
        let conversationSnapshot = messages
        let audienceSnapshot = audience
        let allowAISnapshot = allowAIIfUncertain
        let aiClientSnapshot = aiClient
        let agentSnapshot = agent
        let personaSnapshot = persona
        let useAgentRoute = shouldRouteToAgent(for: trimmed)
        let guestAnswerSnapshot = HelloComputerGuestDirectory.answer(for: trimmed)
        let starTrekSnapshot = starTrekKnowledgeAnswer(for: trimmed)
        let guestLoreQuerySnapshot = HelloComputerGuestDirectory.loreLookupQuery(for: trimmed)
        let loreLookupSnapshot = shouldLookupMemoryAlpha(for: trimmed)

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            // Auto-route: use schedule-aware agent tools for matching intents.
            if useAgentRoute,
               let requestedAction = await agentSnapshot.pendingAction(for: trimmed, audience: audienceSnapshot) {
                await MainActor.run {
                    self.pendingAction = requestedAction
                    self.lastSource = .aiAssist
                    self.isThinking = false
                }
                return
            }

            if useAgentRoute,
               let assistant = await agentSnapshot.answer(for: trimmed, audience: audienceSnapshot) {
                await MainActor.run {
                    self.lastSource = assistant.source
                    self.messages.append(.init(role: .assistant, text: self.decorate(assistant, persona: personaSnapshot)))
                    self.isThinking = false
                }
                return
            }

            if let guestAnswer = guestAnswerSnapshot {
                await MainActor.run {
                    self.lastSource = guestAnswer.source
                    self.messages.append(.init(role: .assistant, text: self.decorate(guestAnswer, persona: personaSnapshot)))
                    self.isThinking = false
                }
                return
            }

            // 0) Star Trek franchise knowledge (TV/lore basics).
            if let starTrek = starTrekSnapshot {
                await MainActor.run {
                    self.lastSource = starTrek.source
                    self.messages.append(.init(role: .assistant, text: self.decorate(starTrek, persona: personaSnapshot)))
                    self.isThinking = false
                }
                return
            }

            if loreLookupSnapshot,
               let memoryAlpha = await MemoryAlphaClient.shared.answer(for: guestLoreQuerySnapshot ?? trimmed) {
                await MainActor.run {
                    self.lastSource = memoryAlpha.source
                    self.messages.append(.init(role: .assistant, text: self.decorate(memoryAlpha, persona: personaSnapshot)))
                    self.isThinking = false
                }
                return
            }

            // 1) Local answer: run off-main (can be a bit expensive)
            let local = HelloComputerEngine.answer(for: trimmed, audience: audienceSnapshot)

            if let local {
                await MainActor.run {
                    self.lastSource = local.source
                    self.messages.append(.init(role: .assistant, text: self.decorate(local, persona: personaSnapshot)))
                    self.isThinking = false
                }
                return
            }

            // 2) No good local answer; either fall back safely or use AI.
            if !allowAISnapshot {
                await MainActor.run {
                    self.lastSource = .generalGuidance
                    let fallback: String
                    if useAgentRoute {
                        fallback = """
                        I could not resolve that schedule request yet. Try:
                        • “What’s next?”
                        • “Build my day”
                        • “Find DS9 panels”
                        • “Show conflicts”
                        """
                    } else {
                        fallback = audienceSnapshot == .staff
                        ? """
                        I don’t want to guess on that. For staff operations, use:
                        • Announcements for live status
                        • Schedule tab with filters for active missions
                        • Map tab for routing and room checks
                        • Information Desk / Ops for escalations
                        You can also ask: “staff incident triage”, “line management plan”, or “where to send lost and found”.
                        """
                        : """
                        I don’t want to guess on that. Try asking at the information desk or:
                        • Schedule tab (filters + “Happening Now”)
                        • Guests & Vendors listings
                        • Map tab for layout
                        • Announcements for live updates
                        Or ask me in another way (e.g., “Where is registration?”).
                        """
                    }
                    self.messages.append(.init(
                        role: .assistant,
                        text: self.applyPersona(to: fallback, persona: personaSnapshot)
                    ))
                    self.isThinking = false
                }
                return
            }

            // 3) Optional AI path (only if you configured a real client)
            do {
                let reply = try await aiClientSnapshot.generateReply(
                    userMessage: trimmed,
                    conversation: conversationSnapshot
                )
                await MainActor.run {
                    self.lastSource = .aiAssist
                    self.messages.append(.init(role: .assistant, text: self.applyPersona(to: reply, persona: personaSnapshot)))
                    self.isThinking = false
                }
            } catch {
                await MainActor.run {
                    self.lastSource = .generalGuidance
                    self.messages.append(.init(
                        role: .assistant,
                        text: self.applyPersona(
                            to: "AI isn’t available right now. Check Schedule/Announcements or try a different question.",
                            persona: personaSnapshot
                        )
                    ))
                    self.isThinking = false
                }
            }
        }
    }

    private func shouldRouteToAgent(for text: String) -> Bool {
        let q = text.lowercased()
        let agentKeywords = [
            "brief me", "happening now", "what's next", "whats next", "what is next",
            "what should i do next", "what do i do next",
            "next panel", "next event", "build my day", "plan my day", "itinerary",
            "where is the venue", "where is registration", "parking", "map",
            "photo op", "photo ops", "autograph", "autographs", "selfie", "selfies",
            "accessibility", "wheelchair", "ada", "quiet space", "sensory",
            "conflict", "overlap", "double booked", "remind", "reminder", "notify",
            "notification", "favorite", "favourite", "unfavorite", "unfavourite",
            "add to favorites", "remove from favorites",
            "star the", "star this", "star next", "star panel", "star event",
            "unstar this", "unstar the", "unstar next", "unstar panel", "unstar event"
        ]
        return agentKeywords.contains { q.contains($0) }
    }

    private func shouldLookupMemoryAlpha(for text: String) -> Bool {
        let q = text.lowercased()
        let hasLoreSignal = hasStarTrekLoreSignal(in: q) || HelloComputerGuestDirectory.containsLoreSignal(in: q)

        let looksLikeLoreQuestion =
            q.hasPrefix("who is ")
            || q.hasPrefix("who was ")
            || q.hasPrefix("what is ")
            || q.hasPrefix("what are ")
            || q.hasPrefix("why ")
            || q.hasPrefix("how ")
            || q.hasPrefix("when ")
            || q.hasPrefix("where ")
            || q.hasPrefix("tell me about ")
            || q.hasPrefix("explain ")

        let conventionTerms = [
            "ticket", "tickets", "schedule", "panel", "panels", "venue", "hotel",
            "registration", "photo op", "autograph", "accessibility", "parking",
            "vendor", "announcement", "ops center"
        ]
        let isConventionQuestion = conventionTerms.contains { q.contains($0) }

        return hasLoreSignal || (looksLikeLoreQuestion && !isConventionQuestion)
    }

    private func starTrekKnowledgeAnswer(for text: String) -> HelloComputerAnswer? {
        let q = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let hasStarTrekSignal = hasStarTrekLoreSignal(in: q)
            || q.hasPrefix("who is ")
            || q.hasPrefix("who was ")
            || q.hasPrefix("tell me about ")
            || q.hasPrefix("how ")
            || q.hasPrefix("why ")

        guard hasStarTrekSignal else { return nil }

        if let clarification = clarificationForUnderspecifiedLoreQuestion(q) {
            return clarification
        }

        if q == "what is star trek" || q == "what is star trek?" || q == "star trek" || q.contains("about star trek") {
            return HelloComputerAnswer(
                text: """
                Star Trek is a science-fiction TV franchise created by Gene Roddenberry. It began with The Original Series in 1966 and explores space through Starfleet crews like the Enterprise, with themes of diplomacy, ethics, discovery, and hope for the future.
                """,
                source: .generalGuidance,
                confidence: 0.95
            )
        }

        if q.contains("who created star trek") || q.contains("who made star trek") {
            return HelloComputerAnswer(
                text: "Star Trek was created by Gene Roddenberry.",
                source: .generalGuidance,
                confidence: 0.98
            )
        }

        if q.contains("captain picard day") || q.contains("capt picard day") || q.contains("picard day") {
            return HelloComputerAnswer(
                text: """
                Captain Picard Day is a shipboard celebration from Star Trek: The Next Generation. It is a children’s event aboard the Enterprise where kids make banners, drawings, and displays honoring Captain Jean-Luc Picard, and the humor comes from Picard being noticeably uncomfortable with the attention.
                """,
                source: .generalGuidance,
                confidence: 0.96
            )
        }

        if q.contains("where should i start") || q.contains("which series should i start") || q.contains("start with") {
            return HelloComputerAnswer(
                text: """
                Good starting points:
                • The Next Generation (classic entry point)
                • Strange New Worlds (modern and very accessible)
                • The Original Series (for the roots of the franchise)
                """,
                source: .generalGuidance,
                confidence: 0.88
            )
        }

        return nil
    }

    private func clarificationForUnderspecifiedLoreQuestion(_ q: String) -> HelloComputerAnswer? {
        let genericOnlyPatterns = [
            "who is actor", "who is the actor", "who is character", "who is the character",
            "who is this actor", "who is this character", "who played the character",
            "who is cast", "who is the cast"
        ]
        if genericOnlyPatterns.contains(where: { q == $0 || q.hasPrefix($0 + " ") }) {
            return HelloComputerAnswer(
                text: """
                I can help with that, but I need a name.
                Try:
                • “Who is Spock?”
                • “Who played Captain Janeway?”
                • “Tell me about Worf.”
                """,
                source: .generalGuidance,
                confidence: 0.9
            )
        }
        return nil
    }

    private func hasStarTrekLoreSignal(in q: String) -> Bool {
        let loreTerms = [
            "star trek", "in star trek", "federation", "klingon", "vulcan", "borg",
            "romulan", "cardassian", "enterprise", "deep space nine", "voyager",
            "next generation", "strange new worlds", "discovery", "the original series",
            "risa", "risian", "horga hn", "horga'hn", "jamaharon",
            "captain kirk", "spock", "picard", "jean luc picard", "riker", "will riker",
            "william riker", "data", "worf", "troi", "deanna troi", "crusher",
            "beverly crusher", "wesley crusher", "geordi", "geordi la forge",
            "laforge", "janeway", "sisko", "kira", "odo", "quark", "seven of nine"
        ]

        return loreTerms.contains { q.contains($0) }
    }

    private func decorate(_ answer: HelloComputerAnswer, persona: HelloComputerPersona) -> String {
        // Keep it subtle; don’t spam.
        // You can remove the suffix if you prefer.
        let text = applyPersona(to: answer.text, persona: persona)
        switch answer.source {
        case .officialFAQ:
            return "\(text)\n\n— Source: Convention FAQ"
        case .generalGuidance:
            return "\(text)\n\n— Source: General guidance"
        case .aiAssist:
            return "\(text)\n\n— Source: AI assistant"
        }
    }

    private func applyPersona(to text: String, persona: HelloComputerPersona) -> String {
        guard persona == .scotty else { return text }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }
        if trimmed.hasPrefix("Engineering note:") || trimmed.hasPrefix("Aye.") {
            return trimmed
        }
        return "Aye. \(trimmed)\n\nEngineering note: I’ll keep the warp core steady, but please verify final room changes and ticket details with official convention updates."
    }

    private func greeting(for persona: HelloComputerPersona) -> String {
        switch persona {
        case .computer:
            return "System Online."
        case .scotty:
            return "Engineering console online. Scotty persona standing by."
        }
    }

    func approvePendingAction() {
        guard let action = pendingAction else { return }
        let key = "TLI.Schedule.favoriteIDsCSV"
        var favorites = Set(UserDefaults.standard.string(forKey: key)?
            .split(separator: "|")
            .map(String.init) ?? [])

        let output: String
        switch action.kind {
        case .addFavorite(let eventID, let title):
            favorites.insert(eventID)
            output = applyPersona(to: "Added to favorites: \(title)", persona: persona) + "\n\n— Source: AI assistant"
        case .removeFavorite(let eventID, let title):
            favorites.remove(eventID)
            output = applyPersona(to: "Removed from favorites: \(title)", persona: persona) + "\n\n— Source: AI assistant"
        case .scheduleReminder(let title, let room, let startDate, let minutesBefore):
            pendingAction = nil
            let personaSnapshot = persona
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.scheduleReminderNotification(
                        title: title,
                        room: room,
                        startDate: startDate,
                        minutesBefore: minutesBefore
                    )
                    await MainActor.run {
                        self.messages.append(.init(
                            role: .assistant,
                            text: self.applyPersona(
                                to: "Reminder scheduled: \(minutesBefore) minutes before \(title).",
                                persona: personaSnapshot
                            ) + "\n\n— Source: AI assistant"
                        ))
                    }
                } catch {
                    await MainActor.run {
                        self.messages.append(.init(
                            role: .assistant,
                            text: self.applyPersona(
                                to: "I could not schedule that reminder: \(error.localizedDescription)",
                                persona: personaSnapshot
                            ) + "\n\n— Source: AI assistant"
                        ))
                    }
                }
            }
            return
        }

        UserDefaults.standard.set(favorites.sorted().joined(separator: "|"), forKey: key)
        messages.append(.init(role: .assistant, text: output))
        pendingAction = nil
    }

    func cancelPendingAction() {
        guard pendingAction != nil else { return }
        messages.append(.init(
            role: .assistant,
            text: "Action canceled.\n\n— Source: AI assistant"
        ))
        pendingAction = nil
    }

    private func scheduleReminderNotification(
        title: String,
        room: String,
        startDate: Date,
        minutesBefore: Int
    ) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else {
            throw NSError(
                domain: "HelloComputerReminder",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Notification permission not granted."]
            )
        }

        let fireDate = startDate.addingTimeInterval(TimeInterval(-minutesBefore * 60))
        guard fireDate > Date() else {
            throw NSError(
                domain: "HelloComputerReminder",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "That event starts too soon for a \(minutesBefore)-minute reminder."]
            )
        }

        let content = UNMutableNotificationContent()
        content.title = "Trek Long Island Reminder"
        content.body = "\"\(title)\" starts in \(minutesBefore) minutes at \(room)."
        content.sound = .default

        let date = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        let identifier = "tli.assistant.reminder.\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
    }
}
