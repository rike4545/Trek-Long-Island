import SwiftUI

@MainActor
struct EasterEggMissionView: View {
    @Environment(\.colorScheme) private var scheme

    @AppStorage("TLI.EasterEggs.welcome") private var foundWelcomeSignal = false
    @AppStorage("TLI.EasterEggs.stardate") private var foundStardateSignal = false
    @AppStorage("TLI.EasterEggs.scottyVideo") private var foundScottyVideo = false
    @AppStorage("TLI.EasterEggs.captainsChair") private var experiencedCaptainsChair = false
    @AppStorage("TLI.EasterEggs.tricorderRecoveredSignal") private var recoveredTricorderSignal = false
    @AppStorage("TLI.EasterEggs.picardDay") private var foundPicardDaySignal = false
    @AppStorage("TLI.EasterEggs.teaOrder") private var foundTeaOrderSignal = false
    @AppStorage("TLI.EasterEggs.makeItSo") private var foundMakeItSoSignal = false
    @AppStorage("TLI.EasterEggs.nasaSignal") private var foundNASASignal = false
    @AppStorage("TLI.EasterEggs.starfleetSecurity") private var foundStarfleetSecuritySignal = false
    @AppStorage("TLI.EasterEggs.tribbles") private var foundTribbleSignal = false
    @AppStorage("TLI.EasterEggs.daystrom") private var foundDaystromSignal = false
    @AppStorage("TLI.EasterEggs.borg") private var foundBorgSignal = false
    @AppStorage("TLI.EasterEggs.wormhole") private var foundWormholeSignal = false

    private struct MissionItem: Identifiable {
        let id: String
        let title: String
        let detail: String
        let found: Bool
        let binding: Binding<Bool>
    }

    private var missionItems: [MissionItem] {
        [
            MissionItem(
                id: "welcome",
                title: "WELCOME hidden message",
                detail: "Triggered from the home screen header.",
                found: foundWelcomeSignal,
                binding: $foundWelcomeSignal
            ),
            MissionItem(
                id: "stardate",
                title: "Stardate hidden frequency",
                detail: "Unlocked from the stardate chip on the home screen.",
                found: foundStardateSignal,
                binding: $foundStardateSignal
            ),
            MissionItem(
                id: "scotty",
                title: "Scotty easter egg video",
                detail: "Available inside Hello Computer.",
                found: foundScottyVideo,
                binding: $foundScottyVideo
            ),
            MissionItem(
                id: "captains-chair",
                title: "Captain's Chair mode",
                detail: "Launched from More under Holodeck.",
                found: experiencedCaptainsChair,
                binding: $experiencedCaptainsChair
            ),
            MissionItem(
                id: "tricorder-signal",
                title: "Recovered tricorder signal",
                detail: "Hidden inside the Tricorder Scan mini-game.",
                found: recoveredTricorderSignal,
                binding: $recoveredTricorderSignal
            ),
            MissionItem(
                id: "picard-day",
                title: "Captain Picard Day transmission",
                detail: "Unlocked from the Picard Day banner on Home.",
                found: foundPicardDaySignal,
                binding: $foundPicardDaySignal
            ),
            MissionItem(
                id: "tea-order",
                title: "Earl Grey, hot",
                detail: "Long-press the stardate chip on Home.",
                found: foundTeaOrderSignal,
                binding: $foundTeaOrderSignal
            ),
            MissionItem(
                id: "make-it-so",
                title: "Make it so",
                detail: "Long-press the Engage button in Mission Control.",
                found: foundMakeItSoSignal,
                binding: $foundMakeItSoSignal
            ),
            MissionItem(
                id: "nasa-signal",
                title: "Orbital Science Relay",
                detail: "Convention-only NASA transmission on Home during June 12–14.",
                found: foundNASASignal,
                binding: $foundNASASignal
            ),
            MissionItem(
                id: "starfleet-security",
                title: "Starfleet Security sweep",
                detail: "Long-press the Bridge status section on Home.",
                found: foundStarfleetSecuritySignal,
                binding: $foundStarfleetSecuritySignal
            ),
            MissionItem(
                id: "tribbles",
                title: "Trouble with tribbles",
                detail: "Tap the sponsors section repeatedly on Home.",
                found: foundTribbleSignal,
                binding: $foundTribbleSignal
            ),
            MissionItem(
                id: "daystrom",
                title: "Daystrom Station archive",
                detail: "Tap the Info & policies section repeatedly on Home.",
                found: foundDaystromSignal,
                binding: $foundDaystromSignal
            ),
            MissionItem(
                id: "borg",
                title: "The Borg",
                detail: "Tap the Happening now card repeatedly on Home.",
                found: foundBorgSignal,
                binding: $foundBorgSignal
            ),
            MissionItem(
                id: "wormhole",
                title: "Bajoran wormhole",
                detail: "Tap the Live at a glance section repeatedly on Home.",
                found: foundWormholeSignal,
                binding: $foundWormholeSignal
            )
        ]
    }

    private var completedCount: Int {
        missionItems.filter(\.found).count
    }

    private var totalCount: Int {
        missionItems.count
    }

    var body: some View {
        List {
            Section {
                summaryCard
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
            }

            Section("Mission Log") {
                ForEach(missionItems) { item in
                    Toggle(isOn: item.binding) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(TLITheme.textPrimary(scheme))
                            Text(item.detail)
                                .font(.subheadline)
                                .foregroundStyle(TLITheme.textSecondary(scheme))
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(TLITheme.accent(scheme))
                }
            }

            Section("Status") {
                Label("\(completedCount) of \(totalCount) easter eggs found or experienced", systemImage: completedCount == totalCount ? "checkmark.seal.fill" : "sparkles")
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                if completedCount < totalCount {
                    Text("Mark each one when you trigger it in the app.")
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                } else {
                    Text("Hidden frequency sweep complete.")
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
            }

            Section {
                Button("Reset Mission Progress", role: .destructive, action: resetProgress)
            }
        }
        .navigationTitle("Easter Egg Mission")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        .tint(TLITheme.accent(scheme))
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How many hidden signals have you found?")
                .font(.title3.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Use this as a mini task and keep count as you discover the app's built-in easter eggs.")
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            ProgressView(value: Double(completedCount), total: Double(totalCount))
                .tint(TLITheme.accent(scheme))

            Text("\(completedCount)/\(totalCount) complete")
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLITheme.textTertiary(scheme))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .padding(.horizontal, 2)
    }

    private func resetProgress() {
        foundWelcomeSignal = false
        foundStardateSignal = false
        foundScottyVideo = false
        experiencedCaptainsChair = false
        recoveredTricorderSignal = false
        foundPicardDaySignal = false
        foundTeaOrderSignal = false
        foundMakeItSoSignal = false
        foundNASASignal = false
        foundStarfleetSecuritySignal = false
        foundTribbleSignal = false
        foundDaystromSignal = false
        foundBorgSignal = false
        foundWormholeSignal = false
    }
}

#Preview {
    NavigationStack {
        EasterEggMissionView()
    }
}
