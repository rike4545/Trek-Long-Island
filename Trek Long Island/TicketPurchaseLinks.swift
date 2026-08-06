// Copyright Bryan Carroll. All rights reserved.
//
//  TicketPurchaseLinks.swift
//  Trek Long Island
//
//  Shared official purchase URLs used across the app.
//

import Foundation

enum TicketPurchaseLinks {
    static let ticketStoreURLString = "https://treklongislandtickets.square.site/"
    static let admissionURLString = "https://treklongislandtickets.square.site/s/search?q=2027"
    static let ticketsURLString = admissionURLString
    static let photoOpsURLString = "https://treklongislandtickets.square.site/photo-ops"
    /// The old /photo-op-schedule-2025/ page now 404s and no 2027 photo-op grid has
    /// been posted yet, so this points at the programming hub that will carry it.
    static let photoOpScheduleURLString = "https://treklongisland.com/programs/"

    // MARK: - 2027 passes

    static let defiantPassURLString = "https://treklongislandtickets.square.site/product/defiant-pass-2027/X7UOWOGSVXUSEHXKYJY3PL54?cs=true&cst=custom"
    static let dinnerWithTheStarsURLString = "https://treklongislandtickets.square.site/product/dinner-with-the-stars-2027/X55MYITM74MT2MRYGGPTSHWE?cs=true&cst=custom"
    static let autographPreSalesURLString = "https://theautographconcierge.com/collections/autograph-pre-orders-1/trek-long-island"
    static let vendorTablingURLString = "https://treklongislandtickets.square.site/vendor"
    static let presaleURLString = admissionURLString

    // MARK: - 2026 special events (RETIRED)
    //
    // These Square products were sold for the June 2026 convention and are no longer
    // listed in the store — fetching them returns the generic storefront shell rather
    // than a product page. They are kept only so the archived 2026 view can name what
    // ran; `areSpecialEventsAnnounced` gates them out of the live purchase UI.
    // Delete this block once 2027 special events are announced and replace with the
    // new product URLs.

    /// Flip to `true` once 2027 special-event products exist in the Square store.
    static let areSpecialEventsAnnounced = false

    static let risaLuauURLString = "https://treklongislandtickets.square.site/product/risa-luau-cocktails-across-the-final-frontier/ASNL2QBQCXUZA23COJZWP77Q?cs=true&cst=custom"
    static let wineCheeseCombsURLString = "https://treklongislandtickets.square.site/product/wine-and-cheese-tasting-with-jeffery-combs/NV5PDEEY4ARO2JMM3PZMSJ43?cs=true&cst=custom"
    static let nanaPaintingURLString = "https://treklongislandtickets.square.site/product/painting-with-nana-visitor-art-of-the-resistance/ZFIE7PX6KOQ4SQ33PCIRBBGE?cs=true&cst=custom"
    static let avaahBlackwellStuntWorkshopURLString = "https://treklongislandtickets.square.site/product/hands-on-with-avaah-blackwell-stunt-action-workshop/RVSCCQU45E5EGAORQM6YNYSO?cs=true&cst=custom"
    static let slutTrekRisaBurlesqueURLString = "https://treklongislandtickets.square.site/product/slut-trek-risa-burlesque-show-with-lucy-blueskies-and-crew-21-and-over-id-will-be-checked-saturday-evening/VALRBYUQYE22ZXUK2AYQ7F4D?cs=true&cst=custom"
    static let nicoleDeBoerGlassEtchingURLString = "https://treklongislandtickets.square.site/product/glass-etching-art-with-nicole-de-boer-saturday-event/C723ICSC6FLEO2KX5NPB4KZE?cs=true&cst=custom"
    static let jenniferHetrickGlassEtchingURLString = "https://treklongislandtickets.square.site/product/glass-etching-art-with-jennifer-hetrick-sunday-event/3RJKLF2552SGAXL7IAL6XF2N?cs=true&cst=custom"
    static let starfleetFusionFlowURLString = "https://treklongislandtickets.square.site/product/starfleet-fusion-flow-with-stephanie-czajkowski-saturday-event/4T3IUEI2Y6SEGM7OTDZQQWGE?cs=true&cst=custom"
    static let musettaQigongSaturdayURLString = "https://treklongislandtickets.square.site/product/qigong-exercise-class-with-musetta-vander-saturday-9-am/HMT4F4O2QPRDLUNUR2IVUT2N?cs=true&cst=custom"
    static let musettaQigongSundayURLString = "https://treklongislandtickets.square.site/product/qigong-exercise-class-with-musetta-vander-sunday-9-am/I7IWVBZHERR6AN3SG4A7SIDG?cs=true&cst=custom"
    static let musettaGoldenKeyQigongURLString = "https://treklongislandtickets.square.site/product/golden-key-qigong-healing-method-class-with-musetta-vander-saturday/LFZDMRLFFIAMLCQ24B6YZ5UZ?cs=true&cst=custom"
    static let danJeannotteMoustacheURLString = "https://treklongislandtickets.square.site/product/moustache-you-a-question-with-dan-jeannotte-aka-sam-kirk/J5FHRH2FGTFHMG54RQLLR74F?cs=true&cst=custom"

