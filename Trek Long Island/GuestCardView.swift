// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

struct GuestCardView: View {
    @Environment(\.colorScheme) private var scheme

    let guest: Guest
    let accentColor: Color
    let isFavorited: Bool
    let toggleFavorite: () -> Void
    let onDoubleTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                portrait
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(TLITheme.border(scheme), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(guest.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)

                        Spacer(minLength: 8)

                        // 44pt target, never overlaps text due to Spacer()
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                toggleFavorite()
                            }
                        }) {
                            favoriteIcon
                                .frame(width: 44, height: 44)
                                .background(
                                    .thinMaterial,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(TLITheme.border(scheme), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            isFavorited ? "Remove from favorites" : "Add to favorites"
                        )
                    }

                    Text(guest.displayRole)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)

                    if let series = guest.displaySeries {
                        Text(series)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                    }

                    if let pricingNote = guest.resolvedTablePricingNote {
                        Label(pricingNote, systemImage: "signature")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TLITheme.accent(scheme))
                            .lineLimit(2)
                    }
                }
            }
            .padding(12)
        }
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            // subtle accent border
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.35), lineWidth: 1)
        )
        .overlay(
            // gentle accent wash from top-left
            LinearGradient(
                colors: [
                    accentColor.opacity(scheme == .dark ? 0.20 : 0.12),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .allowsHitTesting(false)
        )
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.35 : 0.15),
            radius: scheme == .dark ? 5 : 3,
            y: 3
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: onDoubleTap)
        .contextMenu {
            Button(isFavorited ? "Remove Favorite" : "Add Favorite", action: toggleFavorite)
            Button("View Details", systemImage: "person.text.rectangle", action: onDoubleTap)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double-tap to view details.")
    }

    // MARK: - Portrait

    @ViewBuilder
    private var portrait: some View {
        if let name = guest.imageName, !name.isEmpty {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        accentColor.opacity(0.35),
                        accentColor.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text(monogram(from: guest.name))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
    }

    // MARK: - Favorite icon (with iOS 17 bounce where available)

    @ViewBuilder
    private var favoriteIcon: some View {
        let base = Image(systemName: isFavorited ? "star.fill" : "star")
            .font(.headline)
            .foregroundStyle(isFavorited ? .yellow : TLITheme.textSecondary(scheme))

        if #available(iOS 17.0, *) {
            base.symbolEffect(.bounce, value: isFavorited)
        } else {
            base
        }
    }

    private func monogram(from name: String) -> String {
        let comps = name.split(separator: " ")
        let first = comps.first?.prefix(1) ?? "?"
        let last  = comps.dropFirst().first?.prefix(1) ?? ""
        return String(first + last)
    }
}
