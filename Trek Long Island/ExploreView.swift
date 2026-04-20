// Copyright Bryan Carroll. All rights reserved.
//
//  ExploreView.swift
//  Trek Long Island – Final, Perfect, App Store Ready
//  iOS 17+, Swift 6, Xcode 16+ – 100% Clean & Complete
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Animations / Transitions

private extension Animation {
    static var exploreSelection: Animation {
        if #available(iOS 17.0, *) { return .snappy }
        return .easeInOut(duration: 0.22)
    }
}

private extension View {
    @ViewBuilder
    func exploreOpacityTransition() -> some View {
        if #available(iOS 17.0, *) {
            self.contentTransition(.opacity)
        } else {
            self
        }
    }
}

// MARK: - Explore

@MainActor
struct ExploreView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    // Persist last selected tab (survives app relaunch)
    @AppStorage("explore.lastTab")
    private var lastTabRaw: String = Route.guests.rawValue

    @State private var selected: Route = .guests
    @State private var viewportSize: CGSize = .zero

    private var isRegularWidth: Bool {
        hSizeClass == .regular
    }

    private var layoutWidth: CGFloat {
        viewportSize.width > 0 ? viewportSize.width : 390
    }

    private var layoutHeight: CGFloat {
        viewportSize.height > 0 ? viewportSize.height : 844
    }

    private var isCompactPhoneLayout: Bool {
        !isRegularWidth && TLILayout.isSmallPhone(width: layoutWidth, height: layoutHeight)
    }

    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad,
           #available(iOS 16.0, *) {
            splitLayout
        } else {
            phoneLayout
        }
        #else
        phoneLayout
        #endif
    }

    // MARK: - Phone Layout (chips + TabView)

    private var phoneLayout: some View {
        ZStack {
            exploreBackground
                .ignoresSafeArea()

            VStack(spacing: isCompactPhoneLayout ? 8 : 10) {
                ExploreTabs(selected: $selected, scheme: scheme, compact: isCompactPhoneLayout)
                    .padding(.horizontal, TLILayout.compactHorizontalPadding(for: layoutWidth))
                    .padding(.top, isCompactPhoneLayout ? 6 : 8)

                routeView(selected)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, selected == .guests ? 0 : TLILayout.compactHorizontalPadding(for: layoutWidth))
                    .padding(.bottom, isCompactPhoneLayout ? 4 : 8)
                    .animation(.exploreSelection, value: selected)
                    .exploreOpacityTransition()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        viewportSize = proxy.size
                    }
                    .onChange(of: proxy.size) { _, newValue in
                        viewportSize = newValue
                    }
            }
        }
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .toolbar { categoryMenuButton }
        .onAppear { restoreSelection() }
        .onChange(of: selected) { persistSelection() }
        .onOpenURL { handleDeepLink($0) }
    }

    // MARK: - iPad / Regular Width (sidebar + detail)

    @available(iOS 16.0, *)
    private var splitLayout: some View {
        NavigationSplitView {
            ZStack {
                exploreBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        sidebarSection("Featured", routes: Route.primaryRoutes)
                        sidebarSection("More to explore", routes: Route.secondaryRoutes)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            .toolbar { categoryMenuButton }
        } detail: {
            ZStack {
                exploreBackground
                    .ignoresSafeArea()

                if selected == .guests {
                    routeView(selected)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 4)
                        .animation(.exploreSelection, value: selected)
                        .exploreOpacityTransition()
                } else {
                    ScrollView {
                        VStack {
                            Group {
                                routeView(selected)
                            }
                            .frame(maxWidth: 820)
                            .padding(16)

                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .animation(.exploreSelection, value: selected)
                    .exploreOpacityTransition()
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .tliNavBarStyle()
        }
        .onAppear { restoreSelection() }
        .onChange(of: selected) { persistSelection() }
        .onOpenURL { handleDeepLink($0) }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - Background

    private var exploreBackground: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
            if scheme == .dark {
                Color.black.opacity(0.30)
            }
        }
    }

    // MARK: - Category Menu

    @ToolbarContentBuilder
    private var categoryMenuButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(Route.allCases) { route in
                    Button {
                        select(route, withFeedback: true)
                    } label: {
                        Label(route.title, systemImage: route.icon)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selected.icon)
                        .imageScale(.small)
                    Text(selected.title)
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .imageScale(.small)
                        .opacity(0.7)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(
                            scheme == .dark
                            ? Color.black.opacity(0.55)
                            : TLITheme.cardBackground(scheme)
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(TLITheme.border(scheme), lineWidth: TLITheme.hairline)
                )
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .shadow(
                    color: scheme == .dark ? .black.opacity(0.65) : .clear,
                    radius: scheme == .dark ? 4 : 0,
                    x: 0,
                    y: 1
                )
            }
            .accessibilityLabel("Change Explore category")
            .accessibilityValue(selected.title)
        }
    }

    // MARK: - Routing Helpers

    @ViewBuilder
    private func routeView(_ route: Route) -> some View {
        switch route {
        case .guests:
            GuestsView(showsHeader: false)
        case .maps:
            MapsView()
        case .exhibitors:
            ExhibitorListView()
        case .sponsors:
            SponsorsListView()
        case .discounts:
            DiscountsView()
        case .costumeGuide:
            StarTrekCostumeGuideView()
        }
    }

    private func restoreSelection() {
        selected = Route(rawValue: lastTabRaw) ?? .guests
    }

    private func persistSelection() {
        lastTabRaw = selected.rawValue
    }

    private func select(_ route: Route, withFeedback: Bool) {
        #if canImport(UIKit)
        if withFeedback {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        #endif

        withAnimation(.exploreSelection) {
            selected = route
        }
    }

    private func handleDeepLink(_ url: URL) {
        if let route = ExploreView.deepLinkedRoute(from: url) {
            select(route, withFeedback: true)
        }
    }

    private func sidebarSection(_ title: String, routes: [Route]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(RisaTheme.isLCARSThemeEnabled ? lcarsSectionTitle(for: title) : title)
                .font(.caption.weight(.bold))
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)

            ForEach(routes) { route in
                Button {
                    select(route, withFeedback: true)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: route.icon)
                            .imageScale(.medium)
                            .frame(width: 20)
                            .foregroundStyle(route.accentColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(route.title)
                                .font(.body)
                                .foregroundStyle(TLITheme.textPrimary(scheme))
                            Text(route.summary)
                                .font(.caption)
                                .foregroundStyle(TLITheme.textSecondary(scheme))
                                .lineLimit(2)
                        }

                        Spacer()

                        if selected == route {
                            Image(systemName: "checkmark")
                                .imageScale(.small)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        } else if differentiateWithoutColor {
                            Image(systemName: "circle")
                                .imageScale(.small)
                                .foregroundStyle(TLITheme.textTertiary(scheme))
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        TLITheme.controlShape(cornerRadius: 18)
                            .fill(
                                selected == route
                                ? TLITheme.accent(scheme).opacity(0.18)
                                : Color.clear
                            )
                    )
                    .overlay(
                        TLITheme.controlShape(cornerRadius: 18)
                            .stroke(TLITheme.border(scheme).opacity(RisaTheme.isLCARSThemeEnabled ? 0.75 : 0.32), lineWidth: TLITheme.hairline)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(route.title)
                .accessibilityAddTraits(selected == route ? .isSelected : [])
            }
        }
        .padding(14)
        .tliPanelSurface(
            cornerRadius: 24,
            fillOpacity: 0.96,
            borderOpacity: 0.82,
            shadowRadius: 12,
            shadowY: 6
        )
    }
}

