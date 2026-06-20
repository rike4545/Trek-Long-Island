// Copyright Bryan Carroll. All rights reserved.
//
//  AdminLevel.swift
//  Trek Long Island
//
//  Created by Bryan on 6/28/25.
//


import Foundation

/// Represents legacy administrative access levels.
enum AdminLevel: String, CaseIterable {
    case staff1
    case staff2
    case staff3
    case staff4
}

/// Legacy placeholder kept so older references continue to compile.
/// Coordinator authentication is now handled by Firebase allowlisted accounts.
struct AdminPasswordConfig {
    static let passwords: [String: AdminLevel] = [:]

    static let qvipPassword = ""
}
