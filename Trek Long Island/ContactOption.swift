// Copyright Bryan Carroll. All rights reserved.
//
//  ContactOption.swift
//  Trek Long Island
//
//  Created by Bryan on 6/29/25.
//


import Foundation

private let trekLongIslandFeedbackURL = "https://qualtricsxmm8q5gxrhq.qualtrics.com/jfe/form/SV_1TvkCrIKgaEYHPM"

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
        trekLongIslandFeedbackURL
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
