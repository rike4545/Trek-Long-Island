import SwiftUI

@MainActor
struct DevelopmentSupportLinksView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("App Credits")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RisaTheme.textPrimary(colorScheme))

                Text("Background and attribution for the Trek Long Island companion app.")
                    .font(.subheadline)
                    .foregroundStyle(RisaTheme.textSecondary(colorScheme))

                attributionCard
                supportCard
            }
            .adaptiveContentWidth(
                maxWidth: TLILayout.defaultContentMaxWidth,
                horizontalPadding: 18,
                verticalPadding: 16
            )
        }
        .background(
            LinearGradient(
                colors: RisaTheme.backgroundGradientColors(for: colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("App Credits")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var attributionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Attribution")
                .font(.headline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(colorScheme))

            Text("Designed on Long Island, New York. Coded by Bryan Carroll.")
                .font(.subheadline)
                .foregroundStyle(RisaTheme.textPrimary(colorScheme))

            Text("This app is maintained as a companion for Trek Long Island attendees, with a focus on schedule access, venue guidance, and convention updates.")
                .font(.subheadline)
                .foregroundStyle(RisaTheme.textSecondary(colorScheme))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RisaTheme.cardBackground(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.07), lineWidth: 1)
        )
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Support The Developer", systemImage: "heart.circle.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(colorScheme))

            Text("Using optional partner links helps support ongoing maintenance, updates, and response time for this independent companion app.")
                .font(.subheadline)
                .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Link(destination: URL(string: "https://linktr.ee/teslafi")!) {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.car.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Developer Support Links")
                            .font(.subheadline.weight(.bold))
                        Text("Optional support link")
                            .font(.caption.weight(.semibold))
                            .opacity(0.78)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right")
                        .font(.footnote.weight(.bold))
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(RisaTheme.accent(colorScheme))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RisaTheme.cardBackground(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.07), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        DevelopmentSupportLinksView()
    }
    .preferredColorScheme(.dark)
}
