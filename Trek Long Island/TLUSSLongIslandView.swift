// Copyright Bryan Carroll. All rights reserved.
//
//  TLUSSLongIslandView.swift
//  Trek Long Island
//

import SwiftUI

@MainActor
struct TLUSSLongIslandView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShowingBridgeViewscreen = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                commandHeader
                systemsDeck
                academyDeck
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(shipBackground.ignoresSafeArea())
        .navigationTitle("USS Long Island")
        .navigationBarTitleDisplayMode(.inline)
        .tint(ShipDirectoryPalette.accent)
        .fullScreenCover(isPresented: $isShowingBridgeViewscreen) {
            TLBridgeViewscreenView()
        }
    }

    private var commandHeader: some View {
        LCARSShipPanel(fill: ShipDirectoryPalette.shell) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    lcarsRail

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("USS LONG ISLAND")
                                    .font(.caption.weight(.bold))
                                    .tracking(1.6)
                                    .foregroundStyle(ShipDirectoryPalette.textDim)

                                Text("Ship Systems Directory")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(ShipDirectoryPalette.textBright)

                                Text("Bridge, engineering, transporter, tricorder, academy drills, and hidden mission archives are available for immediate crew recreation.")
                                    .font(.subheadline)
                                    .foregroundStyle(ShipDirectoryPalette.textMuted)
                            }

                            Spacer(minLength: 0)

                            VStack(alignment: .trailing, spacing: 8) {
                                headerBadge("STATUS", value: "DOCKED", color: ShipDirectoryPalette.orange)
                                headerBadge("ACCESS", value: "LEVEL 10", color: ShipDirectoryPalette.blue)
                            }
                        }

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 10) {
                                metricPill("Deck", value: "Mini Games")
                                metricPill("Mode", value: "Holodeck")
                                metricPill("Ship", value: "NCC-TLI")
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 10) {
                                    metricPill("Deck", value: "Mini Games")
                                    metricPill("Mode", value: "Holodeck")
                                }
                                metricPill("Ship", value: "NCC-TLI")
                            }
                        }

                        telemetryBars
                    }
                }

                featuredArrivalDisplay
            }
        }
    }

    private var systemsDeck: some View {
        LCARSShipPanel(fill: ShipDirectoryPalette.panel) {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(
                    title: "Ship Systems",
                    subtitle: "Operational stations and training consoles"
                )

                schematicDisplay

                NavigationLink {
                    TLBridgeMiniGameView()
                } label: {
                    systemRow(
                        title: "Bridge Command",
                        subtitle: "Take the center seat and answer tactical, science, and ops incidents.",
                        systemImage: "steeringwheel",
                        accent: ShipDirectoryPalette.orange,
                        code: "BRG-01"
                    )
                }

                NavigationLink {
                    TLEngineeringMiniGameView()
                } label: {
                    systemRow(
                        title: "Engineering Drill",
                        subtitle: "Balance warp-core flow and stabilize the intermix before it drifts.",
                        systemImage: "bolt.horizontal.circle",
                        accent: ShipDirectoryPalette.red,
                        code: "ENG-02"
                    )
                }

                NavigationLink {
                    TLTurboLiftGameView()
                } label: {
                    systemRow(
                        title: "TurboLift Traffic",
                        subtitle: "Route passenger requests efficiently through the ship.",
                        systemImage: "arrow.up.and.down.and.arrow.left.and.right",
                        accent: ShipDirectoryPalette.gold,
                        code: "TLF-03"
                    )
                }

                NavigationLink {
                    TLTransporterRoomShiftView()
                } label: {
                    systemRow(
                        title: "Transporter Room",
                        subtitle: "Operate the pad and try not to scatter anyone across the timeline.",
                        systemImage: "sparkles.tv",
                        accent: ShipDirectoryPalette.mint,
                        code: "TRN-04"
                    )
                }

                NavigationLink {
                    TricorderMiniGameView()
                } label: {
                    systemRow(
                        title: "Tricorder Scan",
                        subtitle: "Sweep sectors, track anomalies, and recover classified fragments.",
                        systemImage: "dot.radiowaves.left.and.right",
                        accent: ShipDirectoryPalette.blue,
                        code: "SCI-05"
                    )
                }

                NavigationLink {
                    TLStellarCartographyBorgGameView()
                } label: {
                    systemRow(
                        title: "Stellar Cartography",
                        subtitle: "Map transwarp echoes, isolate the Borg cube, and keep the grid from assimilation.",
                        systemImage: "sparkles",
                        accent: ShipDirectoryPalette.mint,
                        code: "SCI-06"
                    )
                }
            }
        }
    }

    private var academyDeck: some View {
        LCARSShipPanel(fill: ShipDirectoryPalette.panelSecondary) {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(
                    title: "Academy & Archives",
                    subtitle: "Training simulations and command-side curiosities"
                )

                NavigationLink {
                    TLStarTrekTriviaView()
                } label: {
                    systemRow(
                        title: "Star Trek Trivia",
                        subtitle: "A full knowledge trial across crews, captains, species, and canon.",
                        systemImage: "questionmark.circle",
                        accent: ShipDirectoryPalette.gold,
                        code: "ACA-11"
                    )
                }

                NavigationLink {
                    TLStarTrekTriviaView(startMode: .quick10)
                } label: {
                    systemRow(
                        title: "Quick Trivia",
                        subtitle: "A short ten-question sprint for cadets in a hurry.",
                        systemImage: "bolt.circle",
                        accent: ShipDirectoryPalette.orange,
                        code: "ACA-12"
                    )
                }

                NavigationLink {
                    EasterEggMissionView()
                } label: {
                    systemRow(
                        title: "Easter Egg Mission",
                        subtitle: "Track hidden objectives and cross-system discoveries.",
                        systemImage: "sparkles.rectangle.stack.fill",
                        accent: ShipDirectoryPalette.mint,
                        code: "ARC-13"
                    )
                }

                holodeckPoetryDisplay

                archiveFooter
            }
        }
    }

    private var lcarsRail: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(ShipDirectoryPalette.orange)
                .frame(width: 38, height: 76)

            Capsule()
                .fill(ShipDirectoryPalette.blue)
                .frame(width: 38, height: 30)

            Capsule()
                .fill(ShipDirectoryPalette.gold)
                .frame(width: 38, height: 118)
        }
        .accessibilityHidden(true)
    }

    private var featuredArrivalDisplay: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Bridge Viewscreen")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(ShipDirectoryPalette.textDim)
                Spacer(minLength: 0)
                Text("CAM 01")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ShipDirectoryPalette.orange, in: Capsule())
            }

            Button {
                isShowingBridgeViewscreen = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.92),
                                    ShipDirectoryPalette.screen.opacity(0.96),
                                    ShipDirectoryPalette.blue.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Main Bridge Optical Relay")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(ShipDirectoryPalette.textBright)

                                Text("Open a live camera feed and view the convention floor through a starship bridge overlay.")
                                    .font(.caption)
                                    .foregroundStyle(ShipDirectoryPalette.textMuted)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(ShipDirectoryPalette.gold)
                        }

                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(ShipDirectoryPalette.blue.opacity(0.5), lineWidth: 1.5)
                                .frame(height: 170)

                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [8, 8]))
                                .foregroundStyle(ShipDirectoryPalette.orange.opacity(0.45))
                                .padding(12)

                            VStack(spacing: 10) {
                                Image(systemName: "sparkles.tv")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(ShipDirectoryPalette.orange)

                                Text("Tap To Open Viewscreen")
                                    .font(.system(.title3, design: .rounded).weight(.black))
                                    .foregroundStyle(ShipDirectoryPalette.textBright)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.82)

                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: 8) {
                                        holodeckSoftKey("BRIDGE", color: ShipDirectoryPalette.gold)
                                        holodeckSoftKey("LIVE", color: ShipDirectoryPalette.red)
                                        holodeckSoftKey("AFT CAM", color: ShipDirectoryPalette.blue)
                                    }

                                    VStack(spacing: 8) {
                                        HStack(spacing: 8) {
                                            holodeckSoftKey("BRIDGE", color: ShipDirectoryPalette.gold)
                                            holodeckSoftKey("LIVE", color: ShipDirectoryPalette.red)
                                        }
                                        holodeckSoftKey("AFT CAM", color: ShipDirectoryPalette.blue)
                                    }
                                }
                            }
                        }
                    }
                    .padding(18)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(ShipDirectoryPalette.stroke, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.28), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open bridge viewscreen")
            .accessibilityHint("Shows the convention through a live camera feed with a bridge overlay.")

            Text("Route visual sensors through the main bridge and see the convention through a live Starfleet-style viewscreen.")
                .font(.caption)
                .foregroundStyle(ShipDirectoryPalette.textMuted)
        }
    }

    private var schematicDisplay: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ship Schematic")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(ShipDirectoryPalette.textDim)
                Spacer(minLength: 0)
                Text("NCC-2026")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ShipDirectoryPalette.blue, in: Capsule())
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    schematicImage
                        .frame(maxWidth: 280)

                    schematicReadout
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }

                VStack(alignment: .leading, spacing: 14) {
                    schematicImage
                    schematicReadout
                }
            }
        }
        .padding(14)
        .background(ShipDirectoryPalette.screen.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(ShipDirectoryPalette.stroke, lineWidth: 1)
        )
    }

    private var schematicImage: some View {
        Image("USSLongIsland")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(ShipDirectoryPalette.stroke, lineWidth: 1)
            )
    }

    private var schematicReadout: some View {
        VStack(alignment: .leading, spacing: 10) {
            readoutLine("Registry", value: "Island Class")
            readoutLine("Primary Role", value: "Crew Recreation")
            readoutLine("Station Links", value: "Bridge, Engineering, Tricorder")
            readoutLine("Archive Access", value: "Academy, Missions")
        }
    }

    private var telemetryBars: some View {
        HStack(spacing: 8) {
            telemetryBar(width: 0.82, color: ShipDirectoryPalette.orange)
            telemetryBar(width: 0.44, color: ShipDirectoryPalette.red)
            telemetryBar(width: 0.67, color: ShipDirectoryPalette.blue)
            telemetryBar(width: 0.28, color: ShipDirectoryPalette.mint)
        }
    }

    private func telemetryBar(width: CGFloat, color: Color) -> some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color)
                .frame(width: max(geometry.size.width * width, 12))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 10)
        .background(ShipDirectoryPalette.screen, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var holodeckPoetryDisplay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(ShipDirectoryPalette.gold)
                    .frame(width: 92, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text("HOLODECK PROGRAMMING")
                        .font(.system(.title3, design: .rounded).weight(.black))
                        .foregroundStyle(ShipDirectoryPalette.textBright)

                    Text("Long Island Poetry Archive")
                        .font(.caption.weight(.bold))
                        .tracking(1.3)
                        .foregroundStyle(ShipDirectoryPalette.textDim)
                }

                Spacer(minLength: 0)

                Text("SIM 24")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ShipDirectoryPalette.gold, in: Capsule())
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    holodeckSideRail
                    holodeckPoemScreen
                }

                VStack(alignment: .leading, spacing: 14) {
                    holodeckSideRail
                    holodeckPoemScreen
                }
            }

            HStack(spacing: 10) {
                holodeckSoftKey("NAH BAY", color: ShipDirectoryPalette.orange)
                holodeckSoftKey("PINE BAR", color: ShipDirectoryPalette.red)
                holodeckSoftKey("MON TAUK", color: ShipDirectoryPalette.blue)
                holodeckSoftKey("STAR LIT", color: ShipDirectoryPalette.mint)
            }
        }
        .padding(14)
        .background(ShipDirectoryPalette.screen.opacity(0.9), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(ShipDirectoryPalette.stroke, lineWidth: 1)
        )
    }

    private var holodeckSideRail: some View {
        HStack(spacing: 10) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ShipDirectoryPalette.orange)
                    .frame(width: 82, height: 34)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ShipDirectoryPalette.gold)
                    .frame(width: 82, height: 22)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ShipDirectoryPalette.red)
                    .frame(width: 82, height: 22)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ShipDirectoryPalette.blue)
                    .frame(width: 82, height: 46)
            }

            VStack(alignment: .leading, spacing: 8) {
                metricPill("Program", value: "LI-241")
                metricPill("Voice", value: "Computer")
            }
        }
        .accessibilityHidden(true)
    }

    private var holodeckPoemScreen: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SELECT SIMULATION")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(ShipDirectoryPalette.red)

                Spacer(minLength: 0)

                Text("LCARS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ShipDirectoryPalette.textDim)
            }

            VStack(alignment: .leading, spacing: 8) {
                holodeckPoemLine("01-241", text: "Between the Sound and Atlantic tide,")
                holodeckPoemLine("02-500", text: "Long Island keeps its lanterns wide,")
                holodeckPoemLine("03-778", text: "Pines stand watch where shorebirds wheel,")
                holodeckPoemLine("04-210", text: "Harbors answer steel with keel,")
                holodeckPoemLine("04-577", text: "From city edge to Montauk light,")
                holodeckPoemLine("05-100", text: "Home runs long through a star-filled night.")
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    holodeckActionCluster
                    Spacer(minLength: 0)
                    headerBadge("MODE", value: "RECITE", color: ShipDirectoryPalette.orange)
                }

                VStack(alignment: .leading, spacing: 10) {
                    holodeckActionCluster
                    headerBadge("MODE", value: "RECITE", color: ShipDirectoryPalette.orange)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(scheme == .dark ? 0.92 : 0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ShipDirectoryPalette.stroke, lineWidth: 1)
        )
    }

    private var holodeckActionCluster: some View {
        HStack(spacing: 8) {
            holodeckSoftKey("RECITE", color: ShipDirectoryPalette.gold)
            holodeckSoftKey("AMBER", color: ShipDirectoryPalette.orange)
            holodeckSoftKey("COAST", color: ShipDirectoryPalette.blue)
        }
    }

    private func holodeckPoemLine(_ code: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(code)
                .font(.caption.weight(.bold))
                .foregroundStyle(ShipDirectoryPalette.gold)
                .frame(width: 48, alignment: .leading)

            Text(text)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(ShipDirectoryPalette.textBright)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func holodeckSoftKey(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(.black.opacity(0.82))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color, in: Capsule())
    }

    private var archiveFooter: some View {
        HStack(alignment: .top, spacing: 12) {
            Capsule()
                .fill(ShipDirectoryPalette.red)
                .frame(width: 18, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text("COMPUTER NOTE")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(ShipDirectoryPalette.textDim)

                Text("Select any station to transfer directly into simulation mode. All systems are decorative, dramatic, and at least mostly stable.")
                    .font(.subheadline)
                    .foregroundStyle(ShipDirectoryPalette.textMuted)
            }
        }
        .padding(14)
        .background(ShipDirectoryPalette.screen.opacity(0.84), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(ShipDirectoryPalette.stroke, lineWidth: 1)
        )
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.35)
                    .foregroundStyle(ShipDirectoryPalette.textDim)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(ShipDirectoryPalette.textMuted)
            }

            Spacer(minLength: 0)

            Text(String(format: "%02d", title.count))
                .font(.system(.title3, design: .rounded).weight(.black))
                .foregroundStyle(ShipDirectoryPalette.textBright)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ShipDirectoryPalette.screen, in: Capsule())
        }
    }

    private func headerBadge(_ title: String, value: String, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(ShipDirectoryPalette.textDim)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.black.opacity(0.82))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(color, in: Capsule())
        }
    }

    private func metricPill(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(ShipDirectoryPalette.textDim)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ShipDirectoryPalette.textBright)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ShipDirectoryPalette.screen, in: Capsule())
    }

    private func readoutLine(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(ShipDirectoryPalette.textDim)
            Spacer(minLength: 10)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ShipDirectoryPalette.textBright)
        }
        .padding(.vertical, 4)
    }

    private func systemRow(title: String, subtitle: String, systemImage: String, accent: Color, code: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accent)
                .frame(width: 22)
                .overlay {
                    if !reduceMotion {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    }
                }

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(ShipDirectoryPalette.screen)
                        .frame(width: 54, height: 54)

                    Image(systemName: systemImage)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(ShipDirectoryPalette.textBright)

                        Text(code)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black.opacity(0.82))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accent, in: Capsule())
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(ShipDirectoryPalette.textMuted)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ShipDirectoryPalette.textDim)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(ShipDirectoryPalette.screen.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(ShipDirectoryPalette.stroke, lineWidth: 1)
            )
        }
        .contentShape(Rectangle())
    }

    private var shipBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 9 / 255, green: 12 / 255, blue: 25 / 255),
                    Color(red: 21 / 255, green: 18 / 255, blue: 35 / 255),
                    Color(red: 18 / 255, green: 28 / 255, blue: 45 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [ShipDirectoryPalette.orange.opacity(0.18), .clear],
                center: .topLeading,
                startRadius: 24,
                endRadius: 260
            )

            RadialGradient(
                colors: [ShipDirectoryPalette.blue.opacity(0.16), .clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 320
            )

            LCARSDirectoryGrid()
                .stroke(ShipDirectoryPalette.grid, lineWidth: 1)
                .opacity(0.6)
        }
    }
}

