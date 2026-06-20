// Copyright Bryan Carroll. All rights reserved.
//  HelloComputerAnswerSource.swift
//  Trek Long Island
//
//  Hard-rule source routing for "Hello Computer".
//
//  RULE (non-negotiable):
//   - Ticket purchase / checkout / order / pricing questions → official admission ticket link
//   - Everything else → https://treklongisland.com/
//
//  This file intentionally defines ONLY the router/utilities,
//  and does NOT duplicate the HelloComputerAnswer / HelloComputerAnswerSource models
//  (those live in HelloComputerRole.swift).
//
//  Swift 6 • iOS 17+
//

import Foundation

enum HelloComputerHardRuleRouter {

    static let ticketsURLString = TicketPurchaseLinks.ticketsURLString
    static let photoOpsURLString = TicketPurchaseLinks.photoOpsURLString
    static let websiteURLString = "https://treklongisland.com/"

    static var ticketsURL: URL { URL(string: ticketsURLString)! }
    static var websiteURL: URL { URL(string: websiteURLString)! }
    
    /// Returns true when the user is asking about buying tickets, checkout, orders, pricing, refunds, etc.
    /// NOTE: We keep this conservative (better to route commerce-ish questions to the tickets site).
    static func isTicketPurchaseQuery(_ rawQuery: String) -> Bool {
        let q = normalize(rawQuery)

        // Purchase intent signals
        let purchaseSignals: [String] = [
            "buy", "purchase", "checkout", "check out", "order", "receipt", "confirmation",
            "payment", "paid", "credit card", "card", "charge", "charged",
            "refund", "return", "cancel", "cancellation", "transfer",
            "promo", "discount", "coupon", "code", "price", "pricing", "cost", "fee", "fees",
            "sold out", "availability", "register", "registration", "vip", "admission"
        ]

        // Ticket context signals (including synonyms)
        let ticketContext: [String] = [
            "ticket", "tickets", "pass", "passes", "badge", "badges", "entry"
        ]

        let hasPurchase = purchaseSignals.contains { q.contains($0) }
        let hasTicket = ticketContext.contains { q.contains($0) }

        // If they mention tickets at all, and also anything that smells like purchase/commerce => tickets site.
        if hasTicket && hasPurchase { return true }

        // If they mention explicit order/payment/refund language even without the word ticket => still tickets site.
        let strongCommerce: [String] = ["order", "receipt", "confirmation", "payment", "refund", "charged", "charge", "checkout", "purchase"]
        if strongCommerce.contains(where: { q.contains($0) }) { return true }

        return false
    }

    static func ticketPurchaseAnswerText() -> String {
        """
        For buying tickets, checkout, pricing, confirmations/receipts, or order issues, the official ticket site:
        \(ticketsURLString)

        For photo-op purchases specifically:
        \(photoOpsURLString)

        For schedules, venue details, guests, policies, and everything else:
        \(websiteURLString)
        """
    }

    static func generalWebsiteAnswerText() -> String {
        """
        For schedules, venue info, guests, policies, updates, and all non-ticket-purchase questions, the official Trek Long Island website is the best source:
        \(websiteURLString)

        If you’re trying to buy tickets or need checkout/order help, use:
        \(ticketsURLString)
        """
    }

    // MARK: - Helpers

    private static func normalize(_ s: String) -> String {
        let lower = s.lowercased()
        let trimmed = lower.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
        return parts.joined(separator: " ")
    }
}
