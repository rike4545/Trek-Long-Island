// Copyright Bryan Carroll. All rights reserved.
//
//  ExhibitorsGridView.swift
//  Trek Long Island
//
//  Exhibitor grid used by ExhibitorListView / Explore.
//  - Search-aware
//  - 2-column adaptive grid
//  - TLI glass cards, dark-mode friendly
//  - No placeholder exhibitors; expects real data injected
//

import SwiftUI

struct ExhibitorsGridView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Binding var searchText: String

    // MARK: - Model

    struct Exhibitor: Identifiable, Hashable {
        let name: String
        let imageName: String?   // optional exhibitor logo / table photo
        let blurb: String?
        var id: String { [name, imageName ?? "", blurb ?? ""].joined(separator: "|") }
    }

    /// Real exhibitor data should be passed in from a store or JSON.
    /// Defaults to empty so there are NO placeholder exhibitors.
    var exhibitors: [Exhibitor] = []

    private var columns: [GridItem] {
        TLILayout.adaptiveColumns(
            for: hSizeClass,
            compactMinimum: 150,
            regularMinimum: 220,
            regularMaximum: 320,
            spacing: 14
        )
    }

    // MARK: - Derived

    private var filteredExhibitors: [Exhibitor] {
        guard !exhibitors.isEmpty else { return [] }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return exhibitors }

        return exhibitors.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            ($0.blurb ?? "").localizedCaseInsensitiveContains(q)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            header

            if exhibitors.isEmpty {
                emptyStateNoData
                    .padding(.top, 24)
            } else if filteredExhibitors.isEmpty {
                emptyStateNoMatches
                    .padding(.top, 24)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, alignment: .center, spacing: 14) {
                        ForEach(filteredExhibitors) { exhibitor in
                            ExhibitorCard(exhibitor: exhibitor, scheme: scheme)
                        }
                    }
                    .adaptiveContentWidth(
                        maxWidth: 1120,
                        horizontalPadding: 16,
                        verticalPadding: 0
                    )
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(TLILCARSLabel.exhibitors)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                if exhibitors.isEmpty {
                    Text(RisaTheme.isLCARSThemeEnabled
                         ? "Registry entries will be published closer to the event."
                         : "Exhibitors will be announced closer to the event.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text(RisaTheme.isLCARSThemeEnabled
                         ? "\(filteredExhibitors.count) registry entr\(filteredExhibitors.count == 1 ? "y" : "ies") showing"
                         : "\(filteredExhibitors.count) exhibitor\(filteredExhibitors.count == 1 ? "" : "s") showing")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .tliLCARSPanelChrome(
            accent: RisaTheme.accent(scheme),
            contentTopInset: 24
        )
    }

    private var emptyStateNoData: some View {
        VStack(spacing: 10) {
            Image(systemName: "shippingbox")
                .imageScale(.large)
                .foregroundStyle(.secondary)
            Text("No exhibitors listed yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Check back as we get closer to the convention for our full exhibitor lineup.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var emptyStateNoMatches: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.magnifyingglass")
                .imageScale(.large)
                .foregroundStyle(.secondary)
            Text("No exhibitors match your search.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Try a different name or clear your filters.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}

// MARK: - Card

private struct ExhibitorCard: View {
    let exhibitor: ExhibitorsGridView.Exhibitor
    let scheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let imageName = exhibitor.imageName, !imageName.isEmpty {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .clipped()
                } else {
                    // Fallback gradient tile (no placeholder *name*, just a generic tile)
                    LinearGradient(
                        colors: [
                            TLITheme.accent(scheme).opacity(0.45),
                            TLITheme.accent(scheme).opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "bag.fill")
                            .imageScale(.large)
                            .foregroundStyle(.white.opacity(0.9))
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(exhibitor.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            if let blurb = exhibitor.blurb, !blurb.isEmpty {
                Text(blurb)
                    .font(.footnote)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .tliCard()
        .tliLCARSPanelChrome(
            accent: RisaTheme.accentSecondary(scheme)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(exhibitor.blurb == nil ? exhibitor.name : "\(exhibitor.name). \(blurbSafe)")
    }

    private var blurbSafe: String {
        exhibitor.blurb ?? ""
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        TLITheme.backgroundGradient(.dark)
        ExhibitorsGridView(searchText: .constant(""), exhibitors: [])
            .environment(\.colorScheme, .dark)
    }
}
