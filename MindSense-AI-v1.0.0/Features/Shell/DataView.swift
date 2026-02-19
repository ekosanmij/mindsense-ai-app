import Charts
import SwiftUI

struct DataView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    private enum DataSubmode: String, CaseIterable, Identifiable {
        case trends = "Trends"
        case experiments = "Experiments"
        case history = "History"

        var id: String { rawValue }
    }

    @State private var submode: DataSubmode = .experiments
    @State private var window: TrendWindow = .seven
    @State private var selectedPoint: TrendPoint?
    @State private var selectedSignal: SignalFocus = .readiness
    @State private var selectedExperimentID: UUID?
    @State private var showTrendFilterSheet = false

    @State private var showCompletionSheet = false
    @State private var completionShift = 1.0
    @State private var completionSummary = ""
    @State private var didAppear = false

    private var trendPoints: [TrendPoint] {
        store.trendPoints(for: window)
    }

    private var focusExperiments: [Experiment] {
        store.experiments
            .filter { $0.focus == selectedSignal }
            .sorted { lhs, rhs in
                statusOrder(lhs.status) < statusOrder(rhs.status)
            }
    }

    private var historySections: [(title: String, events: [DemoEventRecord])] {
        let events = Array(store.demoEventHistory.prefix(20))
        guard !events.isEmpty else { return [] }

        let calendar = Calendar.current
        var orderedTitles: [String] = []
        var grouped: [String: [DemoEventRecord]] = [:]

        for event in events {
            let title: String
            if calendar.isDateInToday(event.timestamp) {
                title = "Today"
            } else if calendar.isDateInYesterday(event.timestamp) {
                title = "Yesterday"
            } else {
                title = event.timestamp.formatted(date: .abbreviated, time: .omitted)
            }

            if grouped[title] == nil {
                orderedTitles.append(title)
            }
            grouped[title, default: []].append(event)
        }

        return orderedTitles.compactMap { title in
            guard let sectionEvents = grouped[title], !sectionEvents.isEmpty else { return nil }
            return (title: title, events: sectionEvents)
        }
    }

    private var selectedExperiment: Experiment? {
        focusExperiments.first(where: { $0.id == selectedExperimentID }) ?? focusExperiments.first
    }

    private var readinessValue: Int {
        Int((selectedPoint?.readiness ?? trendPoints.last?.readiness ?? Double(store.demoMetrics.readiness)).rounded())
    }

    private var loadValue: Int {
        Int((selectedPoint?.load ?? trendPoints.last?.load ?? Double(store.demoMetrics.load)).rounded())
    }

    private var consistencyValue: Int {
        let spreads = trendPoints.map { abs($0.readiness - $0.load) }
        let avgSpread = spreads.reduce(0, +) / Double(max(spreads.count, 1))
        let inferred = Int(max(45, 92 - avgSpread).rounded())
        return Int(((Double(inferred) + Double(store.demoMetrics.consistency)) / 2).rounded())
    }

    private var insightNarrative: String {
        store.insightNarrative(for: selectedSignal)
    }

    private var weeklySummary: DemoWeeklySummary {
        store.weeklySummary
    }

    private var signalTrendTiles: [DataSignalTrendTile] {
        store.dataSignalTrendTiles
    }

    private var whatIsWorkingSummary: DemoWhatIsWorkingSummary {
        store.whatIsWorkingSummary
    }

    private var resolvedState: ScreenMode {
        store.screenMode(for: .data)
    }

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    private var experimentCTA: (label: String, id: String, action: () -> Void, disabled: Bool)? {
        guard let selectedExperiment else {
            return nil
        }

        switch selectedExperiment.status {
        case .planned:
            return (
                label: "Start 7-day experiment",
                id: "data_primary_cta",
                action: {
                    store.startExperiment(selectedExperiment.id)
                    store.track(event: .primaryCTATapped, surface: .data, action: "start_experiment")
                },
                disabled: false
            )

        case .active:
            if selectedExperiment.checkInDaysCompleted >= selectedExperiment.durationDays {
                return (
                    label: "Complete experiment",
                    id: "data_complete_experiment_cta",
                    action: { showCompletionSheet = true },
                    disabled: false
                )
            }

            return (
                label: "Log today",
                id: "data_log_day_cta",
                action: {
                    store.logExperimentDay(selectedExperiment.id)
                    store.track(event: .primaryCTATapped, surface: .data, action: "log_experiment_day")
                },
                disabled: false
            )

        case .completed:
            return nil
        }
    }

    private func tabBarCollapseScrollRunway(containerHeight: CGFloat) -> CGFloat {
        let base: CGFloat = 120
        guard submode == .experiments else { return base }
        return max(320, containerHeight * 0.9)
    }

    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                ScrollView {
                    ScreenStateContainer(state: resolvedState, retryAction: { store.retryCoreScreen(.data) }) {
                        VStack(spacing: MindSenseRhythm.section) {
                            workspaceSwitcher
                                .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)
                            currentStateBlock
                                .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)
                            signalsTrendStripBlock
                                .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)
                            activeModeContent
                                .mindSenseStaggerEntrance(4, isPresented: didAppear, reduceMotion: reduceMotion)
                            if submode != .experiments {
                                whatsWorkingBlock
                                    .mindSenseStaggerEntrance(5, isPresented: didAppear, reduceMotion: reduceMotion)
                            }
                            Color.clear
                                .frame(height: tabBarCollapseScrollRunway(containerHeight: proxy.size.height))
                                .accessibilityHidden(true)
                        }
                        .mindSensePageInsets()
                    }
                }
                .scrollBounceBehavior(.always, axes: .vertical)
                .mindSensePageBackground()
                .navigationTitle(AppIA.data)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        MindSenseNavTitleLockup(title: AppIA.data)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ProfileAccessMenu()
                    }
                }
                .sheet(isPresented: $showCompletionSheet) {
                    ExperimentCompletionSheet(
                        perceivedShift: $completionShift,
                        summary: $completionSummary,
                        scenarioTitle: store.demoScenario.title,
                        onCancel: { showCompletionSheet = false },
                        onSubmit: submitExperimentCompletion
                    )
                }
                .sheet(isPresented: $showTrendFilterSheet) {
                    TrendFilterSheet(window: $window)
                }
                .onAppear {
                    didAppear = true
                    if selectedExperimentID == nil {
                        selectedExperimentID = focusExperiments.first?.id
                    }
                    store.prepareCoreScreen(.data)
                    store.track(event: .screenView, surface: .data)
                }
                .onChange(of: window) { _, newWindow in
                    if reduceMotion {
                        selectedPoint = nil
                    } else {
                        withAnimation(MindSenseMotion.chartInteraction) {
                            selectedPoint = nil
                        }
                    }
                    store.track(event: .chartInteraction, surface: .data, metadata: ["window": newWindow.rawValue])
                }
                .onChange(of: selectedSignal) { _, _ in
                    self.selectedExperimentID = focusExperiments.first?.id
                }
                .onChange(of: store.experiments) { _, _ in
                    if let selectedExperimentID,
                       !store.experiments.contains(where: { $0.id == selectedExperimentID && $0.focus == selectedSignal }) {
                        self.selectedExperimentID = focusExperiments.first?.id
                    }
                }
                .onChange(of: store.demoScenario) { _, _ in
                    selectedPoint = nil
                    self.selectedExperimentID = focusExperiments.first?.id
                    store.prepareCoreScreen(.data)
                }
            }
        }
    }

    private var workspaceSwitcher: some View {
        InsetSurface {
            Text("Workspace")
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.8)

            MindSenseSegmentedControl(
                options: DataSubmode.allCases,
                selection: $submode,
                title: { $0.rawValue },
                onSelectionChanged: { mode in
                    store.triggerHaptic(intent: .selection)
                    store.track(
                        event: .secondaryActionTapped,
                        surface: .data,
                        action: "workspace_selected",
                        metadata: ["workspace": mode.rawValue.lowercased()]
                    )
                }
            )
        }
    }

    private var currentStateBlock: some View {
        PrimarySurface {
            MindSenseSectionHeader(
                model: .init(
                    title: store.demoScenario.title,
                    subtitle: "Current state • \(window.rawValue) window",
                    icon: "gauge"
                )
            )

            HStack(spacing: 8) {
                currentStateMetricTile(
                    title: "Readiness",
                    value: readinessValue,
                    tint: MindSensePalette.success
                )
                currentStateMetricTile(
                    title: "Load",
                    value: loadValue,
                    tint: MindSensePalette.warning
                )
                currentStateMetricTile(
                    title: "Consistency",
                    value: consistencyValue,
                    tint: MindSensePalette.signalCool
                )
            }

            Button {
                launchRecommendedAction(source: "data_current_state_recommendation")
            } label: {
                HStack(spacing: 10) {
                    MindSenseIconBadge(
                        systemName: recommendedPresetIcon(for: store.primaryRecommendation.preset),
                        tint: MindSensePalette.signalCool,
                        style: .filled,
                        size: 28
                    )
                    Text("Recommended: \(store.primaryRecommendation.preset.title) • \(store.primaryRecommendation.timeMinutes) min")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                        .fill(MindSenseSurfaceLevel.base.fill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                        .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .overlay(alignment: .topTrailing) {
            MindSenseLogoWatermark(height: 124, tint: MindSensePalette.accent)
                .padding(.top, 8)
                .padding(.trailing, 2)
        }
    }

    private func currentStateMetricTile(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(MindSenseTypography.metricBody)
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .padding(.horizontal, MindSenseLayout.tileHorizontalInset)
        .padding(.vertical, MindSenseLayout.tileVerticalInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: MindSenseLayout.tileMinHeight)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
    }

    private var signalFocusChipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SignalFocus.allCases) { focus in
                    Button {
                        guard selectedSignal != focus else { return }
                        selectedSignal = focus
                        selectedExperimentID = focusExperiments.first?.id
                        store.triggerHaptic(intent: .selection)
                    } label: {
                        PillChip(label: focus.metric.title, state: selectedSignal == focus ? .selected : .unselected)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var signalsTrendStripBlock: some View {
        InsetSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Signals & Trends",
                    subtitle: "Tap a tile to open trend detail.",
                    icon: "chart.line.uptrend.xyaxis"
                )
            )

            HStack(spacing: 8) {
                ForEach(signalTrendTiles) { tile in
                    signalTrendTile(tile)
                }
            }
        }
    }

    private func signalTrendTile(_ tile: DataSignalTrendTile) -> some View {
        let tint = signalTrendTint(for: tile)
        return Button {
            handleSignalTrendTileTap(tile)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(tile.title)
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(tile.value)
                    .font(MindSenseTypography.metricBody)
                    .foregroundStyle(tint)
                    .monospacedDigit()

                HStack(spacing: 4) {
                    Image(systemName: trendArrowSymbol(for: tile.direction))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                    Text(tile.deltaText)
                        .font(MindSenseTypography.micro)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 96, alignment: .topLeading)
            .padding(.horizontal, MindSenseLayout.tileHorizontalInset)
            .padding(.vertical, MindSenseLayout.tileVerticalInset)
            .background(
                RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                    .fill(MindSenseSurfaceLevel.base.fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                    .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var whatsWorkingBlock: some View {
        InsetSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "What's working for you",
                    subtitle: "Weekly learning from sessions and context signals.",
                    icon: "lightbulb"
                )
            )

            whatIsWorkingRow(
                label: "Most effective protocol",
                value: whatIsWorkingSummary.topProtocol
            )
            MindSenseSectionDivider(emphasis: 0.12)
            whatIsWorkingRow(
                label: "Most common trigger",
                value: whatIsWorkingSummary.topTrigger
            )
            MindSenseSectionDivider(emphasis: 0.12)
            whatIsWorkingRow(
                label: "Best recovery window",
                value: whatIsWorkingSummary.bestRecoveryWindow
            )
        }
    }

    private func whatIsWorkingRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.7)
            Spacer(minLength: 8)
            Text(value)
                .font(MindSenseTypography.bodyStrong)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: 34, alignment: .leading)
    }

    @ViewBuilder
    private var activeModeContent: some View {
        switch submode {
        case .trends:
            trendBlock
            if loadValue >= 88 {
                EscalationGuidanceView(context: .sustainedHighLoad)
            }
        case .experiments:
            experimentsBlock
        case .history:
            weeklySummaryBlock
            historyTimelineBlock
        }
    }

    private var trendBlock: some View {
        FocusSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Trend view",
                    subtitle: "Inspect readiness and load across the selected window.",
                    icon: "chart.xyaxis.line",
                    actionTitle: "Filters",
                    action: {
                        showTrendFilterSheet = true
                        store.triggerHaptic(intent: .selection)
                    }
                )
            )

            signalFocusChipBar

            InsetSurface {
                VStack(alignment: .leading, spacing: MindSenseSpacing.sm) {
                    HStack {
                        Text("Readiness vs Load")
                            .font(MindSenseTypography.bodyStrong)
                    }

                    DataTrendChart(points: trendPoints, selectedPoint: $selectedPoint)
                        .frame(height: 220)

                    HStack(spacing: 8) {
                        dataMetaPill("Window \(window.rawValue)")
                        dataMetaPill("Confidence \(store.confidencePercent)%")
                        dataMetaPill("Coverage \(store.demoDataCoveragePercent)%")
                    }
                }
            }

            selectedReadout

            RecommendationRationaleView(
                estimate: "Focus: \(selectedSignal.coachTitle)",
                whyRecommended: selectedSignal.coachBody
            )

            HStack {
                Text("Tap or drag to inspect.")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if selectedPoint != nil {
                    Button("Clear marker") {
                        selectedPoint = nil
                        store.triggerHaptic(intent: .selection)
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                    .accessibilityIdentifier("data_clear_marker")
                }
            }

            InsetSurface {
                MindSenseSectionHeader(
                    model: .init(
                        title: "Insight",
                        subtitle: selectedSignal.coachTitle,
                        icon: "brain.head.profile"
                    )
                )
                Text(insightNarrative)
                    .font(MindSenseTypography.bodyStrong)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(selectedSignal.coachBody)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Button("See suggested plan") {
                    launchRecommendedAction(source: "data_trend_insight")
                }
                .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
            }
        }
    }

    private var weeklySummaryBlock: some View {
        InsetSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "History summary",
                    subtitle: "Wins, risks, and next best action generated from recent activity.",
                    icon: "clock.arrow.circlepath"
                )
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("Wins")
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(MindSensePalette.success)
                ForEach(weeklySummary.wins, id: \.self) { line in
                    Text("• \(line)")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Risks")
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(MindSensePalette.warning)
                ForEach(weeklySummary.risks, id: \.self) { line in
                    Text("• \(line)")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            MindSenseSectionDivider(emphasis: 0.16)

            VStack(alignment: .leading, spacing: 8) {
                Text("Next best action")
                    .font(MindSenseTypography.bodyStrong)
                Text(weeklySummary.nextBestAction)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    dataMetaPill(store.primaryRecommendation.preset.title)
                    dataMetaPill("\(store.primaryRecommendation.timeMinutes) min")
                }

                Button("Do it now") {
                    launchRecommendedAction(source: "data_history_next_action")
                }
                .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 48))
            }
        }
    }

    private var historyTimelineBlock: some View {
        FocusSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Recent activity",
                    subtitle: "Latest events from sessions, check-ins, and experiments.",
                    icon: "clock"
                )
            )

            if historySections.isEmpty {
                Text("No history yet. Complete a session or check-in to populate this timeline.")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(historySections.enumerated()), id: \.offset) { sectionIndex, section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(MindSenseTypography.bodyStrong)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            ForEach(Array(section.events.enumerated()), id: \.element.id) { index, event in
                                historyEventRow(event)

                                if index < section.events.count - 1 {
                                    MindSenseSectionDivider(emphasis: 0.08)
                                }
                            }
                        }
                    }

                    if sectionIndex < historySections.count - 1 {
                        MindSenseSectionDivider(emphasis: 0.14)
                    }
                }
            }
        }
    }

    private var experimentsBlock: some View {
        PrimarySurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "7-day experiments",
                    subtitle: "Run one focused experiment with daily adherence logging.",
                    icon: "flask"
                )
            )

            signalFocusChipBar

            if focusExperiments.isEmpty {
                Text("No experiments configured for this focus.")
                    .font(MindSenseTypography.body)
                    .foregroundStyle(.secondary)
            }

            ForEach(focusExperiments) { experiment in
                let selected = experiment.id == selectedExperiment?.id
                let isActive = experiment.status == .active
                Button {
                    selectedExperimentID = experiment.id
                    store.triggerHaptic(intent: .selection)
                    store.track(event: .secondaryActionTapped, surface: .data, action: "experiment_selected")
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(experiment.title)
                                .font(MindSenseTypography.bodyStrong)
                                .foregroundStyle(.primary)
                            Spacer()
                            PillChip(label: experiment.status.title, state: experimentStatusChipState(experiment.status))
                        }

                        Text(experiment.hypothesis)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            let chips = experimentMetaChips(for: experiment)
                            ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                                dataMetaPill(chip)
                            }
                        }

                        if experiment.status == .active {
                            let nextDay = min(experiment.checkInDaysCompleted + 1, experiment.durationDays)
                            HStack(spacing: 8) {
                                Text("Day \(nextDay) of \(experiment.durationDays)")
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(MindSensePalette.accent)
                                    .monospacedDigit()
                                Spacer()
                                Text("Adherence \(experiment.adherencePercent)%")
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .accessibilityIdentifier("data_active_experiment_progress")

                            GeometryReader { proxy in
                                let ratio = Double(experiment.checkInDaysCompleted) / Double(max(experiment.durationDays, 1))
                                ZStack(alignment: .leading) {
                                    Capsule(style: .continuous)
                                        .fill(MindSenseSurfaceLevel.base.fill)
                                    Capsule(style: .continuous)
                                        .fill(AnyShapeStyle(MindSensePalette.accent))
                                        .frame(width: proxy.size.width * CGFloat(max(0.08, ratio)))
                                }
                            }
                            .frame(height: 5)
                        }

                        if experiment.status == .completed, let result = experiment.result {
                            Text("Result: \(result.summary)")
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.horizontal, MindSenseLayout.tileHorizontalInset)
                    .padding(.vertical, MindSenseLayout.tileVerticalInset)
                    .background(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                            .fill(
                                selected
                                    ? AnyShapeStyle(MindSensePalette.accentMuted)
                                    : (isActive
                                        ? AnyShapeStyle(MindSensePalette.accentMuted.opacity(0.36))
                                        : AnyShapeStyle(MindSenseSurfaceLevel.base.fill))
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                            .stroke(
                                selected
                                    ? MindSensePalette.strokeEdge
                                    : (isActive
                                        ? MindSensePalette.strokeEdge.opacity(0.68)
                                        : MindSensePalette.strokeSubtle),
                                lineWidth: 1
                            )
                    )
                    .animation(reduceMotion ? nil : MindSenseMotion.selection, value: selected)
                }
                .buttonStyle(.plain)
            }

            if let selectedExperiment {
                RecommendationRationaleView(
                    estimate: selectedExperiment.estimate,
                    whyRecommended: "\(selectedExperiment.rationale) Next: \(selectedExperiment.nextStep)"
                )

                if let experimentCTA {
                    Button(experimentCTA.label) {
                        guard !experimentCTA.disabled else { return }
                        store.triggerHaptic(intent: .primary)
                        experimentCTA.action()
                    }
                    .accessibilityIdentifier(experimentCTA.id)
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 52))
                    .disabled(experimentCTA.disabled)
                }
            }
        }
    }

    private func historyEventRow(_ event: DemoEventRecord) -> some View {
        HStack(alignment: .top, spacing: 10) {
            MindSenseIconBadge(
                systemName: eventIcon(for: event.kind),
                tint: eventTint(for: event.kind),
                style: .filled,
                size: 28
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(MindSenseTypography.bodyStrong)
                    .lineLimit(1)
                Text(event.detail)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 10)

            Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }

    private func experimentStatusChipState(_ status: ExperimentStatus) -> MindSenseChipState {
        switch status {
        case .active:
            return .selected
        case .planned:
            return .unselected
        case .completed:
            return .disabled
        }
    }

    private var selectedReadout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text((selectedPoint?.time ?? trendPoints.last?.time ?? Date()).formattedDateLabel())
                .font(MindSenseTypography.metricCaption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                readoutPill(title: "Readiness", value: readinessValue, tint: MindSensePalette.success)
                readoutPill(title: "Load", value: loadValue, tint: MindSensePalette.warning)
                readoutPill(title: "Consistency", value: consistencyValue, tint: MindSensePalette.signalCool)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Selected trend point readiness \(readinessValue), load \(loadValue), consistency \(consistencyValue)")
    }

    private func readoutPill(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(MindSenseTypography.metricBody)
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .padding(.horizontal, MindSenseLayout.tileHorizontalInset)
        .padding(.vertical, MindSenseLayout.tileVerticalInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
    }

    private func dataMetaPill(_ text: String) -> some View {
        Text(text)
            .font(MindSenseTypography.micro)
            .foregroundStyle(.secondary)
            .padding(.horizontal, MindSenseLayout.tileHorizontalInset - 2)
            .frame(minHeight: 24)
            .background(
                Capsule(style: .continuous)
                    .fill(MindSenseSurfaceLevel.base.fill)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
            )
    }

    private func experimentMetaChips(for experiment: Experiment) -> [String] {
        let estimate = store.experimentEffectEstimate(for: experiment)
        guard let open = estimate.firstIndex(of: "("),
              let close = estimate.firstIndex(of: ")"),
              open < close else {
            return [estimate]
        }

        let effect = String(estimate[..<open]).trimmingCharacters(in: .whitespacesAndNewlines)
        let confidenceRange = estimate.index(after: open)..<close
        let confidence = String(estimate[confidenceRange]).capitalized
        return [effect, confidence]
    }

    private func statusOrder(_ status: ExperimentStatus) -> Int {
        switch status {
        case .active:
            return 0
        case .planned:
            return 1
        case .completed:
            return 2
        }
    }

    private func submitExperimentCompletion() {
        guard let selectedExperiment else { return }
        store.completeExperiment(
            selectedExperiment.id,
            perceivedChange: Int(completionShift.rounded()),
            summary: completionSummary
        )
        completionShift = 1
        completionSummary = ""
        showCompletionSheet = false
        store.triggerHaptic(intent: .success)
    }

    private func launchRecommendedAction(source: String) {
        let recommendation = store.primaryRecommendation
        store.openRegulatePreset(recommendation.preset, startImmediately: true)
        store.track(
            event: .primaryCTATapped,
            surface: .data,
            action: "start_mapped_\(recommendation.preset.rawValue)",
            metadata: ["source": source]
        )
        store.triggerHaptic(intent: .primary)
    }

    private func recommendedPresetIcon(for preset: RegulatePresetID) -> String {
        switch preset {
        case .calmNow:
            return "wind"
        case .focusPrep:
            return "scope"
        case .sleepDownshift:
            return "moon.stars.fill"
        }
    }

    private func eventIcon(for kind: DemoEventKind) -> String {
        switch kind {
        case .scenario:
            return "arrow.triangle.2.circlepath"
        case .checkIn:
            return "checkmark.seal.fill"
        case .reflection:
            return "text.bubble.fill"
        case .session:
            return "wind"
        case .experiment:
            return "flask.fill"
        case .system:
            return "gearshape.fill"
        }
    }

    private func eventTint(for kind: DemoEventKind) -> Color {
        switch kind {
        case .scenario, .system:
            return MindSensePalette.accent
        case .checkIn:
            return MindSensePalette.success
        case .reflection:
            return MindSensePalette.signalCoolStrong
        case .session:
            return MindSensePalette.warning
        case .experiment:
            return MindSensePalette.signalCool
        }
    }

    private func handleSignalTrendTileTap(_ tile: DataSignalTrendTile) {
        submode = .trends
        selectedSignal = tile.linkedFocus
        selectedPoint = nil
        store.triggerHaptic(intent: .selection)
        store.track(
            event: .secondaryActionTapped,
            surface: .data,
            action: "trend_tile_opened",
            metadata: ["tile": tile.id, "focus": tile.linkedFocus.rawValue]
        )
    }

    private func trendArrowSymbol(for direction: DataTrendDirection) -> String {
        switch direction {
        case .up:
            return "arrow.up.right"
        case .down:
            return "arrow.down.right"
        case .flat:
            return "arrow.right"
        }
    }

    private func signalTrendTint(for tile: DataSignalTrendTile) -> Color {
        if tile.id == "activation_spikes" {
            switch tile.direction {
            case .up:
                return MindSensePalette.warning
            case .down:
                return MindSensePalette.success
            case .flat:
                return MindSensePalette.accent
            }
        }

        switch tile.direction {
        case .up:
            return MindSensePalette.success
        case .down:
            return MindSensePalette.warning
        case .flat:
            return MindSensePalette.accent
        }
    }
}

private struct TrendFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var window: TrendWindow

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Trend filters",
                                subtitle: "Window is secondary to the metric focus in Trends.",
                                icon: "slider.horizontal.3"
                            )
                        )

                        MindSenseSegmentedControl(
                            options: TrendWindow.allCases,
                            selection: $window,
                            title: { $0.rawValue }
                        )
                    }
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "Filters")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct DataTrendChart: View {
    let points: [TrendPoint]
    @Binding var selectedPoint: TrendPoint?

    var body: some View {
        Chart {
            ForEach(points) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value(CoreMetric.readiness.title, point.readiness)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(MindSensePalette.success)
                .lineStyle(StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round))

                AreaMark(
                    x: .value("Time", point.time),
                    y: .value(CoreMetric.readiness.title, point.readiness)
                )
                .foregroundStyle(MindSensePalette.success.opacity(0.14))
            }

            ForEach(points) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value(CoreMetric.load.title, point.load)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(MindSensePalette.warning)
                .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            }

            if let selectedPoint {
                RuleMark(x: .value("Selected", selectedPoint.time))
                    .foregroundStyle(MindSensePalette.strokeStrong)

                PointMark(
                    x: .value("Readiness point", selectedPoint.time),
                    y: .value("Readiness value", selectedPoint.readiness)
                )
                .foregroundStyle(MindSensePalette.success)

                PointMark(
                    x: .value("Load point", selectedPoint.time),
                    y: .value("Load value", selectedPoint.load)
                )
                .foregroundStyle(MindSensePalette.warning)
            }
        }
        .chartLegend(position: .top) {
            HStack(spacing: 12) {
                legendItem(title: CoreMetric.readiness.title, color: MindSensePalette.success)
                legendItem(title: CoreMetric.load.title, color: MindSensePalette.warning)
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    RoundedRectangle(cornerRadius: MindSenseRadius.medium, style: .continuous)
                        .fill(MindSenseSurfaceLevel.base.fill.opacity(0.84))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MindSenseRadius.medium, style: .continuous)
                        .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: MindSenseRadius.medium, style: .continuous))
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day(), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let number = value.as(Double.self) {
                        Text("\(Int(number.rounded()))")
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 4)
                            .onChanged { value in
                                guard !points.isEmpty else { return }
                                guard let plotFrame = proxy.plotFrame else { return }
                                let origin = geometry[plotFrame].origin
                                let xPosition = value.location.x - origin.x
                                guard xPosition >= 0, xPosition <= proxy.plotSize.width else { return }
                                if let date = proxy.value(atX: xPosition, as: Date.self) {
                                    selectedPoint = nearestPoint(to: date)
                                }
                            }
                    )
            }
        }
        .accessibilityLabel("Data trend chart for readiness and load")
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: MindSenseRadius.pill, style: .continuous)
                .fill(color)
                .frame(width: 16, height: 4)
            Text(title).font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(MindSenseSurfaceLevel.glass.fill)
        )
    }

    private func nearestPoint(to date: Date) -> TrendPoint? {
        points.min(by: {
            abs($0.time.timeIntervalSince(date)) < abs($1.time.timeIntervalSince(date))
        })
    }
}

