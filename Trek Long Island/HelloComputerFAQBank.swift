// Copyright Bryan Carroll. All rights reserved.
//
//  HelloComputerFAQBank.swift
//  Trek Long Island
//
//  “Hello, Computer” curated answers.
//  - Helpful, scannable, friendly
//  - Avoid guessing (no invented guests / prices / policies)
//  - HARD RULE: purchase/checkout questions → official admission ticket link
//  - Everything else → official website (https://treklongisland.com/)
//
//  Swift 6 • iOS 17+
//

import Foundation

enum HelloComputerFAQBank {

    // Official sources (embed as plain URLs so the UI can detect and open them)
    static let ticketsURL: String = TicketPurchaseLinks.ticketsURLString
    static let photoOpsURL: String = TicketPurchaseLinks.photoOpsURLString
    static let photoOpScheduleURL: String = TicketPurchaseLinks.photoOpScheduleURLString
    static let websiteURL: String = "https://treklongisland.com/"
    static let scheduleURL: String = "https://treklongisland.com/programs/"
    static let hotelURL: String = "https://treklongisland.com/hotel/"
    static let contactURL: String = "https://qualtricsxmm8q5gxrhq.qualtrics.com/jfe/form/SV_1TvkCrIKgaEYHPM"

    // Short prompts used for “Quick questions” chips.
    static let suggestedQuestions: [String] = [
        "Where do I buy tickets?",
        "What are the convention dates and hours?",
        "Where is the venue?",
        "Where do I find the schedule?",
        "How do photo ops work?",
        "What accessibility options are available?",
        "Is cosplay welcome?",
        "Tea. Earl Grey. Hot.",
        "Computer, initiate self-destruct",
        "Resistance is futile"
    ]

    static var allFAQs: [HelloComputerFAQ] {
        faqs + additionalFAQs
    }

    static var allSuggestedQuestions: [String] {
        var seen = Set<String>()
        return (suggestedQuestions + additionalFAQs.prefix(8).map(\.question))
            .filter { seen.insert($0.lowercased()).inserted }
    }

