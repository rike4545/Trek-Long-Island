// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

struct EventDetailView: View {
    let event: ICSParsedEvent

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("RisaTopBackground"),
                    Color("RisaBottomBackground")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(event.title)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(Color("TextPrimary"))
                        .padding(.top)

                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("\(event.startDate.formatted(date: .abbreviated, time: .shortened)) – \(event.endDate.formatted(date: .abbreviated, time: .shortened))")
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .foregroundColor(.white)

                        Label {
                            Text(event.room)
                        } icon: {
                            Image(systemName: "mappin.and.ellipse")
                        }
                        .foregroundColor(.white)
                    }

                    if !event.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        LinkifiedText(
                            text: event.description,
                            font: .body,
                            foregroundStyle: .white.opacity(0.9)
                        )
                            .padding(.top)
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Event Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}
