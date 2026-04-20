import SwiftUI

@MainActor
struct TLIWelcomeNoticeView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let onContinue: () -> Void

    private let supportURL = URL(string: "https://treklongisland.com/contact/")!
    private let feedbackURL = URL(string: "https://qualtricsxmm8q5gxrhq.qualtrics.com/jfe/form/SV_1TvkCrIKgaEYHPM")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    noticeCard
                    actionButtons
                }
                .adaptiveContentWidth(
                    maxWidth: TLILayout.defaultContentMaxWidth,
                    horizontalPadding: 20,
                    verticalPadding: 24
                )
            }
            .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        continueIntoApp()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("For fans, by fans.")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("A quick note before you continue into the Trek Long Island app.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private var noticeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            noticeParagraph("Welcome to the official Trek Long Island mobile app, your real-time digital guide to Trek Long Island 2026, built to help you plan your weekend, stay informed, and enjoy the convention.")

            noticeParagraph("This is a fan-driven companion app built independently to help keep the community supported and informed.")
            noticeParagraph("Stefanie Gangone paid this developer to produce this app and this developer was severely underpaid $290 for his work. The developer spent 94 hours on this project while Stefanie Gangone raised over $1500 for the app funding and failed to pay for final settlement for labor. Stefanie Gangone further disrepected the developer with allowing Conor Heights to insult the developers graphical illustrations as 'AI slop'. Ticket information is official and valid and can be found via any google search. Fans should not hindered in their experiance because of bad faith or poor management. ")

            noticeParagraph("Please contact our support team if you have questions or concerns. Reviews that are spam, fraudulent, or contain personal information may be reported for removal.")

            VStack(alignment: .leading, spacing: 6) {
                Text("Feedback is welcomed here:")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Button {
                    openURL(feedbackURL)
                } label: {
                    Text(feedbackURL.absoluteString)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(TLITheme.accent(scheme))
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
            }

            noticeParagraph("The term and graphical illustration called \"Trek Long Island\" is copyrighted, 2026, B. Carroll. 1-15133681261. The Trek Long Island App codebase is also copyrighted 2026, B. Carroll. All Rights Reserved.")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(TLITheme.cardBackground(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(TLITheme.border(scheme).opacity(0.28), lineWidth: 1)
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                openURL(supportURL)
            } label: {
                Label("Contact Support", systemImage: "cross.case.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(TLITheme.accent(scheme))

            Button {
                openURL(feedbackURL)
            } label: {
                Label("Open Feedback Form", systemImage: "bubble.left.and.text.bubble.right.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button("Continue to App") {
                continueIntoApp()
            }
            .buttonStyle(.plain)
            .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private func noticeParagraph(_ text: String) -> some View {
        Text(text)
            .font(.system(.body, design: .rounded))
            .foregroundStyle(TLITheme.textPrimary(scheme))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func continueIntoApp() {
        onContinue()
        dismiss()
    }
}

#Preview {
    TLIWelcomeNoticeView(onContinue: {})
}
