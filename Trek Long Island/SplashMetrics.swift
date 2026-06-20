// Copyright Bryan Carroll. All rights reserved.
//
//  SplashMetrics.swift
//  Trek Long Island
//
//  Created by Bryan on 8/16/25.
//


import SwiftUI

struct SplashMetrics: Equatable {
    var monthCost: String = "—"
    var costPerMile: String = "—"
    var homeRate: String = "—"
    var sessionsImported: String = "—"
}

struct SplashWelcomeView: View {
    // Inject real actions when you integrate
    var onStart: () -> Void = {}
    var onImportTeslaFi: () -> Void = {}
    var onAddEntry: () -> Void = {}
    var onOpenCalculators: () -> Void = {}
    var onOpenDashboard: () -> Void = {}

    var metrics: SplashMetrics = .init()

    @State private var animateGlow = false
    @State private var animatePulse = false

    var body: some View {
        ZStack {
            // Alive background: layered animated gradients + subtle vignette
            AnimatedBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Logo + Title
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 96, height: 96)
                                .overlay(
                                    Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                )
                                .shadow(radius: animateGlow ? 18 : 6, y: animateGlow ? 6 : 2)
                                .scaleEffect(animatePulse ? 1.02 : 1.0)
                                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: animatePulse)
                                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: animateGlow)

                            Image(systemName: "bolt.fill")
                                .font(.system(size: 40, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                                .accessibilityHidden(true)
                        }

                        Text("My KWh Companion")
                            .font(.largeTitle.bold())
                            .accessibilityAddTraits(.isHeader)

                        Text("Own your EV costs. Track sessions, forecast spend, and optimize charging.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.primary.opacity(0.72))
                            .frame(maxWidth: 560)
                            .padding(.horizontal)
                    }
                    .padding(.top, 12)

                    // Hero card: immediate value + key actions (reduces negative space)
                    VStack(spacing: 18) {
                        // Stats Grid
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 150), spacing: 12, alignment: .top)
                        ], spacing: 12) {
                            StatChip(title: "Last 30 Days", value: metrics.monthCost, systemImage: "calendar")
                            StatChip(title: "Avg Cost / mi", value: metrics.costPerMile, systemImage: "speedometer")
                            StatChip(title: "Home Rate", value: metrics.homeRate, systemImage: "house")
                            StatChip(title: "Sessions Imported", value: metrics.sessionsImported, systemImage: "bolt.badge.automatic")
                        }

                        // Primary CTA
                        Button(action: onStart) {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                Text("Open Dashboard")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.primary) // Adapts for Light/Dark; change to brand color if desired

                        // Secondary actions (adaptive grid)
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 200), spacing: 12, alignment: .top)
                        ], spacing: 12) {
                            ActionTile(title: "Import TeslaFi CSV", subtitle: "Bring in charging history", icon: "tray.and.arrow.down.fill", action: onImportTeslaFi)
                            ActionTile(title: "Add First Entry", subtitle: "Quick expense or session", icon: "plus.circle.fill", action: onAddEntry)
                            ActionTile(title: "Open Calculators", subtitle: "Tools & comparisons", icon: "function", action: onOpenCalculators)
                            ActionTile(title: "Go to Dashboard", subtitle: "Recent activity & stats", icon: "rectangle.grid.2x2.fill", action: onOpenDashboard)
                        }
                    }
                    .padding(18)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
                    .padding(.horizontal)
                    .frame(maxWidth: 900)

                    // Onboarding tips (compact, optional)
                    VStack(spacing: 8) {
                        Label("Tip: Set your seasonal home rate for accurate forecasts.", systemImage: "lightbulb")
                            .foregroundStyle(Color.primary.opacity(0.72))
                        Label("Privacy first: your data stays on device unless you export it.", systemImage: "lock.shield")
                            .foregroundStyle(Color.primary.opacity(0.72))
                    }
                    .font(.callout)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            animateGlow = true
            animatePulse = true
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Components

private struct StatChip: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .imageScale(.large)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline).foregroundStyle(Color.primary.opacity(0.72))
                Text(value).font(.title3.weight(.semibold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14).strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct ActionTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).imageScale(.large)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(Color.primary.opacity(0.72))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.72))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private struct AnimatedBackground: View {
    @State private var shift: CGFloat = 0

    var body: some View {
        // Tesla-ish minimal look: dark-to-neutral gradient with a drifting highlight
        ZStack {
            LinearGradient(
                colors: [
                    Color(.sRGB, red: 0.04, green: 0.04, blue: 0.05, opacity: 1),
                    Color(.sRGB, red: 0.10, green: 0.10, blue: 0.12, opacity: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                AngularGradient(
                    gradient: Gradient(colors: [
                        .white.opacity(0.08),
                        .clear,
                        .white.opacity(0.06),
                        .clear
                    ]),
                    center: .center,
                    startAngle: .degrees(Double(shift)),
                    endAngle: .degrees(Double(shift) + 180)
                )
                .blendMode(.softLight)
            )
            .overlay(
                RadialGradient(
                    colors: [.black.opacity(0.0), .black.opacity(0.25)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 800
                )
            )
        }
        .task {
            // Subtle continuous drift
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                shift = 360
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashWelcomeView(
        onStart: {},
        onImportTeslaFi: {},
        onAddEntry: {},
        onOpenCalculators: {},
        onOpenDashboard: {},
        metrics: .init(monthCost: "$142", costPerMile: "$0.09", homeRate: "$0.1049/kWh", sessionsImported: "218")
    )
    .preferredColorScheme(.dark)
}
