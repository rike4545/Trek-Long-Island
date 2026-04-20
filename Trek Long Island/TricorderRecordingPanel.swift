//
//  TricorderRecordingPanel.swift
//  Trek Long Island
//
//  Created by Bryan on 2/24/26.
//


// Copyright Bryan Carroll. All rights reserved.
//
//  HelloComputerTricorderView.swift
//  Trek Long Island
//
//  Tricorder-style animated recording panel for Hello, Computer.
//  Replaces the standard input bar while voice recording is active.
//
//  HOW TO INTEGRATE
//  ─────────────────────────────────────────────────────────────────
//  In HelloComputerView, find `private var inputBar: some View` and
//  wrap it so the tricorder panel swaps in during recording:
//
//      private var inputBar: some View {
//          ZStack(alignment: .bottom) {
//              // Normal input bar (hidden while recording)
//              normalInputBar
//                  .opacity(voiceInput.isRecording ? 0 : 1)
//
//              // Tricorder panel (shown while recording)
//              if voiceInput.isRecording {
//                  TricorderRecordingPanel(
//                      audioLevel: voiceInput.audioLevel,
//                      transcript: store.inputText,
//                      scheme: scheme,
//                      onStop: { voiceInput.stopRecording() }
//                  )
//                  .transition(.asymmetric(
//                      insertion: .scale(scale: 0.92).combined(with: .opacity),
//                      removal:   .scale(scale: 0.92).combined(with: .opacity)
//                  ))
//              }
//          }
//          .animation(.spring(response: 0.38, dampingFraction: 0.82), value: voiceInput.isRecording)
//      }
//
//  Rename the existing inputBar var to `normalInputBar`.
//
//  ─────────────────────────────────────────────────────────────────
//  Swift 6 • iOS 17+

import SwiftUI

// MARK: - TricorderRecordingPanel

/// Full-width panel that replaces the input bar while voice recording is active.
/// Displays a circular scan sweep, audio level bars, live transcript, and
/// cycling status text — all in a tricorder-inspired LCARS aesthetic.
struct TricorderRecordingPanel: View {

    let audioLevel: Float       // 0…1 from HelloComputerVoiceInputController
    let transcript: String      // store.inputText (live partial transcript)
    let scheme: ColorScheme
    let onStop: () -> Void

    // MARK: Animation state

    @State private var sweepAngle: Double = 0
    @State private var scanLineOffset: CGFloat = 0
    @State private var statusIndex: Int = 0
    @State private var blinkOn: Bool = true
    @State private var dataFlicker: Bool = false
    @State private var pulseScale: CGFloat = 1.0

    // MARK: Constants

    private let statusLabels = [
        "VOICE LOCK",
        "SCANNING…",
        "SIGNAL ACQUIRED",
        "PROCESSING",
        "VOICE LOCK",
    ]

    private let sweepColor   = Color(red: 0.25, green: 0.85, blue: 0.65)   // tricorder teal
    private let gridColor    = Color(red: 0.20, green: 0.70, blue: 0.55)
    private let accentOrange = Color(red: 1.00, green: 0.62, blue: 0.18)   // LCARS orange
    private let accentBlue   = Color(red: 0.28, green: 0.58, blue: 1.00)   // LCARS blue
    private let dimTeal      = Color(red: 0.10, green: 0.35, blue: 0.30)

    // MARK: Body

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────
            panelBackground

