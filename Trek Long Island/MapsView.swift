// Copyright Bryan Carroll. All rights reserved.
//
//  MapsView.swift
//  Trek Long Island
//
//  • Hotel area map (GPS-based)
//  • Convention floor map (pinch to zoom, drag to pan, double-tap to reset)
//  • Tuned to fit cleanly on iPhone + iPad, Risa-themed
//

import SwiftUI
import MapKit

@MainActor
struct MapsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    @ObservedObject private var networkMonitor = TLINetworkMonitor.shared

    // MARK: - Map modes

    private enum MapMode {
        case hotelArea
        case floorMap
    }

    @State private var mapMode: MapMode = .hotelArea
    @State private var fromRoom: String = "Main Hall"
    @State private var toRoom: String = "Panel B"
    @State private var hotelMapReloadToken = UUID()
    @AppStorage("TLI.Maps.lastSyncEpoch") private var mapsLastSyncEpoch: Double = 0

    // MARK: - Hotel area map (MapKit)

    private static let hyattCoordinate = CLLocationCoordinate2D(
        latitude: 40.81319,
        longitude: -73.17255
    )
    @State private var hotelMapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: MapsView.hyattCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )

    private struct HotelPin: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let title: String
    }

    private let hotelPin = HotelPin(
        coordinate: MapsView.hyattCoordinate,
        title: "Hyatt Regency Long Island"
    )

    private var routeRooms: [String] {
        ["Main Hall", "Panel B", "Panel C", "Panel D", "Windwatch", "Kids Track", "Photo Sessions", "Vendor Hall Announcements", "Special Events", "Trustees Board Room"]
    }

    // MARK: - Floor map image

    /// Replace this with your actual asset name in Assets.xcassets
    private let floorMapImageName = "ConventionFloorMap"

    // Zoom + pan state for floor map
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            GeometryReader { geo in
                // SAFETY: Clamp width/height so they’re never negative or NaN
                let rawWidth = geo.size.width - 32
                let safeWidth = max(rawWidth, 0)          // never negative
                let cardWidth = min(safeWidth, 700)       // cap at 700
                let cardHeight = max(cardWidth * 1.1, 0)  // never negative

                ScrollView {
                    VStack(spacing: 16) {
                        headerCard

                        modePicker

                        offlineStatusCard

                        if cardWidth > 0, cardHeight > 0 {
                            Group {
                                switch mapMode {
                                case .hotelArea:
                                    hotelMapCard(width: cardWidth, height: cardHeight)
                                case .floorMap:
                                    floorMapCard(width: cardWidth, height: cardHeight)
                                }
                            }
                        }

                        routeAssistantCard

                        footerInfo

                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle(TLILCARSLabel.map)
        .navigationBarTitleDisplayMode(.inline)
        .risaNavBarStyle()
        .tliFixedBottomAdSlot()
        .onAppear {
            if networkMonitor.isConnected {
                mapsLastSyncEpoch = Date().timeIntervalSince1970
            }
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(RisaTheme.isLCARSThemeEnabled ? "Deck Navigation" : "Find Your Way Around")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(RisaTheme.textPrimary(scheme))
                .accessibilityAddTraits(.isHeader)

            Text(RisaTheme.isLCARSThemeEnabled
                 ? "Switch between local starbase approach and internal deck layout. Pinch to zoom, drag to pan, and double-tap to reset the schematic."
                 : "Switch between the hotel area map and the convention floor map. Pinch to zoom and drag to pan the floor map; double-tap to reset.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    RisaTheme.cardBackground(scheme)
                        .opacity(scheme == .dark ? 0.92 : 0.98)
                )
                .shadow(
                    color: TLITheme.cardShadowColor(scheme).opacity(0.9),
                    radius: 14,
                    x: 0,
                    y: 8
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    RisaTheme.accent(scheme).opacity(0.15),
                    lineWidth: 1
                )
        )
        .tliLCARSPanelChrome(
            accent: RisaTheme.accent(scheme),
            contentTopInset: 28
        )
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Map Mode")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundColor(RisaTheme.textSecondary(scheme))
                .accessibilityAddTraits(.isHeader)

            Picker("Map Mode", selection: $mapMode) {
                Text(RisaTheme.isLCARSThemeEnabled ? "Starbase Approach" : "Hotel Area").tag(MapMode.hotelArea)
                Text(RisaTheme.isLCARSThemeEnabled ? "Deck Schematic" : "Convention Level").tag(MapMode.floorMap)
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Choose between the hotel area map and the convention floor map")
        }
    }

    // MARK: - Hotel area map card

    private func hotelMapCard(width: CGFloat, height: CGFloat) -> some View {
        let calloutBackground = reduceTransparency
            ? AnyShapeStyle(RisaTheme.cardBackground(scheme))
            : AnyShapeStyle(.ultraThinMaterial)

        return Map(position: $hotelMapPosition) {
            Marker(hotelPin.title, coordinate: hotelPin.coordinate)
                .tint(RisaTheme.accent(scheme))
        }
        .id(hotelMapReloadToken)
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    Color.white.opacity(scheme == .dark ? 0.25 : 0.10),
                    lineWidth: 1
                )
        )
        .shadow(color: TLITheme.cardShadowColor(scheme), radius: 10, y: 4)
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hyatt Regency Long Island")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundColor(RisaTheme.textPrimary(scheme))
                Text("1717 Motor Pkwy, Hauppauge, NY 11788")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(RisaTheme.textSecondary(scheme))
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(calloutBackground)
            )
            .padding(10)
        }
        .tliLCARSPanelChrome(
            accent: RisaTheme.accentSecondary(scheme),
            metadata: "Approach Map"
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hotel area map")
        .accessibilityHint("Shows the Hyatt Regency Long Island and surrounding area")
    }

    private var offlineStatusCard: some View {
        TLIOfflineStatusCard(
            title: "Map Data",
            detail: !networkMonitor.isConnected
                ? "You are offline. Floor schematic remains fully available; hotel area tiles may be limited."
                : "Map connection is online. You can refresh hotel area tiles if needed.",
            isOffline: !networkMonitor.isConnected,
            lastSyncDate: mapsLastSyncEpoch > 0 ? Date(timeIntervalSince1970: mapsLastSyncEpoch) : nil,
            loadedFromCache: !networkMonitor.isConnected,
            actionTitle: "Retry Map",
            action: {
                retryMapTiles()
            }
        )
    }

    private func retryMapTiles() {
        guard networkMonitor.isConnected else { return }
        hotelMapReloadToken = UUID()
        hotelMapPosition = .region(
            MKCoordinateRegion(
                center: MapsView.hyattCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        )
        mapsLastSyncEpoch = Date().timeIntervalSince1970
    }

    // MARK: - Floor map card

    private func floorMapCard(width: CGFloat, height: CGFloat) -> some View {
        let resetBackground = reduceTransparency
            ? AnyShapeStyle(RisaTheme.cardBackground(scheme))
            : AnyShapeStyle(.ultraThinMaterial)

        return ZStack {
            // Subtle backdrop to help the map image stand out
            RisaTheme.cardBackground(scheme)
                .opacity(scheme == .dark ? 0.65 : 0.12)

            Image(floorMapImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(floorMapGesture)
                .onTapGesture(count: 2) {
                    resetFloorMapTransform(animated: true)
                }
                .accessibilityLabel("Convention floor map")
                .accessibilityHint("Pinch to zoom, drag to pan, or use Reset to return to the default view")
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    Color.white.opacity(scheme == .dark ? 0.25 : 0.10),
                    lineWidth: 1
                )
        )
        .shadow(color: TLITheme.cardShadowColor(scheme), radius: 10, y: 4)
        .tliLCARSPanelChrome(
            accent: RisaTheme.accent(scheme),
            metadata: "Deck Schematic"
        )
        .overlay(alignment: .topTrailing) {
            Button {
                resetFloorMapTransform(animated: true)
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.system(.caption, design: .rounded))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule()
                            .fill(resetBackground)
                    )
                    .tliButtonShapeOutline(
                        shape: Capsule(style: .continuous),
                        strokeColor: differentiateWithoutColor ? RisaTheme.textPrimary(scheme) : RisaTheme.accent(scheme)
                    )
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .accessibilityAction(named: "Reset Zoom") {
            resetFloorMapTransform(animated: false)
        }
        .animation(showButtonShapes || reduceMotion ? nil : .default, value: scale)
    }

    // Combined pinch + drag for the floor map
    private var floorMapGesture: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    let newScale = lastScale * value
                    scale = min(max(newScale, minScale), maxScale)
                }
                .onEnded { _ in
                    lastScale = scale
                },
            DragGesture()
                .onChanged { value in
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    lastOffset = offset
                }
        )
    }

    private func resetFloorMapTransform(animated: Bool) {
        let resetBlock = {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }

        if animated && !reduceMotion {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                resetBlock()
            }
        } else {
            resetBlock()
        }
    }

    private var routeAssistantCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Route Assistant")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(RisaTheme.textPrimary(scheme))
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 12) {
                Picker("From", selection: $fromRoom) {
                    ForEach(routeRooms, id: \.self) { room in
                        Text(room).tag(room)
                    }
                }
                Picker("To", selection: $toRoom) {
                    ForEach(routeRooms, id: \.self) { room in
                        Text(room).tag(room)
                    }
                }
            }
            .pickerStyle(.menu)

            if fromRoom == toRoom {
                Text("You are already at \(toRoom).")
                    .font(.footnote)
                    .foregroundColor(RisaTheme.textSecondary(scheme))
            } else {
                Text("Estimated walk: \(estimatedWalkMinutes) minutes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(RisaTheme.textPrimary(scheme))
                ForEach(routeSteps, id: \.self) { step in
                    Text("• \(step)")
                        .font(.footnote)
                        .foregroundColor(RisaTheme.textSecondary(scheme))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(RisaTheme.cardBackground(scheme).opacity(scheme == .dark ? 0.92 : 0.98))
                .shadow(color: TLITheme.cardShadowColor(scheme).opacity(0.9), radius: 14, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(scheme == .dark ? 0.20 : 0.10), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Route assistant")
        .accessibilityValue(fromRoom == toRoom ? "Already at \(toRoom)" : "From \(fromRoom) to \(toRoom), about \(estimatedWalkMinutes) minutes")
    }

    private var estimatedWalkMinutes: Int {
        let fromIndex = routeRooms.firstIndex(of: fromRoom) ?? 0
        let toIndex = routeRooms.firstIndex(of: toRoom) ?? 0
        return max(2, abs(fromIndex - toIndex) * 2 + 2)
    }

    private var routeSteps: [String] {
        [
            "Start at \(fromRoom) and follow deck signage toward central atrium.",
            "Continue to the nearest corridor marker for \(toRoom).",
            "Check room monitors for any queue or capacity updates before entering."
        ]
    }

    // MARK: - Footer

    private var footerInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tips")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(RisaTheme.textPrimary(scheme))
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 4) {
                Text("• Use the **Hotel Area** map to get driving directions and see where the hotel sits on Long Island.")
                Text("• Switch to **Convention Level** for the on-site floor map – pinch to zoom in on rooms and vendor areas.")
                Text("• Double-tap the floor map or tap **Reset** if you get lost while zooming and panning.")
            }
            .font(.system(.footnote, design: .rounded))
            .foregroundColor(RisaTheme.textSecondary(scheme))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    RisaTheme.cardBackground(scheme)
                        .opacity(scheme == .dark ? 0.92 : 0.98)
                )
                .shadow(
                    color: TLITheme.cardShadowColor(scheme).opacity(0.9),
                    radius: 14,
                    x: 0,
                    y: 8
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    Color.white.opacity(scheme == .dark ? 0.20 : 0.10),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    NavigationStack {
        MapsView()
    }
    .preferredColorScheme(.dark)
}
