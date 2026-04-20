//
//  for.swift
//  Trek Long Island
//
//  Created by Bryan on 2/24/26.
//


// Copyright Bryan Carroll. All rights reserved.
//
//  HelloComputerFAQBank+Additions.swift
//  Trek Long Island
//
//  Additional FAQ entries for HelloComputerFAQBank.
//
//  HOW TO INTEGRATE
//  ─────────────────────────────────────────────────────────────────
//  Option A (cleanest): Copy the .init(…) entries below directly
//  into the `static let faqs: [HelloComputerFAQ] = [` array in
//  HelloComputerFAQBank.swift, before the final closing bracket.
//
//  Option B: Use an extension to append at runtime. Add this anywhere
//  in your app startup (e.g. in HelloComputerStore.init):
//
//      // Already handled by the extension below — no extra code needed.
//
//  The extension approach is used here so this file compiles without
//  modifying the original HelloComputerFAQBank.swift.
//
//  TOPICS ADDED
//  ─────────────────────────────────────────────────────────────────
//  • Parking / transit / hotel directions     (6 entries)
//  • Food & drink at the venue                (5 entries)
//  • Kids & family programming                (5 entries)
//  • Photo op & autograph session details     (7 entries)
//  • Staff-specific operational guidance      (7 entries)
//
//  Swift 6 • iOS 17+

import Foundation

extension HelloComputerFAQBank {

