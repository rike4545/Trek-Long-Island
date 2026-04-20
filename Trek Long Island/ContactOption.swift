// Copyright Bryan Carroll. All rights reserved.
//
//  ContactOption.swift
//  Trek Long Island
//
//  Created by Bryan on 6/29/25.
//


import Foundation

enum ContactOption: String, CaseIterable, Identifiable {
    case guestBooking = "Guest Booking Inquiries"
    case vendors = "Vendors"
    case registration = "Registration"
    case infoDesk = "Info Desk"
    case volunteers = "Volunteer"
    case kidsEvents = "Kid's Events"
    case appIssues = "App Issues"

    var id: String { rawValue }

    var email: String {
        switch self {
        case .guestBooking: return "hellotreklongisland@gmail.com"
        case .vendors: return "hellotreklongisland@gmail.com"
        case .registration: return "hellotreklongisland@gmail.com"
        case .infoDesk: return "hellotreklongisland@gmail.com"
        case .volunteers: return "hellotreklongisland@gmail.com"
        case .kidsEvents: return "hellotreklongisland@gmail.com"
        case .appIssues: return "hellotreklongisland@gmail.com"
        }
    }

    var subjectLine: String {
        switch self {
        case .guestBooking: return "Trek LI Guest Booking Inquiry"
        case .vendors: return "Trek LI Vendor Inquiry"
        case .registration: return "Trek LI Registration Question"
        case .infoDesk: return "Trek LI Info Desk Question"
        case .volunteers: return "Trek LI Volunteer Program"
        case .kidsEvents: return "Trek LI Kid’s Events Inquiry"
        case .appIssues: return "Trek LI App Bug or Feature Request"
        }
    }
}
