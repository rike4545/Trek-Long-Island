// Copyright Bryan Carroll. All rights reserved.
//
//  AuthViewModel.swift
//  Trek Long Island
//
//  Created by Bryan on 6/7/25.
//


import Foundation
import Combine

/// AuthViewModel manages user authentication state and role flags across the app.
/// Use this ObservableObject to publish changes to authentication status and roles.
final class AuthViewModel: ObservableObject {
    /// Indicates whether the current user has super admin privileges.
    @Published var isSuperAdmin: Bool = false
    
    // MARK: - Initialization
    init(isSuperAdmin: Bool = false) {
        self.isSuperAdmin = isSuperAdmin
    }
    
    // MARK: - Authentication Actions
    /// Call this to update the super admin flag after verifying credentials.
    func updateSuperAdminStatus(_ status: Bool) {
        isSuperAdmin = status
    }
}
