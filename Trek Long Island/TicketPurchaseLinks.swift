// Copyright Bryan Carroll. All rights reserved.
//
//  TicketPurchaseLinks.swift
//  Trek Long Island
//
//  Shared official purchase URLs used across the app.
//

import Foundation

enum TicketPurchaseLinks {
    static let ticketsURLString = "https://treklongislandtickets.square.site/"
    static let photoOpsURLString = "https://treklongislandtickets.square.site/photo-ops?"
    static let presaleURLString = "https://treklongislandtickets.square.site/product/presale-of-2026-3-day-adult-badge-for-trek-long-island/136"

    static var ticketsURL: URL { URL(string: ticketsURLString)! }
    static var photoOpsURL: URL { URL(string: photoOpsURLString)! }
    static var presaleURL: URL { URL(string: presaleURLString)! }
}
