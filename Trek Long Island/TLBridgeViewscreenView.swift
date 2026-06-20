//
//  TLBridgeViewscreenView.swift
//  Trek Long Island
//

import AVFoundation
import SwiftUI
import UIKit

@MainActor
struct TLBridgeViewscreenView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var isRequestingCameraAccess = false

    var body: some View {
        ZStack {
            if cameraStatus == .authorized {
                BridgeCameraPreview()
                    .ignoresSafeArea()
            } else {
                permissionBackground
            }

            viewscreenOverlay
        }
        .background(.black)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await refreshCameraAccessIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }
    }

    private var permissionBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 7 / 255, green: 16 / 255, blue: 32 / 255),
                    Color(red: 18 / 255, green: 26 / 255, blue: 40 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "camera.slash.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(BridgeViewscreenPalette.orange)

                    Text(permissionTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(BridgeViewscreenPalette.textBright)

                    Text(permissionDetail)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(BridgeViewscreenPalette.textMuted)

                    if cameraStatus == .notDetermined || isRequestingCameraAccess {
                        Button(isRequestingCameraAccess ? "Requesting Access..." : "Enable Camera") {
                            Task {
                                await requestCameraAccess()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(BridgeViewscreenPalette.gold)
                        .disabled(isRequestingCameraAccess)
                    } else {
                        Button("Open Settings") {
                            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                            openURL(settingsURL)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(BridgeViewscreenPalette.orange)
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var viewscreenOverlay: some View {
        GeometryReader { geometry in
            let safeTop = max(geometry.safeAreaInsets.top, 12)
            let safeBottom = max(geometry.safeAreaInsets.bottom, 8)
            let availableHeight = max(geometry.size.height - safeTop - safeBottom, 240)
            let baseTopPadding: CGFloat = 78
            let baseRailGap: CGFloat = 48
            let railHeight: CGFloat = 24
            let viewportWidth = max(geometry.size.width - 56, 180)
            let baseViewportHeight = min(geometry.size.height * 0.4, viewportWidth * 0.62)
            let requiredHeight = baseTopPadding + baseViewportHeight + baseRailGap + railHeight + 18
            let compressRatio = min(1, availableHeight / max(requiredHeight, 1))

            let topPadding = baseTopPadding * compressRatio
            let railGap = baseRailGap * compressRatio
            let viewportHeight = max(140, baseViewportHeight * compressRatio)
            let viewportTop = safeTop + topPadding
            let viewportY = viewportTop + viewportHeight / 2
            let viewportRect = CGRect(
                x: (geometry.size.width - viewportWidth) / 2,
                y: viewportTop,
                width: viewportWidth,
                height: viewportHeight
            )
            let lowerRailY = min(
                viewportRect.maxY + railGap,
                geometry.size.height - safeBottom - railHeight / 2 - 8
            )

            ZStack {
                wallOverlay(frame: viewportRect)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(BridgeViewscreenPalette.cyanGlow, lineWidth: 3.5)
                    .shadow(color: BridgeViewscreenPalette.cyanGlow.opacity(0.85), radius: 10)
                    .frame(width: viewportWidth, height: viewportHeight)
                    .position(x: geometry.size.width / 2, y: viewportY)

                sidePillars(viewportRect: viewportRect)

                lowerRails(width: viewportWidth)
                    .position(x: geometry.size.width / 2, y: lowerRailY)

                if cameraStatus != .authorized {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                }
            }
            .overlay(alignment: .topLeading) {
                HStack(spacing: 10) {
                    Text("USS LONG ISLAND")
                        .font(.headline.weight(.bold))
                        .tracking(2.2)
                        .foregroundStyle(BridgeViewscreenPalette.textDim)

                    if cameraStatus == .authorized {
                        Label("CAMERA LIVE", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(BridgeViewscreenPalette.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.5), in: Capsule())
                    }
                }
                .padding(.leading, 28)
                .padding(.top, safeTop + 14)
            }
            .overlay(alignment: .bottomLeading) {
                if cameraStatus == .authorized {
                    Text("MAIN VIEWSCREEN")
                        .font(.caption.weight(.bold))
                        .tracking(1.8)
                        .foregroundStyle(BridgeViewscreenPalette.textMuted)
                        .padding(.leading, 28)
                        .padding(.bottom, safeBottom + 8)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(BridgeViewscreenPalette.orange, in: Capsule())
            }
            .padding(.top, 20)
            .padding(.trailing, 16)
        }
    }

    private func wallOverlay(frame: CGRect) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.66),
                    BridgeViewscreenPalette.wallBlue.opacity(0.62),
                    Color.black.opacity(0.70)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }

    private func sidePillars(viewportRect: CGRect) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(BridgeViewscreenPalette.sidePanel)
                .frame(width: 28, height: 116)

            Spacer(minLength: viewportRect.width + 24)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(BridgeViewscreenPalette.sidePanel)
                .frame(width: 28, height: 116)
        }
        .padding(.horizontal, 16)
        .position(x: viewportRect.midX, y: viewportRect.midY)
    }

    private func lowerRails(width: CGFloat) -> some View {
        HStack(spacing: 32) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(BridgeViewscreenPalette.orange)
                .frame(width: width * 0.24, height: 24)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(BridgeViewscreenPalette.orange)
                .frame(width: width * 0.24, height: 24)
        }
    }

    private func refreshCameraAccessIfNeeded() async {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        cameraStatus = currentStatus

        guard currentStatus == .notDetermined else { return }
        await requestCameraAccess()
    }

    private func requestCameraAccess() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraStatus = status

        guard status == .notDetermined else { return }

        isRequestingCameraAccess = true
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraStatus = granted ? .authorized : .denied
        isRequestingCameraAccess = false
    }

    private var permissionTitle: String {
        switch cameraStatus {
        case .notDetermined:
            return isRequestingCameraAccess ? "Requesting camera permission..." : "Camera permission is required for the viewscreen."
        case .restricted:
            return "Camera access is restricted on this device."
        case .denied:
            return "Bridge sensors are offline until camera access is enabled."
        default:
            return "Camera permission is required for the viewscreen."
        }
    }

    private var permissionDetail: String {
        switch cameraStatus {
        case .notDetermined:
            return "Tap Enable Camera and allow access when iOS prompts you."
        case .restricted, .denied:
            return "Open Settings and set Camera access to On for Trek Long Island."
        default:
            return "Camera access is required."
        }
    }
}

