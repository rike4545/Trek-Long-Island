// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

@MainActor
struct TrekNewsView: View {
    @Environment(\.colorScheme) private var scheme

    private let sources: [TrekNewsSource] = [
        .init(
            title: "Reddit: r/startrek (Newest)",
            subtitle: "Latest community posts and discussion threads.",
            urlString: "https://www.reddit.com/r/startrek/new/"
        ),
        .init(
            title: "TrekNews.net",
            subtitle: "News coverage, interviews, and release updates.",
            urlString: "https://treknews.net/"
        ),
        .init(
            title: "TrekCore Blog",
            subtitle: "Editorial posts and Star Trek production updates.",
            urlString: "https://blog.trekcore.com/"
        ),
        .init(
            title: "StarTrek.com",
            subtitle: "Official Star Trek site and announcements.",
            urlString: "https://www.startrek.com/"
        )
    ]

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard

                    ForEach(sources) { source in
                        TrekNewsSourceCard(source: source)
                            .tliCard()
                    }
                }
                .adaptiveContentWidth(
                    maxWidth: TLILayout.defaultContentMaxWidth,
                    horizontalPadding: 18,
                    verticalPadding: 0
                )
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Trek News")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .tliFixedBottomAdSlot()
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trek News")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Quick links to active Star Trek news and community sources.")
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .tliCard()
    }
}

private struct TrekNewsSource: Identifiable {
    let title: String
    let subtitle: String
    let urlString: String
    var id: String { urlString }

    var url: URL? { URL(string: urlString) }
}

private struct TrekNewsSourceCard: View {
    @Environment(\.colorScheme) private var scheme
    let source: TrekNewsSource

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(source.title)
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(source.subtitle)
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            if let url = source.url {
                Link(destination: url) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                        Text("Open Source")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(TLITheme.accent(scheme))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        TrekNewsView()
    }
}
#endif
