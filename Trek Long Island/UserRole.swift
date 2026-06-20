// Copyright Bryan Carroll. All rights reserved.
// UserRole.swift

import Foundation
import SwiftUI

enum UserRole: String, Codable, Equatable {
    case user
    case admin
    case superAdmin
    case none
}

final class AppState: ObservableObject {
    /// When the app starts, nobody is “admin.” We treat `.none` or `.user` interchangeably for non-admin.
    @Published var currentRole: UserRole = .none
}

final class AdminPinStore {
    static let shared = AdminPinStore()
    private init() { }

    /// Local fallback PINs for legacy admin access.
    private let adminPIN = "83106803"
    private let superAdminPIN = "90979747"

    func role(for pin: String) -> UserRole {
        if pin == superAdminPIN {
            return .superAdmin
        } else if pin == adminPIN {
            return .admin
        } else {
            return .none
        }
    }
}
