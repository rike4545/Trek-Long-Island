// Copyright Bryan Carroll. All rights reserved.
//
//  RisaZenMode.swift
//  Trek Long Island
//
//  Created by Bryan on 1/31/26.
//


//
//  RisaZenMode.swift
//  Trek Long Island
//
//  Zen backdrop modes for the Risa Captain’s Chair moment.
//  Swift 6 • iOS 17+
//

import Foundation

enum RisaZenMode: String, CaseIterable, Hashable, Identifiable {
    case sunsetCruise
    case oceanBreeze
    case nightLanterns

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sunsetCruise:  return "Sunset"
        case .oceanBreeze:   return "Breeze"
        case .nightLanterns: return "Night"
        }
    }
}
