// Copyright Bryan Carroll. All rights reserved.
// ExploreLink.swift

import SwiftUI

// MARK: - Expand/Collapse All Toggle Button
struct ExpandCollapseAllButton: View {
    @Binding var allExpanded: Bool
    @Binding var expandedSections: Set<String>
    let categories: Dictionary<String, [ExploreLink.ExploreItem]>.Keys

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut) {
                if allExpanded {
                    expandedSections.removeAll()
                } else {
                    expandedSections = Set(categories)
                }
                allExpanded.toggle()
            }
        }) {
            HStack {
                Image(systemName: allExpanded ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.headline)
                Text(allExpanded ? "Collapse All" : "Expand All")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color("AccentPrimary"), Color("AccentPrimary").opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
}

// MARK: - Main ExploreLink View
struct ExploreLink: View {
    @AppStorage("exploreExpandedSections") private var storedSections: String = ""
    @AppStorage("lastViewedExploreURL") private var lastViewedURL: String?
    @AppStorage("exploreFavoriteLinksCSV") private var favoriteLinksCSV: String = ""
    @Environment(\.openURL) private var openURL

    struct ExploreItem: Identifiable {
        var id: String { url }
        let title: String
        let url: String
        let systemImage: String
        let category: String
    }

    @State private var expandedSections: Set<String> = []
    @State private var allExpanded: Bool = false
    @State private var searchText: String = ""

    private let itemsByCategory: [String: [ExploreItem]] = [
        "People": [
            .init(
                title: "Celebrity Schedule",
                url: "https://treklongisland.com/celebschedule/",
                systemImage: "person.3.fill",
                category: "People"
            )
        ],
        "Events": [
            .init(
                title: "Schedule",
                url: "https://treklongisland.com/programs/",
                systemImage: "calendar.circle.fill",
                category: "Events"
            ),
            .init(
                title: "Photo Op Schedule",
                url: TicketPurchaseLinks.photoOpScheduleURLString,
                systemImage: "camera.viewfinder",
                category: "Events"
            ),
            .init(
                title: "Cosplay",
                url: "https://treklongisland.com/programs/",
                systemImage: "wand.and.stars",
                category: "Events"
            ),
            .init(
                title: "Kids Events",
                url: "https://treklongisland.com/childrens-events/",
                systemImage: "teddybear.fill",
                category: "Events"
            ),
            .init(
                title: "Vendor/Podcasts",
                url: "https://treklongisland.com/participate/",
                systemImage: "mic.fill",
                category: "Events"
            )
        ],
        "Info": [
            .init(
                title: "Social Media",
                url: "https://www.facebook.com/TrekLongIsland",
                systemImage: "link.circle.fill",
                category: "Info"
            ),
            .init(
                title: "Policies",
                url: "https://treklongisland.com/policies/",
                systemImage: "doc.text.fill",
                category: "Info"
            ),
            .init(
                title: "Sponsorship",
                url: "https://treklongisland.com/sponsorship/",
                systemImage: "bag.fill",
                category: "Info"
            ),
            .init(
                title: "About",
                url: "https://treklongisland.com/about/",
                systemImage: "info.circle.fill",
                category: "Info"
            )
        ]
    ]

    private var favoriteLinks: Set<String> {
        Set(favoriteLinksCSV.split(separator: "|").map(String.init))
    }

    private var filteredItemsByCategory: [String: [ExploreItem]] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasQuery = !query.isEmpty

        let filtered = itemsByCategory.compactMapValues { items -> [ExploreItem] in
            var scoped = items
            if hasQuery {
                scoped = scoped.filter {
                    $0.title.localizedCaseInsensitiveContains(query) ||
                    $0.category.localizedCaseInsensitiveContains(query) ||
                    $0.url.localizedCaseInsensitiveContains(query)
                }
            }
            return scoped.sorted { lhs, rhs in
                let lf = favoriteLinks.contains(lhs.url)
                let rf = favoriteLinks.contains(rhs.url)
                if lf != rf { return lf && !rf }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }

        return filtered.filter { !$0.value.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    ExploreHeroBanner()
                        .padding(.horizontal)

                    // “Reopen Last Viewed” Button
                    if let lastURL = lastViewedURL,
                       let url = URL(string: lastURL) {
                        Button(action: {
                            openURL(url)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                    .font(.headline)
                                Text("Reopen Last Viewed")
                                    .font(.headline)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal)
                            .background(
                                Color("AccentPrimary").opacity(0.9)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                    }

                    // Expand/Collapse All
                    ExpandCollapseAllButton(
                        allExpanded: $allExpanded,
                        expandedSections: $expandedSections,
                        categories: filteredItemsByCategory.keys
                    )

                    // Search
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search explore links…", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color("CardBackground"))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Each category section
                    if filteredItemsByCategory.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "text.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("No links match your search.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 24)
                    }

                    ForEach(filteredItemsByCategory.sorted(by: { $0.key < $1.key }), id: \.key) { category, items in
                        ExploreSection(
                            iconNameForCategory: iconNameForCategory(_:),
                            category: category,
                            items: items,
                            isExpanded: expandedSections.contains(category),
                            toggle: { toggleCategory(category) },
                            favoriteCount: items.filter { favoriteLinks.contains($0.url) }.count,
                            openURL: { urlString in
                                if let url = URL(string: urlString) {
                                    lastViewedURL = url.absoluteString
                                    openURL(url)
                                }
                            },
                            isFavorited: { url in
                                favoriteLinks.contains(url)
                            },
                            toggleFavorite: { item in
                                toggleFavorite(item)
                            }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 48)
                .background(Color("PrimaryBackground").ignoresSafeArea())
            }
            .navigationTitle("")
            // Restore expanded state on appear
            .onAppear {
                if storedSections.isEmpty {
                    expandedSections = Set(filteredItemsByCategory.keys)
                    allExpanded = true
                } else {
                    expandedSections = Set(storedSections.components(separatedBy: ","))
                    allExpanded = expandedSections.count == filteredItemsByCategory.count
                }
            }
            // Save expanded state on disappear
            .onDisappear {
                storedSections = expandedSections.joined(separator: ",")
            }
            .onChange(of: storedSections) { _, newValue in
                let syncedSections = newValue.isEmpty ? Set(filteredItemsByCategory.keys) : Set(newValue.components(separatedBy: ","))
                if syncedSections != expandedSections {
                    expandedSections = syncedSections
                    allExpanded = expandedSections.count == filteredItemsByCategory.count
                }
            }
        }
    }

    // MARK: - Helpers

    private func iconNameForCategory(_ category: String) -> String {
        switch category {
        case "People": return "person.3.fill"
        case "Events": return "sparkles"
        case "Info": return "info.circle.fill"
        default: return "square.stack.fill"
        }
    }

    private func toggleCategory(_ category: String) {
        withAnimation(.easeInOut) {
            if expandedSections.contains(category) {
                expandedSections.remove(category)
            } else {
                expandedSections.insert(category)
            }
            allExpanded = expandedSections.count == filteredItemsByCategory.count
        }
    }

    private func toggleFavorite(_ item: ExploreItem) {
        var set = favoriteLinks
        if set.contains(item.url) {
            set.remove(item.url)
        } else {
            set.insert(item.url)
        }
        favoriteLinksCSV = set.sorted().joined(separator: "|")
    }
}

struct ExploreHeroBanner: View {
    @State private var glow = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("AccentPrimary").opacity(0.95),
                            Color("AccentPrimary").opacity(0.55),
                            Color("CardBackground").opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.white.opacity(0.20))
                .frame(width: glow ? 140 : 110, height: glow ? 140 : 110)
                .blur(radius: 10)
                .offset(x: 110, y: -38)

            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: glow ? 92 : 68, height: glow ? 92 : 68)
                .blur(radius: 8)
                .offset(x: -122, y: 52)

            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.22))
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text("Explore Trek Long Island")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                    Text("Schedules, guests, events, and must-see details")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
        }
        .frame(height: 122)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color("AccentPrimary").opacity(0.22), radius: 14, x: 0, y: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

