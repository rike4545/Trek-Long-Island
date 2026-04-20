// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

// MARK: - Detail

struct GuestDetailView: View {
    @Environment(\.colorScheme) private var scheme

    let guest: Guest
    let accentColor: Color   // pass in from caller (derived from guest.accentHex or theme)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroSection
                if let cancellationLabel = guest.cancellationLabel {
                    statusSection(cancellationLabel)
                }
                if let availabilityDetail = guest.availabilityDetail {
                    availabilitySection(availabilityDetail)
                }
                if let pricingNote = guest.resolvedTablePricingNote {
                    tablePricingSection(pricingNote)
                }
                aboutSection
                if let note = guest.memoryAlphaNote {
                    memoryAlphaSection(note)
                }
                if hasAnyLinks { linksSection }
                Spacer(minLength: 24)
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
            .padding(.horizontal, 20)
        }
        .background(
            ZStack {
                TLITheme.backgroundGradient(scheme)

                // Subtle wash for readability; a bit stronger in dark mode
                if scheme == .dark {
                    Color.black.opacity(0.30)
                } else {
                    Color.black.opacity(0.05)
                }
            }
            .ignoresSafeArea()
        )
        .navigationTitle(guest.name)
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            heroImage
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(scheme == .dark ? 0.32 : 0.16),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentColor.opacity(0.45), lineWidth: 2)
                )
                .shadow(
                    color: .black.opacity(scheme == .dark ? 0.38 : 0.20),
                    radius: 8,
                    x: 0,
                    y: 6
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(guest.name)
                    .font(.title.bold())
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(guest.displayRole)
                    .font(.headline)
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                if let series = guest.displaySeries {
                    Text(series)
                        .font(.subheadline)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private var heroImage: some View {
        if let name = guest.imageName, !name.isEmpty {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        accentColor.opacity(0.40),
                        accentColor.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text(monogram(from: guest.name))
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(linkedBio(guest.bio))
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.30 : 0.10),
            radius: 6,
            y: 3
        )
    }

    private func statusSection(_ statusMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Guest Update")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Label(statusMessage, systemImage: guest.status.systemImage)
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.red.opacity(0.45), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.30 : 0.10),
            radius: 6,
            y: 3
        )
    }

    private func tablePricingSection(_ pricingNote: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Autographs & Selfies")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Label(pricingNote, systemImage: "signature")
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.30 : 0.10),
            radius: 6,
            y: 3
        )
    }

    private func availabilitySection(_ availabilityDetail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Availability")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Label(availabilityDetail, systemImage: "calendar")
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.30 : 0.10),
            radius: 6,
            y: 3
        )
    }

    private func memoryAlphaSection(_ note: MemoryAlphaNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Star Trek Notes")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(note.summary)
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            if let url = URL(string: note.sourceURL) {
                Link(destination: url) {
                    Label("Open Memory Alpha", systemImage: "book")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .tint(accentColor)
            }
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.30 : 0.10),
            radius: 6,
            y: 3
        )
    }

    private func linkedBio(_ bio: String) -> AttributedString {
        var attributed = AttributedString(bio)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return attributed
        }

        let range = NSRange(bio.startIndex..., in: bio)
        for match in detector.matches(in: bio, options: [], range: range) {
            guard let url = match.url,
                  let stringRange = Range(match.range, in: bio),
                  let lower = AttributedString.Index(stringRange.lowerBound, within: attributed),
                  let upper = AttributedString.Index(stringRange.upperBound, within: attributed) else {
                continue
            }
            attributed[lower..<upper].link = url
        }

        return attributed
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Links")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            LinksWrapLayout(spacing: 10) {
                if let x = guest.twitterURL {
                    SocialLinkButton(
                        title: "X / Twitter",
                        systemImage: "link",
                        url: x
                    )
                }
                if let ig = guest.instagramURL {
                    SocialLinkButton(
                        title: "Instagram",
                        systemImage: "camera",
                        url: ig
                    )
                }
                if let imdb = guest.imdbURL {
                    SocialLinkButton(
                        title: "IMDb",
                        systemImage: "film",
                        url: imdb
                    )
                }
                if let memoryAlpha = guest.memoryAlphaURL {
                    SocialLinkButton(
                        title: "Memory Alpha",
                        systemImage: "book",
                        url: memoryAlpha
                    )
                }
            }
            .tint(accentColor)
        }
        .padding(16)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.30 : 0.10),
            radius: 6,
            y: 3
        )
    }

    // MARK: - Helpers

    private var hasAnyLinks: Bool {
        guest.twitterURL != nil || guest.instagramURL != nil || guest.imdbURL != nil || guest.memoryAlphaURL != nil
    }

    private func monogram(from name: String) -> String {
        let comps = name.split(separator: " ")
        let first = comps.first?.prefix(1) ?? "?"
        let last  = comps.dropFirst().first?.prefix(1) ?? ""
        return String(first + last)
    }
}

// MARK: - Social Link Pill

private struct SocialLinkButton: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let systemImage: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    .ultraThinMaterial,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(
                            Color.white.opacity(scheme == .dark ? 0.20 : 0.12),
                            lineWidth: 0.7
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - Wrap (Flow) Layout (iOS 16+)

// Renamed to `LinksWrapLayout` to avoid any “Invalid redeclaration of WrapLayout”
// if you use another flow layout elsewhere in the app.
struct LinksWrapLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? 600
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            let needsWrap = x > 0 && x + spacing + sz.width > maxWidth
            if needsWrap {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            rowHeight = max(rowHeight, sz.height)
            x += (x > 0 ? spacing : 0) + sz.width
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var cursorX = bounds.minX
        var cursorY = bounds.minY
        var rowHeight: CGFloat = 0

        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            let nextX = (cursorX == bounds.minX ? cursorX : cursorX + spacing)

            if nextX + sz.width > bounds.maxX {
                cursorY += rowHeight + spacing
                cursorX = bounds.minX
                rowHeight = 0
            } else {
                cursorX = nextX
            }

            sub.place(
                at: CGPoint(x: cursorX, y: cursorY),
                proposal: ProposedViewSize(width: sz.width, height: sz.height)
            )

            cursorX += sz.width
            rowHeight = max(rowHeight, sz.height)
        }
    }
}