    static let additionalFAQs: [HelloComputerFAQ] = [

        // ─────────────────────────────────────────────────────────
        // PARKING / TRANSIT / HOTEL DIRECTIONS
        // ─────────────────────────────────────────────────────────

        .init(
            question: "Where can I park at the Hyatt Regency Long Island?",
            answer: "The Hyatt Regency Long Island (1717 Motor Parkway, Hauppauge, NY 11788) has an on-site parking lot. Parking availability and any fees are managed by the hotel — confirm current details at:\\nhttps://treklongisland.com/hotel/\\n\\nTip: Arriving early on busy days (especially Saturday) is recommended.",
            tags: ["parking", "park", "car", "lot", "garage", "hyatt", "hauppauge"],
            source: .officialFAQ
        ),

        .init(
            question: "How do I get to Trek Long Island by public transit?",
            answer: "The venue is at the Hyatt Regency Long Island, 1717 Motor Parkway, Hauppauge, NY 11788.\\n\\nTransit options:\\n• Long Island Rail Road (LIRR) to Ronkonkoma or Central Islip, then a taxi or rideshare to the hotel.\\n• Suffolk County Transit buses serve the Hauppauge area — check schedules at sct.suffolkcountyny.gov.\\n• Rideshare (Uber/Lyft) from any LIRR stop is the most reliable option.\\n\\nFull hotel and directions info:\\nhttps://treklongisland.com/hotel/",
            tags: ["transit", "train", "lirr", "bus", "subway", "public", "rail", "directions", "how to get there", "rideshare"],
            source: .officialFAQ
        ),

        .init(
            question: "Is there a hotel room block for Trek Long Island?",
            answer: "A hotel block may be available at the Hyatt Regency Long Island. Check current booking details and any group rate at:\\nhttps://treklongisland.com/hotel/\\n\\nBook early — convention hotel blocks tend to fill quickly.",
            tags: ["hotel", "room", "block", "booking", "stay", "overnight", "hyatt", "rate"],
            source: .officialFAQ
        ),

        .init(
            question: "How far is the venue from major airports?",
            answer: "The Hyatt Regency Long Island is in Hauppauge, NY:\\n• JFK Airport: approx. 45–60 min by car.\\n• LaGuardia (LGA): approx. 50–65 min by car.\\n• MacArthur Airport (ISP): approx. 15–20 min by car — closest option.\\n\\nRideshare and car rental are available at all three airports. Full venue info:\\nhttps://treklongisland.com/hotel/",
            tags: ["airport", "jfk", "laguardia", "macarthur", "isp", "fly", "travel", "drive"],
            source: .officialFAQ
        ),

        .init(
            question: "Is there accessible parking or drop-off?",
            answer: "The Hyatt Regency Long Island has ADA-compliant parking and accessible entrances. For specific accessibility needs, contact the hotel directly or ask staff at the Information Desk on arrival.\\n\\nAccessibility info:\\nhttps://treklongisland.com/hotel/",
            tags: ["accessible", "ada", "parking", "drop-off", "wheelchair", "mobility", "handicap"],
            source: .officialFAQ
        ),

        .init(
            question: "Can I check in to the hotel on the same day as the convention?",
            answer: "Standard hotel check-in is typically 3:00 PM. If you arrive before that, the hotel may hold your luggage. Convention registration opens separately — check the schedule for exact times.\\n\\nHotel details:\\nhttps://treklongisland.com/hotel/",
            tags: ["check in", "hotel", "same day", "luggage", "early arrival"],
            source: .officialFAQ
        ),

        // ─────────────────────────────────────────────────────────
        // FOOD & DRINK AT THE VENUE
        // ─────────────────────────────────────────────────────────

        .init(
            question: "Is there food available at the convention?",
            answer: "The Hyatt Regency Long Island has on-site restaurant and bar options. Convention-specific food vendors or concessions may also be present — check the schedule or Announcements for details.\\n\\nFor dietary concerns or special requests, the hotel restaurant staff can usually accommodate.\\n\\nVenue info:\\nhttps://treklongisland.com/hotel/",
            tags: ["food", "eat", "restaurant", "lunch", "dinner", "snack", "hungry", "meal"],
            source: .officialFAQ
        ),

        .init(
            question: "Are there vegetarian, vegan, or allergen-friendly food options?",
            answer: "The Hyatt Regency typically offers vegetarian and allergy-friendly options — speak with hotel restaurant staff directly for the current menu and allergen details.\\n\\nIf you have a severe allergy, it is always safest to ask hotel staff directly rather than relying on convention signage.",
            tags: ["vegetarian", "vegan", "allergy", "allergen", "gluten", "dairy", "nut", "dietary", "kosher", "halal"],
            source: .generalGuidance
        ),

        .init(
            question: "Can I bring my own food and drinks?",
            answer: "Outside food and non-alcoholic beverages in sealed containers are generally permitted for personal consumption. Alcohol brought from outside is not permitted per hotel policy.\\n\\nCheck Announcements for any convention-specific food policies on the day.",
            tags: ["bring food", "outside food", "snacks", "water bottle", "drinks", "alcohol"],
            source: .generalGuidance
        ),

        .init(
            question: "Is there coffee or a café at the venue?",
            answer: "The Hyatt Regency typically has a café or coffee bar in the lobby area. Hours can vary — check with hotel staff on arrival.\\n\\nTip: Saturday tends to be the busiest day; peak times around 10 AM and post-panel rushes can mean longer waits.",
            tags: ["coffee", "café", "cafe", "starbucks", "tea", "espresso", "latte", "caffeine"],
            source: .generalGuidance
        ),

        .init(
            question: "Are there restaurants nearby the Hyatt Regency Long Island?",
            answer: "The Hauppauge/Motor Parkway area has several dining options within a 5–10 minute drive, including chains and local restaurants. Your rideshare app or Maps app will show current options closest to the hotel.\\n\\nNote: on busy convention days, nearby restaurants can fill up — especially Saturday lunch.",
            tags: ["restaurants", "nearby", "outside", "dinner", "off-site", "local food"],
            source: .generalGuidance
        ),

        // ─────────────────────────────────────────────────────────
        // KIDS & FAMILY PROGRAMMING
        // ─────────────────────────────────────────────────────────

        .init(
            question: "Is Trek Long Island family-friendly?",
            answer: "Yes — Trek Long Island welcomes families and younger fans.\\n\\nFamily-friendly tips:\\n• Check the Schedule tab for panels and events listed as family or all-ages.\\n• The Starfleet Academy track is designed with younger fans in mind.\\n• Ask staff at the Information Desk for quiet areas if children need a sensory break.\\n\\nFull program details:\\nhttps://treklongisland.com/programs/",
            tags: ["family", "kids", "children", "all ages", "family friendly", "young fans", "child"],
            source: .officialFAQ
        ),

        .init(
            question: "Is there programming specifically for kids?",
            answer: "Yes — Starfleet Academy sessions and other family-oriented programming are part of the schedule.\\n\\nCheck the Schedule tab and filter for family or academy events. The official program page has the latest lineup:\\nhttps://treklongisland.com/programs/",
            tags: ["kids", "children", "starfleet academy", "family", "youth", "programming", "junior"],
            source: .officialFAQ
        ),

        .init(
            question: "Do children need their own ticket?",
            answer: "Ticket requirements for children vary by age and ticket type. Check the official ticket site for current pricing and children's admission policy:\\nhttps://treklongislandtickets.square.site/",
            tags: ["children", "kids", "ticket", "child ticket", "free", "age", "under"],
            source: .officialFAQ
        ),

        .init(
            question: "Is there a quiet or sensory-friendly space for kids?",
            answer: "If you need a quieter area for a child (or for yourself), ask staff at the Registration or Information Desk — they can direct you to the most suitable low-stimulation area available.\\n\\nAccessibility and comfort details:\\nhttps://treklongisland.com/",
            tags: ["quiet", "sensory", "kids", "children", "overstimulated", "break", "calm", "noise"],
            source: .generalGuidance
        ),

        .init(
            question: "Can my child get an autograph or photo with a guest?",
            answer: "Yes — most guests welcome younger fans. General guidelines:\\n• Keep the child with a guardian at all times in photo op and autograph lines.\\n• Ask the handler or table staff if there are any special accommodations for young fans.\\n• Some guests have personal preferences — table staff will let you know.\\n\\nPhoto op and autograph schedules:\\nhttps://treklongisland.com/programs/",
            tags: ["child", "kids", "autograph", "photo op", "guest", "meet", "young fans"],
            source: .generalGuidance
        ),

        // ─────────────────────────────────────────────────────────
        // PHOTO OP & AUTOGRAPH SESSION DETAILS
        // ─────────────────────────────────────────────────────────

        .init(
            question: "How do photo ops work at Trek Long Island?",
            answer: "Photo ops are time-slotted sessions where you get a posed photo taken with a guest by a professional photographer.\\n\\nHow it works:\\n1) Purchase your photo op ticket: \(TicketPurchaseLinks.photoOpsURLString)\\n2) Check the Schedule for your assigned time slot and room.\\n3) Arrive 5–10 minutes early — lines move fast.\\n4) Have your confirmation ready (screenshot is fine).\\n5) Photos are typically available digitally after the con.\\n\\nSchedule and updates:\\nhttps://treklongisland.com/programs/",
            tags: ["photo op", "photo", "picture", "photograph", "pose", "how", "works"],
            source: .officialFAQ
        ),

        .init(
            question: "Can I bring my own camera to a photo op?",
            answer: "Professional photo ops use a house photographer — personal cameras and phones are generally not allowed in the photo op room itself to keep the line moving.\\n\\nFor casual photos with guests outside of scheduled ops, always ask the guest or their handler first — consent is canon.",
            tags: ["camera", "photo op", "personal camera", "phone", "own camera", "selfie"],
            source: .generalGuidance
        ),

        .init(
            question: "How do autograph sessions work?",
            answer: "Autograph sessions take place at guest tables in the autograph hall.\\n\\nTips:\\n1) Check the Schedule for each guest's signing times — these can change.\\n2) Have your item ready before you reach the table.\\n3) Some autographs may be included with your ticket; others may have an additional fee — check the ticket site.\\n4) Be respectful of time — handlers will let you know if a longer conversation is OK.\\n\\nOfficial updates:\\nhttps://treklongisland.com/",
            tags: ["autograph", "signing", "sign", "table", "how", "works", "session"],
            source: .officialFAQ
        ),

        .init(
            question: "Are autographs included in my ticket?",
            answer: "This depends on your ticket type. Some packages include autographs; others require a separate purchase.\\n\\nCheck your ticket details or the official ticket site:\\nhttps://treklongislandtickets.square.site/",
            tags: ["autograph", "included", "ticket", "free", "extra", "cost", "purchase"],
            source: .officialFAQ
        ),

        .init(
            question: "What can I get signed at an autograph session?",
            answer: "Most guests will sign photos, posters, books, props, and personal items. Some guests have preferences — the handler at the table will let you know if there are any restrictions.\\n\\nPre-printed 8x10 photos of the guest are often available for purchase at or near the table.",
            tags: ["sign", "signed", "autograph", "item", "photo", "poster", "prop", "bring"],
            source: .generalGuidance
        ),

        .init(
            question: "What if I miss my photo op time slot?",
            answer: "If you miss your scheduled time slot, go to the photo op desk or ask a nearby staff member immediately. Depending on availability, you may be able to join a later slot.\\n\\nDo not wait — slots fill quickly and makeup opportunities are limited.",
            tags: ["missed", "miss", "photo op", "late", "time slot", "reschedule"],
            source: .generalGuidance
        ),

        .init(
            question: "Can I do a group photo op with multiple guests?",
            answer: "Some guests offer group or combo photo op packages. Check the photo-op ticket page for available options:\\n\(TicketPurchaseLinks.photoOpsURLString)\\n\\nGroup photos with friends (not additional guests) are typically fine — just confirm with the handler at the session.",
            tags: ["group", "combo", "multiple guests", "together", "photo op", "two guests"],
            source: .officialFAQ
        ),

        // ─────────────────────────────────────────────────────────
        // STAFF-SPECIFIC OPERATIONAL GUIDANCE
        // ─────────────────────────────────────────────────────────

        .init(
            question: "What is the staff code of conduct?",
            answer: "Staff represent Trek Long Island to every attendee. Core standards:\\n1) Professional and welcoming tone at all times.\\n2) De-escalate before escalating — try to resolve calmly before calling for backup.\\n3) Direct attendees, never physically guide or block unless safety requires it.\\n4) Report incidents factually — who, what, where, when. No speculation in official logs.\\n5) Respect attendee privacy and dignity in all interactions.\\n\\nFor policy questions, consult your shift lead or Ops.",
            tags: ["staff", "code of conduct", "policy", "rules", "standards", "behavior", "professional"],
            source: .generalGuidance
        ),

        .init(
            question: "How do I handle a disruptive attendee?",
            answer: "Staff protocol for disruptive behavior:\\n1) Approach calmly, introduce yourself as staff.\\n2) State the specific issue clearly and without judgment.\\n3) Give the attendee a chance to correct the behavior.\\n4) If they comply, thank them and move on.\\n5) If they escalate or refuse, contact Security immediately via radio.\\n6) Document: time, location, description of behavior, action taken.\\n\\nNever argue publicly or raise your voice. Your composure is the de-escalation.",
            tags: ["staff", "disruptive", "attendee", "behavior", "escalation", "security", "handle", "difficult"],
            source: .generalGuidance
        ),

        .init(
            question: "What is the staff lost and found procedure?",
            answer: "Lost and found protocol:\\n1) Collect the item and bring it to the Information Desk / Registration.\\n2) Log: description, where found, time found, your name/badge number.\\n3) Do NOT hold items personally for longer than 10 minutes.\\n4) If an attendee claims an item, they must provide a description before you show it.\\n5) At end of day, confirm all logged items are physically at the Info Desk.",
            tags: ["staff", "lost and found", "lost item", "found", "procedure", "protocol"],
            source: .generalGuidance
        ),

        .init(
            question: "How do I handle a medical situation as staff?",
            answer: "Medical emergency protocol for staff:\\n1) Call for help immediately — radio Security/Medical or call 911 if life-threatening.\\n2) Keep bystanders back and maintain a clear area around the person.\\n3) Do NOT attempt treatment unless you are trained and certified.\\n4) Stay with the person and provide calm reassurance until help arrives.\\n5) Designate someone to meet and guide responders to the exact location.\\n6) Document time, location, and what you observed for the incident report.\\n\\nYour job is to secure the scene and get trained help there — not to provide medical care.",
            tags: ["staff", "medical", "emergency", "injury", "hurt", "ill", "sick", "first aid", "protocol"],
            source: .generalGuidance
        ),

        .init(
            question: "What are the room capacity and line management rules for staff?",
            answer: "Room and capacity protocol:\\n1) Know your room's posted capacity before each session.\\n2) Start a queue line outside the room at least 15 minutes before a popular session.\\n3) Keep the ADA/accessible entry clear at all times.\\n4) When at capacity: hold the line outside, admit as people exit (one-in-one-out).\\n5) Update the queue with estimated wait time every 10–15 minutes.\\n6) If overflow threatens corridor safety, radio Ops for overflow room or redirect support.\\n7) Never leave a full room without a staff presence at the door.",
            tags: ["staff", "capacity", "room", "line", "queue", "management", "overflow", "full"],
            source: .generalGuidance
        ),

        .init(
            question: "What should staff do during shift handoff?",
            answer: "Shift handoff checklist:\\n1) Brief your replacement on any open issues: location, status, owner.\\n2) Hand off any physical items (radios, lanyards, forms).\\n3) Walk the area together if time allows.\\n4) Confirm they have Ops contact info and know escalation path.\\n5) Do not leave your post until your replacement confirms they are ready.\\n6) Log the handoff time and any outstanding items in the shift notes.",
            tags: ["staff", "handoff", "shift", "change", "transition", "relief", "end of shift"],
            source: .generalGuidance
        ),

        .init(
            question: "Where do staff escalate urgent issues?",
            answer: "Escalation path:\\n• Room/floor issues → Your area lead first.\\n• Security threats, medical emergencies → Security/Medical directly (radio or in person). Do not wait for an area lead.\\n• Attendee complaints beyond your authority → Information Desk / Guest Relations.\\n• Ops-level issues (capacity, scheduling, logistics) → Ops Command.\\n\\nWhen in doubt: over-communicate. A false alarm is always better than an unreported incident.",
            tags: ["staff", "escalate", "urgent", "escalation", "report", "who to call", "chain of command", "ops"],
            source: .generalGuidance
        ),

    ]
}

// MARK: - Merge helper
//
// To use additionalFAQs in HelloComputerEngine without modifying
// HelloComputerFAQBank.swift, update the engine's scoring loop to use:
//
//     let allFAQs = HelloComputerFAQBank.faqs + HelloComputerFAQBank.additionalFAQs
//
// and replace `HelloComputerFAQBank.faqs` with `allFAQs` in the for-loop.