private struct BridgeCameraPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BridgeCameraViewController {
        BridgeCameraViewController()
    }

    func updateUIViewController(_ uiViewController: BridgeCameraViewController, context: Context) {}
}

private final class BridgeCameraViewController: UIViewController {
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "me.treklongisland.bridge.viewscreen.camera")
    private var isConfigured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureCamera()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func configureCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        guard captureSession.canAddInput(input) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(input)

        captureSession.commitConfiguration()

        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
        isConfigured = true
    }

    private func startSession() {
        guard isConfigured, !captureSession.isRunning else { return }
        sessionQueue.async { [captureSession] in
            captureSession.startRunning()
        }
    }

    private func stopSession() {
        guard isConfigured, captureSession.isRunning else { return }
        sessionQueue.async { [captureSession] in
            captureSession.stopRunning()
        }
    }
}

private enum BridgeViewscreenPalette {
    static let orange = Color(red: 245 / 255, green: 170 / 255, blue: 91 / 255)
    static let sidePanel = Color(red: 160 / 255, green: 66 / 255, blue: 21 / 255)
    static let cyanGlow = Color(red: 116 / 255, green: 231 / 255, blue: 1)
    static let wallBlue = Color(red: 48 / 255, green: 73 / 255, blue: 112 / 255)
    static let gold = Color(red: 250 / 255, green: 212 / 255, blue: 116 / 255)
    static let red = Color(red: 235 / 255, green: 118 / 255, blue: 124 / 255)
    static let green = Color(red: 119 / 255, green: 232 / 255, blue: 153 / 255)
    static let textBright = Color.white
    static let textMuted = Color(red: 208 / 255, green: 217 / 255, blue: 232 / 255)
    static let textDim = Color(red: 150 / 255, green: 166 / 255, blue: 192 / 255)
}

#Preview {
    TLBridgeViewscreenView()
}
