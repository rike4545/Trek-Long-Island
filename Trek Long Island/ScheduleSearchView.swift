// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

/// A searchable schedule list with navigation to event detail.
struct ScheduleSearchView: View {
    @State private var searchText: String = ""

    struct Event: Identifiable {
        let title: String
        let date: Date
        let room: String
        var id: String { "\(title)|\(room)|\(date.timeIntervalSinceReferenceDate)" }
    }
    // Sample data; replace with real source
    private var allEvents: [Event] = [
        Event(title: "Opening Ceremonies", date: Date(), room: "Main Stage"),
        Event(title: "Starship Engineering Panel", date: Date().addingTimeInterval(3600), room: "Room A"),
        Event(title: "Vulcan Philosophy Q&A", date: Date().addingTimeInterval(7200), room: "Room B"),
    ]

    private var filteredEvents: [Event] {
        if searchText.isEmpty {
            return allEvents
        } else {
            return allEvents.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.room.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search events...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)

            // List of filtered events
            List(filteredEvents) { event in
                NavigationLink(destination: ScheduleEventDetailView(event: event)) {
                    ScheduleEventRow(event: event)
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Search Schedule")
    }
}

// MARK: - Row & Detail

struct ScheduleEventRow: View {
    let event: ScheduleSearchView.Event
    var body: some View {
        VStack(alignment: .leading) {
            Text(event.title)
                .font(.headline)
            Text(event.date, style: .time)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ScheduleEventDetailView: View {
    let event: ScheduleSearchView.Event
    var body: some View {
        VStack(spacing: 16) {
            Text(event.title)
                .font(.largeTitle).bold()
            Text(event.room)
                .font(.title2).foregroundColor(.secondary)
            Divider()
            Text("\(event.date, style: .date) at \(event.date, style: .time)")
                .font(.body)
            Spacer()
        }
        .padding()
        .navigationTitle("Event Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
struct ScheduleSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ScheduleSearchView()
        }
    }
}
