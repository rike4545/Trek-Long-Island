// Copyright Bryan Carroll. All rights reserved.
//
//  AdminLevel.swift
//  Trek Long Island
//
//  Created by Bryan on 6/28/25.
//


import Foundation

/// Represents different levels of administrative access.
enum AdminLevel: String, CaseIterable {
    case staff1
    case staff2
    case staff3
    case staff4
}

/// Centralized configuration for admin passwords and their corresponding access level.
struct AdminPasswordConfig {
    /// A dictionary mapping passwords (lowercased) to `AdminLevel`.
    static let passwords: [String: AdminLevel] = [
        "Qq96jboduGuIGRUz": .staff1,
        "gcAsF8VqZV1rynvJ": .staff2,
        "FRXpO4qhI2gLnqCP": .staff3,
        "Gf98I9HpLLPpBY33": .staff4
    ]

    /// The QVIP password (handled separately in logic).
    static let qvipPassword = "Sgd8tFEBdATPv4DkWz"
}
