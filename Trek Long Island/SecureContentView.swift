// Copyright Bryan Carroll. All rights reserved.
import SwiftUI
import UIKit

/// Renders SwiftUI content inside a secure UIKit container so screenshots and recordings
/// are blocked similarly to secure text fields.
struct SecureContentView<Content: View>: UIViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(rootView: content)
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear

        let secureField = UITextField(frame: .zero)
        secureField.translatesAutoresizingMaskIntoConstraints = false
        secureField.isSecureTextEntry = true
        // Keep enabled so hosted content can receive touch/scroll/navigation events.
        secureField.isUserInteractionEnabled = true
        secureField.backgroundColor = .clear
        container.addSubview(secureField)

        NSLayoutConstraint.activate([
            secureField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            secureField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            secureField.topAnchor.constraint(equalTo: container.topAnchor),
            secureField.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let secureContainer = secureField.subviews.first ?? secureField
        secureContainer.isUserInteractionEnabled = true

        let hostingView = context.coordinator.hostingController.view!
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.backgroundColor = .clear
        secureContainer.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: secureContainer.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: secureContainer.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: secureContainer.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: secureContainer.bottomAnchor)
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.hostingController.rootView = content
    }

    final class Coordinator {
        let hostingController: UIHostingController<Content>

        init(rootView: Content) {
            self.hostingController = UIHostingController(rootView: rootView)
            self.hostingController.view.backgroundColor = .clear
        }
    }
}