    static let faqs: [HelloComputerFAQ] = [
        .init(
            question: "Where do I buy tickets?",
            answer: "Admission tickets are sold on the official Square ticket page:\\n\(ticketsURL)\\n\\nFor other paid add-ons, use the official ticket site:\\n\(TicketPurchaseLinks.ticketStoreURLString)\\n\\nIf your question is about pricing, checkout, receipts, confirmations, or what’s included, start with the admission ticket page above.",
            tags: ["tickets", "buy", "purchase", "passes", "badge", "checkout", "receipt", "confirmation", "square"],
            source: .officialFAQ
        ),

        .init(
            question: "I have a ticket purchase problem (checkout/receipt/confirmation).",
            answer: "For admission ticket purchase help (checkout, receipts, confirmation emails, or what’s included), use:\\n\(ticketsURL)\\n\\nFor other add-ons, use:\\n\(TicketPurchaseLinks.ticketStoreURLString)\\n\\nIf you still need help after checking there, use the support form:\\n\(contactURL)",
            tags: ["purchase", "checkout", "receipt", "confirmation", "email", "problem", "refund", "transfer"],
            source: .officialFAQ
        ),

        .init(
            question: "Are tickets available at the door?",
            answer: "Availability can change. The safest answer is to check the official admission ticket page for current options:\\n\(ticketsURL)",
            tags: ["tickets", "door", "walk-up", "availability"],
            source: .officialFAQ
        ),

        .init(
            question: "What are the convention dates and hours?",
            answer: "Trek Long Island is June 12–14, 2026.\\n\\nConvention hours (confirm on the official site in case anything changes):\\n• Friday: 5:00 PM – 11:00 PM\\n• Saturday: 10:00 AM – 12:00 AM\\n• Sunday: 10:00 AM – 6:00 PM\\n\\nOfficial schedule hub:\\nhttps://treklongisland.com/programs/",
            tags: ["dates", "hours", "when", "time", "june", "2026", "friday", "saturday", "sunday"],
            source: .officialFAQ
        ),

        .init(
            question: "Where is the venue?",
            answer: "Trek Long Island is hosted at the Hyatt Regency Long Island:\\n1717 Motor Parkway, Hauppauge, NY 11788\\n\\nHotel / venue details:\\nhttps://treklongisland.com/hotel/",
            tags: ["venue", "location", "address", "hotel", "hyatt", "hauppauge", "parking", "directions"],
            source: .officialFAQ
        ),

        .init(
            question: "Where do I find the schedule?",
            answer: "The official schedule hub:\\nhttps://treklongisland.com/programs/\\n\\nIn the app:\\n• Open the Schedule tab\\n• Favorite items to build your weekend",
            tags: ["schedule", "agenda", "programs", "panels"],
            source: .officialFAQ
        ),

        .init(
            question: "What’s the best way to keep up with schedule changes?",
            answer: "The official website is the best source for last-minute schedule updates:\\nhttps://treklongisland.com/programs/\\n\\nIn the app:\\n• Favorite events you don’t want to miss\\n• Watch Announcements for changes",
            tags: ["schedule", "changes", "updates", "announcements", "favorites"],
            source: .officialFAQ
        ),

        .init(
            question: "What should I do first when I arrive?",
            answer: "Quick arrival checklist:\\n1) Check-in / Registration\\n2) Open Schedule and favorite your must-see events\\n3) Use Map to find stages, vendors, restrooms\\n4) Check Announcements for updates\\n5) Hydrate (Starfleet recommends it)\\n\\nIf you’re lost, ask staff at the Information Desk.",
            tags: ["arrive", "check-in", "registration", "first", "tips", "map", "announcements"],
            source: .generalGuidance
        ),

        .init(
            question: "Do I need anything for check-in?",
            answer: "Have your confirmation available (email or screenshot). If you purchased paid add-ons, keep those confirmations handy too.\\n\\nFor admission purchase/receipt issues:\\n\(ticketsURL)\\n\\nFor venue/program info:\\nhttps://treklongisland.com/",
            tags: ["check-in", "confirmation", "email", "badge", "entry"],
            source: .officialFAQ
        ),

        .init(
            question: "How do photo ops work?",
            answer: "Photo ops are typically time-slotted.\\n\\nTo purchase photo-op tickets:\\n\(photoOpsURL)\\n\\nFor the official photo-op schedule:\\n\(photoOpScheduleURL)\\n\\nTips:\\n• Arrive a bit early\\n• Keep your confirmation ready\\n• Watch Announcements for time changes",
            tags: ["photo ops", "photos", "time slot", "line", "schedule"],
            source: .officialFAQ
        ),

        .init(
            question: "How do autographs work?",
            answer: "Autographs are usually handled at guest tables. Availability and rules can vary by guest.\\n\\n\(TicketPurchaseLinks.autographPreSalesStatusText())\\n\\nBest approach:\\n• Check guest times when posted\\n• Ask table staff/handler for the current process\\n• Watch for schedule changes\\n\\nOfficial updates:\\nhttps://treklongisland.com/",
            tags: ["autographs", "signing", "guest table", "rules", "updates"],
            source: .officialFAQ
        ),

        .init(
            question: "Is cosplay welcome?",
            answer: "Yes—cosplay is welcome!\\n\\nGood etiquette:\\n• Ask before taking photos\\n• Be mindful of props in crowded areas\\n• Respect personal space\\n\\nAny official policy updates:\\nhttps://treklongisland.com/",
            tags: ["cosplay", "costume", "photos", "rules", "props"],
            source: .officialFAQ
        ),

        .init(
            question: "What accessibility options are available?",
            answer: "If you need accessibility support (seating, routing help, quieter options), start at Registration / the Information Desk and ask staff.\\n\\nAny posted accessibility notes and updates are on:\\nhttps://treklongisland.com/",
            tags: ["accessibility", "ada", "wheelchair", "mobility", "seating", "hearing", "vision"],
            source: .officialFAQ
        ),

        .init(
            question: "Where are the vendors?",
            answer: "Use the Map tab to locate the vendor hall.\\n\\nVendor info may also be posted here:\\nhttps://treklongisland.com/",
            tags: ["vendors", "dealer", "merch", "artist", "shopping", "vendor hall"],
            source: .officialFAQ
        ),

        .init(
            question: "How do I contact Trek Long Island?",
            answer: "Use the support and feedback form:\\n\(contactURL)\\n\\nIf you’re onsite, Registration / the Information Desk is your best first stop.",
            tags: ["contact", "email", "help", "support"],
            source: .officialFAQ
        ),

        .init(
            question: "Is there an official hotel link or room block?",
            answer: "Hotel details (and any official booking info) are on:\\nhttps://treklongisland.com/hotel/\\n\\nFor other questions, the main site is the best hub:\\nhttps://treklongisland.com/",
            tags: ["hotel", "room block", "booking", "hyatt"],
            source: .officialFAQ
        ),

        .init(
            question: "What should I bring?",
            answer: "Recommended checklist:\\n• Comfortable shoes\\n• Phone charger / battery pack\\n• Confirmation screenshots\\n• Water bottle\\n• A small budget for merch\\n• A positive attitude (works across all quadrants)\\n\\nUniform optional. Confidence encouraged.",
            tags: ["bring", "checklist", "tips", "what to bring"],
            source: .generalGuidance
        ),

        .init(
            question: "I need a quiet break—any tips?",
            answer: "Totally understandable.\\n\\nSuggestions:\\n• Step out to a quieter hallway/lounge area\\n• Ask staff where a calm spot is available\\n• Pace your schedule (you don’t have to do everything)\\n\\nStarfleet protocol prioritizes crew well-being.",
            tags: ["quiet", "break", "overwhelmed", "sensory"],
            source: .generalGuidance
        ),

        .init(
            question: "Can I take photos with cosplayers?",
            answer: "Usually yes—just ask first.\\n\\nThe universal rule:\\nConsent is canon.",
            tags: ["photos", "cosplayers", "etiquette", "consent"],
            source: .generalGuidance
        ),

        .init(
            question: "Is this LCARS?",
            answer: "Not officially—but it’s LCARS-adjacent. Calm panels, clear info, minimal dramatic beeping.",
            tags: ["is", "this", "lcars"],
            source: .generalGuidance
        ),

        .init(
            question: "Computer, initiate self-destruct",
            answer: "Authorization denied. This app prefers successful convention weekends—and your battery life.",
            tags: ["computer", "initiate", "self-destruct"],
            source: .generalGuidance
        ),

        .init(
            question: "Tea. Earl Grey. Hot.",
            answer: "Replicator offline. Vibe online.",
            tags: ["tea", "earl", "grey", "hot"],
            source: .generalGuidance
        ),

        .init(
            question: "Make it so",
            answer: "Acknowledged. Engage schedule. Proceed to vendor hall. Hydration recommended.",
            tags: ["make", "it", "so"],
            source: .generalGuidance
        ),

        .init(
            question: "Engage",
            answer: "Engaging. Destination: panels, guests, and an alarming amount of merchandise.",
            tags: ["engage"],
            source: .generalGuidance
        ),

        .init(
            question: "Red alert",
            answer: "Red alert acknowledged. Quick triage:\\n• Admission tickets/purchases → \(ticketsURL)\\n• Schedule/updates → https://treklongisland.com/programs/\\n• Onsite confusion → Information Desk",
            tags: ["red", "alert"],
            source: .generalGuidance
        ),

        .init(
            question: "Resistance is futile",
            answer: "You will be assimilated… into buying collectibles. Budget shields advised.",
            tags: ["resistance", "is", "futile"],
            source: .generalGuidance
        ),

        .init(
            question: "Live long and prosper",
            answer: "🖖 Live long and prosper. Also: comfortable shoes.",
            tags: ["live", "long", "and", "prosper"],
            source: .generalGuidance
        ),

        .init(
            question: "Qapla’",
            answer: "Success. Honor has been acknowledged.",
            tags: ["qapla’"],
            source: .generalGuidance
        ),

        .init(
            question: "Beam me up",
            answer: "Transport unavailable. Elevators and stairs remain operational.",
            tags: ["beam", "me", "up"],
            source: .generalGuidance
        ),

        .init(
            question: "Computer, open hailing frequencies",
            answer: "Hailing frequencies open. Support and feedback form:\\n\(contactURL)",
            tags: ["computer", "open", "hailing", "frequencies"],
            source: .generalGuidance
        ),

        .init(
            question: "Computer, locate Captain Picard",
            answer: "Captain Picard is currently unavailable for tracking. Try the Schedule tab for guests and events.",
            tags: ["computer", "locate", "captain", "picard"],
            source: .generalGuidance
        ),

        .init(
            question: "Are there tribbles?",
            answer: "Tribbles may be present. Please do not feed them. Please do not let them near the vendor hall.",
            tags: ["are", "there", "tribbles"],
            source: .generalGuidance
        ),

        .init(
            question: "Are there Klingons here?",
            answer: "Klingons are frequently spotted at Trek conventions. Approach with honor, compliments, and photo requests. Qapla’.",
            tags: ["are", "there", "klingons", "here"],
            source: .generalGuidance
        ),

        .init(
            question: "Is there a holodeck?",
            answer: "No approved holodeck has cleared Starfleet Safety (yet). But cosplay + panels are excellent immersion.",
            tags: ["is", "there", "a", "holodeck"],
            source: .generalGuidance
        ),

        .init(
            question: "Why do consoles explode?",
            answer: "Starfleet engineering remains an unsolved mystery. We respect the drama and recommend standing clear of sparking panels.",
            tags: ["why", "do", "consoles", "explode"],
            source: .generalGuidance
        ),

        .init(
            question: "Why are turbolifts so big?",
            answer: "Starfleet believes in legroom. Also, it helps with dramatic entrances.",
            tags: ["why", "are", "turbolifts", "so", "big"],
            source: .generalGuidance
        ),

        .init(
            question: "What is warp speed?",
            answer: "Faster-than-light travel. Convention equivalent: speed-walking to a panel you don’t want to miss.",
            tags: ["what", "is", "warp", "speed"],
            source: .generalGuidance
        ),

        .init(
            question: "Set phasers to stun",
            answer: "Phasers imaginary. Enthusiasm real.",
            tags: ["set", "phasers", "to", "stun"],
            source: .generalGuidance
        ),

        .init(
            question: "Captain's log, supplemental",
            answer: "Things have escalated. Please check the schedule and hydrate.",
            tags: ["captain's", "log", "supplemental"],
            source: .generalGuidance
        ),

        .init(
            question: "Computer, energize",
            answer: "Energizing… enthusiasm. Real transport remains elevators and legs.",
            tags: ["computer", "energize"],
            source: .generalGuidance
        ),

        .init(
            question: "Computer, set a course for Trek Long Island",
            answer: "Course laid in. Destination: your next panel. Engage.",
            tags: ["computer", "set", "a", "course", "for", "trek"],
            source: .generalGuidance
        ),

        .init(
            question: "Fascinating.",
            answer: "Confirmed. Data would approve.",
            tags: ["fascinating"],
            source: .generalGuidance
        ),

        .init(
            question: "Highly illogical.",
            answer: "Acknowledged. Logical response withheld for dramatic effect.",
            tags: ["highly", "illogical"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#1: Favorite series?",
            answer: "That’s classified. But the correct answer is: the one that brought you here.",
            tags: ["star trek", "fun", "q1"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#2: Best captain?",
            answer: "Answer varies by crew. All captains have strengths—and dramatic speeches.",
            tags: ["star trek", "fun", "q2"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#3: Is time travel allowed?",
            answer: "Only if you promise not to create a paradox before lunch.",
            tags: ["star trek", "fun", "q3"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#4: Do I need a uniform?",
            answer: "Uniform optional. Enthusiasm required.",
            tags: ["star trek", "fun", "q4"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#5: Is it okay to say 'Qapla’'?",
            answer: "Always. It increases honor by 12%.",
            tags: ["star trek", "fun", "q5"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#6: Can I join Starfleet?",
            answer: "In spirit, yes. In paperwork, ask Starfleet HR.",
            tags: ["star trek", "fun", "q6"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#7: Is the Prime Directive enforced here?",
            answer: "Yes: be kind, ask consent for photos, and don’t block hallways.",
            tags: ["star trek", "fun", "q7"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#8: Are tribbles safe?",
            answer: "Only if you keep them away from snacks.",
            tags: ["star trek", "fun", "q8"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#9: Is the Mirror Universe nearby?",
            answer: "Not detected. Please keep your goatee in standard configuration.",
            tags: ["star trek", "fun", "q9"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#10: Do I have to pick a faction?",
            answer: "No. You can be Federation on Friday and Klingon on Saturday. That’s how weekends work.",
            tags: ["star trek", "fun", "q10"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#11: What is warp core breach?",
            answer: "A strong reminder to take problems seriously and never ignore warning beeps.",
            tags: ["star trek", "fun", "q11"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#12: Do I need a tricorder?",
            answer: "Not required, but checking the schedule repeatedly is highly authentic.",
            tags: ["star trek", "fun", "q12"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#13: What is a captain’s chair?",
            answer: "A chair that makes decisions feel heavier. Works best with armrests.",
            tags: ["star trek", "fun", "q13"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#14: Why are there so many admirals?",
            answer: "Promotion happens quickly in Starfleet. Survival rates vary.",
            tags: ["star trek", "fun", "q14"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#15: Is this canon?",
            answer: "The app respects canon. Your cosplay is gloriously flexible.",
            tags: ["star trek", "fun", "q15"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#16: Where is the bridge?",
            answer: "Bridge not found. However, Registration and the Information Desk are excellent command centers.",
            tags: ["star trek", "fun", "q16"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#17: Can I say 'engage' in public?",
            answer: "Yes. Side effects may include new friends.",
            tags: ["star trek", "fun", "q17"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#18: What is the Delta?",
            answer: "A Starfleet insignia that says, “I’m here for exploration…and snacks.”",
            tags: ["star trek", "fun", "q18"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#19: Is there a replicator?",
            answer: "Sadly no. But real-world food exists, and it’s usually nearby.",
            tags: ["star trek", "fun", "q19"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#20: Do phasers exist here?",
            answer: "Only foam ones, and only if everyone behaves.",
            tags: ["star trek", "fun", "q20"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#21: Favorite series?",
            answer: "That’s classified. But the correct answer is: the one that brought you here.",
            tags: ["star trek", "fun", "q21"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#22: Best captain?",
            answer: "Answer varies by crew. All captains have strengths—and dramatic speeches.",
            tags: ["star trek", "fun", "q22"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#23: Is time travel allowed?",
            answer: "Only if you promise not to create a paradox before lunch.",
            tags: ["star trek", "fun", "q23"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#24: Do I need a uniform?",
            answer: "Uniform optional. Enthusiasm required.",
            tags: ["star trek", "fun", "q24"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#25: Is it okay to say 'Qapla’'?",
            answer: "Always. It increases honor by 12%.",
            tags: ["star trek", "fun", "q25"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#26: Can I join Starfleet?",
            answer: "In spirit, yes. In paperwork, ask Starfleet HR.",
            tags: ["star trek", "fun", "q26"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#27: Is the Prime Directive enforced here?",
            answer: "Yes: be kind, ask consent for photos, and don’t block hallways.",
            tags: ["star trek", "fun", "q27"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#28: Are tribbles safe?",
            answer: "Only if you keep them away from snacks.",
            tags: ["star trek", "fun", "q28"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#29: Is the Mirror Universe nearby?",
            answer: "Not detected. Please keep your goatee in standard configuration.",
            tags: ["star trek", "fun", "q29"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#30: Do I have to pick a faction?",
            answer: "No. You can be Federation on Friday and Klingon on Saturday. That’s how weekends work.",
            tags: ["star trek", "fun", "q30"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#31: What is warp core breach?",
            answer: "A strong reminder to take problems seriously and never ignore warning beeps.",
            tags: ["star trek", "fun", "q31"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#32: Do I need a tricorder?",
            answer: "Not required, but checking the schedule repeatedly is highly authentic.",
            tags: ["star trek", "fun", "q32"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#33: What is a captain’s chair?",
            answer: "A chair that makes decisions feel heavier. Works best with armrests.",
            tags: ["star trek", "fun", "q33"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#34: Why are there so many admirals?",
            answer: "Promotion happens quickly in Starfleet. Survival rates vary.",
            tags: ["star trek", "fun", "q34"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#35: Is this canon?",
            answer: "The app respects canon. Your cosplay is gloriously flexible.",
            tags: ["star trek", "fun", "q35"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#36: Where is the bridge?",
            answer: "Bridge not found. However, Registration and the Information Desk are excellent command centers.",
            tags: ["star trek", "fun", "q36"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#37: Can I say 'engage' in public?",
            answer: "Yes. Side effects may include new friends.",
            tags: ["star trek", "fun", "q37"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#38: What is the Delta?",
            answer: "A Starfleet insignia that says, “I’m here for exploration…and snacks.”",
            tags: ["star trek", "fun", "q38"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#39: Is there a replicator?",
            answer: "Sadly no. But real-world food exists, and it’s usually nearby.",
            tags: ["star trek", "fun", "q39"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#40: Do phasers exist here?",
            answer: "Only foam ones, and only if everyone behaves.",
            tags: ["star trek", "fun", "q40"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#41: Favorite series?",
            answer: "That’s classified. But the correct answer is: the one that brought you here.",
            tags: ["star trek", "fun", "q41"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#42: Best captain?",
            answer: "Answer varies by crew. All captains have strengths—and dramatic speeches.",
            tags: ["star trek", "fun", "q42"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#43: Is time travel allowed?",
            answer: "Only if you promise not to create a paradox before lunch.",
            tags: ["star trek", "fun", "q43"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#44: Do I need a uniform?",
            answer: "Uniform optional. Enthusiasm required.",
            tags: ["star trek", "fun", "q44"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#45: Is it okay to say 'Qapla’'?",
            answer: "Always. It increases honor by 12%.",
            tags: ["star trek", "fun", "q45"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#46: Can I join Starfleet?",
            answer: "In spirit, yes. In paperwork, ask Starfleet HR.",
            tags: ["star trek", "fun", "q46"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#47: Is the Prime Directive enforced here?",
            answer: "Yes: be kind, ask consent for photos, and don’t block hallways.",
            tags: ["star trek", "fun", "q47"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#48: Are tribbles safe?",
            answer: "Only if you keep them away from snacks.",
            tags: ["star trek", "fun", "q48"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#49: Is the Mirror Universe nearby?",
            answer: "Not detected. Please keep your goatee in standard configuration.",
            tags: ["star trek", "fun", "q49"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#50: Do I have to pick a faction?",
            answer: "No. You can be Federation on Friday and Klingon on Saturday. That’s how weekends work.",
            tags: ["star trek", "fun", "q50"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#51: What is warp core breach?",
            answer: "A strong reminder to take problems seriously and never ignore warning beeps.",
            tags: ["star trek", "fun", "q51"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#52: Do I need a tricorder?",
            answer: "Not required, but checking the schedule repeatedly is highly authentic.",
            tags: ["star trek", "fun", "q52"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#53: What is a captain’s chair?",
            answer: "A chair that makes decisions feel heavier. Works best with armrests.",
            tags: ["star trek", "fun", "q53"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#54: Why are there so many admirals?",
            answer: "Promotion happens quickly in Starfleet. Survival rates vary.",
            tags: ["star trek", "fun", "q54"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#55: Is this canon?",
            answer: "The app respects canon. Your cosplay is gloriously flexible.",
            tags: ["star trek", "fun", "q55"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#56: Where is the bridge?",
            answer: "Bridge not found. However, Registration and the Information Desk are excellent command centers.",
            tags: ["star trek", "fun", "q56"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#57: Can I say 'engage' in public?",
            answer: "Yes. Side effects may include new friends.",
            tags: ["star trek", "fun", "q57"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#58: What is the Delta?",
            answer: "A Starfleet insignia that says, “I’m here for exploration…and snacks.”",
            tags: ["star trek", "fun", "q58"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#59: Is there a replicator?",
            answer: "Sadly no. But real-world food exists, and it’s usually nearby.",
            tags: ["star trek", "fun", "q59"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#60: Do phasers exist here?",
            answer: "Only foam ones, and only if everyone behaves.",
            tags: ["star trek", "fun", "q60"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#61: Favorite series?",
            answer: "That’s classified. But the correct answer is: the one that brought you here.",
            tags: ["star trek", "fun", "q61"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#62: Best captain?",
            answer: "Answer varies by crew. All captains have strengths—and dramatic speeches.",
            tags: ["star trek", "fun", "q62"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#63: Is time travel allowed?",
            answer: "Only if you promise not to create a paradox before lunch.",
            tags: ["star trek", "fun", "q63"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#64: Do I need a uniform?",
            answer: "Uniform optional. Enthusiasm required.",
            tags: ["star trek", "fun", "q64"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#65: Is it okay to say 'Qapla’'?",
            answer: "Always. It increases honor by 12%.",
            tags: ["star trek", "fun", "q65"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#66: Can I join Starfleet?",
            answer: "In spirit, yes. In paperwork, ask Starfleet HR.",
            tags: ["star trek", "fun", "q66"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#67: Is the Prime Directive enforced here?",
            answer: "Yes: be kind, ask consent for photos, and don’t block hallways.",
            tags: ["star trek", "fun", "q67"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#68: Are tribbles safe?",
            answer: "Only if you keep them away from snacks.",
            tags: ["star trek", "fun", "q68"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#69: Is the Mirror Universe nearby?",
            answer: "Not detected. Please keep your goatee in standard configuration.",
            tags: ["star trek", "fun", "q69"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#70: Do I have to pick a faction?",
            answer: "No. You can be Federation on Friday and Klingon on Saturday. That’s how weekends work.",
            tags: ["star trek", "fun", "q70"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#71: What is warp core breach?",
            answer: "A strong reminder to take problems seriously and never ignore warning beeps.",
            tags: ["star trek", "fun", "q71"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#72: Do I need a tricorder?",
            answer: "Not required, but checking the schedule repeatedly is highly authentic.",
            tags: ["star trek", "fun", "q72"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#73: What is a captain’s chair?",
            answer: "A chair that makes decisions feel heavier. Works best with armrests.",
            tags: ["star trek", "fun", "q73"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#74: Why are there so many admirals?",
            answer: "Promotion happens quickly in Starfleet. Survival rates vary.",
            tags: ["star trek", "fun", "q74"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#75: Is this canon?",
            answer: "The app respects canon. Your cosplay is gloriously flexible.",
            tags: ["star trek", "fun", "q75"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#76: Where is the bridge?",
            answer: "Bridge not found. However, Registration and the Information Desk are excellent command centers.",
            tags: ["star trek", "fun", "q76"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#77: Can I say 'engage' in public?",
            answer: "Yes. Side effects may include new friends.",
            tags: ["star trek", "fun", "q77"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#78: What is the Delta?",
            answer: "A Starfleet insignia that says, “I’m here for exploration…and snacks.”",
            tags: ["star trek", "fun", "q78"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#79: Is there a replicator?",
            answer: "Sadly no. But real-world food exists, and it’s usually nearby.",
            tags: ["star trek", "fun", "q79"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#80: Do phasers exist here?",
            answer: "Only foam ones, and only if everyone behaves.",
            tags: ["star trek", "fun", "q80"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#81: Favorite series?",
            answer: "That’s classified. But the correct answer is: the one that brought you here.",
            tags: ["star trek", "fun", "q81"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#82: Best captain?",
            answer: "Answer varies by crew. All captains have strengths—and dramatic speeches.",
            tags: ["star trek", "fun", "q82"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#83: Is time travel allowed?",
            answer: "Only if you promise not to create a paradox before lunch.",
            tags: ["star trek", "fun", "q83"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#84: Do I need a uniform?",
            answer: "Uniform optional. Enthusiasm required.",
            tags: ["star trek", "fun", "q84"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#85: Is it okay to say 'Qapla’'?",
            answer: "Always. It increases honor by 12%.",
            tags: ["star trek", "fun", "q85"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#86: Can I join Starfleet?",
            answer: "In spirit, yes. In paperwork, ask Starfleet HR.",
            tags: ["star trek", "fun", "q86"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#87: Is the Prime Directive enforced here?",
            answer: "Yes: be kind, ask consent for photos, and don’t block hallways.",
            tags: ["star trek", "fun", "q87"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#88: Are tribbles safe?",
            answer: "Only if you keep them away from snacks.",
            tags: ["star trek", "fun", "q88"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#89: Is the Mirror Universe nearby?",
            answer: "Not detected. Please keep your goatee in standard configuration.",
            tags: ["star trek", "fun", "q89"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#90: Do I have to pick a faction?",
            answer: "No. You can be Federation on Friday and Klingon on Saturday. That’s how weekends work.",
            tags: ["star trek", "fun", "q90"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#91: What is warp core breach?",
            answer: "A strong reminder to take problems seriously and never ignore warning beeps.",
            tags: ["star trek", "fun", "q91"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#92: Do I need a tricorder?",
            answer: "Not required, but checking the schedule repeatedly is highly authentic.",
            tags: ["star trek", "fun", "q92"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#93: What is a captain’s chair?",
            answer: "A chair that makes decisions feel heavier. Works best with armrests.",
            tags: ["star trek", "fun", "q93"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#94: Why are there so many admirals?",
            answer: "Promotion happens quickly in Starfleet. Survival rates vary.",
            tags: ["star trek", "fun", "q94"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#95: Is this canon?",
            answer: "The app respects canon. Your cosplay is gloriously flexible.",
            tags: ["star trek", "fun", "q95"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#96: Where is the bridge?",
            answer: "Bridge not found. However, Registration and the Information Desk are excellent command centers.",
            tags: ["star trek", "fun", "q96"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#97: Can I say 'engage' in public?",
            answer: "Yes. Side effects may include new friends.",
            tags: ["star trek", "fun", "q97"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#98: What is the Delta?",
            answer: "A Starfleet insignia that says, “I’m here for exploration…and snacks.”",
            tags: ["star trek", "fun", "q98"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#99: Is there a replicator?",
            answer: "Sadly no. But real-world food exists, and it’s usually nearby.",
            tags: ["star trek", "fun", "q99"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#100: Do phasers exist here?",
            answer: "Only foam ones, and only if everyone behaves.",
            tags: ["star trek", "fun", "q100"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#101: Favorite series?",
            answer: "That’s classified. But the correct answer is: the one that brought you here.",
            tags: ["star trek", "fun", "q101"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#102: Best captain?",
            answer: "Answer varies by crew. All captains have strengths—and dramatic speeches.",
            tags: ["star trek", "fun", "q102"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#103: Is time travel allowed?",
            answer: "Only if you promise not to create a paradox before lunch.",
            tags: ["star trek", "fun", "q103"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#104: Do I need a uniform?",
            answer: "Uniform optional. Enthusiasm required.",
            tags: ["star trek", "fun", "q104"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#105: Is it okay to say 'Qapla’'?",
            answer: "Always. It increases honor by 12%.",
            tags: ["star trek", "fun", "q105"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#106: Can I join Starfleet?",
            answer: "In spirit, yes. In paperwork, ask Starfleet HR.",
            tags: ["star trek", "fun", "q106"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#107: Is the Prime Directive enforced here?",
            answer: "Yes: be kind, ask consent for photos, and don’t block hallways.",
            tags: ["star trek", "fun", "q107"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#108: Are tribbles safe?",
            answer: "Only if you keep them away from snacks.",
            tags: ["star trek", "fun", "q108"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#109: Is the Mirror Universe nearby?",
            answer: "Not detected. Please keep your goatee in standard configuration.",
            tags: ["star trek", "fun", "q109"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#110: Do I have to pick a faction?",
            answer: "No. You can be Federation on Friday and Klingon on Saturday. That’s how weekends work.",
            tags: ["star trek", "fun", "q110"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#111: What is warp core breach?",
            answer: "A strong reminder to take problems seriously and never ignore warning beeps.",
            tags: ["star trek", "fun", "q111"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#112: Do I need a tricorder?",
            answer: "Not required, but checking the schedule repeatedly is highly authentic.",
            tags: ["star trek", "fun", "q112"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#113: What is a captain’s chair?",
            answer: "A chair that makes decisions feel heavier. Works best with armrests.",
            tags: ["star trek", "fun", "q113"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#114: Why are there so many admirals?",
            answer: "Promotion happens quickly in Starfleet. Survival rates vary.",
            tags: ["star trek", "fun", "q114"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#115: Is this canon?",
            answer: "The app respects canon. Your cosplay is gloriously flexible.",
            tags: ["star trek", "fun", "q115"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#116: Where is the bridge?",
            answer: "Bridge not found. However, Registration and the Information Desk are excellent command centers.",
            tags: ["star trek", "fun", "q116"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#117: Can I say 'engage' in public?",
            answer: "Yes. Side effects may include new friends.",
            tags: ["star trek", "fun", "q117"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#118: What is the Delta?",
            answer: "A Starfleet insignia that says, “I’m here for exploration…and snacks.”",
            tags: ["star trek", "fun", "q118"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#119: Is there a replicator?",
            answer: "Sadly no. But real-world food exists, and it’s usually nearby.",
            tags: ["star trek", "fun", "q119"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#120: Do phasers exist here?",
            answer: "Only foam ones, and only if everyone behaves.",
            tags: ["star trek", "fun", "q120"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#121: Favorite series?",
            answer: "That’s classified. But the correct answer is: the one that brought you here.",
            tags: ["star trek", "fun", "q121"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#122: Best captain?",
            answer: "Answer varies by crew. All captains have strengths—and dramatic speeches.",
            tags: ["star trek", "fun", "q122"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#123: Is time travel allowed?",
            answer: "Only if you promise not to create a paradox before lunch.",
            tags: ["star trek", "fun", "q123"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#124: Do I need a uniform?",
            answer: "Uniform optional. Enthusiasm required.",
            tags: ["star trek", "fun", "q124"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#125: Is it okay to say 'Qapla’'?",
            answer: "Always. It increases honor by 12%.",
            tags: ["star trek", "fun", "q125"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#126: Can I join Starfleet?",
            answer: "In spirit, yes. In paperwork, ask Starfleet HR.",
            tags: ["star trek", "fun", "q126"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#127: Is the Prime Directive enforced here?",
            answer: "Yes: be kind, ask consent for photos, and don’t block hallways.",
            tags: ["star trek", "fun", "q127"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#128: Are tribbles safe?",
            answer: "Only if you keep them away from snacks.",
            tags: ["star trek", "fun", "q128"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#129: Is the Mirror Universe nearby?",
            answer: "Not detected. Please keep your goatee in standard configuration.",
            tags: ["star trek", "fun", "q129"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#130: Do I have to pick a faction?",
            answer: "No. You can be Federation on Friday and Klingon on Saturday. That’s how weekends work.",
            tags: ["star trek", "fun", "q130"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#131: What is warp core breach?",
            answer: "A strong reminder to take problems seriously and never ignore warning beeps.",
            tags: ["star trek", "fun", "q131"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#132: Do I need a tricorder?",
            answer: "Not required, but checking the schedule repeatedly is highly authentic.",
            tags: ["star trek", "fun", "q132"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#133: What is a captain’s chair?",
            answer: "A chair that makes decisions feel heavier. Works best with armrests.",
            tags: ["star trek", "fun", "q133"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#134: Why are there so many admirals?",
            answer: "Promotion happens quickly in Starfleet. Survival rates vary.",
            tags: ["star trek", "fun", "q134"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#135: Is this canon?",
            answer: "The app respects canon. Your cosplay is gloriously flexible.",
            tags: ["star trek", "fun", "q135"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#136: Where is the bridge?",
            answer: "Bridge not found. However, Registration and the Information Desk are excellent command centers.",
            tags: ["star trek", "fun", "q136"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#137: Can I say 'engage' in public?",
            answer: "Yes. Side effects may include new friends.",
            tags: ["star trek", "fun", "q137"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#138: What is the Delta?",
            answer: "A Starfleet insignia that says, “I’m here for exploration…and snacks.”",
            tags: ["star trek", "fun", "q138"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#139: Is there a replicator?",
            answer: "Sadly no. But real-world food exists, and it’s usually nearby.",
            tags: ["star trek", "fun", "q139"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#140: Do phasers exist here?",
            answer: "Only foam ones, and only if everyone behaves.",
            tags: ["star trek", "fun", "q140"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#141: Favorite series?",
            answer: "That’s classified. But the correct answer is: the one that brought you here.",
            tags: ["star trek", "fun", "q141"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#142: Best captain?",
            answer: "Answer varies by crew. All captains have strengths—and dramatic speeches.",
            tags: ["star trek", "fun", "q142"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#143: Is time travel allowed?",
            answer: "Only if you promise not to create a paradox before lunch.",
            tags: ["star trek", "fun", "q143"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#144: Do I need a uniform?",
            answer: "Uniform optional. Enthusiasm required.",
            tags: ["star trek", "fun", "q144"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#145: Is it okay to say 'Qapla’'?",
            answer: "Always. It increases honor by 12%.",
            tags: ["star trek", "fun", "q145"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#146: Can I join Starfleet?",
            answer: "In spirit, yes. In paperwork, ask Starfleet HR.",
            tags: ["star trek", "fun", "q146"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#147: Is the Prime Directive enforced here?",
            answer: "Yes: be kind, ask consent for photos, and don’t block hallways.",
            tags: ["star trek", "fun", "q147"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#148: Are tribbles safe?",
            answer: "Only if you keep them away from snacks.",
            tags: ["star trek", "fun", "q148"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#149: Is the Mirror Universe nearby?",
            answer: "Not detected. Please keep your goatee in standard configuration.",
            tags: ["star trek", "fun", "q149"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#150: Do I have to pick a faction?",
            answer: "No. You can be Federation on Friday and Klingon on Saturday. That’s how weekends work.",
            tags: ["star trek", "fun", "q150"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#151: What is warp core breach?",
            answer: "A strong reminder to take problems seriously and never ignore warning beeps.",
            tags: ["star trek", "fun", "q151"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#152: Do I need a tricorder?",
            answer: "Not required, but checking the schedule repeatedly is highly authentic.",
            tags: ["star trek", "fun", "q152"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#153: What is a captain’s chair?",
            answer: "A chair that makes decisions feel heavier. Works best with armrests.",
            tags: ["star trek", "fun", "q153"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#154: Why are there so many admirals?",
            answer: "Promotion happens quickly in Starfleet. Survival rates vary.",
            tags: ["star trek", "fun", "q154"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#155: Is this canon?",
            answer: "The app respects canon. Your cosplay is gloriously flexible.",
            tags: ["star trek", "fun", "q155"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#156: Where is the bridge?",
            answer: "Bridge not found. However, Registration and the Information Desk are excellent command centers.",
            tags: ["star trek", "fun", "q156"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#157: Can I say 'engage' in public?",
            answer: "Yes. Side effects may include new friends.",
            tags: ["star trek", "fun", "q157"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#158: What is the Delta?",
            answer: "A Starfleet insignia that says, “I’m here for exploration…and snacks.”",
            tags: ["star trek", "fun", "q158"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#159: Is there a replicator?",
            answer: "Sadly no. But real-world food exists, and it’s usually nearby.",
            tags: ["star trek", "fun", "q159"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#160: Do phasers exist here?",
            answer: "Only foam ones, and only if everyone behaves.",
            tags: ["star trek", "fun", "q160"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#161: Favorite series?",
            answer: "That’s classified. But the correct answer is: the one that brought you here.",
            tags: ["star trek", "fun", "q161"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#162: Best captain?",
            answer: "Answer varies by crew. All captains have strengths—and dramatic speeches.",
            tags: ["star trek", "fun", "q162"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#163: Is time travel allowed?",
            answer: "Only if you promise not to create a paradox before lunch.",
            tags: ["star trek", "fun", "q163"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#164: Do I need a uniform?",
            answer: "Uniform optional. Enthusiasm required.",
            tags: ["star trek", "fun", "q164"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#165: Is it okay to say 'Qapla’'?",
            answer: "Always. It increases honor by 12%.",
            tags: ["star trek", "fun", "q165"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#166: Can I join Starfleet?",
            answer: "In spirit, yes. In paperwork, ask Starfleet HR.",
            tags: ["star trek", "fun", "q166"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#167: Is the Prime Directive enforced here?",
            answer: "Yes: be kind, ask consent for photos, and don’t block hallways.",
            tags: ["star trek", "fun", "q167"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#168: Are tribbles safe?",
            answer: "Only if you keep them away from snacks.",
            tags: ["star trek", "fun", "q168"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#169: Is the Mirror Universe nearby?",
            answer: "Not detected. Please keep your goatee in standard configuration.",
            tags: ["star trek", "fun", "q169"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#170: Do I have to pick a faction?",
            answer: "No. You can be Federation on Friday and Klingon on Saturday. That’s how weekends work.",
            tags: ["star trek", "fun", "q170"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#171: What is warp core breach?",
            answer: "A strong reminder to take problems seriously and never ignore warning beeps.",
            tags: ["star trek", "fun", "q171"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#172: Do I need a tricorder?",
            answer: "Not required, but checking the schedule repeatedly is highly authentic.",
            tags: ["star trek", "fun", "q172"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#173: What is a captain’s chair?",
            answer: "A chair that makes decisions feel heavier. Works best with armrests.",
            tags: ["star trek", "fun", "q173"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#174: Why are there so many admirals?",
            answer: "Promotion happens quickly in Starfleet. Survival rates vary.",
            tags: ["star trek", "fun", "q174"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#175: Is this canon?",
            answer: "The app respects canon. Your cosplay is gloriously flexible.",
            tags: ["star trek", "fun", "q175"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#176: Where is the bridge?",
            answer: "Bridge not found. However, Registration and the Information Desk are excellent command centers.",
            tags: ["star trek", "fun", "q176"],
            source: .generalGuidance
        ),

        .init(
            question: "Star Trek Q#177: Can I say 'engage' in public?",
            answer: "Yes. Side effects may include new friends.",
            tags: ["star trek", "fun", "q177"],
            source: .generalGuidance
        )
    ]
}
