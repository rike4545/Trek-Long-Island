import SwiftUI

@MainActor
struct TLIWelcomeNoticeView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let onContinue: () -> Void

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
            noticeParagraph("Welcome to the Trek Long Island mobile companion, a real-time guide built to help fans plan the weekend, follow updates, and enjoy Trek Long Island 2026.")

            noticeParagraph("This app is built as a companion guide for the Trek Long Island community. For ticket purchases, schedule changes, policies, and event confirmations, please use the Trek Long Island website and on-site announcements as the source of record.")

            noticeParagraph("If something looks wrong or you have a concern, please contact support or send feedback so it can be reviewed quickly.")

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

            noticeParagraph("Star Trek and related marks belong to their respective owners. This app celebrates the fan community and does not replace event credentials, purchases, or on-site instructions.")
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
                openURL(feedbackURL)
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
