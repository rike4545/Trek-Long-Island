import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct IdentitySettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @FocusState private var isNameFocused: Bool

    @AppStorage(TLIProfilePreferences.StorageKey.displayName) private var displayName: String = ""
    @AppStorage(TLIProfilePreferences.StorageKey.rank) private var rankRaw: String = TLIProfileRank.captain.rawValue
    @AppStorage(TLIProfilePreferences.StorageKey.division) private var divisionRaw: String = TLIProfileDivision.command.rawValue
    @AppStorage(TLIProfilePreferences.StorageKey.role) private var roleRaw: String = TLIProfileRole.firstTimer.rawValue
    @AppStorage(TLIProfilePreferences.StorageKey.objectives) private var objectivesRaw: String = ""
    @AppStorage(TLIProfilePreferences.StorageKey.pronouns) private var pronounsRaw: String = TLIProfilePronouns.unspecified.rawValue
    @AppStorage(TLIProfilePreferences.StorageKey.pronounsCustom) private var pronounsCustom: String = ""
    @AppStorage(TLIProfilePreferences.StorageKey.welcomeStyle) private var welcomeStyleRaw: String = TLIWelcomeMessageStyle.defaultStyle.rawValue
    @AppStorage(TLIProfilePreferences.StorageKey.welcomeCustomMessage) private var welcomeCustomMessage: String = ""
    @AppStorage(TLIProfilePreferences.StorageKey.showPronounsInWelcome) private var showPronounsInWelcome: Bool = false

    @FocusState private var isPronounsFocused: Bool
    @FocusState private var isWelcomeMessageFocused: Bool

    private var selectedRole: TLIProfileRole {
        get { TLIProfileRole(rawValue: roleRaw) ?? .firstTimer }
        nonmutating set { roleRaw = newValue.rawValue }
    }

    private var selectedRank: TLIProfileRank {
        get { TLIProfileRank(rawValue: rankRaw) ?? .captain }
        nonmutating set { rankRaw = newValue.rawValue }
    }

    private var selectedDivision: TLIProfileDivision {
        get { TLIProfileDivision(rawValue: divisionRaw) ?? .command }
        nonmutating set { divisionRaw = newValue.rawValue }
    }

    private var selectedObjectives: Set<TLIProfileObjective> {
        get { TLIProfilePreferences.objectives(from: objectivesRaw) }
        nonmutating set { objectivesRaw = TLIProfilePreferences.serialize(newValue) }
    }

    private var selectedPronouns: TLIProfilePronouns {
        get { TLIProfilePreferences.pronouns(from: pronounsRaw) }
        nonmutating set { pronounsRaw = newValue.rawValue }
    }

    private var selectedWelcomeStyle: TLIWelcomeMessageStyle {
        get { TLIProfilePreferences.welcomeStyle(from: welcomeStyleRaw) }
        nonmutating set { welcomeStyleRaw = newValue.rawValue }
    }

    private var resolvedPronouns: String {
        TLIProfilePreferences.pronounsDisplay(selection: selectedPronouns, custom: pronounsCustom)
    }

    private var welcomePreview: String {
        TLIProfilePreferences.welcomeGreeting(
            style: selectedWelcomeStyle,
            customMessage: welcomeCustomMessage,
            rank: selectedRank,
            displayName: displayName,
            pronouns: resolvedPronouns,
            showPronouns: showPronounsInWelcome
        )
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

                    welcomeMessageCard
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
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Identity")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .onDisappear {
            dismissKeyboard()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
            }
        }
    }

    private var welcomeMessageCard: some View {
        SettingsSectionCard(
            icon: "hand.wave.fill",
            iconColor: .yellow,
            title: "Welcome Message",
            subtitle: "Choose the greeting shown on the splash screen after the app opens."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                welcomePreviewPanel

                VStack(alignment: .leading, spacing: 10) {
                    Text("Greeting Style")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    ForEach(TLIWelcomeMessageStyle.allCases) { style in
                        welcomeStyleRow(style)
                    }
                }

                if selectedWelcomeStyle == .custom {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Message")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))

                        TextField("Welcome aboard, {name}", text: $welcomeCustomMessage, axis: .vertical)
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                            .tint(TLITheme.accent(scheme))
                            .lineLimit(1...3)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .tliPanelSurface(
                                cornerRadius: 16,
                                fillOpacity: scheme == .dark ? 0.94 : 0.98,
                                borderOpacity: 0.82,
                                shadowRadius: 4,
                                shadowY: 2
                            )
                            .focused($isWelcomeMessageFocused)
                            .onChange(of: welcomeCustomMessage) { _, newValue in
                                let limited = TLIProfilePreferences.sanitizedSingleLine(
                                    newValue,
                                    limit: TLIProfilePreferences.customWelcomeMessageLimit
                                )
                                if limited != newValue {
                                    welcomeCustomMessage = limited
                                }
                            }

                        Text("Include \(TLIProfilePreferences.welcomeNameToken) anywhere in your message and it becomes your name and rank. Leave it blank to fall back to the time-of-day greeting.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                    }
                }

                Toggle(isOn: $showPronounsInWelcome) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Show pronouns in the welcome message")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                        Text(
                            resolvedPronouns.isEmpty
                                ? "Pick your pronouns in Captain Profile below to use this."
                                : "Adds “(\(resolvedPronouns))” after the greeting."
                        )
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                    }
                }
                .tint(TLITheme.accent(scheme))
                .disabled(resolvedPronouns.isEmpty)
            }
        }
    }

    private var welcomePreviewPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Splash preview")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(TLITheme.textTertiary(scheme))

            Text(welcomePreview)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tliPanelSurface(
            cornerRadius: 18,
            fillOpacity: scheme == .dark ? 0.90 : 0.96,
            borderOpacity: 0.72,
            shadowRadius: 4,
            shadowY: 2
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Splash preview. \(welcomePreview)")
    }

    private func welcomeStyleRow(_ style: TLIWelcomeMessageStyle) -> some View {
        let isSelected = selectedWelcomeStyle == style

        return Button {
            dismissKeyboard()
            selectedWelcomeStyle = style
        } label: {
            preferenceRow(
                title: style.title,
                detail: style.description,
                icon: style.icon,
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var identityCard: some View {
        SettingsSectionCard(
            icon: "person.crop.circle.badge.sparkles",
            iconColor: .orange,
            title: "Captain Profile",
            subtitle: "Set the name, rank, pronouns, and mission profile the app uses."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Captain Name")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    TextField("Your name or captain alias", text: $displayName)
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .tint(TLITheme.accent(scheme))
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 14)
                        .frame(height: 56)
                        .tliPanelSurface(
                            cornerRadius: 16,
                            fillOpacity: scheme == .dark ? 0.94 : 0.98,
                            borderOpacity: 0.82,
                            shadowRadius: 4,
                            shadowY: 2
                        )
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            dismissKeyboard()
                        }
                }

                // Pronouns sit above the rank list on purpose: there are 30+ ranks,
                // and anything below them is a very long scroll away.
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pronouns")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    ForEach(TLIProfilePronouns.allCases) { option in
                        pronounsPreferenceRow(option)
                    }

                    if selectedPronouns == .custom {
                        TextField("Your pronouns", text: $pronounsCustom)
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                            .tint(TLITheme.accent(scheme))
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 14)
                            .frame(height: 56)
                            .tliPanelSurface(
                                cornerRadius: 16,
                                fillOpacity: scheme == .dark ? 0.94 : 0.98,
                                borderOpacity: 0.82,
                                shadowRadius: 4,
                                shadowY: 2
                            )
                            .focused($isPronounsFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                dismissKeyboard()
                            }
                            .onChange(of: pronounsCustom) { _, newValue in
                                let limited = TLIProfilePreferences.sanitizedSingleLine(newValue, limit: 40)
                                if limited != newValue {
                                    pronounsCustom = limited
                                }
                            }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Division")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    ForEach(TLIProfileDivision.allCases) { division in
                        divisionPreferenceRow(division)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Personalized Rank")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    ForEach(TLIProfileRank.allCases) { rank in
                        rankPreferenceRow(rank)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Mission Profile")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    ForEach(TLIProfileRole.allCases) { role in
                        profileRoleRow(role)
                    }
                }

                currentSummary(
                    icon: "person.text.rectangle.fill",
                    title: "Current identity",
                    value: identitySummaryValue
                )
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

            currentSummary(
                icon: "scope",
                title: "Current focus",
                value: TLIProfilePreferences.objectivesSummary(from: selectedObjectives)
            )
        }
    }

    private func profileRoleRow(_ role: TLIProfileRole) -> some View {
        let isSelected = selectedRole == role

        return Button {
            dismissKeyboard()
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

    private var identitySummaryValue: String {
        let commandName = TLIProfilePreferences.commandName(rank: selectedRank, displayName: displayName)
        var parts = [commandName]
        if !resolvedPronouns.isEmpty {
            parts.append(resolvedPronouns)
        }
        parts.append(selectedDivision.title)
        parts.append(selectedRole.title)
        return parts.joined(separator: " • ")
    }

    private func pronounsPreferenceRow(_ option: TLIProfilePronouns) -> some View {
        let isSelected = selectedPronouns == option

        return Button {
            dismissKeyboard()
            selectedPronouns = option
            if option == .unspecified {
                showPronounsInWelcome = false
            }
        } label: {
            preferenceRow(
                title: option.title,
                detail: option.description,
                icon: option.icon,
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
            dismissKeyboard()
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

    private func divisionPreferenceRow(_ division: TLIProfileDivision) -> some View {
        let isSelected = selectedDivision == division

        return Button {
            dismissKeyboard()
            selectedDivision = division
        } label: {
            preferenceRow(
                title: division.title,
                detail: division.description,
                icon: division.icon,
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
            dismissKeyboard()
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
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TLITheme.accentSoft(scheme).opacity(isSelected ? 1.0 : 0.72))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(TLITheme.accent(scheme))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Text(detail)
                    .font(.system(.subheadline, design: .rounded))
                    .lineSpacing(3)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            VStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(isSelected ? TLITheme.accent(scheme) : TLITheme.textTertiary(scheme))
                    .accessibilityHidden(true)

                if isSelected {
                    Text("Selected")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.accent(scheme))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
        .tliPanelSurface(
            cornerRadius: 20,
            fillOpacity: isSelected ? 0.98 : (scheme == .dark ? 0.92 : 0.97),
            borderOpacity: isSelected ? 0.95 : 0.72,
            shadowRadius: 6,
            shadowY: 3
        )
    }

    private func currentSummary(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(TLITheme.accent(scheme))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(TLITheme.textTertiary(scheme))
                Text(value)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .lineSpacing(2)
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tliPanelSurface(
            cornerRadius: 18,
            fillOpacity: scheme == .dark ? 0.90 : 0.96,
            borderOpacity: 0.72,
            shadowRadius: 4,
            shadowY: 2
        )
    }

    private func dismissKeyboard() {
        isNameFocused = false
        isPronounsFocused = false
        isWelcomeMessageFocused = false
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}