            VStack(spacing: 0) {

                // ── Top chrome strip ────────────────────────────────
                topChrome

                // ── Main content row ────────────────────────────────
                HStack(spacing: 12) {

                    // Circular sweep scanner
                    sweepCircle
                        .frame(width: 80, height: 80)

                    // Centre: waveform + transcript
                    VStack(alignment: .leading, spacing: 6) {
                        waveformBars
                        transcriptLine
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Stop button
                    stopButton
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                // ── Bottom data strip ───────────────────────────────
                bottomStrip
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(sweepColor.opacity(0.55), lineWidth: 1.2)
        )
        .shadow(color: sweepColor.opacity(scheme == .dark ? 0.30 : 0.12), radius: 16, x: 0, y: 4)
        .onAppear { startAnimations() }
        .onDisappear { }
    }

    // MARK: - Sub-views

    private var panelBackground: some View {
        ZStack {
            // Dark base
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(scheme == .dark
                      ? Color(red: 0.04, green: 0.10, blue: 0.09)
                      : Color(red: 0.07, green: 0.14, blue: 0.12))

            // Subtle radial glow behind the sweep circle
            RadialGradient(
                colors: [sweepColor.opacity(0.12), .clear],
                center: UnitPoint(x: 0.15, y: 0.5),
                startRadius: 0,
                endRadius: 120
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // Horizontal scan line that drifts top→bottom
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, sweepColor.opacity(0.18), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 18)
                    .offset(y: scanLineOffset * geo.size.height)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var topChrome: some View {
        HStack(spacing: 6) {
            // LCARS left elbow
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(accentOrange)
                .frame(width: 34, height: 10)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(accentBlue.opacity(0.8))
                .frame(width: 18, height: 10)

            Spacer()

            // Status label with blink
            HStack(spacing: 5) {
                Circle()
                    .fill(sweepColor)
                    .frame(width: 6, height: 6)
                    .opacity(blinkOn ? 1.0 : 0.2)

                Text(statusLabels[statusIndex])
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(sweepColor)
                    .tracking(2.5)
            }

            Spacer()

            // Signal strength micro-bars
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    let threshold = Float(i + 1) / 4.0
                    RoundedRectangle(cornerRadius: 1)
                        .fill(audioLevel >= threshold ? accentOrange : dimTeal)
                        .frame(width: 4, height: CGFloat(5 + i * 3))
                }
            }
            .animation(.easeInOut(duration: 0.08), value: audioLevel)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(accentOrange)
                .frame(width: 22, height: 10)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: Circular sweep

    private var sweepCircle: some View {
        ZStack {
            // Concentric range rings
            ForEach([0.90, 0.68, 0.46], id: \.self) { fraction in
                Circle()
                    .stroke(gridColor.opacity(0.35), lineWidth: 0.6)
                    .scaleEffect(fraction)
            }

            // Cross-hairs
            Path { p in
                p.move(to: CGPoint(x: 40, y: 0))
                p.addLine(to: CGPoint(x: 40, y: 80))
                p.move(to: CGPoint(x: 0, y: 40))
                p.addLine(to: CGPoint(x: 80, y: 40))
            }
            .stroke(gridColor.opacity(0.25), lineWidth: 0.5)

            // Sweep pie wedge
            SweepWedge(angle: sweepAngle)
                .fill(
                    AngularGradient(
                        colors: [sweepColor.opacity(0.0), sweepColor.opacity(0.45)],
                        center: .center,
                        startAngle: .degrees(sweepAngle - 55),
                        endAngle: .degrees(sweepAngle)
                    )
                )
                .clipShape(Circle())

            // Sweep leading edge line
            Path { p in
                let rad = Double(sweepAngle - 90) * .pi / 180
                let cx: Double = 40, cy: Double = 40, r: Double = 36
                p.move(to: CGPoint(x: cx, y: cy))
                p.addLine(to: CGPoint(x: cx + r * cos(rad), y: cy + r * sin(rad)))
            }
            .stroke(sweepColor, lineWidth: 1.5)

            // Audio level dot that pulses on the sweep edge
            let dotRad = Double(sweepAngle - 90) * .pi / 180
            let dotR: Double = 30 + Double(audioLevel) * 6
            Circle()
                .fill(sweepColor)
                .frame(width: 5, height: 5)
                .position(
                    x: 40 + dotR * cos(dotRad),
                    y: 40 + dotR * sin(dotRad)
                )
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 0.1), value: audioLevel)

            // Centre dot
            Circle()
                .fill(sweepColor)
                .frame(width: 5, height: 5)
        }
    }

    // MARK: Waveform bars

    private var waveformBars: some View {
        let barCount = 18
        return HStack(alignment: .center, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                let phase = Float(i) / Float(barCount - 1)
                // Each bar gets a sine-wave shaped envelope so the centre bars
                // are taller, with some randomness from the audio level.
                let envelope = sin(.pi * phase)
                let noise = Float.random(in: 0.6...1.0)   // per-bar variation
                let h = CGFloat(max(0.12, Double(audioLevel * envelope * noise)))
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(barGradient(for: i, total: barCount))
                    .frame(width: 3, height: 4 + h * 22)
                    .animation(
                        .easeInOut(duration: 0.09).delay(Double(i) * 0.005),
                        value: audioLevel
                    )
            }
        }
        .frame(height: 30)
    }

