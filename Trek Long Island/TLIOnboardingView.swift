import SwiftUI
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct TLIOnboardingView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @EnvironmentObject private var usageInsightsStore: TLIUsageInsightsStore

    @StateObject private var nearbyRoomCountStore = NearbyRoomCountStore.shared

    @AppStorage("TLI.Onboarding.completed") private var hasCompletedOnboarding = false
    @AppStorage("TLI.Profile.displayName") private var displayName: String = ""
    @AppStorage("TLI.Profile.rank") private var rankRaw: String = TLIProfileRank.captain.rawValue
    @AppStorage("TLI.Profile.division") private var divisionRaw: String = TLIProfileDivision.command.rawValue
    @AppStorage("TLI.Profile.role") private var roleRaw: String = TLIProfileRole.firstTimer.rawValue
    @AppStorage("TLI.Profile.objectives") private var objectivesRaw: String = ""
    @AppStorage("appVisualPreset") private var appVisualPresetRaw: String = TLIVisualPreset.defaultPreset.rawValue
    @AppStorage("appColorTheme") private var appColorThemeRaw: String = TLIColorTheme.defaultTheme.rawValue
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @AppStorage("TLI.Accessibility.largeTapTargets") private var largeTapTargets = false
    @AppStorage("TLI.Accessibility.reduceAnimations") private var reduceAnimations = false

    @FocusState private var isNameFocused: Bool
    @State private var currentStep = 0
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequestingNotifications = false
    @State private var viewportSize: CGSize = .zero

    let canDismiss: Bool
    let onFinish: (() -> Void)?

    private let totalSteps = 6

    init(canDismiss: Bool = false, onFinish: (() -> Void)? = nil) {
        self.canDismiss = canDismiss
        self.onFinish = onFinish
    }

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                topBar

                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    scheduleStep.tag(1)
                    themeStep.tag(2)
                    assistantStep.tag(3)
                    setupStep.tag(4)
                    readyStep.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotionEnabled ? nil : .spring(response: 0.42, dampingFraction: 0.88), value: currentStep)
            }
            .adaptiveContentWidth(
                maxWidth: onboardingContentMaxWidth,
                horizontalPadding: onboardingHorizontalPadding,
                verticalPadding: onboardingVerticalPadding
            )
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        viewportSize = proxy.size
                    }
                    .onChange(of: proxy.size) { _, newValue in
                        viewportSize = newValue
                    }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
                .background(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            RisaTheme.backgroundTop(scheme).opacity(0.18),
                            RisaTheme.backgroundTop(scheme).opacity(0.82)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .background(RisaTheme.tabBarBackground(scheme).opacity(0.92))
                )
        }
        .task {
            notificationStatus = await NotificationPermissionCoordinator.refreshRemoteNotificationRegistration()
        }
        .onAppear {
            normalizeOnboardingState()
            usageInsightsStore.noteSelectedTab("onboarding")
        }
        .onChange(of: currentStep) { _, _ in
            dismissKeyboard()
        }
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

    private var reduceMotionEnabled: Bool {
        reduceAnimations || accessibilityReduceMotion
    }

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

    private var selectedTheme: TLIColorTheme {
        get { TLIColorTheme.fromStoredRawValue(appColorThemeRaw) }
        nonmutating set { appColorThemeRaw = newValue.rawValue }
    }

    private var selectedAppearance: AppAppearance {
        get { AppAppearance(rawValue: appAppearanceRaw) ?? .system }
        nonmutating set { appAppearanceRaw = newValue.rawValue }
    }

    private var selectedVisualPreset: TLIVisualPreset {
        get { TLIVisualPreset.fromStoredRawValue(appVisualPresetRaw) }
        nonmutating set {
            appVisualPresetRaw = newValue.rawValue
            selectedTheme = newValue.theme
            selectedAppearance = newValue.appearance
        }
    }

    private var selectedObjectives: Set<TLIProfileObjective> {
        get { TLIProfilePreferences.objectives(from: objectivesRaw) }
        nonmutating set { objectivesRaw = TLIProfilePreferences.serialize(newValue) }
    }

    private var captainName: String {
        TLIProfilePreferences.captainName(from: displayName)
    }

    private var commandName: String {
        TLIProfilePreferences.commandName(rank: selectedRank, displayName: displayName)
    }

    private var progressValue: Double {
        Double(currentStep + 1) / Double(totalSteps)
    }

    private var layoutWidth: CGFloat {
        viewportSize.width > 0 ? viewportSize.width : 390
    }

    private var layoutHeight: CGFloat {
        viewportSize.height > 0 ? viewportSize.height : 844
    }

    private var isCompactPhoneLayout: Bool {
        hSizeClass != .regular && TLILayout.isSmallPhone(width: layoutWidth, height: layoutHeight)
    }

    private var isNarrowPhoneLayout: Bool {
        hSizeClass != .regular && layoutWidth <= 360
    }

    private var isShortViewport: Bool {
        layoutHeight <= 740
    }

    private var onboardingContentMaxWidth: CGFloat {
        hSizeClass == .regular ? 720 : 560
    }

    private var onboardingHorizontalPadding: CGFloat {
        if hSizeClass == .regular {
            return 24
        }
        return layoutWidth <= 340 ? 10 : 14
    }

    private var onboardingVerticalPadding: CGFloat {
        isShortViewport ? 6 : 12
    }

    private var onboardingSectionSpacing: CGFloat {
        isCompactPhoneLayout ? 12 : 18
    }

    private var onboardingPanelSpacing: CGFloat {
        isCompactPhoneLayout ? 12 : 16
    }

    private var footerButtonHeight: CGFloat {
        isCompactPhoneLayout ? 48 : 54
    }

    private var pageBottomPadding: CGFloat {
        isCompactPhoneLayout ? 82 : 96
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Capsule()
                            .fill(TLITheme.accent(scheme))
                            .frame(width: 42, height: 8)
                        Capsule()
                            .fill(TLITheme.accentSoft(scheme))
                            .frame(width: 22, height: 8)
                        Text("STARFLEET ORIENTATION")
                            .font(.system(.caption2, design: .monospaced).weight(.bold))
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                    }

                    Text(currentStep == 0 ? "Welcome Aboard" : "Mission Setup")
                        .font(
                            RisaTheme.isLCARSThemeEnabled
                                ? .system(size: isCompactPhoneLayout ? 22 : 24, weight: .black, design: .monospaced)
                                : .system(isCompactPhoneLayout ? .title2 : .largeTitle, design: .rounded).weight(.bold)
                        )
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .lineLimit(2)

                    Text(stepSubtitle)
                        .font(.system(isCompactPhoneLayout ? .footnote : .subheadline, design: .rounded))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if canDismiss {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                            .frame(width: 44, height: 44)
                            .tliPanelSurface(
                                cornerRadius: 22,
                                fillOpacity: scheme == .dark ? 0.88 : 0.94,
                                borderOpacity: 0.65,
                                shadowRadius: 4,
                                shadowY: 2
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close onboarding")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Step \(currentStep + 1) of \(totalSteps)")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                    Spacer()
                    Text(stepTitle)
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.accent(scheme))
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(TLITheme.border(scheme).opacity(0.32))
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        TLITheme.accent(scheme),
                                        RisaTheme.accentGold(scheme)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(36, proxy.size.width * progressValue), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(.top, isCompactPhoneLayout ? 2 : 6)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if isNarrowPhoneLayout {
                VStack(spacing: 12) {
                    if currentStep > 0 {
                        backButton
                    }
                    primaryButton
                }
            } else {
                HStack(spacing: 12) {
                    if currentStep > 0 {
                        backButton
                    }
                    primaryButton
                }
            }
        }
        .padding(.horizontal, onboardingHorizontalPadding)
        .padding(.top, isCompactPhoneLayout ? 8 : 12)
        .padding(.bottom, isCompactPhoneLayout ? 6 : 12)
    }

    private var backButton: some View {
        Button {
            isNameFocused = false
            withAnimation(reduceMotionEnabled ? nil : .spring(response: 0.36, dampingFraction: 0.9)) {
                currentStep = max(0, currentStep - 1)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .font(.system(isCompactPhoneLayout ? .subheadline : .body, design: .rounded).weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: footerButtonHeight)
        }
        .buttonStyle(TLIOnboardingSecondaryButtonStyle())
        .opacity(currentStep == 0 ? 0 : 1)
        .disabled(currentStep == 0)
    }

    private var primaryButton: some View {
        Button {
            handlePrimaryAction()
        } label: {
            HStack(spacing: 10) {
                Text(primaryButtonTitle)
                    .font(.system(isCompactPhoneLayout ? .subheadline : .body, design: .rounded).weight(.bold))
                Image(systemName: primaryButtonIcon)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
            }
            .frame(maxWidth: .infinity, minHeight: footerButtonHeight)
        }
        .buttonStyle(TLIOnboardingPrimaryButtonStyle(accent: TLITheme.accent(scheme)))
    }

    private var welcomeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: onboardingSectionSpacing) {
                featureHero(
                    eyebrow: "Personalize first",
                    title: "Let’s tune the bridge to how you explore Trek Long Island.",
                    detail: "A few quick choices help the app spotlight the parts you care about most, from guest hunting to route planning.",
                    imageSystemName: "person.crop.circle.badge.sparkles"
                )

                VStack(alignment: .leading, spacing: onboardingPanelSpacing) {
                    onboardingSectionHeader(
                        title: "What should the crew call you?",
                        detail: "You can use your real name or a captain alias."
                    )

                    TextField("Your name or captain alias", text: $displayName)
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .tint(TLITheme.accent(scheme))
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 14)
                        .frame(height: 56)
                        .onboardingInputFieldStyle(scheme: scheme)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            dismissKeyboard()
                        }

                    onboardingSectionHeader(
                        title: "Choose your personalized rank.",
                        detail: "This becomes part of your bridge identity throughout the app."
                    )

                    LazyVGrid(columns: roleColumns, spacing: 12) {
                        ForEach(TLIProfileRank.allCases) { rank in
                            rankCard(rank)
                        }
                    }

                    onboardingSectionHeader(
                        title: "Choose your division.",
                        detail: "Pick the uniform track that best matches your convention style."
                    )

                    LazyVGrid(columns: roleColumns, spacing: 12) {
                        ForEach(TLIProfileDivision.allCases) { division in
                            divisionCard(division)
                        }
                    }

                    onboardingSectionHeader(
                        title: "Pick the closest mission profile.",
                        detail: "This helps us frame the app around how you move through the con."
                    )

                    LazyVGrid(columns: roleColumns, spacing: 12) {
                        ForEach(TLIProfileRole.allCases) { role in
                            roleCard(role)
                        }
                    }
                }
                .onboardingPanel(scheme: scheme, compact: isCompactPhoneLayout)
            }
            .padding(.bottom, pageBottomPadding)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var scheduleStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: onboardingSectionSpacing) {
                featureHero(
                    eyebrow: "Why this app matters",
                    title: "Your weekend moves faster when your plan lives in one place.",
                    detail: "\(commandName), Trek Long Island works best when you use it like a live convention dashboard instead of a static program book.",
                    imageSystemName: "calendar.badge.clock"
                )

                VStack(alignment: .leading, spacing: onboardingPanelSpacing) {
                    TLIOnboardingFeatureRow(
                        icon: "star.circle.fill",
                        title: "Favorite panels and guests",
                        detail: "Build a personal watchlist so the app keeps your must-see moments close."
                    )

                    TLIOnboardingFeatureRow(
                        icon: "bell.badge.fill",
                        title: "Catch changes in real time",
                        detail: "Announcements and schedule shifts land faster here than word of mouth on the floor."
                    )

                    TLIOnboardingFeatureRow(
                        icon: "map.fill",
                        title: "Get un-lost quickly",
                        detail: "Jump from a panel to the map instead of hunting through signage when the crowd picks up."
                    )

                    personalizedBriefing
                }
                .onboardingPanel(scheme: scheme, compact: isCompactPhoneLayout)
            }
            .padding(.bottom, pageBottomPadding)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var themeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: onboardingSectionSpacing) {
                featureHero(
                    eyebrow: "Make it yours",
                    title: "Choose the command style that feels right.",
                    detail: "Pick Federation Command or the brighter Risa mode for the weekend.",
                    imageSystemName: "paintpalette.fill"
                )

                VStack(alignment: .leading, spacing: onboardingPanelSpacing) {
                    onboardingSectionHeader(
                        title: "Choose your bridge vibe.",
                        detail: "Pick between Federation Command, LCARS Ops, or the brighter Risa mode."
                    )

                    Text("Available themes")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    ForEach(TLIVisualPreset.supportedPresets) { preset in
                        themeCard(preset)
                    }

                    Divider()
                        .overlay(TLITheme.border(scheme).opacity(0.35))

                    Picker("Appearance", selection: Binding(
                        get: { selectedAppearance },
                        set: { selectedAppearance = $0 }
                    )) {
                        Text("System").tag(AppAppearance.system)
                        Text("Light").tag(AppAppearance.light)
                        Text("Dark").tag(AppAppearance.dark)
                    }
                    .pickerStyle(.segmented)

                    Text("These can still be adjusted later in Settings, but onboarding keeps the choice focused on the three supported themes.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
                .onboardingPanel(scheme: scheme, compact: isCompactPhoneLayout)
            }
            .padding(.bottom, pageBottomPadding)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var assistantStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: onboardingSectionSpacing) {
                featureHero(
                    eyebrow: "Unique feature",
                    title: "Hello, Computer turns the app into a convention copilot.",
                    detail: "Instead of digging through tabs, you can ask direct questions about schedules, venue logistics, and Trek lore from one place.",
                    imageSystemName: "sparkles.rectangle.stack.fill"
                )

                VStack(alignment: .leading, spacing: onboardingPanelSpacing) {
                    Text("What matters most on your mission?")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    LazyVGrid(columns: objectiveColumns, spacing: 12) {
                        ForEach(TLIProfileObjective.allCases) { objective in
                            objectiveCard(objective)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Try asking Hello, Computer:")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))

                        ForEach(samplePrompts, id: \.self) { prompt in
                            HStack(spacing: 10) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .foregroundStyle(TLITheme.accent(scheme))
                                Text(prompt)
                                    .foregroundStyle(TLITheme.textSecondary(scheme))
                            }
                        }
                    }
                    .padding(14)
                    .tliPanelSurface(
                        cornerRadius: 18,
                        fillOpacity: scheme == .dark ? 0.84 : 0.92,
                        borderOpacity: 0.6,
                        shadowRadius: 4,
                        shadowY: 2
                    )
                }
                .onboardingPanel(scheme: scheme, compact: isCompactPhoneLayout)
            }
            .padding(.bottom, pageBottomPadding)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var setupStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: onboardingSectionSpacing) {
                featureHero(
                    eyebrow: "Final setup",
                    title: "A couple of switches make the app work harder for you.",
                    detail: "You stay in control, but enabling the right options now helps the app behave more like a real event companion.",
                    imageSystemName: "switch.2"
                )

                VStack(alignment: .leading, spacing: onboardingSectionSpacing) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Notifications", systemImage: "bell.badge.fill")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(TLITheme.textPrimary(scheme))
                            Spacer()
                            Text(notificationLabel)
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .foregroundStyle(TLITheme.textSecondary(scheme))
                        }

                        Text("Best for schedule shifts, room updates, and day-of announcements.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(TLITheme.textSecondary(scheme))

                        Button {
                            Task { await requestNotifications() }
                        } label: {
                            HStack {
                                Image(systemName: isRequestingNotifications ? "hourglass" : "bell.and.waves.left.and.right.fill")
                                Text(notificationButtonTitle)
                                Spacer()
                            }
                            .font(.system(.body, design: .rounded).weight(.semibold))
                        }
                        .buttonStyle(TLIOnboardingPrimaryButtonStyle(accent: TLITheme.accent(scheme)))
                        .disabled(isRequestingNotifications || notificationStatus == .denied)
                    }

                    Divider()
                        .overlay(TLITheme.border(scheme).opacity(0.35))

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Room capacity counting", systemImage: "person.3.sequence.fill")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(TLITheme.textPrimary(scheme))
                            Spacer()
                            Text(roomCapacityCountingLabel)
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .foregroundStyle(TLITheme.textSecondary(scheme))
                        }

                        Toggle("Enable nearby room capacity counting", isOn: roomCapacityCountingToggle)

                        Text("Uses this device to help estimate how busy a room is when you choose to participate, so you can spot crowd levels faster during the convention.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                    }

                    Divider()
                        .overlay(TLITheme.border(scheme).opacity(0.35))

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Comfort options", systemImage: "figure.wave")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))

                        Toggle("Larger tap targets", isOn: $largeTapTargets)
                        Toggle("Reduce animations", isOn: $reduceAnimations)

                        Text("These are the fastest ways to make the app easier to navigate in a crowded, fast-moving con environment.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                    }
                }
                .onboardingPanel(scheme: scheme, compact: isCompactPhoneLayout)
            }
            .padding(.bottom, pageBottomPadding)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var readyStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: onboardingSectionSpacing) {
                featureHero(
                    eyebrow: "You’re ready",
                    title: "Welcome to your personalized Trek Long Island bridge.",
                    detail: "You’re set up to explore faster, miss less, and get more out of the weekend.",
                    imageSystemName: "checkmark.seal.fill"
                )

                VStack(alignment: .leading, spacing: onboardingPanelSpacing) {
                    Text("\(commandName), here’s what your app is optimized for:")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    summaryRow(title: "Rank", value: selectedRank.title)
                    summaryRow(title: "Division", value: selectedDivision.title)
                    summaryRow(title: "Mission profile", value: selectedRole.title)
                    summaryRow(title: "Command style", value: selectedVisualPreset.title)
                    summaryRow(title: "Focus", value: selectedObjectivesSummary)
                    summaryRow(title: "Notifications", value: notificationLabel)
                    summaryRow(title: "Room capacity counting", value: roomCapacityCountingLabel)

                    Divider()
                        .overlay(TLITheme.border(scheme).opacity(0.35))

                    Text("Start in Today for live highlights, then build your weekend in Schedule, ask Hello, Computer when you need answers fast, and rely on announcements when the convention shifts in real time.")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
                .onboardingPanel(scheme: scheme, compact: isCompactPhoneLayout)
            }
            .padding(.bottom, pageBottomPadding)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: "Profile"
        case 1: "Why It Helps"
        case 2: "Theme"
        case 3: "Copilot"
        case 4: "Preferences"
        default: "Launch"
        }
    }

    private var stepSubtitle: String {
        switch currentStep {
        case 0:
            "Personalize the experience so the app can feel like your own bridge console."
        case 1:
            "See how Trek Long Island helps you stay ahead of the con instead of reacting to it."
        case 2:
            "Pick a visual mode that matches your mood."
        case 3:
            "Learn what makes Hello, Computer different from a normal app search bar."
        case 4:
            "Turn on the settings that matter most during a busy convention weekend."
        default:
            "Review your setup and head into the app."
        }
    }

    private var primaryButtonTitle: String {
        currentStep == totalSteps - 1 ? "Open Bridge" : "Continue"
    }

    private var primaryButtonIcon: String {
        currentStep == totalSteps - 1 ? "arrow.up.right.circle.fill" : "arrow.right"
    }

    private var roleColumns: [GridItem] {
        if hSizeClass == .regular {
            return TLILayout.columns(for: .regular, minTileWidth: 210, spacing: 12)
        }
        if layoutWidth <= 380 {
            return [GridItem(.flexible(), spacing: 12)]
        }
        return [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var objectiveColumns: [GridItem] {
        if hSizeClass == .regular {
            return TLILayout.columns(for: .regular, minTileWidth: 220, spacing: 12)
        }
        return layoutWidth <= 430
            ? [GridItem(.flexible(), spacing: 12)]
            : TLILayout.columns(for: .compact, minTileWidth: 200, spacing: 12)
    }

    private var personalizedBriefing: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommended for \(selectedRole.title.lowercased()):")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(selectedRole.guidance)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
        .padding(14)
        .tliPanelSurface(
            cornerRadius: 18,
            fillOpacity: scheme == .dark ? 0.84 : 0.92,
            borderOpacity: 0.6,
            shadowRadius: 4,
            shadowY: 2
        )
    }

    private var samplePrompts: [String] {
        resolvedObjectives.prefix(3).map(\.samplePrompt)
    }

    private var selectedObjectivesSummary: String {
        TLIProfilePreferences.objectivesSummary(from: selectedObjectives)
    }

    private var resolvedObjectives: Set<TLIProfileObjective> {
        selectedObjectives.isEmpty ? Set(TLIProfileObjective.defaultSet) : selectedObjectives
    }

    private var notificationLabel: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            "Enabled"
        case .denied:
            "Disabled in iOS"
        case .notDetermined:
            "Not set"
        @unknown default:
            "Unknown"
        }
    }

    private var notificationButtonTitle: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            "Notifications Enabled"
        case .denied:
            "Enable in iOS Settings"
        case .notDetermined:
            "Allow Notifications"
        @unknown default:
            "Check Notifications"
        }
    }

    private var roomCapacityCountingToggle: Binding<Bool> {
        Binding(
            get: { nearbyRoomCountStore.isEnabled },
            set: { nearbyRoomCountStore.setEnabled($0) }
        )
    }

    private var roomCapacityCountingLabel: String {
        nearbyRoomCountStore.isEnabled ? "Enabled" : "Off"
    }

    private func handlePrimaryAction() {
        dismissKeyboard()
        normalizeOnboardingState()

        if currentStep == totalSteps - 1 {
            completeOnboarding()
        } else {
            withAnimation(reduceMotionEnabled ? nil : .spring(response: 0.36, dampingFraction: 0.9)) {
                currentStep += 1
            }
        }
    }

    private func completeOnboarding() {
        dismissKeyboard()
        normalizeOnboardingState()
        TLIAdExperience.markOnboardingCompleted()
        hasCompletedOnboarding = true
        onFinish?()
        if canDismiss {
            dismiss()
        }
    }

    private func normalizeOnboardingState() {
        if TLIProfileRank(rawValue: rankRaw) == nil {
            selectedRank = .captain
        }
        if TLIProfileDivision(rawValue: divisionRaw) == nil {
            selectedDivision = .command
        }
        if TLIProfileRole(rawValue: roleRaw) == nil {
            selectedRole = .firstTimer
        }
        let normalizedPreset = TLIVisualPreset.fromStoredRawValue(appVisualPresetRaw)
        if normalizedPreset.rawValue != appVisualPresetRaw {
            selectedVisualPreset = normalizedPreset
        }
        if AppAppearance(rawValue: appAppearanceRaw) == nil {
            selectedAppearance = normalizedPreset.appearance
        }
        if selectedObjectives.isEmpty {
            selectedObjectives = Set(TLIProfileObjective.defaultSet)
        }
    }

    private func requestNotifications() async {
        dismissKeyboard()
        guard !isRequestingNotifications else { return }
        isRequestingNotifications = true
        defer { isRequestingNotifications = false }
        notificationStatus = await NotificationPermissionCoordinator.requestAuthorizationIfNeeded()
    }

    private func dismissKeyboard() {
        isNameFocused = false
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    private func onboardingSectionHeader(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
            Text(detail)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    @ViewBuilder
    private func featureHero(eyebrow: String, title: String, detail: String, imageSystemName: String) -> some View {
        HStack(alignment: .top, spacing: isCompactPhoneLayout ? 10 : 14) {
            if !isNarrowPhoneLayout {
                lcarsHeroRail
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    Text(eyebrow.uppercased())
                        .font(.system(.caption, design: .rounded).weight(.heavy))
                        .kerning(1.4)
                        .foregroundStyle(TLITheme.accent(scheme))

                    if !isNarrowPhoneLayout {
                        Spacer(minLength: 8)

                        Text("PADD // \(currentStep + 1)")
                            .font(.system(.caption2, design: .monospaced).weight(.bold))
                            .foregroundStyle(TLITheme.textTertiary(scheme))
                    }
                }

                if isCompactPhoneLayout {
                    VStack(alignment: .leading, spacing: 12) {
                        heroCopy(title: title, detail: detail)
                        if !isShortViewport {
                            heroIcon(systemName: imageSystemName)
                        }
                    }
                } else {
                    HStack(alignment: .top, spacing: 14) {
                        heroCopy(title: title, detail: detail)
                        heroIcon(systemName: imageSystemName)
                    }
                }
            }
        }
        .padding(isCompactPhoneLayout ? 14 : 18)
        .tliPanelSurface(
            cornerRadius: isCompactPhoneLayout ? 18 : 28,
            fillOpacity: scheme == .dark ? 0.88 : 0.94,
            borderOpacity: 0.7,
            shadowRadius: isCompactPhoneLayout ? 5 : 8,
            shadowY: isCompactPhoneLayout ? 2 : 4
        )
    }

    private var lcarsHeroRail: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(TLITheme.accent(scheme))
                .frame(width: 16, height: isCompactPhoneLayout ? 40 : 54)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(RisaTheme.accentGold(scheme))
                .frame(width: 16, height: isCompactPhoneLayout ? 72 : 92)
            Spacer(minLength: 0)
        }
        .frame(width: 16)
    }

    private func heroCopy(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(
                    RisaTheme.isLCARSThemeEnabled
                        ? .system(size: isCompactPhoneLayout ? 18 : 22, weight: .heavy, design: .monospaced)
                        : .system(isCompactPhoneLayout ? .title3 : .title2, design: .rounded).weight(.bold)
                )
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func heroIcon(systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(TLITheme.accentSoft(scheme))
                .frame(width: isCompactPhoneLayout ? 56 : 82, height: isCompactPhoneLayout ? 56 : 82)
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(TLITheme.border(scheme).opacity(0.5), lineWidth: 1)
                .frame(width: isCompactPhoneLayout ? 56 : 82, height: isCompactPhoneLayout ? 56 : 82)
            Image(systemName: systemName)
                .font(.system(size: isCompactPhoneLayout ? 21 : 28, weight: .semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
        }
        .accessibilityHidden(true)
    }

    private func roleCard(_ role: TLIProfileRole) -> some View {
        let isSelected = selectedRole == role
        let fillStyle = isSelected
            ? AnyShapeStyle(TLITheme.accentSoft(scheme))
            : AnyShapeStyle(TLITheme.lcarsPanelFill(scheme).opacity(scheme == .dark ? 0.88 : 0.96))

        return Button {
            selectedRole = role
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: role.icon)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(TLITheme.accent(scheme))
                    }
                }

                Text(role.title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Text(role.description)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }
            .foregroundStyle(TLITheme.textPrimary(scheme))
            .padding(isCompactPhoneLayout ? 14 : 16)
            .frame(maxWidth: .infinity, minHeight: isCompactPhoneLayout ? 110 : 128, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(fillStyle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? TLITheme.accent(scheme) : TLITheme.border(scheme).opacity(0.7), lineWidth: isSelected ? 1.4 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func rankCard(_ rank: TLIProfileRank) -> some View {
        let isSelected = selectedRank == rank

        return Button {
            selectedRank = rank
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: rank.icon)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(TLITheme.accent(scheme))
                    }
                }

                Text(rank.title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text(rank.description)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(isCompactPhoneLayout ? 14 : 16)
            .tliPanelSurface(
                cornerRadius: 20,
                fillOpacity: isSelected ? 0.98 : (scheme == .dark ? 0.84 : 0.92),
                borderOpacity: isSelected ? 0.9 : 0.65,
                shadowRadius: 5,
                shadowY: 3
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func divisionCard(_ division: TLIProfileDivision) -> some View {
        let isSelected = selectedDivision == division

        return Button {
            selectedDivision = division
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: division.icon)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(TLITheme.accent(scheme))
                    }
                }

                Text(division.title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text(division.description)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(isCompactPhoneLayout ? 14 : 16)
            .tliPanelSurface(
                cornerRadius: 20,
                fillOpacity: isSelected ? 0.98 : (scheme == .dark ? 0.84 : 0.92),
                borderOpacity: isSelected ? 0.9 : 0.65,
                shadowRadius: 5,
                shadowY: 3
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func themeCard(_ preset: TLIVisualPreset) -> some View {
        let isSelected = selectedVisualPreset == preset
        let accent = themeAccent(preset.theme)

        return Button {
            selectedVisualPreset = preset
        } label: {
            HStack(spacing: isCompactPhoneLayout ? 10 : 14) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(themeGradient(preset.theme))
                    .frame(width: isCompactPhoneLayout ? 54 : 74, height: isCompactPhoneLayout ? 54 : 74)
                    .overlay(
                        Image(systemName: themeSymbol(preset.theme))
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(preset.shortLabel)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    Text(preset.description)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                    Text(preset.title)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(TLITheme.textTertiary(scheme))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(isSelected ? accent : TLITheme.textTertiary(scheme))
            }
            .padding(isCompactPhoneLayout ? 12 : 14)
            .tliPanelSurface(
                cornerRadius: 22,
                fillOpacity: scheme == .dark ? 0.86 : 0.93,
                borderOpacity: isSelected ? 0.95 : 0.7,
                shadowRadius: 6,
                shadowY: 3
            )
        }
        .buttonStyle(.plain)
    }

    private func objectiveCard(_ objective: TLIProfileObjective) -> some View {
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
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: objective.icon)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundStyle(isSelected ? TLITheme.accent(scheme) : TLITheme.textTertiary(scheme))
                }

                Text(objective.title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text(objective.description)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }
            .padding(isCompactPhoneLayout ? 14 : 16)
            .frame(maxWidth: .infinity, minHeight: isCompactPhoneLayout ? 118 : 150, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        isSelected
                        ? AnyShapeStyle(TLITheme.accentSoft(scheme))
                        : AnyShapeStyle(TLITheme.lcarsPanelFill(scheme).opacity(scheme == .dark ? 0.84 : 0.92))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? TLITheme.accent(scheme) : TLITheme.border(scheme).opacity(0.7), lineWidth: isSelected ? 1.4 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private func themeGradient(_ theme: TLIColorTheme) -> LinearGradient {
        switch theme {
        case .tos:
            LinearGradient(colors: [Color(red: 0.87, green: 0.00, blue: 0.00), Color(red: 0.95, green: 0.76, blue: 0.00), Color(red: 0.00, green: 0.60, blue: 0.96)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .tng:
            LinearGradient(colors: [Color(red: 167/255, green: 19/255, blue: 19/255), Color(red: 214/255, green: 164/255, blue: 68/255), Color(red: 43/255, green: 83/255, blue: 167/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ds9:
            LinearGradient(colors: [Color(red: 0.18, green: 0.19, blue: 0.22), Color(red: 0.70, green: 0.48, blue: 0.26)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .voyager:
            LinearGradient(colors: [Color(red: 0.12, green: 0.15, blue: 0.18), Color(red: 0.38, green: 0.42, blue: 0.46), Color(red: 0.62, green: 0.67, blue: 0.70)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .enterprise:
            LinearGradient(colors: [Color(red: 0.31, green: 0.67, blue: 0.80), Color(red: 0.47, green: 0.53, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .starfleet:
            LinearGradient(colors: [Color(red: 0.87, green: 0.00, blue: 0.00), Color(red: 0.25, green: 0.25, blue: 0.30), Color(red: 0.00, green: 0.60, blue: 0.96)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .lcars:
            LinearGradient(colors: [Color(red: 1.00, green: 0.60, blue: 0.20), Color(red: 1.00, green: 0.80, blue: 0.40), Color(red: 0.20, green: 0.40, blue: 0.80)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .risa:
            LinearGradient(colors: [Color(red: 1.00, green: 0.41, blue: 0.75), Color(red: 0.26, green: 0.78, blue: 1.00)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func themeAccent(_ theme: TLIColorTheme) -> Color {
        switch theme {
        case .tos:
            Color(red: 242/255, green: 195/255, blue: 0/255)
        case .tng:
            Color(red: 214/255, green: 164/255, blue: 68/255)
        case .ds9:
            Color(red: 0.70, green: 0.48, blue: 0.26)
        case .voyager:
            Color(red: 0.62, green: 0.72, blue: 0.78)
        case .enterprise:
            Color(red: 0.31, green: 0.67, blue: 0.80)
        case .starfleet:
            Color(red: 223/255, green: 0/255, blue: 0/255)
        case .lcars:
            Color(red: 255/255, green: 153/255, blue: 51/255)
        case .risa:
            Color(red: 1.00, green: 0.41, blue: 0.75)
        }
    }

    private func themeSymbol(_ theme: TLIColorTheme) -> String {
        switch theme {
        case .tos: "sparkles.tv"
        case .tng: "rectangle.3.group.bubble.left.fill"
        case .ds9: "building.2.crop.circle.fill"
        case .voyager: "location.north.line.fill"
        case .enterprise: "dot.radiowaves.left.and.right"
        case .starfleet: "star.circle.fill"
        case .lcars: "cpu.fill"
        case .risa: "sun.max.fill"
        }
    }

    private func themeDescription(_ theme: TLIColorTheme) -> String {
        switch theme {
        case .tos:
            "Bold bridge primaries, black consoles, and classic-series command drama."
        case .tng:
            "Enterprise-D warmth, soft greys, and polished late-24th-century comfort."
        case .ds9:
            "Promenade bronze, gunmetal structure, and station-side amber light."
        case .voyager:
            "Cool shipboard greys, blue instrumentation, and long-range mission focus."
        case .enterprise:
            "NX-era steel framing, blue displays, and practical early-Starfleet restraint."
        case .starfleet:
            "A cinematic bridge look with deeper console tones and brighter instrumentation."
        case .lcars:
            "Black-backed LCARS with yellow, blue, red, and warm ops-console color."
        case .risa:
            "Bright resort-world energy with tropical color and an easygoing vacation mood."
        }
    }
}


private struct TLIOnboardingFeatureRow: View {
    @Environment(\.colorScheme) private var scheme

    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(TLITheme.accent(scheme))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Text(detail)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }
        }
    }
}

private struct TLIOnboardingPrimaryButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 18,
                        bottomLeading: 18,
                        bottomTrailing: 28,
                        topTrailing: 28
                    )
                )
                    .fill(accent.opacity(configuration.isPressed ? 0.82 : 1.0))
            )
            .shadow(color: accent.opacity(0.18), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

private struct TLIOnboardingSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
                configuration.label
            .foregroundStyle(TLITheme.textPrimary(scheme))
            .background(
                UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 18,
                        bottomLeading: 18,
                        bottomTrailing: 28,
                        topTrailing: 28
                    )
                )
                    .fill(TLITheme.lcarsPanelFill(scheme).opacity(scheme == .dark ? 0.88 : 0.94))
            )
            .overlay(
                UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 18,
                        bottomLeading: 18,
                        bottomTrailing: 28,
                        topTrailing: 28
                    )
                )
                    .stroke(TLITheme.border(scheme).opacity(0.7), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

private struct TLIOnboardingPanelModifier: ViewModifier {
    let scheme: ColorScheme
    let compact: Bool

    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            if !compact {
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [TLITheme.accent(scheme), RisaTheme.accentGold(scheme)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 14, height: 84)

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(TLITheme.accentSoft(scheme))
                        .frame(width: 14)

                    Spacer(minLength: 0)
                }
                .padding(.leading, 16)
                .padding(.vertical, 18)
            }

            content
                .padding(compact ? 14 : 18)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: compact ? 18 : 26, style: .continuous)
                .fill(TLITheme.cardBackground(scheme).opacity(scheme == .dark ? 0.9 : 0.76))
        )
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 18 : 26, style: .continuous)
                .stroke(TLITheme.border(scheme).opacity(compact ? 0.58 : 0.72), lineWidth: 1)
        )
        .shadow(color: TLITheme.cardShadowColor(scheme), radius: compact ? 6 : 16, x: 0, y: compact ? 3 : 8)
    }
}

private struct TLIOnboardingInputFieldModifier: ViewModifier {
    let scheme: ColorScheme

    func body(content: Content) -> some View {
        let backgroundStyle = scheme == .dark
            ? AnyShapeStyle(TLITheme.lcarsPanelFill(scheme).opacity(0.94))
            : AnyShapeStyle(Color.white.opacity(0.98))
        let borderGradient = LinearGradient(
            colors: [
                TLITheme.border(scheme).opacity(0.8),
                TLITheme.accentSoft(scheme).opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(backgroundStyle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(borderGradient, lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(scheme == .dark ? 0.18 : 0.06),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}

private extension View {
    func onboardingPanel(scheme: ColorScheme, compact: Bool) -> some View {
        modifier(TLIOnboardingPanelModifier(scheme: scheme, compact: compact))
    }

    func onboardingInputFieldStyle(scheme: ColorScheme) -> some View {
        modifier(TLIOnboardingInputFieldModifier(scheme: scheme))
    }
}
