// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

struct PicardDayBannerView: View {
    @Environment(\.colorScheme) private var scheme

    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image("picard_day")
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(TLITheme.border(scheme).opacity(0.75), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Label("Ceremonial Alert", systemImage: "star.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TLITheme.accent(scheme))

                    Text("USS Enterprise-D")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(TLITheme.chipBackground(scheme).opacity(0.92))
                        )
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                }

                Text("Captain Picard Day")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text("June 16 • Stardate 47457.1")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textSecondary(scheme))

                Text("A shipwide morale holiday honoring Jean-Luc Picard with banners, crafts, and the exact amount of ceremony he would never request.")
                    .font(.footnote)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss Captain Picard Day banner")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(TLITheme.cardBackground(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            Capsule(style: .continuous)
                .fill(TLITheme.sectionAccentGradient(scheme))
                .frame(width: 72, height: 8)
                .padding(.top, 12)
                .padding(.leading, 16)
        }
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.26 : 0.10),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}
