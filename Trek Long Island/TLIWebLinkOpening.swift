// Copyright Bryan Carroll. All rights reserved.
//
//  TLIWebLinkOpening.swift
//  Trek Long Island
//

import SwiftUI
#if canImport(SafariServices)
import SafariServices
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum TLIWebLinkOpeningPreference: String, CaseIterable, Identifiable {
    case insideApp
    case defaultBrowser

    static let storageKey = "TLI.WebLinks.openingPreference"
    static let defaultPreference: TLIWebLinkOpeningPreference = .insideApp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .insideApp:
            return "Inside App"
        case .defaultBrowser:
            return "Default Browser"
        }
    }

    var subtitle: String {
        switch self {
        case .insideApp:
            return "Keep web pages in a Safari sheet inside Trek Long Island."
        case .defaultBrowser:
            return "Open websites in the device browser so the address bar is visible."
        }
    }

    var systemImage: String {
        switch self {
        case .insideApp:
            return "app.badge"
        case .defaultBrowser:
            return "safari"
        }
    }

    static func fromStoredRawValue(_ rawValue: String) -> TLIWebLinkOpeningPreference {
        TLIWebLinkOpeningPreference(rawValue: rawValue) ?? defaultPreference
    }
}

private struct TLIWebLinkItem: Identifiable {
    let url: URL
    var id: URL { url }
}

enum TLIExternalWebOpener {
    @MainActor
    static func open(_ url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #else
        _ = url
        #endif
    }
}

private struct TLIWebLinkOpeningModifier: ViewModifier {
    @Environment(\.openURL) private var systemOpenURL
    @AppStorage(TLIWebLinkOpeningPreference.storageKey) private var preferenceRaw: String = TLIWebLinkOpeningPreference.defaultPreference.rawValue
    @State private var presentedWebLink: TLIWebLinkItem?

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                guard isWebURL(url) else {
                    systemOpenURL(url)
                    return .handled
                }

                switch TLIWebLinkOpeningPreference.fromStoredRawValue(preferenceRaw) {
                case .insideApp:
                    #if canImport(SafariServices)
                    presentedWebLink = TLIWebLinkItem(url: url)
                    #else
                    systemOpenURL(url)
                    #endif
                case .defaultBrowser:
                    systemOpenURL(url)
                }

                return .handled
            })
            #if canImport(SafariServices)
            .sheet(item: $presentedWebLink) { item in
                TLIWebLinkSafariView(url: item.url)
                    .ignoresSafeArea()
            }
            #endif
    }

    private func isWebURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
}

#if canImport(SafariServices)
private struct TLIWebLinkSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif

extension View {
    func tliWebLinkOpening() -> some View {
        modifier(TLIWebLinkOpeningModifier())
    }
}
