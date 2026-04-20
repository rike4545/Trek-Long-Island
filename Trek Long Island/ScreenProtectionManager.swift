// Copyright Bryan Carroll. All rights reserved.
import SwiftUI
import UIKit

@MainActor
final class ScreenProtectionManager {
    static let shared = ScreenProtectionManager()
    
    private var overlayWindow: UIWindow?
    private var captureObserver: NSObjectProtocol?
    private var activeObserver: NSObjectProtocol?
    private var resignObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?
    private var appSwitcherProtectionActive = false

    private init() {}

    func start() {
        captureObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateVisibility()
            }
        }

        activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.appSwitcherProtectionActive = false
                self?.updateVisibility()
            }
        }
        
        resignObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.appSwitcherProtectionActive = true
                self?.updateVisibility()
            }
        }
        
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.appSwitcherProtectionActive = true
                self?.updateVisibility()
            }
        }

        updateVisibility()
    }

    private func updateVisibility() {
        let isCaptured = currentScreenIsCaptured()
        if appSwitcherProtectionActive || isCaptured {
            showOverlay(captureActive: isCaptured, appSwitcherActive: appSwitcherProtectionActive)
        } else {
            hideOverlay()
        }
    }

    private func showOverlay(captureActive: Bool, appSwitcherActive: Bool) {
        guard overlayWindow == nil else {
            if let host = overlayWindow?.rootViewController as? UIHostingController<ScreenProtectionOverlayView> {
                host.rootView = ScreenProtectionOverlayView(
                    captureActive: captureActive,
                    appSwitcherActive: appSwitcherActive
                )
            }
            overlayWindow?.isHidden = false
            return
        }

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .sorted(by: { lhs, rhs in
                activationPriority(lhs.activationState) < activationPriority(rhs.activationState)
            })
            .first else {
            return
        }

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .black
        window.rootViewController = UIHostingController(
            rootView: ScreenProtectionOverlayView(
                captureActive: captureActive,
                appSwitcherActive: appSwitcherActive
            )
        )
        window.isUserInteractionEnabled = false
        window.isHidden = false
        overlayWindow = window
    }

    private func currentScreenIsCaptured() -> Bool {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .sorted(by: { lhs, rhs in
                activationPriority(lhs.activationState) < activationPriority(rhs.activationState)
            })

        return scenes.first?.screen.isCaptured ?? false
    }
    
    private func activationPriority(_ state: UIScene.ActivationState) -> Int {
        switch state {
        case .foregroundActive: return 0
        case .foregroundInactive: return 1
        case .background: return 2
        case .unattached: return 3
        @unknown default: return 4
        }
    }

    private func hideOverlay() {
        overlayWindow?.isHidden = true
        overlayWindow = nil
    }
}

private struct ScreenProtectionOverlayView: View {
    let captureActive: Bool
    let appSwitcherActive: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 30, weight: .semibold))
                Text(captureActive ? "Screen capture blocked" : "Screen protected")
                    .font(.headline)
                Text(appSwitcherActive ? "Hidden in app switcher." : "For security, this screen is hidden.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.white)
            .padding(24)
        }
    }
}
