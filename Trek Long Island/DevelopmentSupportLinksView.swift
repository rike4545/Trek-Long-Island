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
}

#Preview {
    NavigationStack {
        DevelopmentSupportLinksView()
    }
    .preferredColorScheme(.dark)
}
