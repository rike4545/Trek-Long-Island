// Copyright Bryan Carroll. All rights reserved.
//
//  TribblesBannerView.swift
//  Trek Long Island
//
//  Tribbles banner
//  • Light, playful “tribble advisory” card
//  • Risa glass style (no starfield)
//  • Can be dismissed + optionally tapped for more info
//

import SwiftUI

@MainActor
struct TribblesBannerView: View {
    @Environment(\.colorScheme) private var scheme

    /// Persisted dismissal so the banner doesn’t keep coming back.
    @AppStorage("TLI.hideTribblesBanner") private var isHidden: Bool = false

    /// Optional tap handler if the host wants to navigate to a detail screen.
    let onTap: (() -> Void)?

    // MARK: - Init

    init(onTap: (() -> Void)? = nil) {
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        if !isHidden {
            content
        }
    }

    private var content: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(RisaTheme.cardBorder(scheme).opacity(0.9), lineWidth: 1)
                )

            tapContent

            // Dismiss “X” button
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    isHidden = true
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(RisaTheme.textSecondary(scheme).opacity(0.9))
                    .padding(8)
            }
            .accessibilityLabel("Dismiss tribbles banner")
        }
        .padding(1) // gives the stroke some breathing room in stacks
    }

    @ViewBuilder
    private var tapContent: some View {
        if let onTap {
            Button(action: onTap) {
                bannerContent
            }
            .buttonStyle(.plain)
        } else {
            bannerContent
        }
    }

    private var bannerContent: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.95, green: 0.80, blue: 0.60),
                                Color(red: 0.80, green: 0.60, blue: 0.40),
                                Color(red: 0.95, green: 0.80, blue: 0.60)
                            ]),
                            center: .center
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .shadow(radius: 2)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Tribbles Aboard")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))

                    Text("Fun notice")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(RisaTheme.accentSoft(scheme))
                        )
                        .foregroundStyle(RisaTheme.textPrimary(scheme))
                }

                Text("You may encounter tribbles around the convention. They’re adorable, mostly harmless, and excellent at multiplying.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(RisaTheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    pill(icon: "exclamationmark.triangle.fill", text: "Do not feed after midnight")
                    pill(icon: "camera.fill", text: "Photo ops welcome")
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

    private func pill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(.caption2, design: .rounded).weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(RisaTheme.cardBackground(scheme).opacity(0.8))
        )
        .overlay(
            Capsule()
                .stroke(RisaTheme.cardBorder(scheme).opacity(0.8), lineWidth: 0.5)
        )
        .foregroundStyle(RisaTheme.textSecondary(scheme))
    }
}

// MARK: - Previews

#Preview("Tribbles Banner – Dark") {
    ZStack {
        TLITheme.backgroundGradient(.dark).ignoresSafeArea()
        VStack {
            TribblesBannerView()
                .padding()
            Spacer()
        }
    }
    .environment(\.colorScheme, .dark)
}

#Preview("Tribbles Banner – Light") {
    ZStack {
        TLITheme.backgroundGradient(.light).ignoresSafeArea()
        VStack {
            TribblesBannerView()
                .padding()
            Spacer()
        }
    }
    .environment(\.colorScheme, .light)
}
