import SwiftUI

@MainActor
struct IdentitySettingsView: View {
    @Environment(\.colorScheme) private var scheme

    @AppStorage("TLI.Profile.displayName") private var displayName: String = ""
    @AppStorage("TLI.Profile.rank") private var rankRaw: String = TLIProfileRank.captain.rawValue
    @AppStorage("TLI.Profile.role") private var roleRaw: String = TLIProfileRole.firstTimer.rawValue
    @AppStorage("TLI.Profile.objectives") private var objectivesRaw: String = ""

    private var selectedRole: TLIProfileRole {
        get { TLIProfileRole(rawValue: roleRaw) ?? .firstTimer }
        nonmutating set { roleRaw = newValue.rawValue }
    }

    private var selectedRank: TLIProfileRank {
        get { TLIProfileRank(rawValue: rankRaw) ?? .captain }
        nonmutating set { rankRaw = newValue.rawValue }
    }

    private var selectedObjectives: Set<TLIProfileObjective> {
        get { TLIProfilePreferences.objectives(from: objectivesRaw) }
        nonmutating set { objectivesRaw = TLIProfilePreferences.serialize(newValue) }
    }

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Identity")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))

                        Text("Set the captain profile and mission priorities the app uses across Bridge, Schedule, and Hello, Computer.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 4)

                    identityCard
                    missionFocusCard
                }
                .adaptiveContentWidth(
                    maxWidth: TLILayout.tightContentMaxWidth + 120,
                    horizontalPadding: 20,
                    verticalPadding: 0
                )
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Identity")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
    }

    private var identityCard: some View {
        SettingsSectionCard(
            icon: "person.crop.circle.badge.sparkles",
            iconColor: .orange,
            title: "Captain Profile",
            subtitle: "Set the name, rank, and mission profile the app uses."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Captain Name")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    TextField("Your name or captain alias", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .tliPanelSurface(
                            cornerRadius: 14,
                            fillOpacity: scheme == .dark ? 0.78 : 0.90,
                            borderOpacity: 0.65,
                            shadowRadius: 3,
                            shadowY: 2
                        )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Personalized Rank")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    ForEach(TLIProfileRank.allCases) { rank in
                        rankPreferenceRow(rank)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Mission Profile")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    ForEach(TLIProfileRole.allCases) { role in
                        profileRoleRow(role)
                    }
                }

                Text("Current identity: \(TLIProfilePreferences.commandName(rank: selectedRank, displayName: displayName)) • \(selectedRole.title)")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var missionFocusCard: some View {
        SettingsSectionCard(
            icon: "scope",
            iconColor: .teal,
            title: "Mission Focus",
            subtitle: "Choose what Trek Long Island should emphasize for you."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(TLIProfileObjective.allCases) { objective in
                    objectivePreferenceRow(objective)
                }
            }

            Text("Current focus: \(TLIProfilePreferences.objectivesSummary(from: selectedObjectives))")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func profileRoleRow(_ role: TLIProfileRole) -> some View {
        let isSelected = selectedRole == role

        return Button {
            selectedRole = role
        } label: {
            preferenceRow(
                title: role.title,
                detail: role.description,
                icon: role.icon,
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func rankPreferenceRow(_ rank: TLIProfileRank) -> some View {
        let isSelected = selectedRank == rank

        return Button {
            selectedRank = rank
        } label: {
            preferenceRow(
                title: rank.title,
                detail: rank.description,
                icon: rank.icon,
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func objectivePreferenceRow(_ objective: TLIProfileObjective) -> some View {
        let isSelected = selectedObjectives.contains(objective)

        return Button {
            var updated = selectedObjectives
            if isSelected {
                updated.remove(objective)
            } else {
                updated.insert(objective)
            }
            selectedObjectives = updated
        } label: {
            preferenceRow(
                title: objective.title,
                detail: objective.description,
                icon: objective.icon,
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func preferenceRow(title: String, detail: String, icon: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(TLITheme.accent(scheme))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Text(detail)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? TLITheme.accent(scheme) : TLITheme.textTertiary(scheme))
                .accessibilityHidden(true)
        }
        .padding(14)
        .tliPanelSurface(
            cornerRadius: 18,
            fillOpacity: isSelected ? 0.96 : (scheme == .dark ? 0.82 : 0.90),
            borderOpacity: isSelected ? 0.8 : 0.55,
            shadowRadius: 4,
            shadowY: 2
        )
    }
}
