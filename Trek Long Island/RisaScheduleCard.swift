// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

private let risaScheduleCardTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

struct RisaScheduleCard: View {
    let event: RisaScheduleEvent
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                Spacer()

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Text(event.location)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("\(formattedTimeRange(start: event.startDate, end: event.endDate))")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding()
        .background(colorScheme == .dark ? Color.black.opacity(0.6) : Color.white.opacity(0.85))
        .cornerRadius(12)
        .shadow(radius: 3)
    }

    private func formattedTimeRange(start: Date, end: Date) -> String {
        "\(risaScheduleCardTimeFormatter.string(from: start)) - \(risaScheduleCardTimeFormatter.string(from: end))"
    }
}