    static var defiantPassURL: URL { URL(string: defiantPassURLString)! }
    static var dinnerWithTheStarsURL: URL { URL(string: dinnerWithTheStarsURLString)! }
    static var ticketStoreURL: URL { URL(string: ticketStoreURLString)! }
    static var admissionURL: URL { URL(string: admissionURLString)! }
    static var ticketsURL: URL { URL(string: ticketsURLString)! }
    static var photoOpsURL: URL { URL(string: photoOpsURLString)! }
    static var photoOpScheduleURL: URL { URL(string: photoOpScheduleURLString)! }
    static var autographPreSalesURL: URL { URL(string: autographPreSalesURLString)! }
    static var vendorTablingURL: URL { URL(string: vendorTablingURLString)! }
    static var presaleURL: URL { URL(string: presaleURLString)! }
    static var risaLuauURL: URL { URL(string: risaLuauURLString)! }
    static var wineCheeseCombsURL: URL { URL(string: wineCheeseCombsURLString)! }
    static var nanaPaintingURL: URL { URL(string: nanaPaintingURLString)! }
    static var avaahBlackwellStuntWorkshopURL: URL { URL(string: avaahBlackwellStuntWorkshopURLString)! }
    static var slutTrekRisaBurlesqueURL: URL { URL(string: slutTrekRisaBurlesqueURLString)! }
    static var nicoleDeBoerGlassEtchingURL: URL { URL(string: nicoleDeBoerGlassEtchingURLString)! }
    static var jenniferHetrickGlassEtchingURL: URL { URL(string: jenniferHetrickGlassEtchingURLString)! }
    static var starfleetFusionFlowURL: URL { URL(string: starfleetFusionFlowURLString)! }
    static var musettaQigongSaturdayURL: URL { URL(string: musettaQigongSaturdayURLString)! }
    static var musettaQigongSundayURL: URL { URL(string: musettaQigongSundayURLString)! }
    static var musettaGoldenKeyQigongURL: URL { URL(string: musettaGoldenKeyQigongURLString)! }
    static var danJeannotteMoustacheURL: URL { URL(string: danJeannotteMoustacheURLString)! }

    static var autographPreSalesCutoffDate: Date {
        let calendar = Calendar.current
        let conventionStart = TLIConventionDates.conventionDays.first?.date
            ?? TLIEventInfo.current.startDate
        return calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: conventionStart))
            ?? conventionStart
    }

    static func areAutographPreSalesAvailable(on date: Date = .now) -> Bool {
        date < autographPreSalesCutoffDate
    }

    static func autographPreSalesStatusText(on date: Date = .now) -> String {
        if areAutographPreSalesAvailable(on: date) {
            return "Autograph pre-sales:\n\(autographPreSalesURLString)"
        }
        return "Autograph pre-sales are now closed. Please check guest tables and autograph hall staff during the convention for current autograph availability."
    }
}
