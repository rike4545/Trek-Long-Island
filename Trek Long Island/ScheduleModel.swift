// Copyright Bryan Carroll. All rights reserved.
import Foundation
import Combine

class ScheduleModel: ObservableObject {
    @Published var allEvents: [RisaScheduleEvent] = []
    @Published var filteredEvents: [RisaScheduleEvent] = []
    private var debounceWorkItem: DispatchWorkItem?

    func load(events: [RisaScheduleEvent]) {
        self.allEvents = events
        self.filteredEvents = events
    }

    func search(keyword: String) {
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem(block: {
            DispatchQueue.main.async {
                if keyword.isEmpty {
                    self.filteredEvents = self.allEvents
                } else {
                    self.filteredEvents = self.allEvents.filter {
                        $0.title.localizedCaseInsensitiveContains(keyword) ||
                        $0.description.localizedCaseInsensitiveContains(keyword)
                    }
                }
            }
        })

        debounceWorkItem = workItem
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    func sortByStartDate() {
        filteredEvents.sort { $0.startDate < $1.startDate }
    }
}
