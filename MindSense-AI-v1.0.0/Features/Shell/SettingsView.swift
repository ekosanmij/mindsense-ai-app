import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("notifications.gentlePrompts") private var gentlePrompts = true
    @AppStorage("notifications.weeklyReview") private var weeklyReview = true
    @AppStorage("notifications.stressNudge") private var stressNudge = true
    @AppStorage("notifications.recoveryWindow") private var recoveryWindow = true
    @AppStorage("notifications.quietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("notifications.quietStartMinutes") private var quietStartMinutes = 22 * 60
    @AppStorage("notifications.quietEndMinutes") private var quietEndMinutes = 7 * 60
    @AppStorage("batteryFriendlyMode") private var batteryFriendlyMode = false

    @State private var screenState: ScreenMode = .ready
    @State private var autosaveNotice = ""
    @State private var didAppear = false

    private let settingsRowMinHeight: CGFloat = 50
    private let settingsToggleRowMinHeight: CGFloat = 64
    private let settingsIconSize: CGFloat = 16
    private let privacyPolicyURLString = "https://example.com/privacy"

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding {
            AppearanceMode(rawValue: appearanceMode) ?? .system
        } set: { value in
            appearanceMode = value.rawValue
        }
    }

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    private var quietStartBinding: Binding<Date> {
        Binding(
            get: { timeFromMinutes(quietStartMinutes) },
            set: { quietStartMinutes = minutesFromTime($0) }
        )
    }

    private var quietEndBinding: Binding<Date> {
        Binding(
            get: { timeFromMinutes(quietEndMinutes) },
            set: { quietEndMinutes = minutesFromTime($0) }
        )
    }

    private var meetingCallSignalsBinding: Binding<Bool> {
        Binding(
            get: { store.useMeetingCallSignals },
            set: { store.setUseMeetingCallSignals($0, source: "settings_health_data") }
        )
    }

    private var meetingCallSignalsStateTitle: String {
        store.useMeetingCallSignals
            ? "Current state: Included in Top drivers"
            : "Current state: Excluded from Top drivers"
    }

    private var meetingCallSignalsStateIcon: String {
        store.useMeetingCallSignals ? "checkmark.circle.fill" : "minus.circle.fill"
    }

    private var meetingCallSignalsStateTint: Color {
        store.useMeetingCallSignals ? MindSensePalette.success : MindSensePalette.warning
    }

    var body: some View {
        Group {
            if case .ready = screenState {
                settingsList
            } else {
                ScrollView {
                    ScreenStateContainer(state: screenState, retryAction: { screenState = .ready }) {
                        EmptyView()
                    }
                    .mindSensePageInsets()
                }
            }
        }
        .mindSensePageBackground()
        .navigationTitle(AppIA.settings)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MindSenseNavTitleLockup(title: AppIA.settings)
            }
        }
        .onAppear {
            didAppear = true
            store.track(event: .screenView, surface: .settings)
        }
        .onChange(of: appearanceMode) { _, newValue in
            autosaveSetting("Appearance saved")
            store.track(event: .settingAutosaved, surface: .settings, action: "appearance_mode", metadata: ["value": newValue])
            store.triggerHaptic(intent: .selection)
        }
        .onChange(of: appReduceMotion) { _, newValue in
            autosaveSetting("Motion preference saved")
            store.track(event: .settingAutosaved, surface: .settings, action: "reduce_motion", metadata: ["value": "\(newValue)"])
            store.triggerHaptic(intent: .selection)
        }
        .onChange(of: enableHaptics) { _, newValue in
            autosaveSetting("Haptic preference saved")
            store.track(event: .settingAutosaved, surface: .settings, action: "haptics", metadata: ["value": "\(newValue)"])
            if newValue {
                store.triggerHaptic(intent: .selection)
            }
        }
        .onChange(of: gentlePrompts) { _, newValue in
            autosaveSetting("Notification preference saved")
            store.track(event: .settingAutosaved, surface: .settings, action: "gentle_prompts", metadata: ["value": "\(newValue)"])
            store.triggerHaptic(intent: .selection)
        }
        .onChange(of: weeklyReview) { _, newValue in
            autosaveSetting("Notification preference saved")
            store.track(event: .settingAutosaved, surface: .settings, action: "weekly_review", metadata: ["value": "\(newValue)"])
            store.triggerHaptic(intent: .selection)
        }
        .onChange(of: stressNudge) { _, newValue in
            autosaveSetting("Notification preference saved")
            store.track(event: .settingAutosaved, surface: .settings, action: "stress_nudge", metadata: ["value": "\(newValue)"])
            store.triggerHaptic(intent: .selection)
        }
        .onChange(of: recoveryWindow) { _, newValue in
            autosaveSetting("Notification preference saved")
            store.track(event: .settingAutosaved, surface: .settings, action: "recovery_window", metadata: ["value": "\(newValue)"])
            store.triggerHaptic(intent: .selection)
        }
        .onChange(of: batteryFriendlyMode) { _, newValue in
            autosaveSetting("Battery mode preference saved")
            store.track(event: .settingAutosaved, surface: .settings, action: "battery_friendly_mode", metadata: ["value": "\(newValue)"])
            store.showBanner(
                title: "Battery friendly mode",
                detail: newValue
                    ? "Battery friendly mode is on. Low Power Mode will reduce refresh frequency, suppress non-essential nudges, and defer heavy processing."
                    : "Battery friendly mode is off. Standard refresh and notification behavior restored.",
                severity: .info
            )
            store.triggerHaptic(intent: .selection)
        }
        .onChange(of: quietHoursEnabled) { _, newValue in
            autosaveSetting("Notification preference saved")
            store.track(event: .settingAutosaved, surface: .settings, action: "quiet_hours_enabled", metadata: ["value": "\(newValue)"])
            store.triggerHaptic(intent: .selection)
        }
        .onChange(of: quietStartMinutes) { _, newValue in
            autosaveSetting("Quiet hours saved")
            store.track(event: .settingAutosaved, surface: .settings, action: "quiet_hours_start", metadata: ["minutes": "\(newValue)"])
            store.triggerHaptic(intent: .selection)
        }
        .onChange(of: quietEndMinutes) { _, newValue in
            autosaveSetting("Quiet hours saved")
            store.track(event: .settingAutosaved, surface: .settings, action: "quiet_hours_end", metadata: ["minutes": "\(newValue)"])
            store.triggerHaptic(intent: .selection)
        }
        .onChange(of: store.useMeetingCallSignals) { _, _ in
            autosaveSetting("Signal source preference saved")
            store.triggerHaptic(intent: .selection)
        }
    }

    private var settingsList: some View {
        ScrollView {
            VStack(spacing: MindSenseRhythm.section) {
                profileSection
                    .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)
                healthDataSection
                    .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)
                notificationSection
                    .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)
                appearanceSection
                    .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)
                safetySection
                    .mindSenseStaggerEntrance(4, isPresented: didAppear, reduceMotion: reduceMotion)
                accountSection
                    .mindSenseStaggerEntrance(5, isPresented: didAppear, reduceMotion: reduceMotion)
            }
            .mindSensePageInsets()
        }
    }

    private var autosaveStatusText: String {
        autosaveNotice.isEmpty ? "Preferences save automatically." : autosaveNotice
    }

    private var nudgesEnabledCount: Int {
        [gentlePrompts, weeklyReview, stressNudge, recoveryWindow].filter { $0 }.count
    }

    private var appearanceChipText: String {
        "Theme \(appearanceBinding.wrappedValue.title)"
    }

    private var motionChipText: String {
        "Motion \(appReduceMotion ? "Reduced" : "Standard")"
    }

    private var nudgeChipText: String {
        "Nudges \(nudgesEnabledCount)/4"
    }

    private var quietHoursChipText: String {
        quietHoursEnabled ? "Quiet hours On" : "Quiet hours Off"
    }

    private var profileSection: some View {
        FocusSurface {
            settingsModuleHeader(
                title: "Settings control center",
                subtitle: "Personal preferences, signal behavior, and trust controls.",
                icon: "gearshape.2"
            )

            settingsInfoPanel {
                HStack(alignment: .center, spacing: MindSenseSpacing.sm) {
                    MindSenseIconBadge(
                        systemName: "person.crop.circle.fill",
                        tint: MindSensePalette.signalCoolStrong,
                        style: .filled,
                        size: MindSenseControlSize.profileBadge
                    )

                    VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
                        Text(store.userDisplayName)
                            .font(MindSenseTypography.bodyStrong)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Profile and preference defaults")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: MindSenseSpacing.xs)

                    settingsStatusChip(
                        title: autosaveNotice.isEmpty ? "Auto-save" : "Saved",
                        icon: autosaveNotice.isEmpty ? "checkmark.circle" : "checkmark.circle.fill",
                        tint: MindSensePalette.signalCoolStrong
                    )
                    .fixedSize()
                }

                Text(autosaveStatusText)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(autosaveNotice.isEmpty ? .secondary : MindSensePalette.signalCoolStrong)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !dynamicTypeSize.isAccessibilitySize {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MindSenseSpacing.xs) {
                        settingsStatusChip(title: appearanceChipText, icon: "paintbrush", tint: MindSensePalette.signalCoolStrong)
                        settingsStatusChip(title: motionChipText, icon: "figure.walk", tint: MindSensePalette.signalCool)
                        settingsStatusChip(title: nudgeChipText, icon: "bell.badge", tint: MindSensePalette.signalCoolStrong)
                        settingsStatusChip(title: quietHoursChipText, icon: "moon.zzz", tint: quietHoursEnabled ? MindSensePalette.warning : MindSensePalette.signalCool)
                    }
                    .padding(.vertical, 1)
                }
                .accessibilityLabel("Settings status summary")
            }

            Button {
                store.showBanner(
                    title: "Recommended next step",
                    detail: "Review notification settings for quiet hours and stress nudges.",
                    severity: .info
                )
                store.triggerHaptic(intent: .selection)
            } label: {
                Label("Recommended: Review notifications", systemImage: "bell.badge.fill")
            }
            .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary))
        }
    }

    private var accountSection: some View {
        InsetSurface {
            settingsModuleHeader(
                title: "Account and access",
                subtitle: "Session access and account-level actions.",
                icon: "person.badge.key"
            )

            settingsInfoPanel(spacing: MindSenseSpacing.xxxs) {
                Text("Sign out is separate from data controls so privacy and export actions remain easy to find above.")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            settingsCluster {
                settingsRow(
                    title: "Sign out",
                    icon: "rectangle.portrait.and.arrow.right",
                    tint: MindSensePalette.critical,
                    showsDisclosure: false
                ) {
                    store.signOut()
                }
            }
        }
    }

    private var healthDataSection: some View {
        FocusSurface {
            settingsModuleHeader(
                title: "Privacy and data",
                subtitle: "Trust-first controls for local data access, export, and signal-source behavior.",
                icon: "heart.text.square"
            )

            settingsCluster {
                settingsRow(title: "Privacy policy", icon: "lock.shield") {
                    guard let url = URL(string: privacyPolicyURLString) else {
                        store.showBanner(
                            title: "Privacy policy unavailable",
                            detail: "The privacy policy link is not configured correctly yet. Please try again later.",
                            severity: .warning
                        )
                        return
                    }
                    openURL(url)
                }
                .accessibilityIdentifier("settings_privacy_policy_row")

                settingsClusterDivider()

                settingsRow(title: "Data export and delete", icon: "tray.and.arrow.down") {
                    store.showBanner(title: "Data controls", detail: "Export and delete workflows can be connected here.", severity: .info)
                }

                settingsClusterDivider()

                NavigationLink {
                    AppleHealthPermissionsView()
                } label: {
                    settingsRowLabel(title: "Apple Health permissions", icon: "waveform.path.ecg")
                }
                .buttonStyle(.plain)
            }

            settingsSubgroupLabel(
                "Signal sources",
                subtitle: "Metadata-only calendar and call volume can optionally influence Top drivers ranking."
            )

            settingsCluster {
                settingsToggleRow(
                    title: "Use meeting/call signals",
                    subtitle: "Allow Calendar and calls metadata to influence Top drivers ranking.",
                    isOn: meetingCallSignalsBinding
                )
            }

            meetingCallSignalsContextRow
        }
    }

    private var meetingCallSignalsContextRow: some View {
        settingsInfoPanel {
            HStack(spacing: MindSenseSpacing.xs) {
                Image(systemName: meetingCallSignalsStateIcon)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(meetingCallSignalsStateTint)
                Text(meetingCallSignalsStateTitle)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Uses: Calendar busy windows and call-volume metadata only for Top drivers ranking.")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Does not use: event titles, participant names, contact names, or message content.")
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meetingCallSignalsStateTitle). Uses calendar busy windows and call-volume metadata for Top drivers ranking. Does not use event titles, participant names, contact names, or message content.")
    }

    private var notificationSection: some View {
        InsetSurface {
            settingsModuleHeader(
                title: "Notifications",
                subtitle: "Tune nudges, quiet windows, and battery-aware behavior with clearer groups.",
                icon: "bell.badge"
            )

            settingsSubgroupLabel(
                "Guidance nudges",
                subtitle: "Choose which proactive prompts MindSense can surface."
            )

            settingsCluster {
                settingsToggleRow(title: "Gentle nudges", subtitle: "Low-friction nudges before likely high-load windows.", isOn: $gentlePrompts)
                settingsClusterDivider()
                settingsToggleRow(title: "Weekly review", subtitle: "Prompt to review trend and experiment quality.", isOn: $weeklyReview)
                settingsClusterDivider()
                settingsToggleRow(title: "Smart stress nudge", subtitle: "Offer a 3-minute downshift when a stress episode is detected.", isOn: $stressNudge)
                settingsClusterDivider()
                settingsToggleRow(title: "Recovery window", subtitle: "Notify when physiology stabilizes for a deep-work window.", isOn: $recoveryWindow)
            }

            settingsSubgroupLabel(
                "System behavior",
                subtitle: "Low Power Mode handling and refresh efficiency."
            )

            settingsCluster {
                settingsToggleRow(
                    title: "Battery friendly mode",
                    subtitle: batteryFriendlyModeSubtitle,
                    isOn: $batteryFriendlyMode
                )
                settingsClusterDivider()
                batteryFriendlyModeStatusRow
            }

            settingsSubgroupLabel(
                "Quiet hours",
                subtitle: "Protect a no-nudge window and set the active time range."
            )

            settingsCluster {
                settingsToggleRow(
                    title: "Quiet hours",
                    subtitle: "Pause nudges during your protected time window.",
                    isOn: $quietHoursEnabled
                )

                if quietHoursEnabled {
                    settingsClusterDivider()
                    quietHoursRow
                        .padding(.horizontal, MindSenseSpacing.sm)
                        .padding(.bottom, MindSenseSpacing.sm)
                }
            }
        }
    }

    private var batteryFriendlyModeStatusRow: some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
            Text(store.batteryFriendlyModeStatusLine)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if batteryFriendlyMode {
                Text("Applies only while iPhone Low Power Mode is on. Manual resync and user-started reminders are still available.")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, MindSenseSpacing.sm)
        .padding(.vertical, MindSenseSpacing.sm)
    }

    private var quietHoursRow: some View {
        settingsInfoPanel(spacing: MindSenseSpacing.sm) {
            VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
                Text("Active \(quietHoursLabel)")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Nudges remain paused during this window while user-started reminders stay available.")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: MindSenseSpacing.sm) {
                        quietTimePicker(title: "Start", selection: quietStartBinding)
                        quietTimePicker(title: "End", selection: quietEndBinding)
                    }
                } else {
                    HStack(spacing: MindSenseSpacing.sm) {
                        quietTimePicker(title: "Start", selection: quietStartBinding)
                        quietTimePicker(title: "End", selection: quietEndBinding)
                    }
                }
            }
        }
        .padding(.top, MindSenseSpacing.xxxs)
    }

    private var appearanceSection: some View {
        InsetSurface {
            settingsModuleHeader(
                title: "Appearance and motion",
                subtitle: "Theme, animation intensity, and tactile feedback in one coherent preference group.",
                icon: "paintbrush"
            )

            settingsSubgroupLabel(
                "Theme",
                subtitle: "Follow iPhone appearance or lock a specific app theme."
            )

            settingsInfoPanel {
                MindSenseSegmentedControl(
                    options: AppearanceMode.allCases,
                    selection: appearanceBinding,
                    title: { $0.title }
                )
            }

            settingsSubgroupLabel(
                "Motion and feedback",
                subtitle: "Animation intensity harmonizes with iOS Reduce Motion; haptics confirm key actions."
            )

            appearanceMotionSemanticsRow

            settingsCluster {
                settingsToggleRow(title: "Reduce motion", subtitle: "Lower animation amplitude throughout the app. Also follows iOS Reduce Motion.", isOn: $appReduceMotion)
                settingsClusterDivider()
                settingsToggleRow(title: "Haptics", subtitle: "Tactile confirmation for key actions and completions. iOS System Haptics off will suppress output.", isOn: $enableHaptics)
            }
        }
    }

    private var appearanceMotionSemanticsRow: some View {
        settingsInfoPanel {
            Text("Theme controls visual appearance. Motion controls animation intensity and follows iOS Reduce Motion.")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: MindSenseSpacing.xs) {
                Image(systemName: appReduceMotion || accessibilityReduceMotion ? "figure.walk.circle" : "figure.walk")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MindSensePalette.signalCoolStrong)
                Text("Motion state: App \(appReduceMotion ? "Reduced" : "Standard") • iOS \(accessibilityReduceMotion ? "Reduced" : "Standard")")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var safetySection: some View {
        InsetSurface {
            settingsModuleHeader(
                title: "Safety and support",
                subtitle: "Quick access to support pathways and guidance without replacing emergency care.",
                icon: "cross.case"
            )

            settingsCluster {
                settingsRow(title: "Crisis resources (US 988)", icon: "phone.fill", tint: MindSensePalette.warning, haptic: .warning) {
                    if let tel = URL(string: "tel://988") {
                        openURL(tel)
                    }
                }

                settingsClusterDivider()

                settingsRow(title: "Safety guidelines", icon: "exclamationmark.shield") {
                    store.showBanner(title: "Safety guidelines", detail: "Use support channels and personal boundaries that keep you safe.", severity: .info)
                }
            }

            settingsInfoPanel(spacing: MindSenseSpacing.xxxs) {
                Text("MindSense provides wellness support and does not replace emergency services.")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func settingsModuleHeader(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color = MindSensePalette.signalCoolStrong
    ) -> some View {
        MindSenseSectionHeader(
            model: .init(
                title: title,
                subtitle: subtitle,
                icon: icon,
                iconTint: tint
            )
        )
    }

    private func settingsSubgroupLabel(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 2) {
            Text(title.uppercased())
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.75)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func settingsCluster<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
    }

    private func settingsClusterDivider() -> some View {
        MindSenseSectionDivider(inset: MindSenseSpacing.sm)
    }

    private func settingsInfoPanel<Content: View>(
        spacing: CGFloat = MindSenseSpacing.xs,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .padding(.horizontal, MindSenseSpacing.sm)
        .padding(.vertical, MindSenseSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
    }

    private func settingsStatusChip(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: MindSenseSpacing.xxxs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(title)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, MindSenseSpacing.sm)
        .frame(minHeight: 32)
        .background(
            Capsule(style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private func autosaveSetting(_ notice: String) {
        autosaveNotice = notice
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if autosaveNotice == notice {
                autosaveNotice = ""
            }
        }
    }

    private func settingsRow(
        title: String,
        icon: String,
        tint: Color = MindSensePalette.accent,
        haptic: MindSenseHapticIntent = .primary,
        showsDisclosure: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            store.triggerHaptic(intent: haptic)
            action()
        } label: {
            settingsRowLabel(title: title, icon: icon, tint: tint, showsDisclosure: showsDisclosure)
        }
        .buttonStyle(.plain)
    }

    private func settingsRowLabel(
        title: String,
        icon: String,
        tint: Color = MindSensePalette.accent,
        showsDisclosure: Bool = true
    ) -> some View {
        HStack(spacing: MindSenseSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: settingsIconSize, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .frame(width: 20)

            Text(title)
                .font(MindSenseTypography.bodyStrong)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: MindSenseSpacing.xs)

            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: settingsRowMinHeight)
        .padding(.horizontal, MindSenseSpacing.sm)
        .padding(.vertical, MindSenseSpacing.xs)
        .contentShape(Rectangle())
    }

    private func settingsToggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: MindSenseSpacing.sm) {
            VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
                Text(title)
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(MindSensePalette.signalCool)
                .frame(minWidth: 50, alignment: .trailing)
                .padding(.top, 1)
        }
        .frame(minHeight: settingsToggleRowMinHeight, alignment: .leading)
        .padding(.horizontal, MindSenseSpacing.sm)
        .padding(.vertical, MindSenseSpacing.sm)
    }

    private var batteryFriendlyModeSubtitle: String {
        if store.isBatteryFriendlyModeActive {
            return "Low Power Mode is on: use less frequent refreshes, fewer non-essential nudges, and defer heavy processing."
        }
        return "When iPhone Low Power Mode is on, use less frequent refreshes, fewer notifications, and no heavy processing."
    }

    private func quietTimePicker(title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
            Text(title)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.7)

            DatePicker(
                "",
                selection: selection,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(MindSensePalette.signalCool)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
    }

    private var quietHoursLabel: String {
        "\(formatTime(minutes: quietStartMinutes))-\(formatTime(minutes: quietEndMinutes))"
    }

    private func timeFromMinutes(_ minutes: Int) -> Date {
        let normalized = ((minutes % 1_440) + 1_440) % 1_440
        let dayStart = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .minute, value: normalized, to: dayStart) ?? Date()
    }

    private func minutesFromTime(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return max(0, min(1_439, (hour * 60) + minute))
    }

    private func formatTime(minutes: Int) -> String {
        let date = timeFromMinutes(minutes)
        return date.formatted(date: .omitted, time: .shortened)
    }
}

