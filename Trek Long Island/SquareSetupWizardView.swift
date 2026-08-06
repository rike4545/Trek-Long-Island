// Copyright Bryan Carroll. All rights reserved.
//
//  SquareSetupWizardView.swift
//  Trek Long Island
//
//  Guided operator setup flow for Square OAuth, webhooks, and ticket sync.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct SquareSetupWizardView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL

    @ObservedObject private var squareIntegration = SquareIntegrationStore.shared
    @ObservedObject private var ticketStore = TicketOpsStore.shared

    @State private var isLaunchingOAuth = false
    @State private var oauthErrorMessage: String?
    @State private var copiedSnippet: String?

    private let projectID = "trek-long-island"
    private let region = "us-central1"
    private let conventionID = TLIEventInfo.current.conventionID

    private var functionsRootURL: String {
        let configured = squareIntegration.connection.backendBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !configured.isEmpty {
            if configured.contains("squareCRMCustomerSync") || configured.contains("squareTicketOrderSync") {
                return configured.replacingOccurrences(of: "/squareCRMCustomerSync", with: "")
                    .replacingOccurrences(of: "/squareTicketOrderSync", with: "")
            }
            return configured
        }
        return "https://\(region)-\(projectID).cloudfunctions.net"
    }

    private var oauthCallbackURL: String {
        "\(functionsRootURL)/squareOAuthCallback?conventionID=\(conventionID)"
    }

    private var webhookURL: String {
        "\(functionsRootURL)/squareWebhook"
    }

    private var commandBlock: String {
        """
        cd "/Users/bryan/Desktop/App Development/Trek Long Island"
        firebase use \(projectID)
        firebase functions:secrets:set SQUARE_APP_ID
        firebase functions:secrets:set SQUARE_APP_SECRET
        firebase functions:secrets:set SQUARE_WEBHOOK_SIGNATURE_KEY
        npm --prefix functions run build
        firebase deploy --only functions
        """
    }

    private var seedCommand: String {
        """
        export GOOGLE_APPLICATION_CREDENTIALS="/absolute/path/to/service-account.json"
        node scripts/seed_square_integration.mjs \(projectID) \(region) sandbox
        """
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard
                statusCard
                deployStepCard
                seedStepCard
                oauthStepCard
                webhookStepCard
                importStepCard
                goLiveCard
            }
            .adaptiveContentWidth(
                maxWidth: TLILayout.tightContentMaxWidth + 120,
                horizontalPadding: 20,
                verticalPadding: 16
            )
            .padding(.bottom, 28)
        }
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        .navigationTitle("Square Setup Wizard")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .alert("Square Connect", isPresented: Binding(
            get: { oauthErrorMessage != nil },
            set: { if !$0 { oauthErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(oauthErrorMessage ?? "")
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Square Setup Wizard")
                .font(.largeTitle.bold())
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Walk through deploy, Firestore setup, seller OAuth, webhook registration, and ticket import without leaving the app blind to status.")
                .font(.callout)
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
        .padding(18)
        .tliPanelSurface(cornerRadius: 28, fillOpacity: 0.98, borderOpacity: 0.92, shadowRadius: 16, shadowY: 8)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Current Integration Status", systemImage: statusSymbol)
                .font(.headline.weight(.semibold))
                .foregroundStyle(statusColor)

            Text(squareIntegration.connection.statusSummary)
                .font(.footnote)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            HStack(spacing: 10) {
                badge(title: "CMS Sync", value: squareIntegration.connection.cmsSyncEnabled ? "On" : "Off")
                badge(title: "Ticket Sync", value: squareIntegration.connection.canSyncOrders ? "Ready" : "Not Ready")
                badge(title: "Orders", value: "\(ticketStore.tally.orderCount)")
            }
        }
        .padding(16)
        .tliPanelSurface(cornerRadius: 24, fillOpacity: 0.98, borderOpacity: 0.84, shadowRadius: 12, shadowY: 6)
    }

    private var deployStepCard: some View {
        wizardStep(
            number: 1,
            title: "Deploy Firebase Functions",
            detail: "Run this once after updating Square backend code or secrets."
        ) {
            commandSnippet(commandBlock, copyLabel: "Copy Deploy Commands")
        }
    }

    private var seedStepCard: some View {
        wizardStep(
            number: 2,
            title: "Seed Firestore Integration Doc",
            detail: "This writes the Square integration document the app watches for status, capabilities, and URLs."
        ) {
            commandSnippet(seedCommand, copyLabel: "Copy Seed Command")
        }
    }

    private var oauthStepCard: some View {
        wizardStep(
            number: 3,
            title: "Connect Seller Account",
            detail: "Launch Square OAuth after deploy and Firestore seeding. This should flip the integration status to Connected."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                keyValue(label: "Callback URL", value: oauthCallbackURL)

                HStack(spacing: 10) {
                    Button {
                        Task { await launchSellerOAuth() }
                    } label: {
                        Label(isLaunchingOAuth ? "Launching..." : "Launch Seller Connect", systemImage: "link.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLaunchingOAuth)

                    Button {
                        copyToClipboard(oauthCallbackURL, label: "Callback URL")
                    } label: {
                        Label("Copy Callback URL", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var webhookStepCard: some View {
        wizardStep(
            number: 4,
            title: "Register Square Webhooks",
            detail: "In Square Developer Console, subscribe the app to payment and order updates so ticket records can materialize automatically."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                keyValue(label: "Webhook URL", value: webhookURL)
                keyValue(label: "Recommended Events", value: "payment.updated, order.updated")

                Button {
                    copyToClipboard(webhookURL, label: "Webhook URL")
                } label: {
                    Label("Copy Webhook URL", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var importStepCard: some View {
        wizardStep(
            number: 5,
            title: "Backfill Ticket Orders",
            detail: "Once connected, import existing Square ticket purchases into the Firestore ticket store used by QR Tools."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    Task { await ticketStore.importSquareOrders() }
                } label: {
                    Label("Import Square Orders Now", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!squareIntegration.connection.canSyncOrders)

                if let lastSquareImportMessage = ticketStore.lastSquareImportMessage {
                    Text(lastSquareImportMessage)
                        .font(.caption)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
            }
        }
    }

    private var goLiveCard: some View {
        wizardStep(
            number: 6,
            title: "Go Live Checklist",
            detail: "Confirm these before staff rely on the Square ticket path."
        ) {
            VStack(alignment: .leading, spacing: 8) {
                checklistRow("Functions deployed", completed: true)
                checklistRow("Square integration enabled in Ops Center", completed: squareIntegration.connection.cmsSyncEnabled)
                checklistRow("Seller account connected", completed: squareIntegration.connection.status == .connected)
                checklistRow("Order sync ready", completed: squareIntegration.connection.canSyncOrders)
                checklistRow("At least one ticket order imported", completed: ticketStore.orders.contains(where: { $0.source.lowercased() == "square" }))
            }
        }
    }

    private func wizardStep<Content: View>(
        number: Int,
        title: String,
        detail: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(number)")
                    .font(.headline.weight(.bold))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(TLITheme.accent(scheme)))
                    .foregroundStyle(Color.black)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
            }

            content()

            if let copiedSnippet {
                Text("Copied: \(copiedSnippet)")
                    .font(.caption)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }
        }
        .padding(16)
        .tliPanelSurface(cornerRadius: 24, fillOpacity: 0.98, borderOpacity: 0.82, shadowRadius: 10, shadowY: 5)
    }

    private func commandSnippet(_ value: String, copyLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                Text(value)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(TLITheme.cardBackground(scheme)))
            }

            Button {
                copyToClipboard(value, label: copyLabel)
            } label: {
                Label(copyLabel, systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
        }
    }

    private func keyValue(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLITheme.textSecondary(scheme))
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .textSelection(.enabled)
        }
    }

    private func checklistRow(_ title: String, completed: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(completed ? .green : TLITheme.textSecondary(scheme))
            Text(title)
                .font(.footnote)
                .foregroundStyle(TLITheme.textPrimary(scheme))
        }
    }

    private func badge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLITheme.textSecondary(scheme))
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(TLITheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var statusSymbol: String {
        switch squareIntegration.connection.status {
        case .connected: return "link.circle.fill"
        case .pending: return "hourglass.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .disconnected: return "link.badge.minus"
        }
    }

    private var statusColor: Color {
        switch squareIntegration.connection.status {
        case .connected: return .green
        case .pending: return .orange
        case .error: return .red
        case .disconnected: return TLITheme.textSecondary(scheme)
        }
    }

    private func copyToClipboard(_ value: String, label: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = value
        #endif
        copiedSnippet = label
    }

    private func launchSellerOAuth() async {
        isLaunchingOAuth = true
        defer { isLaunchingOAuth = false }

        let urlString = "\(functionsRootURL)/squareAuthorizeURL?conventionID=\(conventionID)"
        guard let requestURL = URL(string: urlString) else {
            oauthErrorMessage = "The Square authorize URL is invalid."
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: requestURL)
            guard let http = response as? HTTPURLResponse else {
                oauthErrorMessage = "Square authorize response was invalid."
                return
            }

            struct AuthorizePayload: Decodable {
                let authorizeURL: String?
                let error: String?
            }

            let payload = try JSONDecoder().decode(AuthorizePayload.self, from: data)
            guard (200...299).contains(http.statusCode), let authorizeURL = payload.authorizeURL, let url = URL(string: authorizeURL) else {
                oauthErrorMessage = payload.error ?? "Square authorization URL was not returned."
                return
            }

            openURL(url)
        } catch {
            oauthErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SquareSetupWizardView()
    }
}
