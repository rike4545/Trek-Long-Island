// Copyright Bryan Carroll. All rights reserved.
//
//  SplashScreenView.swift
//  Trek Long Island – Dark PADD Splash, Stage-based
//

import SwiftUI

private let trekLogo    = "Splash6"
private let sponsorLogo = "appsponsor1"

private enum SplashStage {
    case trek
    case sponsor
}

struct SplashScreenView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("TLI.Profile.displayName") private var displayName: String = ""
    @AppStorage("TLI.Profile.rank") private var rankRaw: String = TLIProfileRank.captain.rawValue

    @State private var stage: SplashStage = .trek
    @State private var cardOpacity: Double = 0
    @State private var stardate: String = formattedStardate()
    @State private var hasRequestedDismissal = false

    let isSponsorActive: Bool
    let onFinish: () -> Void

    init(isSponsorActive: Bool = true, onFinish: @escaping () -> Void) {
        self.isSponsorActive = isSponsorActive
        self.onFinish = onFinish
    }

    var body: some View {
        GeometryReader { geo in
            Button(action: dismiss) {
                ZStack {
                // Background follows app theme + dark veil
                    TLITheme.backgroundGradient(scheme)
                        .ignoresSafeArea()

                    Color.black.opacity(scheme == .dark ? 0.60 : 0.50)
                        .ignoresSafeArea()

                    let safeTop = max(geo.safeAreaInsets.top, 24)
                    let safeBottom = max(geo.safeAreaInsets.bottom, 18)
                    let isCompactHeight = geo.size.height < 720
                    let cardWidth = min(geo.size.width - 48, 420)
                    let cardHeight = min(
                        max(geo.size.height - safeTop - safeBottom - (isCompactHeight ? 156 : 178), 330),
                        isCompactHeight ? 460 : 560
                    )

                    VStack(spacing: isCompactHeight ? 10 : 16) {
                        Spacer(minLength: safeTop)

                        glassPanel(isCompactHeight: isCompactHeight)
                            .frame(width: cardWidth, height: cardHeight)
                            .opacity(cardOpacity)

                        Text("""
Star Trek and all related marks, logos and characters are solely owned by CBS Studios Inc. and Paramount Pictures. This fan production is not endorsed by, sponsored by, nor affiliated with CBS, Paramount Pictures, or any other Star Trek franchise.
""")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.82)
                            .padding(.horizontal, geo.size.width < 360 ? 18 : 28)
                            .accessibilityLabel("Star Trek and related marks disclaimer. This fan production is not endorsed by, sponsored by, nor affiliated with CBS, Paramount Pictures, or any other Star Trek franchise.")

                        Text("Tap anywhere to continue")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .padding(.bottom, safeBottom)

                        Spacer(minLength: 0)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            .onAppear(perform: startTimeline)
        }
    }

    // MARK: - Glass PADD Panel

    private func glassPanel(isCompactHeight: Bool) -> some View {
        let accent = RisaTheme.accentGold(scheme)
        let logoSize: CGFloat = isCompactHeight ? 168 : 220
        let verticalPadding: CGFloat = isCompactHeight ? 16 : 20
        let horizontalPadding: CGFloat = isCompactHeight ? 22 : 26
        let panelSpacing: CGFloat = isCompactHeight ? 12 : 18

        return VStack(spacing: panelSpacing) {
            // LCARS header
            HStack(spacing: 8) {
                Capsule()
                    .fill(accent)
                    .frame(width: 72, height: 6)
                Capsule()
                    .fill(accent.opacity(0.6))
                    .frame(width: 46, height: 6)

                Spacer()

                Text("AWAY  TEAM  PADD")
                    .font(.system(.caption2, design: .monospaced))
                    .textCase(.uppercase)
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 4)

            // Logo + deflector glow
            ZStack {
                DeflectorGlow()
                    .frame(width: logoSize, height: logoSize)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                if stage == .trek || !isSponsorActive {
                    Image(trekLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: logoSize)
                        .transition(.opacity)
                }

                if stage == .sponsor && isSponsorActive {
                    Image(sponsorLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: logoSize)
                        .transition(.opacity)
                }
            }
            .padding(.top, isCompactHeight ? 0 : 4)
            .animation(.easeInOut(duration: 0.7), value: stage)

            // Title block – either Trek LI or sponsor presentation
            Group {
                if stage == .sponsor && isSponsorActive {
                    VStack(spacing: 8) {
                        Text("APP SPONSOR")
                            .font(.caption.monospaced())
                            .textCase(.uppercase)
                            .foregroundColor(.white.opacity(0.7))

                        Text("The Transporter Room Podcast")
                            .font(isCompactHeight ? .subheadline.weight(.semibold) : .headline.weight(.semibold))
                            .foregroundColor(accent)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)

                        Text("Proudly Presents")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))

                        Text("Trek Long Island")
                            .font(isCompactHeight ? .title3.bold() : .title2.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                } else {
                    VStack(spacing: 2) {
                        Text("Trek Long Island")
                            .font(.system(isCompactHeight ? .title3 : .title2, design: .rounded).weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text("Convention Companion")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.75))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
            }

            // Greeting + Stardate
            VStack(spacing: 8) {
                Text(greeting())
                    .font(.system(isCompactHeight ? .subheadline : .headline, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                HStack(spacing: 12) {
                    Capsule()
                        .fill(.white.opacity(0.22))
                        .frame(width: 58, height: 26)
                        .overlay(
                            Text("SD")
                                .font(.caption.monospaced())
                                .foregroundColor(.white)
                        )

                    Text(stardate)
                        .font(.footnote.monospaced())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.45))
                        .cornerRadius(8)
                }
            }

            // Event info
            VStack(spacing: 4) {
                Text(TLIConventionDates.displayRange)
                    .font(isCompactHeight ? .subheadline.weight(.semibold) : .headline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text("Hauppauge, New York · Sector 001")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.80))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.top, isCompactHeight ? 0 : 2)

            // Warp sweep “progress”
            WarpSweepBar()
                .frame(width: 180, height: 8)
                .padding(.top, isCompactHeight ? 0 : 4)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.94),
                            Color.black.opacity(0.88)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: Color.black.opacity(0.75),
                    radius: 20,
                    x: 0,
                    y: 18
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.20), lineWidth: 0.9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(accent.opacity(0.45), lineWidth: 1.2)
                .blur(radius: 2.0)
                .blendMode(.plusLighter)
        )
        .clipped()
    }

    // MARK: - Timeline

    private func startTimeline() {
        stardate = formattedStardate()

        withAnimation(.easeOut(duration: 0.8)) {
            cardOpacity = 1.0
        }

        if isSponsorActive {
            // Switch to sponsor stage after a beat
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeInOut(duration: 0.7)) {
                    stage = .sponsor
                }
            }
        }

        // Auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            dismiss()
        }
    }

    private func dismiss() {
        guard !hasRequestedDismissal else { return }
        hasRequestedDismissal = true

        withAnimation(.easeIn(duration: 0.6)) {
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onFinish()
        }
    }

    private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let rank = TLIProfileRank(rawValue: rankRaw) ?? .captain
        let commandName = TLIProfilePreferences.commandName(rank: rank, displayName: displayName)
        switch hour {
        case 5..<12:  return "Good morning, \(commandName)"
        case 12..<17: return "Good afternoon, \(commandName)"
        default:      return "Good evening, \(commandName)"
        }
    }
}

// MARK: - Supporting Views

struct DeflectorGlow: View {
    @Environment(\.colorScheme) private var scheme
    @State private var pulse = 0.0

    var body: some View {
        Circle()
            .fill(RisaTheme.accentGold(scheme).opacity(0.55))
            .blur(radius: 40)
            .scaleEffect(0.9 + 0.12 * pulse)
            .animation(
                .easeInOut(duration: 2.6).repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear { pulse = 1.0 }
    }
}

struct WarpSweepBar: View {
    @State private var offset: CGFloat = -260

    var body: some View {
        ZStack {
            Capsule().fill(.white.opacity(0.22))
            Capsule()
                .fill(.white.opacity(0.95))
                .frame(width: 80)
                .offset(x: offset)
                .animation(
                    .linear(duration: 2.0).repeatForever(autoreverses: false),
                    value: offset
                )
                .onAppear { offset = 260 }
        }
        .clipShape(Capsule())
    }
}

// MARK: - Stardate

private func formattedStardate(_ date: Date = Date()) -> String {
    TLIStardate.formatted(for: date)
}

// MARK: - Preview

#Preview {
    SplashScreenView(isSponsorActive: true) { }
        .preferredColorScheme(.dark)
}
