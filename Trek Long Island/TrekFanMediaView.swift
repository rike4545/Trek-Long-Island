import SwiftUI

@MainActor
struct TrekFanMediaView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                TLI_FanMedia_Header(
                    title: "Star Trek Fan Culture & Media",
                    subtitle: "Fan-made stories, real-world tours, and documentaries that show how Trek lives beyond the screen."
                )

                TLI_FanMedia_Card(
                    title: "📺 Risa Takes Over Long Island",
                    blurb: "Captains Quadrant hosts the Trek Long Island convention runners for a major announcement and a Risa-flavored look at what is coming next.",
                    whyItMatters: "It gives attendees an easy video entry point into the 2026 convention story, directly from a Trek media show connected to the fan community.",
                    linkTitle: "Watch on YouTube",
                    linkURL: "https://www.youtube.com/watch?v=PdEP7mUEkXI"
                )

                TLI_FanMedia_Card(
                    title: "🎬 Beam Me Up Sulu",
                    blurb: "A free Roku Channel watch link for the Sulu-focused feature already highlighted in the Trek Long Island experience.",
                    whyItMatters: "It gives attendees an easy way to watch the film before or after the convention, especially if they spotted the Sulu feature callout elsewhere in the app.",
                    linkTitle: "Watch free on The Roku Channel",
                    linkURL: "https://therokuchannel.roku.com/details/0877697658e59d0f63be13a35581544c/beam-me-up-sulu"
                )

                TLI_FanMedia_Card(
                    title: "🛠 Fan Films & Projects: Letters4Legacy",
                    blurb: "A community-driven project and outreach initiative connected to Star Trek fan culture.",
                    whyItMatters: "Highlights how fan projects extend beyond media into real-world impact and engagement.",
                    linkTitle: "Open letters4legacy.org",
                    linkURL: "https://letters4legacy.org/?utm_source=ig&utm_medium=social&utm_content=link_in_bio&fbclid=PAZXh0bgNhZW0CMTEAc3J0YwZhcHBfaWQMMjU2MjgxMDQwNTU4AAGnlkr7GABY02CppTuHEb1hXgznMduKoufxgz4fBhGx7nznx4j8i7sJnHUMsJs_aem_nWjxnbIpGLjlGnXpqPtAFw"
                )

                TLI_FanMedia_Card(
                    title: "⭐ Star Trek Continues",
                    blurb: "A fan-created web series crafted to feel like a direct continuation of The Original Series—tone, pacing, sets, and episodic storytelling.",
                    whyItMatters: "It shows how far fan creators can go when they treat canon and craft seriously—also a great ‘starter’ link for attendees new to fan productions.",
                    linkTitle: "Open startrekcontinues.com",
                    linkURL: "https://www.startrekcontinues.com/"
                )

                TLI_FanMedia_Card(
                    title: "🖖 Star Trek Original Series Set Tour",
                    blurb: "A real-world tour experience featuring lovingly recreated TOS-era sets. For many fans it’s a pilgrimage-style destination.",
                    whyItMatters: "It connects fandom to place—fans don’t just watch Trek; they visit it.",
                    linkTitle: "Open startrektour.com",
                    linkURL: "https://startrektour.com/"
                )

                TLI_FanMedia_Card(
                    title: "🎥 Trekkies (Documentary)",
                    blurb: "A documentary lens on Star Trek fandom—its creativity, intensity, humor, and heart. Often remembered as a snapshot of convention culture.",
                    whyItMatters: "It’s a reminder that conventions aren’t ‘extras’—they’re a core ritual of the franchise’s community.",
                    linkTitle: "Read about Trekkies",
                    linkURL: "https://en.wikipedia.org/wiki/Trekkies_(film)"
                )

                TLI_FanMedia_Card(
                    title: "📺 Fan Films, Quality, and Rules",
                    blurb: "A YouTube essay-style discussion about fan productions reaching ‘professional’ quality and how studio policies/guidelines shaped what came next.",
                    whyItMatters: "Useful context for why some fan projects changed direction—and why conventions often become the ‘safe place’ where fan creativity is still celebrated.",
                    linkTitle: "Watch on YouTube",
                    linkURL: "https://www.youtube.com/watch?v=2n6EWsVGroU"
                )

                TLI_FanMedia_Card(
                    title: "📽 Star Trek: Renegades",
                    blurb: "A feature-length fan film released on YouTube with an ambitious ‘ragtag crew on a mission’ vibe.",
                    whyItMatters: "It’s a good example of the scale fan projects can reach—and the costs/coordination that start to look like real production.",
                    linkTitle: "Watch on YouTube",
                    linkURL: "https://www.youtube.com/watch?v=eE2Wgop9VLM"
                )

                TLI_FanMedia_Callout(
                    title: "How this connects to Trek Long Island",
                    message: """
                    Fan media (films, series, documentaries) and real-world experiences (like set tours) feed the same ecosystem that conventions depend on: community, creativity, and shared rituals.

                    This section is a great “between panels” deep dive for attendees—especially first-timers who want context for why Trek fandom is uniquely organized, welcoming, and persistent.
                    """
                )

                Spacer(minLength: 10)
            }
            .padding()
        }
        .navigationTitle("Fan Media & Culture")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Ultra-unique helper views (to prevent collisions)

private struct TLI_FanMedia_Header: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.largeTitle.bold())

            Text(subtitle)
                .font(.body)
                .foregroundStyle(Color.primary.opacity(0.72))
        }
        .padding(.bottom, 6)
    }
}

private struct TLI_FanMedia_Card: View {
    let title: String
    let blurb: String
    let whyItMatters: String
    let linkTitle: String
    let linkURL: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text(title)
                .font(.title2.bold())

            Text(blurb)
                .font(.body)

            VStack(alignment: .leading, spacing: 4) {
                Text("Why it matters")
                    .font(.headline)
                Text(whyItMatters)
                    .font(.body)
                    .foregroundStyle(Color.primary.opacity(0.72))
            }
            .padding(.top, 2)

            if let url = URL(string: linkURL) {
                Link(destination: url) {
                    Label(linkTitle, systemImage: "safari")
                        .font(.body)
                }
                .padding(.top, 2)
            } else {
                Text("Invalid link URL")
                    .font(.footnote)
                    .foregroundStyle(Color.primary.opacity(0.72))
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
    }
}

private struct TLI_FanMedia_Callout: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "sparkles")
                .font(.headline)

            Text(message) // <-- IMPORTANT: message, not body
                .font(.body)
                .foregroundStyle(Color.primary.opacity(0.72))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TrekFanMediaView()
    }
}
