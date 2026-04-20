// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

@MainActor
struct ShopSimonAffiliateAdView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL

    @State private var didTrackImpression = false

    private let clickURL: URL
    private let impressionURL: URL?
    private let creativeImageURL: URL

    init(clickURL: URL, impressionURL: URL? = nil, creativeImageURL: URL) {
        self.clickURL = clickURL
        self.impressionURL = impressionURL
        self.creativeImageURL = creativeImageURL
    }

    var body: some View {
        Button {
            openURL(clickURL)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text("Sponsored")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                AsyncImage(url: creativeImageURL) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(TLITheme.cardBackground(scheme))
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    case .failure:
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(TLITheme.cardBackground(scheme))
                            .overlay {
                                VStack(spacing: 4) {
                                    Image(systemName: "bag.fill")
                                        .font(.headline)
                                    Text("Shop Simon")
                                        .font(.footnote.weight(.semibold))
                                }
                                .foregroundStyle(TLITheme.textSecondary(scheme))
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 170)

                HStack {
                    Text("Open Offer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TLITheme.cardBackground(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(TLITheme.border(scheme), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            sendImpressionIfNeeded()
        }
        .accessibilityLabel("Sponsored Shop Simon offer")
        .accessibilityHint("Opens the affiliate destination")
    }

    private func sendImpressionIfNeeded() {
        guard didTrackImpression == false else { return }
        guard let impressionURL else { return }
        didTrackImpression = true

        var request = URLRequest(url: impressionURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 8
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        URLSession.shared.dataTask(with: request).resume()
    }
}

#if DEBUG
#Preview {
    ShopSimonAffiliateAdView(
        clickURL: URL(string: "https://click.linksynergy.com/link?id=rG4d7%2fdjvVM&offerid=1949172.507459946392012825333997&type=2&murl=https%3A%2F%2Fshop.simon.com%2Fproducts%2Fwomens-adidas-avacourt-2-tennis-shoes-2%3Fvariant%3D43416018583612")!,
        impressionURL: URL(string: "https://ad.linksynergy.com/fs-bin/show?id=rG4d7%2fdjvVM&bids=1949172.507459946392012825333997&type=2&subid=0")!,
        creativeImageURL: URL(string: "https://cdn.shopify.com/s/files/1/0291/4536/6588/files/a8dde58a39e04a0695a071f44da116e1.jpg?v=1755340558")!
    )
        .padding()
        .preferredColorScheme(.dark)
}
#endif
