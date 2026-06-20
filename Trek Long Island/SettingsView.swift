// Copyright Bryan Carroll. All rights reserved.
//
//  SettingsView.swift
//  Trek Long Island
//

import SwiftUI
import UserNotifications
import AVFoundation
import Speech
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var showOnboardingReplay = false

    @AppStorage("TLI.Profile.displayName") private var displayName: String = ""
    @AppStorage("TLI.Profile.rank") private var rankRaw: String = TLIProfileRank.captain.rawValue
    @AppStorage("TLI.Profile.division") private var divisionRaw: String = TLIProfileDivision.command.rawValue
    @AppStorage("TLI.Profile.role") private var roleRaw: String = TLIProfileRole.firstTimer.rawValue
    @AppStorage("TLI.Profile.objectives") private var objectivesRaw: String = ""

    // Appearance (backed by your AppAppearance enum)
    @AppStorage("appVisualPreset") private var appVisualPresetRaw: String = TLIVisualPreset.defaultPreset.rawValue
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @AppStorage("appColorTheme") private var appColorThemeRaw: String = TLIColorTheme.defaultTheme.rawValue
    @AppStorage(TLITypographyPreference.storageKey) private var typographyRaw: String = TLITypographyPreference.defaultPreference.rawValue

    // App Icon
    @AppStorage(TLIAppIconChoice.storageKey) private var selectedAppIconRaw: String = TLIAppIconChoice.appIcon.rawValue
    @State private var isChangingAppIcon = false
    @State private var appIconErrorMessage: String?
    @State private var suppressAppIconApply = false
    @State private var pendingAppIconApplyTask: Task<Void, Never>?

    // Local notification state
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isLoadingNotifStatus = false
    @State private var isSchedulingTest = false
    @State private var speechStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @State private var microphoneStatus: AVAudioApplication.recordPermission = .undetermined
    @State private var isRefreshingVoiceStatus = false

    @AppStorage("TLI.NotificationPrefs.digestMode") private var digestMode: Bool = false
    @AppStorage("TLI.NotificationPrefs.quietStartHour") private var quietStartHour: Int = 22
    @AppStorage("TLI.NotificationPrefs.quietEndHour") private var quietEndHour: Int = 7
    @AppStorage("TLI.NotificationPrefs.priorityOverridesQuiet") private var priorityOverridesQuiet: Bool = true

    @AppStorage("TLI.Accessibility.highContrast") private var highContrastMode: Bool = false
    @AppStorage("TLI.Accessibility.largeTypeBoost") private var largeTypeBoost: Bool = false
    @AppStorage("TLI.Accessibility.largeTapTargets") private var largeTapTargets: Bool = false
    @AppStorage("TLI.Accessibility.reduceAnimations") private var reduceAnimations: Bool = false
    @AppStorage("TLI.Home.showMissionControl") private var showMissionControl: Bool = true
    @AppStorage(TLIAudioSettings.uiSoundsEnabledKey) private var uiSoundsEnabled: Bool = true
    @AppStorage(TLIWebLinkOpeningPreference.storageKey) private var webLinkOpeningRaw: String = TLIWebLinkOpeningPreference.defaultPreference.rawValue

    private var selectedAppearance: AppAppearance {
        get { AppAppearance(rawValue: appAppearanceRaw) ?? .system }
        nonmutating set { appAppearanceRaw = newValue.rawValue }
    }

    private var selectedTheme: TLIColorTheme {
        get { TLIColorTheme.fromStoredRawValue(appColorThemeRaw) }
        nonmutating set { appColorThemeRaw = newValue.rawValue }
    }

    private var selectedVisualPreset: TLIVisualPreset {
        get { TLIVisualPreset.fromStoredRawValue(appVisualPresetRaw) }
        nonmutating set {
            appVisualPresetRaw = newValue.rawValue
            selectedTheme = newValue.theme
            selectedAppearance = newValue.appearance
        }
    }

    private var selectedRole: TLIProfileRole {
        get { TLIProfileRole(rawValue: roleRaw) ?? .firstTimer }
        nonmutating set { roleRaw = newValue.rawValue }
    }

    private var selectedTypography: TLITypographyPreference {
        get { TLITypographyPreference.fromStoredRawValue(typographyRaw) }
        nonmutating set { typographyRaw = newValue.rawValue }
    }

    private var selectedWebLinkOpening: TLIWebLinkOpeningPreference {
        get { TLIWebLinkOpeningPreference.fromStoredRawValue(webLinkOpeningRaw) }
        nonmutating set { webLinkOpeningRaw = newValue.rawValue }
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

    var body: some View {
        NavigationStack {
            ZStack {
                // Risa/TLI gradient only – no starfield, no dark overlay
                TLITheme.backgroundGradient(scheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Page header
                        settingsHeader

                        identityNavigationCard
                        stylePresetsCard
                        displayCard
                        audioCard
                        notificationAccessCard
                        notificationBehaviorCard
                        homeScreenCard
                        webLinksCard
                        accessibilityCard
                        voicePermissionsCard
                        adminAccessCard
                        linksCard
                        aboutCard

                        Spacer(minLength: 24)
                    }
                    .adaptiveContentWidth(
                        maxWidth: TLILayout.tightContentMaxWidth + 120,
                        horizontalPadding: 20,
                        verticalPadding: 0
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(TapGesture().onEnded { dismissKeyboard() })
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .tliNavBarStyle()
        }
        .tint(TLITheme.accent(scheme))
        .tliFixedBottomAdSlot()
        .task {
            await refreshNotificationStatus()
            refreshVoicePermissionStatus()
            syncAppIconPickerWithSystem()
            await sanitizeAppIconSelectionIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await refreshNotificationStatus() }
                refreshVoicePermissionStatus()
                syncAppIconPickerWithSystem()
                Task { await sanitizeAppIconSelectionIfNeeded() }
            }
        }
        .onChange(of: selectedAppIconRaw) { _, _ in
            guard !suppressAppIconApply else { return }
            dismissKeyboard()
            scheduleAppIconApply()
        }
        .onDisappear {
            dismissKeyboard()
        }
        .fullScreenCover(isPresented: $showOnboardingReplay) {
            TLIOnboardingView(canDismiss: true)
                .onDisappear {
                    dismissKeyboard()
                }
        }
    }

    // MARK: - Cards

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(RisaTheme.isLCARSThemeEnabled ? "LCARS CONFIG" : "Bridge Configuration")
                    .font(
                        RisaTheme.isLCARSThemeEnabled
                            ? .system(size: 12, weight: .heavy, design: .monospaced)
                            : .system(.caption, design: .rounded).weight(.bold)
                    )
                    .textCase(.uppercase)
                    .kerning(0.7)
                    .foregroundStyle(TLITheme.textTertiary(scheme))

                Capsule()
                    .fill(TLITheme.border(scheme).opacity(0.24))
                    .frame(width: 28, height: 4)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Settings")
                        .font(
                            RisaTheme.isLCARSThemeEnabled
                                ? .system(size: 32, weight: .black, design: .monospaced)
                                : selectedTypography.font(.largeTitle, weight: .bold)
                        )
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    Text(RisaTheme.isLCARSThemeEnabled ? "Tune your console rails, palette, and station identity." : "Tune the app to match your bridge layout.")
                        .font(
                            RisaTheme.isLCARSThemeEnabled
                                ? .system(size: 13, weight: .semibold, design: .monospaced)
                                : selectedTypography.font(.subheadline)
                        )
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    Image(systemName: selectedVisualPreset.theme.symbol)
                        .font(selectedTypography.font(.caption, weight: .bold))
                    Text(selectedVisualPreset.title)
                        .font(selectedTypography.font(.caption, weight: .bold))
                }
                .foregroundStyle(TLITheme.accent(scheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(TLITheme.accentSoft(scheme), in: Capsule())
            }
        }
        .padding(.horizontal, 4)
    }

    private var identityNavigationCard: some View {
        SettingsSectionCard(
            icon: "person.crop.circle.badge.sparkles",
            iconColor: .orange,
            title: "Identity",
            subtitle: "Manage your captain name, rank, role, and mission focus."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                settingsSummaryRow(title: "Captain", value: TLIProfilePreferences.commandName(rank: selectedRank, displayName: displayName))
                settingsSummaryRow(title: "Division", value: selectedDivision.title)
                settingsSummaryRow(title: "Profile", value: selectedRole.title)
                settingsSummaryRow(title: "Focus", value: TLIProfilePreferences.objectivesSummary(from: selectedObjectives))
            }

            NavigationLink {
                IdentitySettingsView()
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(TLITheme.accentSoft(scheme))
                            .frame(width: 34, height: 34)
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundStyle(TLITheme.accent(scheme))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Open identity settings")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Text("Update your captain name, rank, role, and mission focus.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundStyle(TLITheme.textTertiary(scheme))
                }
            }
            .buttonStyle(SettingsGhostButtonStyle())
        }
    }

    private var stylePresetsCard: some View {
        SettingsSectionCard(
            icon: "paintpalette.fill",
            iconColor: .pink,
            title: "Style Presets",
            subtitle: "Choose between Federation Command, LCARS, and the brighter Risa look."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Available themes")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(TLITheme.textSecondary(scheme))

                ForEach(TLIVisualPreset.supportedPresets) { preset in
                    visualPresetRow(preset)
                }
            }

            Text("Current preset: \(selectedVisualPreset.title). Three supported themes are available here, and the display controls below are only for fine-tuning.")
                .font(.system(.footnote, design: .rounded))
                .lineSpacing(2)
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private var displayCard: some View {
        SettingsSectionCard(
            icon: "slider.horizontal.3",
            iconColor: .indigo,
            title: "Display",
            subtitle: "Fine-tune appearance mode and the \(TLIAppBranding.appDisplayName) icon."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Appearance Mode")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Picker("Theme", selection: $appAppearanceRaw) {
                    Text("System").tag(AppAppearance.system.rawValue)
                    Text("Light").tag(AppAppearance.light.rawValue)
                    Text("Dark").tag(AppAppearance.dark.rawValue)
                }
                .font(.system(.subheadline, design: .rounded))
                .pickerStyle(.segmented)

                Text("“System” follows your device setting.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(TLITheme.textSecondary(scheme))

                Divider().opacity(0.6)

                if supportsAlternateIcons {
                    HStack {
                        Label("App Icon", systemImage: "app.badge")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                        Spacer()
                        if isChangingAppIcon {
                            ProgressView().scaleEffect(0.9)
                        }
                    }

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(minimum: 88), spacing: 10),
                            GridItem(.flexible(minimum: 88), spacing: 10),
                            GridItem(.flexible(minimum: 88), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(TLIAppIconChoice.pickerChoices) { choice in
                            appIconChoiceCard(choice)
                        }
                    }
                    .disabled(isChangingAppIcon)

                    if let msg = appIconErrorMessage {
                        Text(msg)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Color.primary.opacity(0.72))
                    } else {
                        Text("Select a preview to switch your Home Screen icon. Older novelty icons were removed from the selector.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                    }
                } else {
                    Text("App icon switching isn’t available on this device.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
            }
        }
    }

    private func appIconChoiceCard(_ choice: TLIAppIconChoice) -> some View {
        let isSelected = selectedAppIconRaw == choice.rawValue

        return Button {
            selectedAppIconRaw = choice.rawValue
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.08, green: 0.14, blue: 0.24),
                                    Color(red: 0.14, green: 0.24, blue: 0.42)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 82)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(isSelected ? TLITheme.accent(scheme) : TLITheme.border(scheme).opacity(0.45), lineWidth: isSelected ? 2 : 1)
                        )

                    Image(choice.brandAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding(14)
                        .frame(height: 82)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(TLITheme.accent(scheme))
                            .padding(6)
                    }
                }

                Text(choice.title)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(TLITheme.accentSoft(scheme).opacity(isSelected ? 0.55 : 0.24))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? TLITheme.accent(scheme).opacity(0.35) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(choice.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func settingsSummaryRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private func typographyPreferenceRow(_ preference: TLITypographyPreference) -> some View {
        let isSelected = selectedTypography == preference

        return Button {
            selectedTypography = preference
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(preference.title)
                        .font(preference.font(.body, weight: .semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    Text(preference.subtitle)
                        .font(preference.font(.caption))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }

                Spacer(minLength: 12)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(selectedTypography.font(.title3, weight: .semibold))
                    .foregroundStyle(isSelected ? TLITheme.accent(scheme) : TLITheme.textTertiary(scheme))
                    .accessibilityHidden(true)
            }
            .padding(12)
            .background(TLITheme.accentSoft(scheme).opacity(isSelected ? 0.8 : 0.35), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func visualPresetRow(_ preset: TLIVisualPreset) -> some View {
        let isSelected = selectedVisualPreset == preset

        return Button {
            selectedVisualPreset = preset
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(TLITheme.accentSoft(scheme))
                            .frame(width: 56, height: 56)

                        Image(systemName: preset.theme.symbol)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(TLITheme.accent(scheme))
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(preset.shortLabel)
                            .font(
                                preset == .lcars
                                    ? .system(size: 24, weight: .black, design: .monospaced)
                                    : .system(.title3, design: .rounded).weight(.bold)
                            )
                            .kerning(preset == .lcars ? 0.3 : 0)
                            .foregroundStyle(TLITheme.textPrimary(scheme))

                        Text(preset.title)
                            .font(
                                preset == .lcars
                                    ? .system(size: 12, weight: .bold, design: .monospaced)
                                    : .system(.caption, design: .rounded).weight(.semibold)
                            )
                            .kerning(preset == .lcars ? 0.2 : 0)
                            .foregroundStyle(TLITheme.textTertiary(scheme))
                    }

                    Spacer(minLength: 12)

                    if isSelected {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                            Text("Selected")
                                .font(
                                    preset == .lcars
                                        ? .system(size: 12, weight: .bold, design: .monospaced)
                                        : .system(.caption, design: .rounded).weight(.bold)
                                )
                        }
                        .foregroundStyle(TLITheme.accent(scheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(TLITheme.accentSoft(scheme), in: Capsule())
                    } else {
                        Image(systemName: "circle")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(TLITheme.textTertiary(scheme))
                            .padding(.top, 4)
                            .accessibilityHidden(true)
                    }
                }

                Text(preset.description)
                    .font(
                        preset == .lcars
                            ? .system(size: 15, weight: .medium, design: .monospaced)
                            : .system(.body, design: .rounded)
                    )
                    .lineSpacing(preset == .lcars ? 4 : 2)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                if preset == .risa {
                    risaPresetArtwork
                }

                HStack(spacing: 8) {
                    ForEach(presetPreviewLabels(for: preset), id: \.self) { item in
                        Text(item)
                            .font(
                                preset == .lcars
                                    ? .system(size: 11, weight: .bold, design: .monospaced)
                                    : .system(.caption2, design: .rounded).weight(.semibold)
                            )
                            .foregroundStyle(preset == .lcars ? Color.black : TLITheme.chipForeground(scheme))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                preset == .lcars
                                    ? AnyShapeStyle(lcarsPreviewFill(for: item))
                                    : AnyShapeStyle(TLITheme.accentSoft(scheme))
                            ,
                                in: TLITheme.controlShape(cornerRadius: 14)
                            )
                    }
                }

                HStack(spacing: 8) {
                    Label(isSelected ? "Active Theme" : "Tap to apply", systemImage: isSelected ? "sparkles" : "hand.tap")
                        .font(
                            preset == .lcars
                                ? .system(size: 12, weight: .bold, design: .monospaced)
                                : .system(.caption, design: .rounded).weight(.semibold)
                        )
                        .foregroundStyle(isSelected ? TLITheme.accent(scheme) : TLITheme.textSecondary(scheme))

                    Spacer(minLength: 12)
                }
            }
            .padding(16)
            .settingsCardSurface(
                cornerRadius: 22,
                emphasize: isSelected
            )
            .tliLCARSPanelChrome(
                accent: preset == .lcars ? RisaTheme.accent(.dark) : TLITheme.accent(scheme),
                metadata: nil
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var risaPresetArtwork: some View {
        Image("RisaSettingsSunsetWater")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 124)
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        .clear,
                        TLITheme.cardBackground(scheme).opacity(scheme == .dark ? 0.28 : 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(TLITheme.border(scheme).opacity(0.28), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }

    private func presetPreviewLabels(for preset: TLIVisualPreset) -> [String] {
        switch preset {
        case .tos, .tng, .ds9, .voyager, .enterprise, .starfleet:
            ["Bridge", "Alerts", "Command"]
        case .lcars:
            ["Personnel", "Timeline", "Registry"]
        case .risa:
            ["Resort", "Sunset", "Leisure"]
        }
    }

    private func lcarsPreviewFill(for item: String) -> Color {
        switch item {
        case "Personnel":
            RisaTheme.accentGold(.dark)
        case "Timeline":
            RisaTheme.accentSecondary(.light)
        case "Registry":
            RisaTheme.accent(.dark)
        default:
            RisaTheme.accent(.light)
        }
    }

    private var notificationAccessCard: some View {
        SettingsSectionCard(
            icon: "bell.badge.fill",
            iconColor: .orange,
            title: "Notification Access",
            subtitle: "Allow alerts and check your current permission state."
        ) {
            HStack {
                Label("Status", systemImage: "waveform.path.ecg.rectangle")
                    .labelStyle(.titleAndIcon)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Spacer()

                if isLoadingNotifStatus {
                    ProgressView()
                } else {
                    Text(statusLabel(for: notificationStatus))
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.72))
                }
            }

            Divider().opacity(0.6)

            Button(action: handleNotificationsButton) {
                HStack {
                    Image(systemName: buttonIcon)
                    Text(buttonTitle)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .opacity(0.6)
                }
            }
                .buttonStyle(
                    SettingsPrimaryButtonStyle(
                        accent: TLITheme.accent(scheme)
                    )
                )

            Text(footerText(for: notificationStatus))
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private var audioCard: some View {
        SettingsSectionCard(
            icon: "speaker.wave.2.fill",
            iconColor: .pink,
            title: "Sound Effects",
            subtitle: "Control UI click and tap noises."
        ) {
            Toggle("Play click sounds", isOn: $uiSoundsEnabled)

            Text("Turn this off to mute interface tap sounds across the app, including tab clicks and Hello, Computer controls.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private var notificationBehaviorCard: some View {
        SettingsSectionCard(
            icon: "bell.and.waves.left.and.right.fill",
            iconColor: .mint,
            title: "Notification Behavior",
            subtitle: "Choose how and when app alerts should be delivered."
        ) {
            if isAuthorizedLike(notificationStatus) {
                Button {
                    Task { await scheduleTestNotification() }
                } label: {
                    HStack {
                        Image(systemName: isSchedulingTest ? "hourglass" : "paperplane.fill")
                        Text(isSchedulingTest ? "Scheduling…" : "Send Test Notification")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                        Spacer()
                    }
                }
                .buttonStyle(SettingsGhostButtonStyle())
                .disabled(isSchedulingTest)

                Divider().opacity(0.6)
            }

            Toggle("Digest mode", isOn: $digestMode)
            Toggle("Priority overrides quiet hours", isOn: $priorityOverridesQuiet)

            HStack {
                Text("Quiet hours")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Spacer(minLength: 12)
                Picker("Start", selection: $quietStartHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(hourLabel(hour)).tag(hour)
                    }
                }
                .labelsHidden()
                Picker("End", selection: $quietEndHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(hourLabel(hour)).tag(hour)
                    }
                }
                .labelsHidden()
            }

            Text("Digest mode groups lower-priority updates together, while quiet hours reduce late-night pings.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private var adminAccessCard: some View {
        SettingsSectionCard(
            icon: "person.badge.key.fill",
            iconColor: .red,
            title: "Admin Access",
            subtitle: "Open the unified operator and master portal."
        ) {
            NavigationLink {
                OpsCenterView()
            } label: {
                HStack {
                    Label("Open Ops Center", systemImage: "person.crop.rectangle.stack.fill")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .opacity(0.6)
                }
            }
            .buttonStyle(SettingsGhostButtonStyle())

            Text("Live Ops, Notifications, Ticket QR controls, CRM, and master controls are unified there.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))

            Text("Coordinator tools now require Firebase sign-in with an approved account.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))

            Divider().opacity(0.6)

            VStack(alignment: .leading, spacing: 8) {
                Text("Role Permissions")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                adminPermissionRow(role: "Watcher", detail: "Can update room status in Live Ops.")
                adminPermissionRow(role: "Notifier", detail: "Can submit notifications.")
                adminPermissionRow(role: "Reviewer", detail: "Can review pending notification and incident changes.")
                adminPermissionRow(role: "Master", detail: "Full access: review, delete published notifications, and super controls.")
            }
        }
    }

    private var voicePermissionsCard: some View {
        SettingsSectionCard(
            icon: "mic.fill",
            iconColor: .blue,
            title: "Voice Assistant Permissions",
            subtitle: "Manage microphone and speech recognition access."
        ) {
            if isRefreshingVoiceStatus {
                ProgressView()
            } else {
                HStack {
                    Label("Microphone", systemImage: "waveform")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    Spacer()
                    Text(microphoneStatusLabel)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.72))
                }

                HStack {
                    Label("Speech Recognition", systemImage: "captions.bubble.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    Spacer()
                    Text(speechStatusLabel)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.72))
                }
            }

            Divider().opacity(0.6)

            if shouldOfferVoicePermissionRequest {
                Button {
                    requestVoicePermissions()
                } label: {
                    HStack {
                        Image(systemName: "mic.badge.plus")
                        Text("Allow Voice Input")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                        Spacer()
                    }
                }
                .buttonStyle(
                    SettingsPrimaryButtonStyle(
                        accent: TLITheme.accent(scheme)
                    )
                )
            }

            Button {
                openSystemSettings()
            } label: {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Open iOS Settings")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .opacity(0.6)
                }
            }
            .buttonStyle(SettingsGhostButtonStyle())

            Text("Voice commands in Hello, Computer require both microphone and speech recognition permissions.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    @ViewBuilder
    private func adminPermissionRow(role: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(role)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
            Text(detail)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private func accessibilityStatusRow(title: String, isEnabled: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isEnabled ? TLITheme.accent(scheme) : TLITheme.textTertiary(scheme))
                .accessibilityHidden(true)

            Text(title)
                .font(selectedTypography.font(.subheadline, weight: .semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Spacer()

            Text(isEnabled ? "On" : "Off")
                .font(selectedTypography.font(.caption, weight: .semibold))
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(TLITheme.accentSoft(scheme).opacity(isEnabled ? 0.6 : 0.24), in: Capsule())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(isEnabled ? "On" : "Off")")
    }

    private var accessibilityCard: some View {
        SettingsSectionCard(
            icon: "accessibility",
            iconColor: .green,
            title: "Accessibility",
            subtitle: "Visual clarity and readability options."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Reading Font")
                    .font(selectedTypography.font(.subheadline, weight: .semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                ForEach(TLITypographyPreference.allCases) { preference in
                    typographyPreferenceRow(preference)
                }
            }

            Divider().opacity(0.6)

            Toggle("High contrast mode", isOn: $highContrastMode)
            Toggle("Larger text boost", isOn: $largeTypeBoost)
            Toggle("Larger tap targets", isOn: $largeTapTargets)
            Toggle("Reduce animations", isOn: $reduceAnimations)

            Divider().opacity(0.6)

            VStack(alignment: .leading, spacing: 8) {
                Text("Apple Accessibility Features")
                    .font(selectedTypography.font(.subheadline, weight: .semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                accessibilityStatusRow(title: "VoiceOver", isEnabled: voiceOverEnabled)
                accessibilityStatusRow(title: "Reduce Motion", isEnabled: systemReduceMotion)
                accessibilityStatusRow(title: "Reduce Transparency", isEnabled: systemReduceTransparency)
                accessibilityStatusRow(title: "Differentiate Without Color", isEnabled: differentiateWithoutColor)
                accessibilityStatusRow(title: "Button Shapes", isEnabled: showButtonShapes)
            }

            Button {
                openSystemSettings()
            } label: {
                HStack {
                    Image(systemName: "figure.roll")
                    Text("Open iOS Settings")
                        .font(selectedTypography.font(.body, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(selectedTypography.font(.footnote, weight: .semibold))
                        .opacity(0.6)
                }
            }
            .buttonStyle(SettingsGhostButtonStyle())

            Text("These settings increase contrast, readability, touch target size, and reduce motion across the app. Atkinson Hyperlegible is included as an open licensed accessibility-first reading option.")
                .font(selectedTypography.font(.footnote))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private var homeScreenCard: some View {
        SettingsSectionCard(
            icon: "rectangle.grid.1x2.fill",
            iconColor: .blue,
            title: "Home Screen",
            subtitle: "Choose which sections appear on the main page."
        ) {
            Toggle("Show Mission Control", isOn: $showMissionControl)

            Text("Turn this off if you want a simpler Today page without the personalized Mission Control panel.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private var webLinksCard: some View {
        SettingsSectionCard(
            icon: "safari.fill",
            iconColor: .cyan,
            title: "Web Links",
            subtitle: "Choose where website links open."
        ) {
            Picker("Open Web Links", selection: Binding(
                get: { selectedWebLinkOpening },
                set: { selectedWebLinkOpening = $0 }
            )) {
                ForEach(TLIWebLinkOpeningPreference.allCases) { preference in
                    Label(preference.title, systemImage: preference.systemImage)
                        .tag(preference)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(TLIWebLinkOpeningPreference.allCases) { preference in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: preference.systemImage)
                            .foregroundStyle(
                                selectedWebLinkOpening == preference
                                ? TLITheme.accent(scheme)
                                : TLITheme.textTertiary(scheme)
                            )
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(preference.title)
                                .font(selectedTypography.font(.subheadline, weight: .semibold))
                                .foregroundStyle(TLITheme.textPrimary(scheme))

                            Text(preference.subtitle)
                                .font(selectedTypography.font(.footnote))
                                .foregroundStyle(TLITheme.textSecondary(scheme))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Text("This applies to website links across the app. System links, local files, and app deep links still use their normal handler.")
                .font(selectedTypography.font(.footnote))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private var linksCard: some View {
        SettingsSectionCard(
            icon: "link.circle.fill",
            iconColor: .cyan,
            title: "Links",
            subtitle: "Hop out to the convention site, contact options, and hotel details."
        ) {
            SettingsLinkRow(
                title: "Suggestion or App Issue",
                systemImage: "exclamationmark.bubble.fill",
                url: URL(string: "https://qualtricsxmm8q5gxrhq.qualtrics.com/jfe/form/SV_1TvkCrIKgaEYHPM")
            )

            SettingsLinkRow(
                title: "Convention Hotel Reservations",
                systemImage: "globe",
                url: URL(string: "https://www.hyatt.com/events/en-US/group-booking/HAUPP/G-TKA6?fbclid=IwY2xjawPP8KxleHRuA2FlbQIxMABicmlkETFuQUlaUkl2Q3NnUXFCbW5Dc3J0YwZhcHBfaWQQMjIyMDM5MTc4ODIwMDg5MgABHhGhcQgVYYsIdMnDKd0yZPAWSAaBYEckE7jHlf56ryiLVOOErTHevhFS3JEh_aem_9ZrAhujSQ4R9_APUdAET-Q")
            )

            SettingsLinkRow(
                title: "Contact Support",
                systemImage: "envelope.open",
                url: URL(string: "https://qualtricsxmm8q5gxrhq.qualtrics.com/jfe/form/SV_1TvkCrIKgaEYHPM")
            )

            SettingsLinkRow(
                title: "Made in NY Shop",
                systemImage: "bag.fill",
                url: URL(string: "https://made-in-ny-shop.fourthwall.com/")
            )

            SettingsLinkRow(
                title: "Convention Swag Bundle",
                systemImage: "gift.fill",
                url: URL(string: "https://made-in-ny-shop.fourthwall.com/products/convention-bundle")
            )

            SettingsLinkRow(
                title: "Trek Long Island Etsy Shop",
                systemImage: "sparkles",
                url: URL(string: "https://www.etsy.com/shop/TrekLongIsland")
            )

            SettingsLinkRow(
                title: "Facebook",
                systemImage: "f.cursive.circle.fill",
                url: URL(string: "https://facebook.com/TrekLongIsland")
            )
        }
    }

    private var aboutCard: some View {
        SettingsSectionCard(
            icon: "info.circle.fill",
            iconColor: .purple,
            title: "About",
            subtitle: "Build info for your starfleet logs."
        ) {
            HStack {
                Text("Version")
                    .font(.system(.subheadline, design: .rounded))
                Spacer()
                Text(appVersionString)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.72))
            }

            HStack {
                Text("Build")
                    .font(.system(.subheadline, design: .rounded))
                Spacer()
                Text(appBuildString)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.72))
            }

            Divider().opacity(0.4)

            Text("Trek Long Island is an independent fan-run convention celebrating Star Trek and the values of inclusion, curiosity, and kindness.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))

            Text("Star Trek and all related marks, logos and characters are solely owned by CBS Studios Inc. and Paramount Pictures. This fan production is not endorsed by, sponsored by, nor affiliated with CBS, Paramount Pictures, or any other Star Trek franchise. The term and graphical illustration called, 'Trek Long Island' is copyrighted, 2026, B. Carroll. 1-15133681261. All Rights Reserved.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))

            Text("The Trek Long Island App Codebase is also copyrighted 2026. B. Carroll. All Rights Reserved.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))

            Button {
                dismissKeyboard()
                showOnboardingReplay = true
            } label: {
                HStack {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                    Text("Replay Onboarding")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                    Spacer()
                }
            }
            .buttonStyle(SettingsGhostButtonStyle())
        }
    }

    // MARK: - App Icon helpers

    private var supportsAlternateIcons: Bool {
        #if canImport(UIKit)
        return UIApplication.shared.supportsAlternateIcons
        #else
        return false
        #endif
    }

    private func currentSystemIconChoice() -> TLIAppIconChoice {
        #if canImport(UIKit)
        return TLIAppIconChoice.fromSystemAlternateIconName(UIApplication.shared.alternateIconName)
        #else
        return .appIcon
        #endif
    }

    private func syncAppIconPickerWithSystem() {
        let sys = currentSystemIconChoice().preferredChoice
        guard selectedAppIconRaw != sys.rawValue else { return }

        suppressAppIconApply = true
        selectedAppIconRaw = sys.rawValue

        Task { @MainActor in
            await Task.yield()
            suppressAppIconApply = false
        }
    }

    private func applySelectedAppIcon() async {
        guard supportsAlternateIcons else { return }
        guard !isChangingAppIcon else { return }

        let desired = (TLIAppIconChoice(rawValue: selectedAppIconRaw) ?? .appIcon).preferredChoice
        let current = currentSystemIconChoice()
        guard desired != current.preferredChoice else { return }

        #if canImport(UIKit)
        isChangingAppIcon = true
        appIconErrorMessage = nil
        defer { isChangingAppIcon = false }

        let result = await setAlternateIconNameWithRetry(desired.alternateIconName)
        if let error = result.error {
            appIconErrorMessage = result.isTransient
                ? "iOS is still busy updating the icon. Please wait a moment and try again."
                : error.localizedDescription
            syncAppIconPickerWithSystem()
        }
        #endif
    }

    private func scheduleAppIconApply() {
        dismissKeyboard()
        pendingAppIconApplyTask?.cancel()
        pendingAppIconApplyTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await applySelectedAppIcon()
            pendingAppIconApplyTask = nil
        }
    }

    #if canImport(UIKit)
    private func setAlternateIconNameWithRetry(_ iconName: String?) async -> (error: Error?, isTransient: Bool) {
        let retryDelays = [0, 450, 900, 1600]
        var lastError: Error?

        for (index, delay) in retryDelays.enumerated() {
            if delay > 0 {
                try? await Task.sleep(for: .milliseconds(delay))
            }

            let error = await setAlternateIconName(iconName)
            if error == nil {
                return (nil, false)
            }

            lastError = error
            guard let error, isTransientAppIconError(error), index < retryDelays.count - 1 else {
                return (lastError, error.map(isTransientAppIconError) ?? false)
            }
        }

        return (lastError, lastError.map(isTransientAppIconError) ?? false)
    }

    private func setAlternateIconName(_ iconName: String?) async -> Error? {
        await withCheckedContinuation { cont in
            UIApplication.shared.setAlternateIconName(iconName) { error in
                cont.resume(returning: error)
            }
        }
    }

    private func isTransientAppIconError(_ error: Error) -> Bool {
        let nsError = error as NSError
        let message = nsError.localizedDescription.lowercased()
        return nsError.domain == NSPOSIXErrorDomain
            || nsError.code == EAGAIN
            || message.contains("temporarily unavailable")
    }
    #endif

    private func sanitizeAppIconSelectionIfNeeded() async {
        let current = currentSystemIconChoice()
        guard current.isDeprecatedChoice else { return }

        suppressAppIconApply = true
        selectedAppIconRaw = current.preferredChoice.rawValue
        suppressAppIconApply = false
        await applySelectedAppIcon()
    }

    // MARK: - Notification helpers

    private func isAuthorizedLike(_ status: UNAuthorizationStatus) -> Bool {
        NotificationPermissionCoordinator.isAuthorizedLike(status)
    }

    private func statusLabel(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized:    return "Allowed"
        case .denied:        return "Denied"
        case .notDetermined: return "Not Determined"
        case .provisional:   return "Provisional"
        case .ephemeral:     return "Ephemeral"
        @unknown default:    return "Unknown"
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let normalized = ((hour % 24) + 24) % 24
        let suffix = normalized >= 12 ? "PM" : "AM"
        let value = normalized % 12 == 0 ? 12 : normalized % 12
        return "\(value) \(suffix)"
    }

    private func footerText(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "Notifications are enabled. You can manage sounds, badges, and alert style in iOS Settings."
        case .provisional:
            return "Provisional authorization delivers quietly. Promote to full alerts in iOS Settings for banners and sounds."
        case .ephemeral:
            return "You currently have temporary authorization. Consider enabling full alerts in iOS Settings."
        case .denied:
            return "Notifications are off. Use “Enable in Settings” to allow alerts, sounds, and badges."
        case .notDetermined:
            return "We haven’t asked for permission yet. Use “Allow Notifications” to enable alerts, sounds, and badges."
        @unknown default:
            return "Notification status is unknown. You can adjust preferences in iOS Settings."
        }
    }

    private var buttonTitle: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return "Manage in Settings"
        case .denied:                                return "Enable in Settings"
        case .notDetermined:                         return "Allow Notifications"
        @unknown default:                            return "Manage"
        }
    }

    private var buttonIcon: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return "gearshape"
        case .denied, .notDetermined:               return "bell.badge"
        @unknown default:                            return "gearshape"
        }
    }

    private func handleNotificationsButton() {
        switch notificationStatus {
        case .notDetermined:
            Task { await requestNotificationsPermission() }
        default:
            openSystemSettings()
        }
    }

    private func requestNotificationsPermission() async {
        notificationStatus = await NotificationPermissionCoordinator.requestAuthorizationIfNeeded()
    }

    private func refreshNotificationStatus() async {
        isLoadingNotifStatus = true
        notificationStatus = await NotificationPermissionCoordinator.refreshRemoteNotificationRegistration()
        isLoadingNotifStatus = false
    }

    private func scheduleTestNotification() async {
        guard !isSchedulingTest else { return }
        isSchedulingTest = true
        defer { isSchedulingTest = false }

        let content = UNMutableNotificationContent()
        content.title = TLIAppBranding.appDisplayName
        content.subtitle = "Notifications working"
        content.body = "This is a test alert from Settings."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "tli.test.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Optional: add your own in-app toast if you have one.
        }
    }

    private var microphoneStatusLabel: String {
        switch microphoneStatus {
        case .granted: return "Allowed"
        case .denied: return "Denied"
        case .undetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    private var speechStatusLabel: String {
        switch speechStatus {
        case .authorized: return "Allowed"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    private var shouldOfferVoicePermissionRequest: Bool {
        microphoneStatus == .undetermined || speechStatus == .notDetermined
    }

    private func refreshVoicePermissionStatus() {
        isRefreshingVoiceStatus = true
        microphoneStatus = AVAudioApplication.shared.recordPermission
        speechStatus = SFSpeechRecognizer.authorizationStatus()
        isRefreshingVoiceStatus = false
    }

    private func requestVoicePermissions() {
        Task {
            _ = await requestMicrophonePermission()
            _ = await requestSpeechPermission()
            await MainActor.run {
                refreshVoicePermissionStatus()
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func openSystemSettings() {
        dismissKeyboard()
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
        #endif
    }

    private func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    // MARK: - App Info

    private var appVersionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var appBuildString: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

// MARK: - Shared Section Card

struct SettingsSectionCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes

    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let content: Content

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(iconColor.opacity(0.16))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .accessibilityAddTraits(.isHeader)
                    Text(subtitle)
                        .font(.system(.footnote, design: .rounded))
                        .lineSpacing(1.5)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }

                Spacer()
            }

            content
                .font(.system(.subheadline, design: .rounded))
        }
        .padding(16)
        .settingsCardSurface(
            cornerRadius: 22,
            emphasize: false
        )
        .overlay(alignment: .topTrailing) {
            if showButtonShapes {
                Image(systemName: "accessibility")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TLITheme.textTertiary(scheme))
                    .padding(10)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - Button Styles

struct SettingsPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        configuration.label
            .padding(.vertical, 11)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(shape.fill(TLITheme.cardBackground(scheme).opacity(scheme == .dark ? 0.78 : 0.94)))
            .overlay(shape.fill(TLITheme.accentSoft(scheme).opacity(scheme == .dark ? 0.12 : 0.08)))
            .overlay(
                shape
                    .stroke(accent.opacity(configuration.isPressed ? 0.55 : 0.30), lineWidth: 1)
            )
            .overlay(alignment: .trailing) {
                if differentiateWithoutColor {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(accent)
                        .padding(.trailing, 12)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(TLITheme.textPrimary(scheme))
            .shadow(
                color: TLITheme.cardShadowColor(scheme).opacity(scheme == .dark ? 0.24 : 0.10),
                radius: configuration.isPressed ? 2 : 4,
                y: 2
            )
            .tliButtonShapeOutline(shape: shape, strokeColor: accent)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(showButtonShapes ? nil : .spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct SettingsGhostButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        configuration.label
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .settingsCardSurface(
                cornerRadius: 16,
                emphasize: configuration.isPressed
            )
            .foregroundStyle(TLITheme.textPrimary(scheme))
            .tliButtonShapeOutline(shape: shape, strokeColor: TLITheme.border(scheme))
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(showButtonShapes ? nil : .spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

private struct SettingsCardSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var accessibilityContrast

    let cornerRadius: CGFloat
    let emphasize: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let baseFill = TLITheme.cardBackground(scheme).opacity(scheme == .dark ? 0.82 : 0.95)
        let accentWash = TLITheme.accentSoft(scheme).opacity(emphasize ? (scheme == .dark ? 0.16 : 0.10) : (scheme == .dark ? 0.08 : 0.05))
        let strokeColor = TLITheme.border(scheme).opacity(emphasize ? 0.34 : 0.18)

        content
            .tliAccessibleSurface(
                shape: shape,
                baseFill: reduceTransparency ? TLITheme.cardBackground(scheme) : baseFill,
                accentWash: reduceTransparency ? .clear : accentWash,
                strokeColor: strokeColor.opacity(accessibilityContrast == .increased ? 1.0 : 0.92),
                shadowColor: TLITheme.cardShadowColor(scheme).opacity(scheme == .dark ? 0.22 : 0.08),
                shadowRadius: emphasize ? 8 : 4,
                shadowY: emphasize ? 4 : 2
            )
    }
}

private extension View {
    func settingsCardSurface(
        cornerRadius: CGFloat = 20,
        emphasize: Bool = false
    ) -> some View {
        modifier(
            SettingsCardSurfaceModifier(
                cornerRadius: cornerRadius,
                emphasize: emphasize
            )
        )
    }
}

// MARK: - Link Row

private struct SettingsLinkRow: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let systemImage: String
    let url: URL?

    var body: some View {
        if let url {
            Link(destination: url) {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .imageScale(.medium)
                        .foregroundStyle(TLITheme.accent(scheme))
                        .frame(width: 22)

                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    Spacer()

                    Image(systemName: "arrow.up.forward.square")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.72))
                }
                .padding(.vertical, 6)
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Uses your Web Links setting.")
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(\.colorScheme, .dark)
}
#endif
