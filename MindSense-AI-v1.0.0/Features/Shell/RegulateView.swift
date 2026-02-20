import SwiftUI
import Combine

struct RegulateView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    @State private var selectedPresetID: RegulatePresetID?
    @State private var feelRating = 3.0
    @State private var helpfulness: SessionHelpfulness = .some
    @State private var hapticPacingEnabled = true
    @State private var didAppear = false
    @State private var now = Date()
    @State private var showRecordImpactDetails = false

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

    private var outcomeDirection: SessionImpactDirection {
        let score = Int(feelRating.rounded())
        if helpfulness == .no || score <= 2 {
            return .worse
        }
        if helpfulness == .yes && score >= 4 {
            return .better
        }
        if helpfulness == .some && score >= 4 {
            return .better
        }
        return .same
    }

    private var outcomeIntensity: Int {
        let score = Int(feelRating.rounded())
        let distance = abs(score - 3)
        switch outcomeDirection {
        case .better:
            return max(1, min(5, score))
        case .same:
            return max(1, min(5, distance + 1))
        case .worse:
            return max(1, min(5, 6 - score))
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
                label: "Save post-session check-in",
                id: "regulate_outcome_submit_cta",
                action: submitOutcome,
                disabled: false
            )
        case .completed, .cancelled:
            return nil
        }
    }

    private var shouldHideTabBar: Bool {
        store.activeRegulateSession?.isInProgress == true
    }

    private var bottomContentPadding: CGFloat {
        16
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                ScreenStateContainer(state: resolvedState, retryAction: { store.retryCoreScreen(.regulate) }) {
                    VStack(spacing: MindSenseRhythm.section) {
                        commandDeck
                            .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)
                        stepProgressBlock
                            .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)
                        sessionStatusBlock
                            .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)
                        activeStepBlock
                            .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)
                    }
                    .mindSensePageInsets(bottom: bottomContentPadding)
                }
            }
            .scrollBounceBehavior(.always, axes: .vertical)
            .mindSensePageBackground()
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
            .toolbar(shouldHideTabBar ? .hidden : .automatic, for: .tabBar)
            .tabBarMinimizeBehavior(.onScrollDown)
            .safeAreaInset(edge: .bottom) {
                if case .ready = resolvedState, let primaryCTAConfig {
                    MindSenseBottomActionDock {
                        Spacer()
                            .frame(height: 12)

                        Button(primaryCTAConfig.label) {
                            guard !primaryCTAConfig.disabled else { return }
                            store.triggerHaptic(intent: .primary)
                            primaryCTAConfig.action()
                        }
                        .accessibilityIdentifier(primaryCTAConfig.id)
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 52))
                        .disabled(primaryCTAConfig.disabled)
                    }
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
                guard store.activeRegulateSession?.isInProgress == true else { return }
                now = date
                store.syncActiveRegulateSessionState(now: date)
            }
            .onChange(of: store.regulateLaunchRequest) { _, _ in
                consumeLaunchRequestIfNeeded()
            }
            .onChange(of: store.demoScenario) { _, _ in
                selectedPresetID = presets.first?.id
                store.prepareCoreScreen(.regulate)
            }
        }
    }

    private var commandDeck: some View {
        InsetSurface {
            HStack(alignment: .top, spacing: MindSenseSpacing.sm) {
                MindSenseLogoBadge(size: 28, tint: MindSensePalette.signalCoolStrong)

                VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                    Text("Guided regulate flow")
                        .font(MindSenseTypography.titleCompact)
                        .tracking(0.15)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)

                    Text(commandDetail)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                PillChip(label: "Step \(currentStep.rawValue + 1) of \(RegulateStep.allCases.count)", state: .selected)
                PillChip(label: commandMetric, state: .unselected)
            }

            Text("Select one protocol, run the timer, then record impact.")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var commandDetail: String {
        switch currentStep {
        case .selectProtocol:
            return "Step 1 of 3: Choose one protocol."
        case .runTimer:
            return "Step 2 of 3: Stay with the timer until completion."
        case .recordImpact:
            return "Step 3 of 3: Record impact to close the loop."
        }
    }

    private var commandMetric: String {
        if currentStep == .runTimer {
            return remainingLabel
        }
        return "\(currentStep.rawValue + 1)/\(RegulateStep.allCases.count)"
    }

    private var sessionProgressRatio: Double {
        let totalSteps = Double(max(RegulateStep.allCases.count - 1, 1))
        return min(1, Double(currentStep.rawValue) / totalSteps)
    }

    private var sessionStatusBlock: some View {
        InsetSurface {
            Text("Load \(store.demoMetrics.load)  •  Readiness \(store.demoMetrics.readiness)  •  Flow \(flowLabel)")
                .font(MindSenseTypography.bodyStrong)
                .fixedSize(horizontal: false, vertical: true)

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

    private var stepProgressBlock: some View {
        InsetSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Progress",
                    subtitle: "1 Select -> 2 Run -> 3 Record",
                    icon: "chart.bar.fill"
                )
            )

            GeometryReader { proxy in
                let width = proxy.size.width * max(0.18, sessionProgressRatio)
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(MindSenseSurfaceLevel.base.fill)
                    Capsule(style: .continuous)
                        .fill(MindSensePalette.signalCoolStrong)
                        .frame(width: width)
                }
            }
            .frame(height: 8)

            HStack(spacing: 8) {
                ForEach(RegulateStep.allCases) { step in
                    stepRow(step)
                }
            }
        }
    }

    private func stepRow(_ step: RegulateStep) -> some View {
        let isCurrent = step == currentStep
        let isComplete = step.rawValue < currentStep.rawValue
        let isEnabled = step.rawValue <= currentStep.rawValue
        let tint: Color = isCurrent ? MindSensePalette.signalCoolStrong : (isComplete ? MindSensePalette.success : .secondary)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(tint.opacity(isEnabled ? 1 : 0.45), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(tint)
                    } else {
                        Text("\(step.rawValue + 1)")
                            .font(MindSenseTypography.micro)
                            .foregroundStyle(tint)
                    }
                }
                Text(step.title)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(tint)
            }

            if isCurrent {
                Text(stepSummary(for: step))
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(isEnabled ? 1 : 0.45)
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
                    subtitle: "Pick one protocol, then start it from this section.",
                    icon: "list.bullet.rectangle"
                )
            )

            ForEach(presets) { preset in
                let selected = preset.id == activePreset?.id
                Button {
                    selectedPresetID = preset.id
                    store.triggerHaptic(intent: .selection)
                    store.track(event: .secondaryActionTapped, surface: .regulate, action: "preset_selected_\(preset.id.rawValue)")
                } label: {
                    HStack(spacing: 12) {
                        MindSenseIconBadge(
                            systemName: preset.icon,
                            tint: MindSensePalette.signalCool,
                            style: selected ? .filled : .muted,
                            size: 40
                        )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.title)
                                .font(MindSenseTypography.bodyStrong)
                                .foregroundStyle(.primary)
                            Text(preset.subtitle)
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Text(preset.expectedEffect)
                                .font(MindSenseTypography.caption)
                                .lineLimit(1)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                selectionMetaPill(
                                    icon: "waveform.path.ecg",
                                    text: "Confidence \(store.expectedEffectConfidence(for: preset.id))%"
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
            }

            if let activePreset {
                DisclosureGroup("Protocol details") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(activePreset.protocolSteps, id: \.self) { step in
                            Text("• \(step)")
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(activePreset.expectedEffect)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 6)
                }
                .font(MindSenseTypography.bodyStrong)
            }

            if let activePreset {
                Button("Start \(activePreset.title) (\(activePreset.durationLabel))") {
                    store.triggerHaptic(intent: .primary)
                    startPreset(activePreset.id, source: "regulate_primary_cta")
                }
                .accessibilityIdentifier("regulate_start_cta")
                .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 52))
            }
        }
    }

    private func selectionMetaPill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
            Text(text)
                .font(MindSenseTypography.micro)
                .monospacedDigit()
        }
        .foregroundStyle(MindSensePalette.accent)
        .padding(.horizontal, 8)
        .frame(minHeight: 22)
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
        FocusSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Run timer",
                    subtitle: "Stay with the timer to complete the session.",
                    icon: "timer"
                )
            )

            ZStack {
                Circle()
                    .stroke(MindSenseSurfaceLevel.base.fill, lineWidth: 14)

                Circle()
                    .trim(from: 0, to: max(0.03, sessionProgress))
                    .stroke(
                        MindSensePalette.signalCoolStrong,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
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
            .frame(width: 180, height: 180)
            .frame(maxWidth: .infinity, alignment: .center)

            Text("Session progress \(Int((sessionProgress * 100).rounded()))%")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Text("Session: \(runningPreset.title)")
                .font(MindSenseTypography.bodyStrong)

            ProtocolTokenStripView(
                what: runningPreset.title,
                why: runningPreset.whyNow,
                expectedEffect: runningPreset.expectedEffect,
                time: runningPreset.durationLabel,
                maxValueLines: 2
            )

            DisclosureGroup("Why this works") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(runningPreset.whyNow)
                    Text(runningPreset.expectedEffect)
                    Text("What to think: \(store.todayCognitivePrompt)")
                }
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            }
            .font(MindSenseTypography.bodyStrong)

            Toggle("Haptic pacing", isOn: $hapticPacingEnabled)
                .font(MindSenseTypography.caption)
                .tint(MindSensePalette.accent)

            HStack(spacing: 8) {
                MindSenseIconBadge(systemName: "heart.text.square", tint: MindSensePalette.signalCool, style: .filled, size: 28)
                Text("Calming trend: \(calmingTrendLabel)")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    MindSenseIconBadge(systemName: "waveform.path.ecg", tint: impactTint, style: .filled, size: 28)
                    Text("Current impact selection: \(impactStateLine)")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Text("How do you feel?")
                    .font(MindSenseTypography.bodyStrong)

                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { score in
                        feelScoreButton(score)
                    }
                }

                Text("\(Int(feelRating.rounded()))/5 • \(feelLabel)")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Did this help?")
                    .font(MindSenseTypography.bodyStrong)

                MindSenseSegmentedControl(
                    options: SessionHelpfulness.allCases,
                    selection: $helpfulness,
                    title: { $0.title },
                    onSelectionChanged: { _ in
                        store.triggerHaptic(intent: .selection)
                    }
                )
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

            Text("Capture immediate outcome to improve tomorrow's recommendation quality.")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(store.todayMeasurementPlanLine)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            DisclosureGroup(isExpanded: $showRecordImpactDetails) {
                VStack(alignment: .leading, spacing: 8) {
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
    }

    private func recordImpactDetailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
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

    private func feelScoreButton(_ score: Int) -> some View {
        let selected = Int(feelRating.rounded()) == score
        return Button {
            feelRating = Double(score)
            store.triggerHaptic(intent: .selection)
        } label: {
            Text("\(score)")
                .font(MindSenseTypography.caption)
                .foregroundStyle(selected ? MindSensePalette.signalCoolStrong : .secondary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 36)
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
        .accessibilityIdentifier("regulate_feel_\(score)")
    }

    private var flowLabel: String {
        switch currentStep {
        case .selectProtocol:
            return "Ready"
        case .runTimer:
            return "Running"
        case .recordImpact:
            return "Review"
        }
    }

    private func stepSummary(for step: RegulateStep) -> String {
        switch step {
        case .selectProtocol:
            return "Pick one protocol."
        case .runTimer:
            return "Complete the timer."
        case .recordImpact:
            return "Log feeling, helpfulness, and measured effect."
        }
    }

    private func consumeLaunchRequestIfNeeded() {
        guard let request = store.consumeRegulateLaunchRequest() else { return }
        selectedPresetID = request.preset
        if request.startImmediately {
            startPreset(request.preset, source: "today_mapped_cta")
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
        feelRating = 3
        helpfulness = .some
        showRecordImpactDetails = false
        store.track(event: .primaryCTATapped, surface: .regulate, action: "start_\(presetID.rawValue)")
        _ = store.beginRegulateSession(preset: presetID, source: source)
        store.showActionFeedback(.applied, detail: "\(preset.title) started.")
        store.triggerHaptic(intent: .success)
    }

    private func submitOutcome() {
        guard store.activeRegulateSession != nil else { return }
        let intensity = outcomeIntensity
        let feeling = Int(feelRating.rounded())
        store.recordRegulateOutcome(
            direction: outcomeDirection,
            intensity: intensity,
            feelRating: feeling,
            helpfulness: helpfulness
        )
        store.track(event: .actionCompleted, surface: .regulate, action: "post_session_check_in_saved")
        store.triggerHaptic(intent: .success)
        feelRating = 3
        helpfulness = .some
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
        "\(outcomeDirection.title) • feel \(Int(feelRating.rounded()))/5 • help \(helpfulness.title)"
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

    private var feelLabel: String {
        switch Int(feelRating.rounded()) {
        case 1: return "Very strained"
        case 2: return "Strained"
        case 3: return "Neutral"
        case 4: return "Steadier"
        default: return "Calmer"
        }
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