private struct ExperimentCompletionSheet: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @Binding var perceivedShift: Double
    @Binding var summary: String
    let scenarioTitle: String
    let onCancel: () -> Void
    let onSubmit: () -> Void
    @State private var didAppear = false

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MindSenseCommandDeck(
                        label: "Experiment",
                        title: "Complete your 7-day run",
                        detail: "Context: \(scenarioTitle). Finalize this result to improve your next recommendation.",
                        metric: "Final step"
                    )
                    .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)

                    PrimarySurface {
                        ProtocolTokenStripView(
                            what: "Capture perceived shift + summary",
                            why: "Close the experiment loop for this context",
                            expectedEffect: "Sharper next recommendation",
                            time: "About 1 min"
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Perceived change")
                                .font(MindSenseTypography.bodyStrong)
                            Slider(value: $perceivedShift, in: -5...5, step: 1)
                            Text("\(Int(perceivedShift.rounded()))")
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Result summary")
                                .font(MindSenseTypography.bodyStrong)
                            TextField("What changed over the 7-day run?", text: $summary, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3, reservesSpace: true)
                        }
                    }
                    .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)

                    Button("Save result", action: onSubmit)
                        .accessibilityIdentifier("data_complete_submit_cta")
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .primary))
                        .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)

                    Button("Cancel", action: onCancel)
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                        .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("Experiment result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "Experiment result")
                }
            }
            .onAppear {
                didAppear = true
            }
        }
    }
}
