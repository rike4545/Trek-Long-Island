// Copyright Bryan Carroll. All rights reserved.
//
//  LibraryForTheKindView.swift
//  Trek Long Island
//
//  Clean, non-messy resource page:
//  - Simple “About” + clear actions
//  - Opens Website/Donate in SFSafariViewController (in-app Safari)
//  Swift 6 • iOS 17+
//

import SwiftUI
#if canImport(SafariServices)
import SafariServices
#endif

@MainActor
struct LibraryForTheKindView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL

    private let pageURL = URL(string: "https://storytimesolidarity.com/library-for-the-kind/")!
    private let donateURL = URL(string: "https://givebutter.com/mTTOdx")!

    @State private var safariItem: TLI_LFTK_SafariItem?

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    headerCard

                    actionCard

                    infoCard(
                        title: "What this is",
                        body: "A children’s book charity focused on inclusive, kind, affirming books — helping more kids see themselves in stories."
                    )

                    infoCard(
                        title: "Why it’s in Trek Long Island",
                        body: "Trek is about community, inclusion, and doing good. This is a simple way to learn more or help out."
                    )

                    footerNote
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Library for the Kind")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: pageURL)
                Button {
                    presentSafari(pageURL)
                } label: {
                    Image(systemName: "safari")
                }
                .accessibilityLabel("Open Website")
            }
        }
        #if canImport(SafariServices)
        .sheet(item: $safariItem) { item in
            TLI_LFTK_SafariSheet(url: item.url)
                .ignoresSafeArea()
        }
        #endif
    }

    // MARK: - Sections

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.thinMaterial)
                    Image(systemName: "books.vertical.fill")
                        .font(.title2)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Library for the Kind")
                        .font(.title3.weight(.semibold))
                    Text("Where every child sees themselves in a book")
                        .font(.subheadline)
                        .opacity(0.85)
                }

                Spacer()
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)

            Button {
                presentSafari(donateURL)
            } label: {
                Label("Donate", systemImage: "heart.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                presentSafari(pageURL)
            } label: {
                Label("Open Website", systemImage: "globe")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                openURL(pageURL)
            } label: {
                Label("Open in Safari (external)", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .opacity(0.95)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func infoCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(body)
                .font(.body)
                .opacity(0.9)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var footerNote: some View {
        Text("Content and donations are handled on the official website.")
            .font(.footnote)
            .opacity(0.75)
            .padding(.top, 4)
    }

    // MARK: - Safari Presentation

    private func presentSafari(_ url: URL) {
        #if canImport(SafariServices)
        safariItem = TLI_LFTK_SafariItem(url: url)
        #else
        openURL(url)
        #endif
    }
}

// MARK: - Safari helpers (unique names to avoid collisions)

private struct TLI_LFTK_SafariItem: Identifiable {
    let url: URL
    var id: URL { url }
}

#if canImport(SafariServices)
private struct TLI_LFTK_SafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif
