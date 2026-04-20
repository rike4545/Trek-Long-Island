// Copyright Bryan Carroll. All rights reserved.
//
//  Role.swift
//  Trek Long Island
//
//  Created by Bryan on 6/28/25.
//


import Foundation

enum Role: String, CaseIterable, Identifiable {
    case guest
    case qvip
    case staff
    case ops

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .guest: return "Guest"
        case .qvip: return "Q-VIP"
        case .staff: return "Staff"
        case .ops: return "Ops"
        }
    }
}
