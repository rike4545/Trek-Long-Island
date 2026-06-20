// Copyright Bryan Carroll. All rights reserved.
//
//  ExhibitorListView.swift
//  Trek Long Island
//

import SwiftUI

struct ExhibitorListView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL

    @State private var searchText: String = ""

    private let signUpURL = URL(string: "https://treklongisland.com/participate/")!
    private let vendorTicketsURL = TicketPurchaseLinks.vendorTablingURL

    // Try common hero asset names; first one found is used
    private let heroCandidates = [
        "ExhibitorsHero", "TLI/ExhibitorsHero", "VendorRoomHero", "ExhibitorsHeroImage", "Exhibitors"
    ]

    var body: some View {
        ZStack {
            ZStack {
                TLITheme.backgroundGradient(scheme)
                if scheme == .dark {
                    Color.black.opacity(0.28)
                }
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // HERO (optional)
                    Hero(image: assetImage(heroCandidates), scheme: scheme)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Title + intro
                    VStack(alignment: .leading, spacing: 10) {
                        Text(RisaTheme.isLCARSThemeEnabled ? "Open Commerce Registry" : "Become an Exhibitor")
                            .font(.largeTitle.bold())
                            .foregroundStyle(TLITheme.textPrimary(scheme))

                        Text(RisaTheme.isLCARSThemeEnabled
                             ? "Interested in joining the commerce registry? We’d love to add your booth, inventory, and mission support to the manifest."
                             : "Interested in exhibiting at Trek Long Island? We’d love to have you join our mission to build an inclusive, welcoming Trek community.")
                            .font(.callout)
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .tliCard()
                    .tliLCARSPanelChrome(
                        accent: RisaTheme.accent(scheme),
                        contentTopInset: 28
                    )
                    .padding(.horizontal, 16)

                    // CTAs
                    VStack(spacing: 12) {
                        Button {
                            openURL(signUpURL)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "globe")
                                Text(RisaTheme.isLCARSThemeEnabled ? "Register Vendor Booth" : "Sign Up to Exhibit")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                TLITheme.accent(scheme),
                                in: TLITheme.controlShape(cornerRadius: 18)
                            )
                            .overlay(
                                TLITheme.controlShape(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .foregroundStyle(Color.black)
                        }
                        .buttonStyle(.plain)

                        Button {
                            openURL(vendorTicketsURL)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "ticket.fill")
                                Text(RisaTheme.isLCARSThemeEnabled ? "Acquire Vendor Access" : "Purchase Vendor Tickets")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                TLITheme.cardBackground(scheme),
                                in: TLITheme.controlShape(cornerRadius: 18)
                            )
                            .overlay(
                                TLITheme.controlShape(cornerRadius: 18)
                                    .stroke(TLITheme.border(scheme), lineWidth: 1)
                            )
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                        }
                        .buttonStyle(.plain)

                        Text(RisaTheme.isLCARSThemeEnabled
                             ? "Already listed? Review the current commerce registry below."
                             : "Already exhibiting? Browse the current exhibitor list below.")
                            .font(.footnote)
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)

                    // Search + grid
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.primary.opacity(0.72))
                            TextField(RisaTheme.isLCARSThemeEnabled ? "Search registry…" : "Search exhibitors…", text: $searchText)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.primary.opacity(0.72))
                                }
                                .accessibilityLabel("Clear search")
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            TLITheme.cardBackground(scheme),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(TLITheme.border(scheme), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)

                        ExhibitorsGridView(searchText: $searchText)
                            .padding(.top, 4)
                    }

                    Spacer(minLength: 12)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(TLILCARSLabel.exhibitors)
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .tliFixedBottomAdSlot()
    }

    // MARK: - Helpers

    private func assetImage(_ candidates: [String]) -> Image? {
        #if canImport(UIKit)
        for name in candidates {
            if let ui = UIImage(named: name) {
                return Image(uiImage: ui)
            }
        }
        #endif
        return nil
    }
}

// MARK: - Subviews

private struct Hero: View {
    let image: Image?
    let scheme: ColorScheme

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let img = image {
                img
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [
                                .black.opacity(0.0),
                                .black.opacity(scheme == .dark ? 0.40 : 0.22)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )
            } else {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(TLITheme.cardBackground(scheme))
                    .frame(height: 150)
                    .shadow(
                        color: TLITheme.cardShadowColor(scheme),
                        radius: scheme == .dark ? 10 : 6,
                        y: 4
                    )
            }

            Text(TLILCARSLabel.exhibitors)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    .ultraThinMaterial,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                )
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .padding(16)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExhibitorListView()
            .environment(\.colorScheme, .dark)
    }
}
