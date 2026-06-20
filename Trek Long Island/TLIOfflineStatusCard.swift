// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

struct TLIOfflineStatusCard: View {
    let title: String
    let detail: String
    let isOffline: Bool
    let lastSyncDate: Date?
    let loadedFromCache: Bool
    let actionTitle: String?
    let action: (() -> Void)?

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: isOffline ? "wifi.slash" : "checkmark.circle")
                    .foregroundStyle(isOffline ? .orange : .green)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Spacer(minLength: 8)

                Text(isOffline ? "Offline" : "Online")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isOffline ? .orange : .green)
            }

            Text(detail)
                .font(.footnote)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if let lastSyncDate {
                    Text(
                        loadedFromCache
                        ? "Using cache • last sync \(lastSyncDate.formatted(date: .abbreviated, time: .shortened))"
                        : "Last sync \(lastSyncDate.formatted(date: .abbreviated, time: .shortened))"
                    )
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
                } else {
                    Text(loadedFromCache ? "Using cached data" : "No sync timestamp available")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.72))
                }

                Spacer(minLength: 8)

                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(12)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }
}
