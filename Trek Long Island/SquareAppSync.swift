// Copyright Bryan Carroll. All rights reserved.
//
//  SquareAppSync.swift
//  Trek Long Island
//
//  Marketplace-safe app-side Square sync boundary.
//  The app should prefer proxying through our backend instead of talking
//  directly to Square with seller credentials.
//

import Foundation

struct SquareCRMContactPayload: Codable {
    let contactID: String
    let fullName: String
    let organization: String
    let roleTitle: String
    let kind: String
    let email: String
    let phone: String
    let squareCustomerID: String?
    let tags: [String]
    let notes: String

    init(contact: CRMContact) {
        self.contactID = contact.id.uuidString.lowercased()
        self.fullName = contact.fullName
        self.organization = contact.organization
        self.roleTitle = contact.roleTitle
        self.kind = contact.kind.rawValue
        self.email = contact.email
        self.phone = contact.phone
        self.squareCustomerID = contact.squareCustomerID
        self.tags = contact.tags
        self.notes = contact.notes
    }
}

struct SquareCRMContactSyncRequest: Codable {
    let conventionID: String
    let contact: SquareCRMContactPayload
}

struct SquareCRMContactSyncResponse: Codable {
    let customerID: String
    let action: String
    let source: String?
}