struct AppleHealthPermissionsView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.openURL) private var openURL
    @State private var showDeleteDerivedConfirmation = false
    @State private var selectedRemediationGuide: DemoHealthPermissionRemediationGuide?

    var body: some View {
        ScrollView {
            VStack(spacing: MindSenseSpacing.md) {
                MindSenseCommandDeck(
                    label: "Apple Health",
                    title: "Permissions and sync diagnostics",
                    detail: "Review connection, imports, and data confidence from Apple Health.",
                    metric: store.healthSourceStatusLine
                )

                InsetSurface {
                    MindSenseSectionHeader(
                        model: .init(
                            title: store.demoHealthProfile.isConnected ? "Connected" : "Not connected",
                            subtitle: "Last sync \(store.healthLastSyncRelativeLabel)"
                        )
                    )

                    HStack(spacing: MindSenseSpacing.sm) {
                        MindSenseIconBadge(
                            systemName: "waveform.path.ecg",
                            tint: qualityTint(score: store.healthDataQualityScore),
                            style: .filled,
                            size: MindSenseControlSize.profileBadge
                        )
                        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
                            Text("Data confidence \(store.healthDataQualityScore)")
                                .font(MindSenseTypography.bodyStrong)
                            Text(store.demoHealthProfile.quality.actionHint)
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                InsetSurface {
                    MindSenseSectionHeader(
                        model: .init(
                            title: "Permissions checklist",
                            subtitle: "Requested Health data types."
                        )
                    )

                    ForEach(store.healthPermissions) { permission in
                        permissionRow(permission)
                    }

                    Text("Recommendation confidence uses sleep coverage, heart-rate density, HRV availability, and watch wear continuity. Respiratory rate and environmental audio are optional context signals.")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                InsetSurface {
                    MindSenseSectionHeader(
                        model: .init(
                            title: "Data confidence diagnostics",
                            subtitle: "Coverage by signal category."
                        )
                    )
                    ForEach(store.healthQualityDiagnostics, id: \.0) { diagnostic in
                        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
                            HStack {
                                Text(diagnostic.0)
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(diagnostic.1)")
                                    .font(MindSenseTypography.bodyStrong)
                                    .monospacedDigit()
                            }
                            GeometryReader { proxy in
                                let width = proxy.size.width * CGFloat(max(0.04, Double(diagnostic.1) / 100.0))
                                ZStack(alignment: .leading) {
                                    Capsule(style: .continuous)
                                        .fill(MindSenseSurfaceLevel.base.fill)
                                    Capsule(style: .continuous)
                                        .fill(qualityTint(score: diagnostic.1))
                                        .frame(width: width)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }

                FocusSurface {
                    MindSenseSectionHeader(
                        model: .init(
                            title: "Actions",
                            subtitle: "Use these controls to refresh and recalculate health-derived insights."
                        )
                    )

                    Button("Open Health app") {
                        if let url = URL(string: "x-apple-health://") {
                            openURL(url)
                        } else {
                            store.showBanner(title: "Health app", detail: "Unable to open Health app URL on this device.", severity: .warning)
                        }
                        store.triggerHaptic(intent: .selection)
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary))

                    Button("Resync now") {
                        store.resyncDemoHealthData()
                        store.triggerHaptic(intent: .success)
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .primary))

                    Button("Rebuild baseline") {
                        store.rebuildDemoHealthDerivedData()
                        store.triggerHaptic(intent: .selection)
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary))

                    Button("Delete health-derived data") {
                        showDeleteDerivedConfirmation = true
                        store.triggerHaptic(intent: .warning)
                    }
                    .buttonStyle(MindSenseButtonStyle(kind: .destructive))
                }
            }
            .mindSensePageInsets()
        }
        .mindSensePageBackground()
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MindSenseNavTitleLockup(title: "Apple Health")
            }
        }
        .alert("Delete health-derived data?", isPresented: $showDeleteDerivedConfirmation) {
            Button("Delete", role: .destructive) {
                store.deleteDemoHealthDerivedData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This keeps account data but clears derived signal outputs. You can resync to rebuild.")
        }
        .sheet(item: $selectedRemediationGuide) { guide in
            SettingsPermissionRemediationSheet(guide: guide)
        }
    }

    @ViewBuilder
    private func permissionRow(_ permission: DemoHealthPermissionStatus) -> some View {
        if let remediationGuide = permission.remediationGuide {
            Button {
                selectedRemediationGuide = remediationGuide
            } label: {
                permissionRowContent(permission, showsDisclosure: true)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens setup steps")
        } else {
            permissionRowContent(permission, showsDisclosure: false)
        }
    }

    private func permissionRowContent(_ permission: DemoHealthPermissionStatus, showsDisclosure: Bool) -> some View {
        HStack(spacing: MindSenseSpacing.sm) {
            Image(systemName: permission.state.statusIcon)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(permissionTint(for: permission.state))
            VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
                Text(permission.signal.title)
                    .font(MindSenseTypography.bodyStrong)
                Text(permission.state.title)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                if let statusDetail = permission.statusDetail {
                    Text(statusDetail)
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, MindSenseSpacing.xxxs)
    }

    private func permissionTint(for state: DemoHealthPermissionState) -> Color {
        switch state {
        case .granted:
            return MindSensePalette.success
        case .missing:
            return MindSensePalette.warning
        case .unsupported:
            return MindSensePalette.critical
        }
    }

    private func qualityTint(score: Int) -> Color {
        if score >= 82 {
            return MindSensePalette.success
        }
        if score >= 62 {
            return MindSensePalette.accent
        }
        return MindSensePalette.warning
    }
}

private struct SettingsPermissionRemediationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let guide: DemoHealthPermissionRemediationGuide

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MindSenseSpacing.md) {
                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: guide.title,
                                subtitle: "How to enable"
                            )
                        )
                        Text(guide.summary)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Checklist",
                                subtitle: "Complete each step in order."
                            )
                        )
                        ForEach(Array(guide.checklist.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .top, spacing: MindSenseSpacing.xs) {
                                Text("\(index + 1).")
                                    .font(MindSenseTypography.bodyStrong)
                                    .foregroundStyle(.secondary)
                                Text(item)
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                        }
                    }

                    InsetSurface {
                        Text(guide.expectedTimeToPopulate)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(MindSensePalette.accent)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(guide.modelUsageNote)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("How to enable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "How to enable")
                }
            }
        }
        .mindSenseSheetPresentationChrome()
    }
}
