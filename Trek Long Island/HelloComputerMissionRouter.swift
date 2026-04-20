// Copyright Bryan Carroll. All rights reserved.
import Foundation

enum HelloComputerMissionRouter {
    static func answer(for normalizedQuery: String, audience: HelloComputerAudience) -> HelloComputerAnswer? {
        if containsAny(normalizedQuery, ["brief me", "briefing", "status report", "captain's log", "captains log"]) {
            return HelloComputerAnswer(
                text: briefingResponse(audience: audience),
                source: .generalGuidance,
                confidence: 0.95
            )
        }

        if containsAny(normalizedQuery, ["happening now", "live now", "what's live", "whats live", "what is live", "right now"]) {
            return HelloComputerAnswer(
                text: happeningNowResponse(audience: audience),
                source: .aiAssist,
                confidence: 0.94
            )
        }

        if containsAny(normalizedQuery, ["what's next", "whats next", "what is next", "next up", "next event", "next panel"]) {
            return HelloComputerAnswer(
                text: whatsNextResponse(audience: audience),
                source: .aiAssist,
                confidence: 0.94
            )
        }

        if containsAny(normalizedQuery, ["conflict", "conflicts", "overlap", "double booked", "double-booked"]) {
            return HelloComputerAnswer(
                text: conflictResponse(audience: audience),
                source: .aiAssist,
                confidence: 0.91
            )
        }

        if containsAny(normalizedQuery, ["medical", "injury", "hurt", "emergency", "unsafe", "security", "harassment", "fight", "threat"]) {
            return HelloComputerAnswer(
                text: emergencyResponse(audience: audience),
                source: .generalGuidance,
                confidence: 0.98
            )
        }

        if containsAny(normalizedQuery, ["lost child", "missing child", "lost kid", "missing kid", "missing person", "lost person"]) {
            return HelloComputerAnswer(
                text: lostPersonResponse(audience: audience),
                source: .generalGuidance,
                confidence: 0.97
            )
        }

        if containsAny(normalizedQuery, ["line", "queue", "crowd", "capacity", "overfull", "packed", "too many people"]) {
            return HelloComputerAnswer(
                text: lineAndCrowdResponse(audience: audience),
                source: .generalGuidance,
                confidence: 0.92
            )
        }

        if containsAny(normalizedQuery, ["photo op", "photo ops", "autograph", "autographs", "selfie", "selfies"]) {
            return HelloComputerAnswer(
                text: guestLogisticsResponse(audience: audience),
                source: .generalGuidance,
                confidence: 0.9
            )
        }

        if containsAny(normalizedQuery, ["first time", "new here", "where do i start", "plan my day", "what should i do", "itinerary", "mission plan"]) {
            return HelloComputerAnswer(
                text: startPlanResponse(audience: audience),
                source: .generalGuidance,
                confidence: 0.9
            )
        }

        if containsAny(normalizedQuery, ["quiet", "sensory", "overwhelmed", "accessibility", "wheelchair", "ada", "mobility"]) {
            return HelloComputerAnswer(
                text: accessibilityResponse(audience: audience),
                source: .officialFAQ,
                confidence: 0.92
            )
        }

        if audience == .staff, containsAny(normalizedQuery, ["handoff", "shift", "briefing", "ops", "staff update", "incident report", "radio"]) {
            return HelloComputerAnswer(
                text: staffOpsResponse(),
                source: .generalGuidance,
                confidence: 0.93
            )
        }

        return nil
    }

    static func suggestedQuestions(for audience: HelloComputerAudience) -> [String] {
        switch audience {
        case .attendee:
            return [
                "Brief me",
                "Happening now",
                "What's next?",
                "Build my day",
                "Show conflicts",
                "How do photo ops work?",
                "I need accessibility support",
                "Where is the venue?"
            ]
        case .staff:
            return [
                "Staff briefing",
                "Staff incident triage checklist",
                "Line management plan for a crowded panel",
                "Lost child protocol",
                "Accessibility routing support steps",
                "Shift handoff checklist",
                "Where do I send escalations?",
                "What's next for high-volume rooms?"
            ]
        }
    }

    private static func briefingResponse(audience: HelloComputerAudience) -> String {
        if audience == .staff {
            return """
            Staff bridge briefing:
            1) Check Announcements for live operational changes.
            2) Review high-volume rooms and current crowd pressure.
            3) Confirm accessibility watchpoints and open support requests.
            4) Use Schedule for active sessions and Ops for escalations.
            """
        }

        return """
        Convention briefing:
        1) Open Schedule to check what is live now and what starts next.
        2) Review your saved events so you do not miss anchor panels.
        3) Check Announcements before moving between rooms.
        4) Use Map if you need a quick room-orientation reset.
        """
    }

    private static func happeningNowResponse(audience: HelloComputerAudience) -> String {
        if audience == .staff {
            return """
            For a live status check, use the Schedule tools plus Announcements together:
            1) Open Schedule and review the current timeline.
            2) Cross-check active crowd or room changes in Announcements.
            3) Prioritize high-volume rooms, accessibility needs, and line pressure first.
            """
        }

        return """
        For the fastest live briefing:
        1) Open Schedule and review the `Now` timeline.
        2) Check Announcements for room changes or surprise updates.
        3) If nothing live fits your plans, look at `Next` and pick your next destination.
        """
    }

