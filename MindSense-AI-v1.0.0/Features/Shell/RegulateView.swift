import SwiftUI
import Combine
import AVFoundation

struct RegulateView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.mindSenseTabBarOverlayClearance) private var tabBarOverlayClearance
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    @State private var selectedPresetID: RegulatePresetID?
    @State private var checkInRating: SessionCheckInRating?
    @State private var selectedOutcomeTag: String?
    @State private var outcomeNote = ""
    @State private var hapticPacingEnabled = true
    @State private var audioGuidanceEnabled = false
    @State private var didAppear = false
    @State private var now = Date()
    @State private var showRecordImpactDetails = false
    @State private var showRunFocusDetails = false
    @State private var showPredictedFitExplanation = false
    @State private var showFlowStateExplanation = false
    @State private var selectedPresetDetails: DemoRegulatePreset?
    @State private var lastGuidedPhaseID: Int?
    @State private var viewSafeAreaBottomInset: CGFloat = 0
    @StateObject private var audioCoach = RegulateAudioCoach()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private enum RegulateStep: Int, CaseIterable, Identifiable {
        case selectProtocol
        case runTimer
        case recordImpact

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .selectProtocol:
                return "Select"
            case .runTimer:
                return "Run"
            case .recordImpact:
                return "Record"
            }
        }

        var fullTitle: String {
            switch self {
            case .selectProtocol:
                return "Select protocol"
            case .runTimer:
                return "Run timer"
            case .recordImpact:
                return "Record impact"
            }
        }
    }

    private struct TimerProtocolPhase: Identifiable {
        let id: Int
        let title: String
        let startSecond: Int
        let endSecond: Int

        var minuteRangeLabel: String {
            if startSecond % 60 != 0 || endSecond % 60 != 0 {
                return "\(clockLabel(for: startSecond))-\(clockLabel(for: endSecond))"
            }
            let startMinute = (startSecond / 60) + 1
            let endMinute = max(startMinute, Int(ceil(Double(endSecond) / 60.0)))
            if startMinute == endMinute {
                return "Minute \(startMinute)"
            }
            return "Minutes \(startMinute)-\(endMinute)"
        }

        private func clockLabel(for seconds: Int) -> String {
            let minutes = seconds / 60
            let remainder = seconds % 60
            return String(format: "%d:%02d", minutes, remainder)
        }
    }

    private var presets: [DemoRegulatePreset] {
        store.rankedRegulatePresetCatalog
    }

    private var activePreset: DemoRegulatePreset? {
        presets.first(where: { $0.id == selectedPresetID }) ?? presets.first
    }

    private var runningSessionPreset: DemoRegulatePreset? {
        guard let session = store.activeRegulateSession else { return nil }
        return presets.first(where: { $0.id == session.preset }) ?? store.presetDefinition(for: session.preset)
    }

    private var currentStep: RegulateStep {
        guard let session = store.activeRegulateSession else { return .selectProtocol }
        switch session.state {
        case .inProgress:
            return .runTimer
        case .awaitingCheckIn:
            return .recordImpact
        case .completed, .cancelled:
            return .selectProtocol
        }
    }

    private var resolvedState: ScreenMode {
        store.screenMode(for: .regulate)
    }

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    private var sessionProgress: Double {
        guard let session = store.activeRegulateSession else { return 0 }
        let elapsed = Double(store.activeSessionElapsedSeconds(now: now))
        let duration = Double(max(session.plannedDurationSeconds, 1))
        return min(1, elapsed / duration)
    }

    private var remainingLabel: String {
        let remaining = store.activeSessionRemainingSeconds(now: now)
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var outcomeTagOptions: [String] {
        ["Stress load", "Focus drift", "Physical strain", "Sleep debt", "Social load"]
    }

    private var selectedCheckInRating: SessionCheckInRating {
        checkInRating ?? .noRating
    }

    private var outcomeDirection: SessionImpactDirection {
        switch selectedCheckInRating {
        case .helped:
            return .better
        case .didNotHelp:
            return .worse
        case .mixed, .noRating:
            return .same
        }
    }

    private var outcomeIntensity: Int {
        switch selectedCheckInRating {
        case .helped:
            return 4
        case .didNotHelp:
            return 3
        case .mixed:
            return 3
        case .noRating:
            return 1
        }
    }

    private var outcomeFeeling: Int {
        switch selectedCheckInRating {
        case .helped:
            return 4
        case .didNotHelp:
            return 2
        case .mixed, .noRating:
            return 3
        }
    }

    private var outcomeHelpfulness: SessionHelpfulness {
        switch selectedCheckInRating {
        case .helped:
            return .yes
        case .didNotHelp:
            return .no
        case .mixed, .noRating:
            return .some
        }
    }

    private var predictedEffectMetrics: RegulateEffectMetrics? {
        guard let preset = runningSessionPreset?.id ?? activePreset?.id else { return nil }
        return store.previewSessionEffectMetrics(
            preset: preset,
            direction: outcomeDirection,
            intensity: outcomeIntensity
        )
    }

    private var primaryCTAConfig: (label: String, id: String, action: () -> Void, disabled: Bool)? {
        guard let session = store.activeRegulateSession else { return nil }

        switch session.state {
        case .inProgress:
            return nil
        case .awaitingCheckIn:
            return (
                label: "Save check-in",
                id: "regulate_outcome_submit_cta",
                action: submitOutcome,
                disabled: checkInRating == nil
            )
        case .completed, .cancelled:
            return nil
        }
    }

    private var bottomContentPadding: CGFloat {
        MindSenseLayout.pageBottom + MindSenseLayout.tabBarClearance(
            measuredOverlay: tabBarOverlayClearance,
            tier: .standard
        )
    }

    private var stickyDockBottomOffset: CGFloat {
        MindSenseLayout.bottomDockOffset(
            measuredOverlay: tabBarOverlayClearance,
            safeAreaInset: viewSafeAreaBottomInset
        )
    }

    private var tabBarCollapseScrollRunway: CGFloat {
        return 180
    }

    private var hasAnyRegulateHistory: Bool {
        !store.regulateSessionHistory.isEmpty
    }

    private var shouldShowExpandedCommandDeck: Bool {
        switch currentStep {
        case .selectProtocol:
            return !hasAnyRegulateHistory
        case .runTimer:
            return false
        case .recordImpact:
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                ScreenStateContainer(state: resolvedState, retryAction: { store.retryCoreScreen(.regulate) }) {
                    VStack(spacing: MindSenseRhythm.section) {
                        if shouldShowExpandedCommandDeck {
                            commandDeck
                                .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)
                        }
                        if currentStep == .recordImpact {
                            sessionStatusBlock
                                .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)
                        }
                        activeStepBlock
                            .mindSenseStaggerEntrance(
                                currentStep == .recordImpact ? 2 : 1,
                                isPresented: didAppear,
                                reduceMotion: reduceMotion
                            )
                        // Keep a short scroll runway so tab-bar minimize can trigger on shorter layouts.
                        Color.clear
                            .frame(height: tabBarCollapseScrollRunway)
                            .accessibilityHidden(true)
                    }
                    .mindSensePageInsets(bottom: bottomContentPadding)
                }
            }
            .refreshable {
                store.retryCoreScreen(.regulate)
                store.resyncDemoHealthData(surface: .regulate, source: "pull_to_refresh")
                store.triggerHaptic(intent: .success)
            }
            .mindSensePageBackground()
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            viewSafeAreaBottomInset = proxy.safeAreaInsets.bottom
                        }
                        .onChange(of: proxy.safeAreaInsets.bottom) { _, newValue in
                            viewSafeAreaBottomInset = newValue
                        }
                }
            }
            .navigationTitle(AppIA.regulate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: AppIA.regulate)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileAccessMenu()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if case .ready = resolvedState, let primaryCTAConfig {
                    MindSenseDoItNowDock(
                        subtitle: "Finish the session loop by saving impact."
                    ) {
                        Button(primaryCTAConfig.label) {
                            guard !primaryCTAConfig.disabled else { return }
                            store.triggerHaptic(intent: .primary)
                            primaryCTAConfig.action()
                        }
                        .accessibilityIdentifier(primaryCTAConfig.id)
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: MindSenseControlSize.primaryButton))
                        .disabled(primaryCTAConfig.disabled)
                    }
                    .padding(.bottom, stickyDockBottomOffset)
                }
            }
            .sheet(isPresented: $store.shouldPresentPostActivationPaywall) {
                PostActivationPaywallSheet(
                    onMaybeLater: {
                        store.triggerHaptic(intent: .selection)
                        store.dismissPostActivationPaywall(accepted: false)
                    },
                    onStartTrial: {
                        store.triggerHaptic(intent: .primary)
                        store.dismissPostActivationPaywall(accepted: true)
                    }
                )
            }
            .sheet(item: $selectedPresetDetails) { preset in
                RegulatePresetDetailSheet(preset: preset)
            }
            .alert("Predicted fit", isPresented: $showPredictedFitExplanation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This score estimates how likely a protocol is to help right now, using your recent signals, data coverage, and outcomes from similar sessions.")
            }
            .onAppear {
                let firstAppearance = !didAppear
                if firstAppearance {
                    didAppear = true
                }
                if selectedPresetID == nil {
                    selectedPresetID = presets.first?.id
                }
                consumeLaunchRequestIfNeeded()
                store.prepareCoreScreen(.regulate)
                if firstAppearance {
                    store.track(event: .screenView, surface: .regulate)
                }
            }
            .onReceive(timer) { date in
                handleTimerTick(date)
            }
            .onChange(of: store.regulateLaunchRequest) { _, _ in
                consumeLaunchRequestIfNeeded()
            }
            .onChange(of: currentStep) { _, step in
                if step == .runTimer {
                    showRunFocusDetails = false
                    lastGuidedPhaseID = nil
                    announceCurrentProtocolPhase(force: true)
                } else {
                    showRunFocusDetails = false
                    lastGuidedPhaseID = nil
                    audioCoach.stop()
                }
            }
            .onChange(of: audioGuidanceEnabled) { _, enabled in
                if enabled {
                    announceCurrentProtocolPhase(force: true)
                } else {
                    audioCoach.stop()
                }
            }
            .onChange(of: store.demoScenario) { _, _ in
                selectedPresetID = presets.first?.id
                store.prepareCoreScreen(.regulate)
            }
            .onChange(of: store.intentMode) { _, _ in
                guard store.activeRegulateSession == nil else { return }
                selectedPresetID = presets.first?.id
                store.prepareCoreScreen(.regulate)
            }
            .onDisappear {
                audioCoach.stop()
            }
        }
    }

    private var commandDeck: some View {
        MindSenseTabHero(
            label: AppIA.regulate,
            title: currentStep.fullTitle,
            detail: commandDetail,
            metric: commandMetric,
            icon: "waveform.path.ecg",
            tone: .accent,
            watermarkTint: MindSensePalette.accent
        ) {
            HStack(spacing: MindSenseSpacing.xs) {
                PillChip(label: store.intentMode.shortTitle, state: .selected)
                PillChip(label: flowLabel, state: .unselected)
            }

            MindSenseSummaryDisclosureText(
                summary: "This is the action step in the daily loop: run one protocol, then rate impact.",
                detail: "MindSense is optimizing for \(store.intentMode.shortTitle.lowercased()) today. Select one protocol, run the timer, then rate impact so future recommendations improve.",
                collapsedLabel: "How this flow works",
                expandedLabel: "Hide flow details"
            )
        }
    }

    private var commandDetail: String {
        switch currentStep {
        case .selectProtocol:
            return "Choose one protocol matched to today's goal."
        case .runTimer:
            return "Run the protocol to complete today's action step."
        case .recordImpact:
            return "Rate impact to close the loop and improve future recommendations."
        }
    }

    private var commandMetric: String {
        if currentStep == .runTimer {
            return remainingLabel
        }
        return flowLabel
    }

    private var sessionStatusBlock: some View {
        InsetSurface {
            MindSenseCollapsibleSection(
                model: .init(
                    title: "Session status",
                    subtitle: "Live state from your current regulate flow.",
                    icon: "heart.text.square"
                ),
                storageKey: "ui.collapse.regulate.session_status",
                collapsedSummary: sessionStatusCollapsedSummary
            ) {
                HStack(alignment: .top, spacing: MindSenseSpacing.xs) {
                    Text("Load \(store.demoMetrics.load)  •  Readiness \(store.demoMetrics.readiness)  •  \(flowLabel)")
                        .font(MindSenseTypography.body)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    Button {
                        showFlowStateExplanation = true
                        store.triggerHaptic(intent: .selection)
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Flow state definitions")
                    .accessibilityHint("Shows what Flow ready and Flow running mean.")
                    .accessibilityIdentifier("regulate_flow_state_info")
                    .alert("Flow states", isPresented: $showFlowStateExplanation) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Flow ready: conditions suggest the selected protocol is a good fit right now\n\nFlow running: you're in a session")
                    }
                }

                if let runningSessionPreset {
                    Text("Active protocol: \(runningSessionPreset.title) • \(runningSessionPreset.durationLabel)")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No active session.")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                }

                if let latestEffect = store.latestSessionEffectLine {
                    Text("Last measured effect: \(latestEffect)")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private var activeStepBlock: some View {
        switch currentStep {
        case .selectProtocol:
            selectProtocolStep
        case .runTimer:
            if let runningPreset = runningSessionPreset {
                runTimerStep(runningPreset)
            }
        case .recordImpact:
            if let runningPreset = runningSessionPreset {
                recordImpactStep(runningPreset)
            }
        }
    }

    private var selectProtocolStep: some View {
        FocusSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Choose protocol",
                    subtitle: "Pick one protocol, then start it from this section. Ranking is tuned for your \(store.intentMode.shortTitle.lowercased()) goal today.",
                    icon: "list.bullet.rectangle"
                )
            )

            if runningSessionPreset == nil {
                Label("No active session. Choose one protocol to start.", systemImage: "circle.dotted")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(presets) { preset in
                let selected = preset.id == activePreset?.id
                VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                    Button {
                        selectedPresetID = preset.id
                        store.triggerHaptic(intent: .selection)
                        store.track(event: .secondaryActionTapped, surface: .regulate, action: "preset_selected_\(preset.id.rawValue)")
                    } label: {
                        HStack(spacing: MindSenseSpacing.sm) {
                            MindSenseIconBadge(
                                systemName: preset.icon,
                                tint: MindSensePalette.signalCool,
                                style: selected ? .filled : .muted,
                                size: MindSenseControlSize.iconBadgeXL
                            )
                            VStack(alignment: .leading, spacing: MindSenseSpacing.xxs) {
                                Text(preset.title)
                                    .font(MindSenseTypography.bodyStrong)
                                    .foregroundStyle(.primary)
                                Text(preset.subtitle)
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(preset.expectedEffect)
                                    .font(MindSenseTypography.caption)
                                    .lineLimit(2)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                HStack(spacing: MindSenseSpacing.xs) {
                                    selectionMetaPill(
                                        icon: "waveform.path.ecg",
                                        text: "Predicted fit \(store.expectedEffectConfidence(for: preset.id))%",
                                        onTap: {
                                            showPredictedFitExplanation = true
                                            store.triggerHaptic(intent: .selection)
                                        }
                                    )
                                    selectionMetaPill(
                                        icon: "clock.fill",
                                        text: preset.durationLabel
                                    )
                                }
                            }
                            Spacer()
                            if selected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(MindSensePalette.accent)
                            }
                        }
                        .padding(.horizontal, MindSenseLayout.tileHorizontalInset)
                        .padding(.vertical, MindSenseLayout.tileVerticalInset)
                        .background(
                            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                                .fill(
                                    selected
                                        ? AnyShapeStyle(MindSensePalette.accentMuted.opacity(0.88))
                                        : AnyShapeStyle(MindSenseSurfaceLevel.base.fill)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                                .stroke(
                                    selected ? MindSensePalette.strokeEdge.opacity(0.82) : MindSensePalette.strokeSubtle,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(store.activeRegulateSession?.isInProgress == true)

                    if selected {
                        Button {
                            selectedPresetDetails = preset
                            store.track(
                                event: .secondaryActionTapped,
                                surface: .regulate,
                                action: "preset_details_opened",
                                metadata: ["preset": preset.id.rawValue]
                            )
                            store.triggerHaptic(intent: .selection)
                        } label: {
                            Label("Details", systemImage: "chevron.right")
                                .font(MindSenseTypography.caption)
                        }
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                        .accessibilityIdentifier("regulate_preset_details_\(preset.id.rawValue)")
                    }
                }
            }

            Text("Tap predicted fit to see what it means.")
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let activePreset {
                Button("Start \(activePreset.title) (\(activePreset.durationLabel))") {
                    store.triggerHaptic(intent: .primary)
                    startPreset(activePreset.id, source: "regulate_primary_cta")
                }
                .accessibilityIdentifier("regulate_start_cta")
                .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: MindSenseControlSize.primaryButton))
            }
        }
    }

    @ViewBuilder
    private func selectionMetaPill(icon: String, text: String, onTap: (() -> Void)? = nil) -> some View {
        if let onTap {
            Button(action: onTap) {
                selectionMetaPillContent(icon: icon, text: text)
            }
            .buttonStyle(.plain)
            .frame(minHeight: MindSenseControlSize.minimumTapTarget)
            .accessibilityLabel(text)
            .accessibilityHint("Shows explanation.")
        } else {
            selectionMetaPillContent(icon: icon, text: text)
        }
    }

    private func selectionMetaPillContent(icon: String, text: String) -> some View {
        HStack(spacing: MindSenseSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
            Text(text)
                .font(MindSenseTypography.micro)
                .monospacedDigit()
        }
        .foregroundStyle(MindSensePalette.accent)
        .padding(.horizontal, MindSenseSpacing.xs)
        .frame(minHeight: MindSenseControlSize.compactPill)
        .background(
            Capsule(style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
    }

    private func runTimerStep(_ runningPreset: DemoRegulatePreset) -> some View {
        let protocolPhases = protocolTimeline(for: runningPreset)
        let activePhase = currentProtocolPhase(in: protocolPhases, preset: runningPreset)
        let elapsedSeconds = store.activeSessionElapsedSeconds(now: now)

        return FocusSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Run timer",
                    subtitle: "Stay with the timer to complete the session.",
                    icon: "timer"
                )
            )

            runStatusChip

            ZStack {
                Circle()
                    .stroke(timerRingTrackColor, lineWidth: timerRingLineWidth)

                Circle()
                    .trim(from: 0, to: max(0.03, sessionProgress))
                    .stroke(
                        timerRingProgressColor,
                        style: StrokeStyle(lineWidth: timerRingLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: MindSenseSpacing.xxs) {
                    Text(remainingLabel)
                        .font(MindSenseTypography.metricDisplay)
                        .minimumScaleFactor(0.75)
                        .monospacedDigit()
                        .accessibilityIdentifier("regulate_session_timer")
                    Text("remaining")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: runTimerDiameter, height: runTimerDiameter)
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                Text("Step schedule")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                if let activePhase {
                    runStepSummaryRow(
                        title: "Current",
                        detail: "\(activePhase.minuteRangeLabel): \(activePhase.title)",
                        emphasized: true
                    )
                        .accessibilityIdentifier("regulate_protocol_step_current")

                    if let nextPhase = protocolPhases.first(where: { $0.id == activePhase.id + 1 }) {
                        runStepSummaryRow(
                            title: "Up next",
                            detail: "\(nextPhase.minuteRangeLabel): \(nextPhase.title)",
                            emphasized: false
                        )
                    }
                }
            }

            DisclosureGroup(isExpanded: $showRunFocusDetails) {
                VStack(alignment: .leading, spacing: MindSenseSpacing.sm) {
                    Text(runMetaLine)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let latestEffect = store.latestSessionEffectLine {
                        Text("Last measured effect: \(latestEffect)")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text("Session: \(runningPreset.title)")
                        .font(MindSenseTypography.bodyStrong)

                    ProtocolTokenStripView(
                        what: runningPreset.title,
                        why: runningPreset.whyNow,
                        expectedEffect: runningPreset.expectedEffect,
                        time: runningPreset.durationLabel,
                        maxValueLines: 2
                    )

                    VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                        Text("Why this works")
                            .font(MindSenseTypography.bodyStrong)
                        Text(runningPreset.whyNow)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Expected effect: \(runningPreset.expectedEffect)")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("What to think: \(store.todayCognitivePrompt)")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text("Full step schedule")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                        ForEach(protocolPhases) { phase in
                            let phaseStatus = protocolPhaseStatus(
                                phase,
                                activePhaseID: activePhase?.id,
                                elapsedSeconds: elapsedSeconds
                            )

                            HStack(spacing: MindSenseSpacing.xs) {
                                Image(systemName: phaseStatus.symbol)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(phaseStatus.tint)
                                Text("\(phase.minuteRangeLabel): \(phase.title)")
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(phaseStatus.tint)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, minHeight: MindSenseControlSize.minimumTapTarget, alignment: .leading)
                            .padding(.horizontal, MindSenseSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                                    .fill(MindSenseSurfaceLevel.base.fill)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                                    .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
                            )
                        }
                    }

                    Toggle("Haptic step cues", isOn: $hapticPacingEnabled)
                        .font(MindSenseTypography.caption)
                        .tint(MindSensePalette.accent)
                        .frame(minHeight: MindSenseControlSize.minimumTapTarget)
                        .accessibilityIdentifier("regulate_haptic_pacing_toggle")

                    Toggle("Audio guidance", isOn: $audioGuidanceEnabled)
                        .font(MindSenseTypography.caption)
                        .tint(MindSensePalette.accent)
                        .frame(minHeight: MindSenseControlSize.minimumTapTarget)
                        .accessibilityIdentifier("regulate_audio_guidance_toggle")

                    Text("Cues trigger when the protocol moves to the next step.")
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: MindSenseSpacing.xs) {
                        MindSenseIconBadge(
                            systemName: "heart.text.square",
                            tint: MindSensePalette.signalCool,
                            style: .filled,
                            size: MindSenseControlSize.iconBadge
                        )
                        Text("Calming trend: \(calmingTrendLabel)")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 6)
            } label: {
                Text("Details")
                    .font(MindSenseTypography.bodyStrong)
            }

            Button("Cancel session") {
                store.cancelRegulateSession(reason: "user_cancelled")
                store.triggerHaptic(intent: .warning)
            }
            .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary, fullWidth: false))
        }
    }

    private func recordImpactStep(_ runningPreset: DemoRegulatePreset) -> some View {
        FocusSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Record impact",
                    subtitle: "Save immediate impact.",
                    icon: "checkmark.seal"
                )
            )

            Text("Session: \(runningPreset.title)")
                .font(MindSenseTypography.bodyStrong)
                .accessibilityIdentifier("regulate_active_preset_label")

            recordImpactForm(runningPreset)
        }
    }

    @ViewBuilder
    private func recordImpactForm(_ runningPreset: DemoRegulatePreset) -> some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
            HStack(spacing: MindSenseSpacing.xs) {
                MindSenseIconBadge(
                    systemName: "waveform.path.ecg",
                    tint: impactTint,
                    style: .filled,
                    size: MindSenseControlSize.iconBadge
                )
                Text("Current impact selection: \(impactStateLine)")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Helped?")
                .font(MindSenseTypography.bodyStrong)

            HStack(spacing: MindSenseSpacing.xs) {
                outcomeRatingButton(
                    .helped,
                    title: "Yes",
                    systemImage: "hand.thumbsup.fill",
                    accessibilityID: "regulate_helped_yes"
                )
                outcomeRatingButton(
                    .didNotHelp,
                    title: "No",
                    systemImage: "hand.thumbsdown.fill",
                    accessibilityID: "regulate_helped_no"
                )
                outcomeRatingButton(
                    .mixed,
                    title: "Mixed",
                    systemImage: "equal.circle.fill",
                    accessibilityID: "regulate_helped_mixed"
                )
            }
        }

        VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
            Text("Optional tag")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)

            let columns = [GridItem(.adaptive(minimum: 118), spacing: MindSenseSpacing.xs)]
            LazyVGrid(columns: columns, alignment: .leading, spacing: MindSenseSpacing.xs) {
                ForEach(outcomeTagOptions, id: \.self) { tag in
                    outcomeTagButton(tag)
                }
            }

            TextField("Optional note (what changed?)", text: $outcomeNote, axis: .vertical)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .padding(.horizontal, MindSenseSpacing.sm)
                .frame(minHeight: MindSenseControlSize.minimumTapTarget)
                .background(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                        .fill(MindSenseSurfaceLevel.base.fill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                        .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
                )
                .accessibilityIdentifier("regulate_outcome_note_input")
        }

        if let metrics = predictedEffectMetrics {
            InsetSurface {
                MindSenseSectionHeader(
                    model: .init(
                        title: "Measured effect",
                        subtitle: metrics.quality == .live ? "Live watch-quality estimate" : "Estimated from nearest samples",
                        icon: "waveform.path.ecg"
                    )
                )

                recordImpactDetailRow(label: "HR downshift", value: heartShiftLine(for: metrics))
                recordImpactDetailRow(label: "HRV shift", value: hrvShiftLine(for: metrics))
                recordImpactDetailRow(label: "Recovery slope", value: metrics.recoverySlope.title.capitalized)
            }
        }

        MindSenseSummaryDisclosureText(
            summary: "Pick Yes, No, or Mixed to save.",
            detail: "Pick Yes, No, or Mixed to save, or skip to log No rating with reduced learning weight.",
            collapsedLabel: "How ratings are saved",
            expandedLabel: "Hide save details"
        )

        HStack {
            Spacer()
            Button("Skip rating") {
                submitNoRatingOutcome()
            }
            .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
            .accessibilityIdentifier("regulate_outcome_skip_cta")
        }

        DisclosureGroup(isExpanded: $showRecordImpactDetails) {
            VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                recordImpactDetailRow(label: "What", value: "Capture immediate outcome")
                recordImpactDetailRow(label: "Why", value: runningPreset.whyNow)
                recordImpactDetailRow(label: "Expected effect", value: "Used to tune protocol ranking and confidence.")
                recordImpactDetailRow(label: "Time", value: "Under 30 sec")
                recordImpactDetailRow(label: "What to think", value: store.todayCognitivePrompt)
                Text("Protocol")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .tracking(0.7)
                ForEach(runningPreset.protocolSteps, id: \.self) { step in
                    Text("• \(step)")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 6)
        } label: {
            Text("Details")
                .font(MindSenseTypography.bodyStrong)
        }
    }

    private func recordImpactDetailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
            Text(label)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.7)
            Text(value)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func outcomeRatingButton(
        _ rating: SessionCheckInRating,
        title: String,
        systemImage: String,
        accessibilityID: String
    ) -> some View {
        let selected = checkInRating == rating
        return Button {
            checkInRating = rating
            if rating == .mixed {
                store.track(event: .secondaryActionTapped, surface: .regulate, action: "rating_mixed_selected")
            }
            store.triggerHaptic(intent: .selection)
        } label: {
            Label(title, systemImage: systemImage)
                .font(MindSenseTypography.bodyStrong)
                .foregroundStyle(selected ? MindSensePalette.signalCoolStrong : .secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(minHeight: MindSenseControlSize.minimumTapTarget)
                .background(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                        .fill(selected ? MindSensePalette.accentMuted : MindSenseSurfaceLevel.base.fill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                        .stroke(selected ? MindSensePalette.strokeEdge : MindSensePalette.strokeSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityID)
    }

    private func outcomeTagButton(_ tag: String) -> some View {
        let isSelected = selectedOutcomeTag == tag
        return Button {
            selectedOutcomeTag = isSelected ? nil : tag
            store.triggerHaptic(intent: .selection)
        } label: {
            PillChip(label: tag, state: isSelected ? .selected : .unselected)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: MindSenseControlSize.minimumTapTarget)
        }
        .buttonStyle(.plain)
    }

    private var sessionStatusCollapsedSummary: String {
        if let runningSessionPreset {
            return "\(flowLabel) • \(runningSessionPreset.title) • \(remainingLabel)"
        }
        return "Load \(store.demoMetrics.load) • Readiness \(store.demoMetrics.readiness) • \(flowLabel)"
    }

    private var flowLabel: String {
        switch currentStep {
        case .selectProtocol:
            return "Flow ready"
        case .runTimer:
            return "Flow running"
        case .recordImpact:
            return "Flow check-in"
        }
    }

    private var runMetaLine: String {
        "Load \(store.demoMetrics.load) • Readiness \(store.demoMetrics.readiness) • \(flowLabel)"
    }

    private var timerRingLineWidth: CGFloat {
        colorSchemeContrast == .increased ? 18 : 14
    }

    private var runTimerDiameter: CGFloat {
        if dynamicTypeSize.isAccessibilitySize {
            return 152
        }
        if dynamicTypeSize >= .xxxLarge {
            return 168
        }
        return 180
    }

    private var timerRingTrackColor: Color {
        colorSchemeContrast == .increased
            ? MindSensePalette.strokeStrong
            : MindSenseSurfaceLevel.base.fill
    }

    private var timerRingProgressColor: Color {
        colorSchemeContrast == .increased
            ? MindSensePalette.accentStrong
            : MindSensePalette.signalCoolStrong
    }

    private var runStatusChip: some View {
        Label("Flow running", systemImage: "waveform.path.ecg")
            .font(MindSenseTypography.micro)
            .foregroundStyle(MindSensePalette.accentStrong)
            .padding(.horizontal, MindSenseSpacing.sm)
            .frame(minHeight: MindSenseSpacing.xl)
            .background(
                Capsule(style: .continuous)
                    .fill(MindSensePalette.accentMuted)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(MindSensePalette.strokeEdge, lineWidth: 1)
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("regulate_run_status_chip")
    }

    private func runStepSummaryRow(title: String, detail: String, emphasized: Bool) -> some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
            Text(title)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.7)
            Text(detail)
                .font(emphasized ? MindSenseTypography.bodyStrong : MindSenseTypography.caption)
                .foregroundStyle(emphasized ? .primary : .secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: MindSenseControlSize.minimumTapTarget, alignment: .leading)
    }

    private func protocolTimeline(for preset: DemoRegulatePreset) -> [TimerProtocolPhase] {
        let rawSteps: [String]
        if preset.protocolSteps.isEmpty {
            rawSteps = ["\(preset.durationMinutes)m guided protocol"]
        } else {
            rawSteps = preset.protocolSteps
        }

        let parsedDurations = rawSteps.map(stepDurationSeconds(from:))
        let knownDuration = parsedDurations.compactMap { $0 }.reduce(0, +)
        let unknownIndexes = parsedDurations.indices.filter { parsedDurations[$0] == nil }
        let remainingDuration = max(preset.durationSeconds - knownDuration, 0)

        let fallbackSeconds = unknownIndexes.isEmpty ? 0 : (remainingDuration / unknownIndexes.count)
        var fallbackRemainder = unknownIndexes.isEmpty ? 0 : (remainingDuration % unknownIndexes.count)
        var durations = Array(repeating: 1, count: rawSteps.count)

        for index in rawSteps.indices {
            if let parsed = parsedDurations[index] {
                durations[index] = max(1, parsed)
            } else {
                let bonus = fallbackRemainder > 0 ? 1 : 0
                durations[index] = max(1, fallbackSeconds + bonus)
                if fallbackRemainder > 0 {
                    fallbackRemainder -= 1
                }
            }
        }

        let targetDuration = max(preset.durationSeconds, durations.count)
        let currentDuration = durations.reduce(0, +)
        if currentDuration < targetDuration {
            durations[durations.count - 1] += targetDuration - currentDuration
        } else if currentDuration > targetDuration {
            var overflow = currentDuration - targetDuration
            for index in durations.indices.reversed() {
                guard overflow > 0 else { break }
                let removable = durations[index] - 1
                guard removable > 0 else { continue }
                let adjustment = min(removable, overflow)
                durations[index] -= adjustment
                overflow -= adjustment
            }
        }

        var cursor = 0
        return rawSteps.enumerated().map { index, step in
            let end = cursor + durations[index]
            defer { cursor = end }
            return TimerProtocolPhase(
                id: index,
                title: protocolStepTitle(from: step),
                startSecond: cursor,
                endSecond: end
            )
        }
    }

    private func currentProtocolPhase(
        in phases: [TimerProtocolPhase],
        preset: DemoRegulatePreset
    ) -> TimerProtocolPhase? {
        guard !phases.isEmpty else { return nil }
        let maxElapsed = max(preset.durationSeconds - 1, 0)
        let elapsed = min(max(store.activeSessionElapsedSeconds(now: now), 0), maxElapsed)
        return phases.first(where: { elapsed >= $0.startSecond && elapsed < $0.endSecond }) ?? phases.last
    }

    private func protocolPhaseStatus(
        _ phase: TimerProtocolPhase,
        activePhaseID: Int?,
        elapsedSeconds: Int
    ) -> (symbol: String, tint: Color) {
        if elapsedSeconds >= phase.endSecond {
            return ("checkmark.circle.fill", MindSensePalette.success)
        }
        if phase.id == activePhaseID {
            return ("play.circle.fill", MindSensePalette.signalCoolStrong)
        }
        return ("circle", .secondary)
    }

    private func stepDurationSeconds(from step: String) -> Int? {
        let components = step
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(maxSplits: 1, whereSeparator: \.isWhitespace)
        guard let token = components.first else { return nil }
        return durationTokenToSeconds(String(token))
    }

    private func durationTokenToSeconds(_ token: String) -> Int? {
        let normalized = token
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,;:"))
        let minuteSuffixes = ["minutes", "minute", "mins", "min", "m"]
        for suffix in minuteSuffixes {
            guard normalized.hasSuffix(suffix) else { continue }
            guard let value = Int(normalized.dropLast(suffix.count)), value > 0 else { return nil }
            return value * 60
        }

        let secondSuffixes = ["seconds", "second", "secs", "sec", "s"]
        for suffix in secondSuffixes {
            guard normalized.hasSuffix(suffix) else { continue }
            guard let value = Int(normalized.dropLast(suffix.count)), value > 0 else { return nil }
            return value
        }
        return nil
    }

    private func protocolStepTitle(from step: String) -> String {
        let trimmed = step.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Guided step" }

        let parts = trimmed.split(maxSplits: 1, whereSeparator: \.isWhitespace)
        guard let token = parts.first else { return sentenceCase(trimmed) }
        if durationTokenToSeconds(String(token)) != nil, parts.count > 1 {
            return sentenceCase(String(parts[1]))
        }
        return sentenceCase(trimmed)
    }

    private func sentenceCase(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }

    private func handleTimerTick(_ date: Date) {
        now = date
        guard store.activeRegulateSession != nil else { return }

        if store.activeRegulateSession?.isInProgress == true {
            store.syncActiveRegulateSessionState(now: date)
            announceCurrentProtocolPhase()
        }
    }

    private func announceCurrentProtocolPhase(force: Bool = false) {
        guard currentStep == .runTimer, let preset = runningSessionPreset else { return }
        let phases = protocolTimeline(for: preset)
        guard let activePhase = currentProtocolPhase(in: phases, preset: preset) else { return }

        if !force, lastGuidedPhaseID == activePhase.id {
            return
        }

        let previousPhaseID = lastGuidedPhaseID
        lastGuidedPhaseID = activePhase.id

        if hapticPacingEnabled, previousPhaseID != activePhase.id {
            let isFinalPhase = activePhase.id == phases.last?.id
            store.triggerHaptic(intent: isFinalPhase ? .success : .selection)
        }

        if audioGuidanceEnabled {
            let instruction = "\(activePhase.minuteRangeLabel). \(activePhase.title)."
            audioCoach.speak(instruction)
        }
    }

    private func consumeLaunchRequestIfNeeded() {
        guard let request = store.consumeRegulateLaunchRequest() else { return }
        selectedPresetID = request.preset
        if request.startImmediately {
            startPreset(request.preset, source: request.source)
        }
    }

    private func startPreset(_ presetID: RegulatePresetID, source: String) {
        guard let preset = presets.first(where: { $0.id == presetID }) else { return }

        if let session = store.activeRegulateSession {
            if session.isInProgress || session.isAwaitingCheckIn {
                store.showActionFeedback(.updated, detail: "Finish or cancel the active session first.")
                store.triggerHaptic(intent: .warning)
                return
            }
        }

        selectedPresetID = presetID
        resetOutcomeDraft()
        lastGuidedPhaseID = nil
        audioCoach.stop()
        store.track(
            event: .primaryCTATapped,
            surface: .regulate,
            action: "start_\(presetID.rawValue)",
            metadata: ["source": source]
        )
        _ = store.beginRegulateSession(preset: presetID, source: source)
        store.showActionFeedback(.applied, detail: "\(preset.title) started.")
        store.triggerHaptic(intent: .success)
    }

    private func submitOutcome() {
        guard store.activeRegulateSession != nil else { return }
        guard checkInRating != nil else { return }
        store.recordRegulateOutcome(
            checkInRating: checkInRating,
            outcomeTag: selectedOutcomeTag,
            outcomeNote: outcomeNote
        )
        store.track(event: .actionCompleted, surface: .regulate, action: "post_session_check_in_saved")
        store.triggerHaptic(intent: .success)
        resetOutcomeDraft()
    }

    private func submitNoRatingOutcome() {
        guard store.activeRegulateSession != nil else { return }
        store.recordRegulateOutcome(
            checkInRating: .noRating,
            outcomeTag: selectedOutcomeTag,
            outcomeNote: outcomeNote
        )
        store.track(event: .actionCompleted, surface: .regulate, action: "post_session_check_in_skipped")
        store.triggerHaptic(intent: .selection)
        resetOutcomeDraft()
    }

    private func resetOutcomeDraft() {
        checkInRating = nil
        selectedOutcomeTag = nil
        outcomeNote = ""
        showRecordImpactDetails = false
    }

    private var impactTint: Color {
        switch outcomeDirection {
        case .better:
            return MindSensePalette.success
        case .same:
            return MindSensePalette.accent
        case .worse:
            return MindSensePalette.warning
        }
    }

    private var impactStateLine: String {
        let ratingLabel = switch selectedCheckInRating {
        case .helped:
            "Helped"
        case .didNotHelp:
            "Didn't help"
        case .mixed:
            "Mixed"
        case .noRating:
            "No rating yet"
        }
        if let selectedOutcomeTag {
            return "\(ratingLabel) • \(selectedOutcomeTag)"
        }
        return ratingLabel
    }

    private var calmingTrendLabel: String {
        if sessionProgress >= 0.8 {
            return "strong downshift trend"
        }
        if sessionProgress >= 0.45 {
            return "moderate downshift trend"
        }
        return "settling"
    }

    private func heartShiftLine(for metrics: RegulateEffectMetrics) -> String {
        let value = metrics.heartRateDownshiftBPM
        if value >= 0 {
            return "-\(value) bpm"
        }
        return "+\(abs(value)) bpm"
    }

    private func hrvShiftLine(for metrics: RegulateEffectMetrics) -> String {
        let value = metrics.hrvShiftMS
        if value >= 0 {
            return "+\(value) ms"
        }
        return "-\(abs(value)) ms"
    }
}

private struct RegulatePresetDetailSheet: View {
    let preset: DemoRegulatePreset

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MindSenseSpacing.md) {
                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: preset.title,
                                subtitle: preset.subtitle,
                                icon: preset.icon
                            )
                        )
                        detailRow(label: "Duration", value: preset.durationLabel)
                        detailRow(label: "Expected effect", value: preset.expectedEffect)
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Protocol steps",
                                subtitle: "Use this sequence as your guidance during the run."
                            )
                        )
                        VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                            ForEach(Array(preset.protocolSteps.enumerated()), id: \.offset) { index, step in
                                Text("\(index + 1). \(step)")
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Why now",
                                subtitle: "How this protocol matches your current intent."
                            )
                        )
                        Text(preset.whyNow)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("Protocol details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "Protocol details")
                }
            }
        }
        .mindSenseSheetPresentationChrome()
    }

    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
            Text(label)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.7)
            Text(value)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

@MainActor
private final class RegulateAudioCoach: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.46
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.9
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
