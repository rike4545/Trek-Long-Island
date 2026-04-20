// Copyright Bryan Carroll. All rights reserved.
//
//  CoordinatorAccessView.swift
//  Trek Long Island
//
//  Firebase sign-in and secure session controls for coordinator tools.
//

import SwiftUI

@MainActor
struct CoordinatorAccessView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var adminAuth = AdminAuthService.shared
    @ObservedObject private var notifications = NotificationManager.shared

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isWorking = false

    var onSessionActivated: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                accountStatusSection
                actionSection
            }
            .navigationTitle("Coordinator Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var accountStatusSection: some View {
        Section("Status") {
            switch adminAuth.status {
            case .unavailable:
                statusRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Firebase Auth Unavailable",
                    detail: adminAuth.lastError ?? "This build cannot present coordinator sign-in."
                )

            case .signedOut:
                statusRow(
                    icon: "person.badge.key.fill",
                    title: "Signed Out",
                    detail: "Sign in with an approved coordinator account to unlock tools."
                )

            case .signingIn:
                statusRow(
                    icon: "hourglass",
                    title: "Signing In",
                    detail: "Verifying your account credentials."
                )

            case .checkingApproval:
                statusRow(
                    icon: "checkmark.shield",
                    title: "Checking Approval",
                    detail: "Validating allowlist role for this account."
                )

            case .signedInNotApproved:
                statusRow(
                    icon: "xmark.shield.fill",
                    title: "Not Approved",
                    detail: adminAuth.lastError ?? "This account is not allowlisted for coordinator tools."
                )

            case .approved(let role):
                let sessionText = notifications.adminLevel == .none ? "Quick protection lock is active." : "Coordinator session is active."
                statusRow(
                    icon: notifications.adminLevel == .none ? "lock.fill" : "lock.open.fill",
                    title: "Approved as \(roleTitle(role))",
                    detail: sessionText
                )
            }

            if let email = adminAuth.signedInEmail, !email.isEmpty {
                LabeledContent("Account", value: email)
                    .font(.footnote)
            }
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        switch adminAuth.status {
        case .signedOut:
            Section("Sign In") {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)

                SecureField("Password", text: $password)

                Button {
                    Task {
                        await signIn()
                    }
                } label: {
                    if isWorking {
                        ProgressView()
                    } else {
                        Text("Sign In")
                    }
                }
                .disabled(isWorking || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
            }

        case .signingIn, .checkingApproval:
            Section {
                ProgressView("Working…")
            }

        case .signedInNotApproved:
            Section("Account") {
                Button("Refresh Approval") {
                    Task { await adminAuth.refreshApproval() }
                }

                Button("Sign Out", role: .destructive) {
                    adminAuth.signOut()
                }
            }

        case .approved:
            Section("Session") {
                if notifications.adminLevel == .none {
                    Button("Resume Secure Session") {
                        Task {
                            let unlocked = await adminAuth.resumeProtectedSession()
                            if unlocked {
                                onSessionActivated?()
                                dismiss()
                            }
                        }
                    }
                } else {
                    Button("Lock Session", role: .destructive) {
                        notifications.lockAdmin()
                    }
                }

                Button("Refresh Approval") {
                    Task { await adminAuth.refreshApproval() }
                }

                Button("Sign Out", role: .destructive) {
                    adminAuth.signOut()
                    dismiss()
                }
            }

        case .unavailable:
            Section {
                Text(adminAuth.lastError ?? "This build does not include FirebaseAuth.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func signIn() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        await adminAuth.signIn(email: email, password: password)

        if adminAuth.isApproved {
            password = ""
            onSessionActivated?()
            dismiss()
        }
    }

    private func statusRow(icon: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))

            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func roleTitle(_ role: NotificationManager.AdminLevel) -> String {
        switch role {
        case .none:
            return "Locked"
        case .watcher:
            return "Watcher"
        case .notifier:
            return "Notifier"
        case .reviewer:
            return "Reviewer"
        case .superAdmin:
            return "Master"
        }
    }
}

#Preview {
    CoordinatorAccessView()
}