// MARK: - Single Section View
struct ExploreSection: View {
    let iconNameForCategory: (String) -> String
    let category: String
    let items: [ExploreLink.ExploreItem]
    let isExpanded: Bool
    let toggle: () -> Void
    let favoriteCount: Int
    let openURL: (String) -> Void
    let isFavorited: (String) -> Bool
    let toggleFavorite: (ExploreLink.ExploreItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: toggle) {
                HStack {
                    Label(category, systemImage: iconNameForCategory(category))
                        .font(.title3.bold())
                        .foregroundColor(Color("AccentPrimary"))
                    if favoriteCount > 0 {
                        Text("★ \(favoriteCount)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color("AccentPrimary"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("AccentPrimary").opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("AccentPrimary"))
                        .rotationEffect(.degrees(isExpanded ? 0 : 0)) // no rotation needed, using different SFSymbol
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }

            if isExpanded {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                    ForEach(items) { item in
                        ExploreItemCard(item: item) {
                            openURL(item.url)
                        }
                        .overlay(alignment: .topTrailing) {
                            Button {
                                toggleFavorite(item)
                            } label: {
                                Image(systemName: isFavorited(item.url) ? "star.fill" : "star")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(isFavorited(item.url) ? .yellow : .white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.35))
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            Divider()
                .background(Color("AccentPrimary").opacity(0.4))
        }
    }
}

// MARK: - Individual Card View
struct ExploreItemCard: View {
    let item: ExploreLink.ExploreItem
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            onTap()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("AccentPrimary"), Color("AccentPrimary").opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                    Image(systemName: item.systemImage)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                Text(item.title)
                    .font(.subheadline.bold())
                    .foregroundColor(Color("TextPrimary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 4)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
        }
    }
}
