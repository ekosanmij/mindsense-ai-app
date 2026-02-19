import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

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

    @State private var screenState: ScreenMode = .ready
    @State private var autosaveNotice = ""
    @State private var didAppear = false

    private let settingsRowMinHeight: CGFloat = 50
    private let settingsToggleRowMinHeight: CGFloat = 56
    private let settingsIconSize: CGFloat = 16

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
            store.triggerHaptic(intent: .selection)
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
    }

    private var settingsList: some View {
        List {
            profileSection
                .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)
            accountSection
                .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)
            healthDataSection
                .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)
            notificationSection
                .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)
            appearanceSection
                .mindSenseStaggerEntrance(4, isPresented: didAppear, reduceMotion: reduceMotion)
            safetySection
                .mindSenseStaggerEntrance(5, isPresented: didAppear, reduceMotion: reduceMotion)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var profileSection: some View {
        Section {
            VStack(alignment: .leading, spacing: MindSenseSpacing.sm) {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(MindSensePalette.signalCoolStrong)
                    Text(store.userDisplayName)
                        .font(MindSenseTypography.bodyStrong)
                        .foregroundStyle(.primary)
                    Spacer()
                }

                Text(
                    autosaveNotice.isEmpty
                        ? "Preferences save automatically."
                        : autosaveNotice
                )
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                Button {
                    store.showBanner(
                        title: "Recommended next step",
                        detail: "Review notification settings for quiet hours and stress nudges.",
                        severity: .info
                    )
                    store.triggerHaptic(intent: .selection)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(MindSensePalette.signalCoolStrong)
                            .frame(width: 20)
                        Text("Recommended: Review notifications")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 40)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)
            .listRowInsets(settingsRowInsets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } header: {
            settingsSectionHeader("Profile", icon: "person.crop.circle")
        }
    }

    private var accountSection: some View {
        Section {
            settingsRow(
                title: "Sign out",
                icon: "rectangle.portrait.and.arrow.right",
                tint: MindSensePalette.critical
            ) {
                store.signOut()
            }
            .listRowInsets(settingsRowInsets)
            .listRowBackground(Color.clear)
        } header: {
            settingsSectionHeader("Account and access", icon: "person.badge.key")
        }
    }

    private var healthDataSection: some View {
        Section {
            NavigationLink {
                AppleHealthPermissionsView()
            } label: {
                settingsRowLabel(title: "Apple Health permissions", icon: "waveform.path.ecg")
            }
            .buttonStyle(.plain)
            .listRowInsets(settingsRowInsets)
            .listRowBackground(Color.clear)

            settingsRow(title: "Data export and delete", icon: "tray.and.arrow.down") {
                store.showBanner(title: "Data controls", detail: "Export and delete workflows can be connected here.", severity: .info)
            }
            .listRowInsets(settingsRowInsets)
            .listRowBackground(Color.clear)

            settingsRow(title: "Privacy policy", icon: "lock.shield") {
                if let url = URL(string: "https://example.com/privacy") {
                    openURL(url)
                }
            }
            .listRowInsets(settingsRowInsets)
            .listRowBackground(Color.clear)
        } header: {
            settingsSectionHeader("Health and data", icon: "heart.text.square")
        }
    }

    private var notificationSection: some View {
        Section {
            settingsToggleRow(title: "Gentle nudges", subtitle: "Low-friction nudges before likely high-load windows.", isOn: $gentlePrompts)
                .listRowInsets(settingsRowInsets)
                .listRowBackground(Color.clear)
            settingsToggleRow(title: "Weekly review", subtitle: "Prompt to review trend and experiment quality.", isOn: $weeklyReview)
                .listRowInsets(settingsRowInsets)
                .listRowBackground(Color.clear)
            settingsToggleRow(title: "Smart stress nudge", subtitle: "Offer a 3-minute downshift when a stress episode is detected.", isOn: $stressNudge)
                .listRowInsets(settingsRowInsets)
                .listRowBackground(Color.clear)
            settingsToggleRow(title: "Recovery window", subtitle: "Notify when physiology stabilizes for a deep-work window.", isOn: $recoveryWindow)
                .listRowInsets(settingsRowInsets)
                .listRowBackground(Color.clear)
            settingsToggleRow(
                title: "Quiet hours",
                subtitle: "Pause nudges during your protected time window.",
                isOn: $quietHoursEnabled
            )
            .listRowInsets(settingsRowInsets)
            .listRowBackground(Color.clear)

            if quietHoursEnabled {
                quietHoursRow
                    .listRowInsets(settingsRowInsets)
                    .listRowBackground(Color.clear)
            }
        } header: {
            settingsSectionHeader("Notifications", icon: "bell.badge")
        }
    }

    private var quietHoursRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active \(quietHoursLabel)")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                quietTimePicker(title: "Start", selection: quietStartBinding)
                quietTimePicker(title: "End", selection: quietEndBinding)
            }
        }
        .padding(.vertical, 4)
    }

    private var appearanceSection: some View {
        Section {
            MindSenseSegmentedControl(
                options: AppearanceMode.allCases,
                selection: appearanceBinding,
                title: { $0.title }
            )
            .listRowInsets(settingsRowInsets)
            .listRowBackground(Color.clear)

            settingsToggleRow(title: "Reduce motion", subtitle: "Lower animation amplitude throughout the app.", isOn: $appReduceMotion)
                .listRowInsets(settingsRowInsets)
                .listRowBackground(Color.clear)
            settingsToggleRow(title: "Haptics", subtitle: "Tactile confirmation for key actions and completions.", isOn: $enableHaptics)
                .listRowInsets(settingsRowInsets)
                .listRowBackground(Color.clear)
        } header: {
            settingsSectionHeader("Appearance and motion", icon: "paintbrush")
        }
    }

    private var safetySection: some View {
        Section {
            settingsRow(title: "Crisis resources (US 988)", icon: "phone.fill", haptic: .warning) {
                if let tel = URL(string: "tel://988") {
                    openURL(tel)
                }
            }
            .listRowInsets(settingsRowInsets)
            .listRowBackground(Color.clear)
            .tint(MindSensePalette.warning)

            settingsRow(title: "Safety guidelines", icon: "exclamationmark.shield") {
                store.showBanner(title: "Safety guidelines", detail: "Use support channels and personal boundaries that keep you safe.", severity: .info)
            }
            .listRowInsets(settingsRowInsets)
            .listRowBackground(Color.clear)

            Text("MindSense provides wellness support and does not replace emergency services.")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .listRowInsets(settingsRowInsets)
                .listRowBackground(Color.clear)
        } header: {
            settingsSectionHeader("Safety", icon: "cross.case")
        }
    }

    private var settingsRowInsets: EdgeInsets {
        EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
    }

    private func settingsSectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            MindSenseIconBadge(
                systemName: icon,
                tint: MindSensePalette.signalCoolStrong,
                style: .muted,
                size: 20
            )
            Text(title.uppercased())
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.85)
        }
        .padding(.bottom, 2)
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
        action: @escaping () -> Void
    ) -> some View {
        Button {
            store.triggerHaptic(intent: haptic)
            action()
        } label: {
            settingsRowLabel(title: title, icon: icon, tint: tint)
        }
        .buttonStyle(.plain)
    }

    private func settingsRowLabel(
        title: String,
        icon: String,
        tint: Color = MindSensePalette.accent
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: settingsIconSize, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .frame(width: 20)
            Text(title)
                .font(MindSenseTypography.bodyStrong)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: settingsRowMinHeight)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private func settingsToggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(MindSenseTypography.bodyStrong)
                Text(subtitle)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func quietTimePicker(title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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

private struct AppleHealthPermissionsView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.openURL) private var openURL
    @State private var showDeleteDerivedConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MindSenseCommandDeck(
                    label: "Apple Health",
                    title: "Permissions and sync diagnostics",
                    detail: "Review connection, imports, and data quality from Apple Health.",
                    metric: store.healthSourceStatusLine
                )

                InsetSurface {
                    MindSenseSectionHeader(
                        model: .init(
                            title: store.demoHealthProfile.isConnected ? "Connected" : "Not connected",
                            subtitle: "Last sync \(store.healthLastSyncRelativeLabel)"
                        )
                    )

                    HStack(spacing: 10) {
                        MindSenseIconBadge(
                            systemName: "waveform.path.ecg",
                            tint: qualityTint(score: store.healthDataQualityScore),
                            style: .filled,
                            size: 34
                        )
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Data quality \(store.healthDataQualityScore)")
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
                        HStack(spacing: 10) {
                            Image(systemName: permission.state.statusIcon)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(permissionTint(for: permission.state))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(permission.signal.title)
                                    .font(MindSenseTypography.bodyStrong)
                                Text(permission.state.title)
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }

                InsetSurface {
                    MindSenseSectionHeader(
                        model: .init(
                            title: "Data quality diagnostics",
                            subtitle: "Coverage by signal category."
                        )
                    )
                    ForEach(store.healthQualityDiagnostics, id: \.0) { diagnostic in
                        VStack(alignment: .leading, spacing: 4) {
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