    private func barGradient(for index: Int, total: Int) -> LinearGradient {
        let t = Double(index) / Double(total - 1)
        // Colour shifts from teal → orange across the bar row
        let c1 = sweepColor.opacity(0.9)
        let c2 = accentOrange.opacity(0.75)
        return LinearGradient(
            colors: [t < 0.5 ? c1 : c2, sweepColor.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: Transcript

    private var transcriptLine: some View {
        HStack(spacing: 4) {
            Text(transcript.isEmpty ? "Listening…" : transcript)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(transcript.isEmpty
                                 ? sweepColor.opacity(0.45)
                                 : sweepColor.opacity(0.90))
                .lineLimit(2)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Cursor blink
            Rectangle()
                .fill(sweepColor)
                .frame(width: 6, height: 11)
                .opacity(blinkOn ? 1.0 : 0.0)
        }
    }

    // MARK: Stop button

    private var stopButton: some View {
        Button(action: onStop) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.red.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.red.opacity(0.4), lineWidth: 1)
                    )

                Image(systemName: "stop.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop voice input")
    }

    // MARK: Bottom strip

    private var bottomStrip: some View {
        HStack(spacing: 6) {
            // Flickering hex data (decorative)
            Text(dataFlicker ? "AF:3C:91:7E" : "B2:0D:4F:A8")
                .font(.system(size: 7, weight: .regular, design: .monospaced))
                .foregroundStyle(dimTeal.opacity(0.7))

            Spacer()

            // Level percentage readout
            Text(String(format: "SIG  %03d%%", Int(audioLevel * 100)))
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(sweepColor.opacity(0.6))
                .tracking(1.5)

            Spacer()

            Text("STARFLEET·VOICECOM")
                .font(.system(size: 7, weight: .regular, design: .monospaced))
                .foregroundStyle(dimTeal.opacity(0.7))
                .tracking(1)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
        .padding(.top, 4)
    }

    // MARK: - Animation Drivers

    private func startAnimations() {

        // Continuous sweep rotation
        withAnimation(
            .linear(duration: 2.8).repeatForever(autoreverses: false)
        ) {
            sweepAngle = 360
        }

        // Scan line drifts from top to bottom
        withAnimation(
            .linear(duration: 3.2).repeatForever(autoreverses: false)
        ) {
            scanLineOffset = 1.0
        }

        // Status label cycles every 2.5 s
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                statusIndex = (statusIndex + 1) % statusLabels.count
            }
        }

        // Cursor / dot blink
        Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                blinkOn.toggle()
            }
        }

        // Hex data flicker
        Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
            dataFlicker.toggle()
        }

        // Edge dot pulse on high audio level
        Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                pulseScale = audioLevel > 0.3 ? CGFloat.random(in: 0.85...1.25) : 1.0
            }
        }
    }
}

// MARK: - SweepWedge Shape

/// A pie/wedge shape used for the scanner sweep arc.
private struct SweepWedge: Shape {
    var angle: Double   // degrees, 0 = top, rotating clockwise

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) / 2 * 0.9
        let spanDeg: Double = 55   // wedge width
        let start = Angle.degrees(angle - spanDeg - 90)
        let end   = Angle.degrees(angle - 90)

        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy))
        p.addArc(
            center: CGPoint(x: cx, y: cy),
            radius: r,
            startAngle: start,
            endAngle: end,
            clockwise: false
        )
        p.closeSubpath()
        return p
    }
}


// MARK: - ─────────────────────────────────────────────────────────────
// MARK:   INTEGRATION GUIDE — HelloComputerView.swift changes
// MARK: ─────────────────────────────────────────────────────────────────
//
//  STEP 1: Rename `private var inputBar` → `private var normalInputBar`
//
//  STEP 2: Add a new `private var inputBar` that switches between the two:
//
//      private var inputBar: some View {
//          ZStack(alignment: .bottom) {
//              normalInputBar
//                  .opacity(voiceInput.isRecording ? 0 : 1)
//                  .allowsHitTesting(!voiceInput.isRecording)
//
//              if voiceInput.isRecording {
//                  TricorderRecordingPanel(
//                      audioLevel: voiceInput.audioLevel,
//                      transcript: store.inputText,
//                      scheme: scheme,
//                      onStop: { voiceInput.stopRecording() }
//                  )
//                  .transition(.asymmetric(
//                      insertion: .scale(scale: 0.94)
//                                   .combined(with: .opacity),
//                      removal:   .scale(scale: 0.94)
//                                   .combined(with: .opacity)
//                  ))
//              }
//          }
//          .animation(
//              .spring(response: 0.38, dampingFraction: 0.80),
//              value: voiceInput.isRecording
//          )
//      }
//
//  STEP 3: In the existing inputBar (now normalInputBar), the mic button
//          can keep its current styling — TricorderRecordingPanel provides
//          its own stop button, so no mic button is shown while recording.
//
//  STEP 4: The existing .onChange(of: voiceInput.transcript) handler that
//          sets store.inputText still works unchanged. The panel reads
//          store.inputText directly for its live transcript display.
//