    private static func whatsNextResponse(audience: HelloComputerAudience) -> String {
        if audience == .staff {
            return """
            To decide what is next operationally:
            1) Check upcoming sessions in Schedule.
            2) Focus on rooms likely to create line pressure in the next hour.
            3) Verify staffing, accessibility routing, and communication needs before the rush hits.
            """
        }

        return """
        To figure out your next move:
        1) Check your saved events first.
        2) If you have a gap, look for a nearby panel, guest signing, or exhibitor stop.
        3) Recheck Announcements before committing in case room details changed.
        """
    }

    private static func conflictResponse(audience: HelloComputerAudience) -> String {
        if audience == .staff {
            return """
            For staff, schedule conflicts usually mean operational overlap:
            1) Identify the rooms and time window in conflict.
            2) Prioritize safety, accessibility, and crowd management first.
            3) Escalate staffing gaps or simultaneous incidents to Ops immediately.
            """
        }

        return """
        To resolve attendee conflicts:
        1) Open Schedule and review your saved events in `My Plan`.
        2) Choose the one that is hardest to replace: limited guest access, one-time panel, or priority personal favorite.
        3) Use Explore and Announcements to find a backup option for the one you skip.
        """
    }

    private static func emergencyResponse(audience: HelloComputerAudience) -> String {
        if audience == .staff {
            return """
            Staff emergency protocol:
            1) Secure immediate safety and call onsite security/medical now.
            2) Keep radio updates short: location, type, current status, support needed.
            3) Re-route nearby lines/traffic away from the area.
            4) Log time + facts only (no speculation) for handoff.
            5) Post a clear attendee-facing update via Announcements when approved.
            """
        }

        return """
        If this is urgent or unsafe, contact onsite staff/security immediately.
        Quick steps:
        1) Go to the nearest staff member or Information Desk.
        2) Share exact location and what happened.
        3) Stay nearby if safe so responders can find you.
        """
    }

    private static func lostPersonResponse(audience: HelloComputerAudience) -> String {
        if audience == .staff {
            return """
            Staff lost-person protocol:
            1) Notify Ops/Security immediately with description + last known location.
            2) Keep guardian/reporting party at a fixed rendezvous point.
            3) Coordinate zone checks via staff radios.
            4) Use approved Announcements wording only after Ops confirmation.
            5) Document timeline for shift handoff.
            """
        }

        return """
        For a lost child or missing person:
        1) Alert staff/security immediately.
        2) Go to the Information Desk and share description + last location.
        3) Stay reachable for follow-up.
        """
    }

    private static func lineAndCrowdResponse(audience: HelloComputerAudience) -> String {
        if audience == .staff {
            return """
            Crowd/line response for staff:
            1) Set a clear queue start point and visible lane.
            2) Keep ADA pathway open and monitor room capacity.
            3) Provide ETA updates every 10-15 minutes.
            4) If needed, add overflow guidance using Map + Announcements.
            5) Escalate to Ops if ingress/egress or safety is affected.
            """
        }

        return """
        If a line is heavy:
        • Ask nearby staff for expected wait time and cutoff policy.
        • Check Schedule tab for alternates while you wait.
        • Keep walkways clear and follow posted staff routing.
        """
    }

    private static func guestLogisticsResponse(audience: HelloComputerAudience) -> String {
        if audience == .staff {
            return """
            Guest logistics support:
            1) Confirm whether the attendee needs photo op, autograph, or table guidance.
            2) Direct them to the guest listing, posted procedures, or the correct queue start.
            3) Escalate capacity or cutoff confusion to Ops or the guest-services lead.
            """
        }

        return """
        For guest logistics:
        • Check the guest listing for signings, table notes, and appearance info.
        • Buy photo-op tickets at \(TicketPurchaseLinks.photoOpsURLString)
        • Ask nearby staff if you need the current queue start or cutoff rule.
        • For photo ops, keep confirmations handy and arrive a little early in case lines move fast.
        """
    }

    private static func startPlanResponse(audience: HelloComputerAudience) -> String {
        if audience == .staff {
            return """
            Staff shift start plan:
            1) Review Announcements + known issues.
            2) Confirm priority rooms and high-volume sessions.
            3) Walk your area for accessibility and wayfinding checks.
            4) Sync handoff notes before taking first escalation.
            """
        }

        return """
        Starter mission plan:
        1) Open Schedule and star your must-see events.
        2) Use Map to locate rooms before your first panel.
        3) Watch Announcements for live changes.
        4) Keep ticket/confirmation screenshots handy.
        """
    }

    private static func accessibilityResponse(audience: HelloComputerAudience) -> String {
        if audience == .staff {
            return """
            Staff accessibility support:
            1) Confirm the request and preferred assistance style.
            2) Route through the most accessible path available.
            3) Coordinate seating/space needs with room staff.
            4) Escalate unresolved needs to Ops/Info Desk immediately.
            Official updates: https://treklongisland.com/
            """
        }

        return """
        For accessibility support (seating, routing, quieter options), start at Registration or the Information Desk and ask staff.
        Official updates: https://treklongisland.com/
        """
    }

    private static func staffOpsResponse() -> String {
        """
        Staff ops checklist:
        1) Confirm current issue status in Announcements.
        2) Record who/what/where/when in concise notes.
        3) Hand off unresolved issues with owner + next action.
        4) Escalate blockers to Ops with exact location and impact.
        """
    }

    private static func containsAny(_ text: String, _ phrases: [String]) -> Bool {
        phrases.contains { text.contains($0) }
    }
}