// MARK: - Tabs (phone)

private struct ExploreTabs: View {
    @Binding var selected: ExploreView.Route
    let scheme: ColorScheme
    let compact: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: compact ? 8 : 10) {
                ForEach(ExploreView.Route.allCases) { route in
                    ExploreTabChip(
                        title: route.title,
                        systemImage: route.icon,
                        isSelected: selected == route,
                        scheme: scheme,
                        isPrimary: route.isPrimary
                        ,
                        compact: compact
                    ) {
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        withAnimation(.exploreSelection) { selected = route }
                    }
                    .keyboardShortcut(route.shortcutKey, modifiers: [])
                    .hoverEffect(.highlight)
                }
            }
            .padding(.vertical, 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Explore Categories")
    }
}

private struct ExploreTabChip: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    let title: String
    let systemImage: String
    let isSelected: Bool
    let scheme: ColorScheme
    let isPrimary: Bool
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .imageScale(.medium)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .exploreOpacityTransition()
                if differentiateWithoutColor {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .imageScale(.small)
                        .accessibilityHidden(true)
                }
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, compact ? 12 : 14)
            .padding(.vertical, compact ? 8 : 9)
            .background(
                TLITheme.controlShape(cornerRadius: 18).fill(
                    isSelected
                    ? TLITheme.selectedChipBackground(scheme)
                    : isPrimary
                        ? TLITheme.cardBackground(scheme)
                        : TLITheme.cardBackground(scheme).opacity(0.65)
                )
            )
            .overlay(
                TLITheme.controlShape(cornerRadius: 18).stroke(
                    isPrimary ? TLITheme.border(scheme) : TLITheme.border(scheme).opacity(0.55),
                    lineWidth: TLITheme.hairline
                )
            )
            .foregroundStyle(isSelected ? TLITheme.selectedChipForeground(scheme) : TLITheme.textPrimary(scheme))
            .tliButtonShapeOutline(
                shape: RoundedRectangle(cornerRadius: 18, style: .continuous),
                strokeColor: isSelected ? TLITheme.selectedChipForeground(scheme) : TLITheme.border(scheme)
            )
            .shadow(
                color: scheme == .dark ? .black.opacity(0.75) : .clear,
                radius: scheme == .dark ? 5 : 0,
                x: 0,
                y: 1
            )
            .contentShape(TLITheme.controlShape(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(showButtonShapes ? nil : .exploreSelection, value: isSelected)
    }
}

