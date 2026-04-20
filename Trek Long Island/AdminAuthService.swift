// Copyright Bryan Carroll. All rights reserved.
//
//  AdminAuthService.swift
//  Trek Long Island
//
//  Firebase-backed coordinator authentication + approval checks.
//

import Foundation
import FirebaseFirestore
import LocalAuthentication

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

@MainActor
final class AdminAuthService: ObservableObject {
    enum Status: Equatable {
        case unavailable
        case signedOut
        case signingIn
        case checkingApproval
        case approved(NotificationManager.AdminLevel)
        case signedInNotApproved
    }

    static let shared = AdminAuthService()

    @Published private(set) var status: Status = .signedOut
    @Published private(set) var signedInEmail: String?
    @Published private(set) var lastError: String?

    private let db = Firestore.firestore()
    private let conventionID = "trekli-2026"

    #if canImport(FirebaseAuth)
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    #endif

    private init() {
        #if canImport(FirebaseAuth)
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                self.signedInEmail = user?.email
                if user == nil {
                    self.status = .signedOut
                    self.lastError = nil
                    NotificationManager.shared.lockAdmin()
                } else {
                    await self.refreshApproval()
                }
            }
        }
        #else
        status = .unavailable
        lastError = "FirebaseAuth SDK is not linked in this build."
        #endif
    }

    deinit {
        #if canImport(FirebaseAuth)
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
        #endif
    }

    var isSignedIn: Bool {
        switch status {
        case .approved, .signedInNotApproved, .checkingApproval:
            return true
        default:
            return false
        }
    }

    var approvedRole: NotificationManager.AdminLevel? {
        if case .approved(let role) = status {
            return role
        }
        return nil
    }

    var isApproved: Bool {
        approvedRole != nil
    }

    func signIn(email: String, password: String) async {
        #if canImport(FirebaseAuth)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            lastError = "Enter both email and password."
            return
        }

        status = .signingIn
        lastError = nil

        do {
            let result = try await Auth.auth().signIn(withEmail: normalizedEmail, password: password)
            signedInEmail = result.user.email
            await refreshApproval()
        } catch {
            status = .signedOut
            lastError = error.localizedDescription
        }
        #else
        status = .unavailable
        lastError = "FirebaseAuth SDK is not linked in this build."
        #endif
    }

    func signOut() {
        #if canImport(FirebaseAuth)
        do {
            try Auth.auth().signOut()
        } catch {
            lastError = error.localizedDescription
        }
        status = .signedOut
        signedInEmail = nil
        NotificationManager.shared.lockAdmin()
        #else
        status = .unavailable
        #endif
    }

    func refreshApproval() async {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            status = .signedOut
            signedInEmail = nil
            NotificationManager.shared.lockAdmin()
            return
        }

        status = .checkingApproval
        signedInEmail = user.email
        lastError = nil

        do {
            if let resolvedRole = try await resolveApprovedRole(for: user) {
                status = .approved(resolvedRole)
                if NotificationManager.shared.adminLevel == .none {
                    NotificationManager.shared.activateApprovedAdminSession(level: resolvedRole)
                }
            } else {
                status = .signedInNotApproved
                NotificationManager.shared.lockAdmin()
                lastError = "This account is signed in, but not approved for coordinator access."
            }
        } catch {
            status = .signedInNotApproved
            NotificationManager.shared.lockAdmin()
            lastError = "Approval check failed: \(error.localizedDescription)"
        }
        #else
        status = .unavailable
        lastError = "FirebaseAuth SDK is not linked in this build."
        #endif
    }

    func resumeProtectedSession() async -> Bool {
        guard let role = approvedRole else {
            lastError = "Sign in with an approved coordinator account first."
            return false
        }

        if await performDeviceOwnerAuthentication() {
            NotificationManager.shared.activateApprovedAdminSession(level: role)
            lastError = nil
            return true
        }

        return false
    }

    private func performDeviceOwnerAuthentication() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var evaluationError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &evaluationError) else {
            // On devices without passcode/biometrics configured, allow approved accounts
            // to continue while still requiring Firebase identity + allowlist checks.
            return true
        }

        do {
            let reason = "Re-authenticate to unlock coordinator tools."
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if !success {
                lastError = "Device authentication failed."
            }
            return success
        } catch {
            lastError = "Device authentication failed: \(error.localizedDescription)"
            return false
        }
    }

    #if canImport(FirebaseAuth)
    private func resolveApprovedRole(for user: FirebaseAuth.User) async throws -> NotificationManager.AdminLevel? {
        let tokenResult = try await user.getIDTokenResult(forcingRefresh: true)
        if let claimsRole = roleFromCustomClaims(tokenResult.claims) {
            return claimsRole
        }

        // Primary allowlist doc: conventions/{id}/coordinator_allowlist/{uid}
        let conventionDoc = try await db
            .collection("conventions")
            .document(conventionID)
            .collection("coordinator_allowlist")
            .document(user.uid)
            .getDocument()

        if let role = roleFromAllowlistDocument(conventionDoc) {
            return role
        }

        // Global fallback: coordinator_allowlist/{uid}
        let globalDoc = try await db
            .collection("coordinator_allowlist")
            .document(user.uid)
            .getDocument()

        return roleFromAllowlistDocument(globalDoc)
    }

    private func roleFromCustomClaims(_ claims: [String: Any]) -> NotificationManager.AdminLevel? {
        let approvedFlag = (claims["adminApproved"] as? Bool) ?? (claims["coordinatorApproved"] as? Bool) ?? false
        guard approvedFlag else { return nil }

        let roleValue = (claims["adminRole"] as? String) ?? (claims["coordinatorRole"] as? String)
        return mapRole(roleValue) ?? .reviewer
    }
    #endif

    private func roleFromAllowlistDocument(_ snapshot: DocumentSnapshot) -> NotificationManager.AdminLevel? {
        guard snapshot.exists, let data = snapshot.data() else { return nil }

        let isApproved = (data["approved"] as? Bool)
            ?? (data["isApproved"] as? Bool)
            ?? true

        guard isApproved else { return nil }

        let disabled = (data["disabled"] as? Bool) ?? false
        guard !disabled else { return nil }

        let roleString = data["role"] as? String
        return mapRole(roleString) ?? .reviewer
    }

    private func mapRole(_ raw: String?) -> NotificationManager.AdminLevel? {
        guard let raw else { return nil }
        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case "watcher", "staff", "ops":
            return .watcher
        case "notifier":
            return .notifier
        case "reviewer", "admin", "coordinator":
            return .reviewer
        case "superadmin", "super_admin", "master", "owner":
            return .superAdmin
        default:
            return nil
        }
    }
}