private struct LCARSShipPanel<Content: View>: View {
    let fill: LinearGradient
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(ShipDirectoryPalette.stroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.34), radius: 18, y: 10)
    }
}

private struct LCARSDirectoryGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let rowCount = 9
        let columnCount = 6

        for row in 0...rowCount {
            let y = rect.minY + (rect.height / CGFloat(rowCount)) * CGFloat(row)
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        for column in 0...columnCount {
            let x = rect.minX + (rect.width / CGFloat(columnCount)) * CGFloat(column)
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        return path
    }
}

private enum ShipDirectoryPalette {
    static let shell = LinearGradient(
        colors: [Color(red: 35 / 255, green: 21 / 255, blue: 35 / 255), Color(red: 18 / 255, green: 21 / 255, blue: 39 / 255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let panel = LinearGradient(
        colors: [Color(red: 25 / 255, green: 22 / 255, blue: 41 / 255), Color(red: 14 / 255, green: 18 / 255, blue: 34 / 255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let panelSecondary = LinearGradient(
        colors: [Color(red: 22 / 255, green: 24 / 255, blue: 36 / 255), Color(red: 12 / 255, green: 16 / 255, blue: 28 / 255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let screen = Color(red: 11 / 255, green: 16 / 255, blue: 28 / 255)
    static let stroke = Color.white.opacity(0.08)
    static let grid = Color.white.opacity(0.06)
    static let textBright = Color(red: 245 / 255, green: 247 / 255, blue: 251 / 255)
    static let textMuted = Color(red: 188 / 255, green: 198 / 255, blue: 217 / 255)
    static let textDim = Color(red: 129 / 255, green: 145 / 255, blue: 170 / 255)
    static let orange = Color(red: 1, green: 170 / 255, blue: 110 / 255)
    static let gold = Color(red: 245 / 255, green: 193 / 255, blue: 92 / 255)
    static let red = Color(red: 234 / 255, green: 112 / 255, blue: 116 / 255)
    static let blue = Color(red: 112 / 255, green: 171 / 255, blue: 1)
    static let mint = Color(red: 100 / 255, green: 221 / 255, blue: 205 / 255)
    static let accent = orange
}