// MARK: - Routing Enum + Deep Links

extension ExploreView {
    private func lcarsSectionTitle(for title: String) -> String {
        switch title {
        case "Featured": return "Primary Databanks"
        case "More to explore": return "Secondary Channels"
        default: return title
        }
    }

    enum Route: String, CaseIterable, Identifiable, Hashable {
        case guests
        case maps
        case exhibitors
        case sponsors
        case discounts
        case costumeGuide

        var id: String { rawValue }

        static var primaryRoutes: [Route] {
            [.guests, .exhibitors, .maps]
        }

        static var secondaryRoutes: [Route] {
            [.sponsors, .discounts, .costumeGuide]
        }

        var title: String {
            switch self {
            case .guests:      return TLILCARSLabel.guests
            case .maps:        return TLILCARSLabel.maps
            case .exhibitors:  return TLILCARSLabel.exhibitors
            case .sponsors:    return TLILCARSLabel.sponsors
            case .discounts:   return "Discounts"
            case .costumeGuide:
                return RisaTheme.isLCARSThemeEnabled ? "Costume Database" : "Cosplay Guide"
            }
        }

        var summary: String {
            switch self {
            case .guests:
                return RisaTheme.isLCARSThemeEnabled
                    ? "Crew files, guest biographies, appearance data, and away-team intel."
                    : "Celebrities, authors, artists, and featured away-team intel."
            case .maps:
                return RisaTheme.isLCARSThemeEnabled
                    ? "Deck references, venue routing, and shipwide navigation assistance."
                    : "Hotel and convention-level navigation for your next move."
            case .exhibitors:
                return RisaTheme.isLCARSThemeEnabled
                    ? "Vendor manifests, collectibles, and trading targets across the promenade."
                    : "Vendors, collectibles, and shopping targets across the floor."
            case .sponsors:
                return "Organizations helping power the convention."
            case .discounts:
                return "Convention-adjacent deals, offers, and partner links."
            case .costumeGuide:
                return RisaTheme.isLCARSThemeEnabled
                    ? "Uniform research, sewing files, and partner supply channels."
                    : "Uniform research, sewing patterns, and cosplay supply links."
            }
        }

        var isPrimary: Bool {
            Self.primaryRoutes.contains(self)
        }

        var accentColor: Color {
            switch self {
            case .guests:
                return .orange
            case .maps:
                return .teal
            case .exhibitors:
                return .yellow
            case .sponsors:
                return .pink
            case .discounts:
                return .blue
            case .costumeGuide:
                return .purple
            }
        }

        var icon: String {
            switch self {
            case .guests:      return "person.3.fill"
            case .maps:        return "map.fill"
            case .exhibitors:  return "bag.fill"
            case .sponsors:    return "star.fill"
            case .discounts:   return "tag.fill"
            case .costumeGuide: return "theatermasks.fill"
            }
        }

        var shortcutKey: KeyEquivalent {
            switch self {
            case .guests:      return "1"
            case .maps:        return "2"
            case .exhibitors:  return "3"
            case .sponsors:    return "4"
            case .discounts:   return "5"
            case .costumeGuide: return "6"
            }
        }

    }

    static func deepLinkedRoute(from url: URL) -> Route? {
        let all = Set(Route.allCases.map(\.rawValue))

        let host = (url.host ?? "").lowercased()
        let pathComponents = url.pathComponents.map { $0.lowercased() }

        if host == "explore" {
            if let first = pathComponents.dropFirst().first, all.contains(first) {
                return Route(rawValue: first)
            }
            if let frag = url.fragment?.lowercased(), all.contains(frag) {
                return Route(rawValue: frag)
            }
        }

        if all.contains(host) {
            return Route(rawValue: host)
        }

        return nil
    }
}

// MARK: - PERFECT Previews

#Preview("✅ Explore - iPhone Dark") {
    NavigationStack {
        ExploreView()
    }
    .environment(\.colorScheme, .dark)
}

#Preview("✅ Explore - iPhone Light") {
    NavigationStack {
        ExploreView()
    }
    .environment(\.colorScheme, .light)
}

#Preview("✅ Explore - iPad Dark") {
    NavigationStack {
        ExploreView()
    }
    .environment(\.colorScheme, .dark)
}

#Preview("✅ Explore - iPad Landscape", traits: .landscapeLeft) {
    NavigationStack {
        ExploreView()
    }
    .environment(\.colorScheme, .dark)
}
