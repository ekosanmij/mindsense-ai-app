import Charts
import EventKit
import EventKitUI
import SwiftUI
import UserNotifications

private enum TrendSmoothing: String, CaseIterable, Identifiable {
    case none = "None"
    case light = "Light"
    case heavy = "Heavy"

    var id: String { rawValue }

    var radius: Int {
        switch self {
        case .none:
            return 0
        case .light:
            return 1
        case .heavy:
            return 2
        }
    }
}

private enum TrendDayFilter: String, CaseIterable, Identifiable {
    case allDays = "All"
    case weekdays = "Weekdays"
    case weekends = "Weekends"

    var id: String { rawValue }

    var analyticsValue: String {
        switch self {
        case .allDays:
            return "all"
        case .weekdays:
            return "weekdays"
        case .weekends:
            return "weekends"
        }
    }

    func includes(_ date: Date, calendar: Calendar = .current) -> Bool {
        switch self {
        case .allDays:
            return true
        case .weekdays:
            return !calendar.isDateInWeekend(date)
        case .weekends:
            return calendar.isDateInWeekend(date)
        }
    }
}

private enum TrendEventOverlayType: String, CaseIterable, Hashable, Identifiable {
    case workouts
    case checkIns
    case experiments

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workouts:
            return "Workouts"
        case .checkIns:
            return "Check-ins"
        case .experiments:
            return "Experiments"
        }
    }

    var icon: String {
        switch self {
        case .workouts:
            return "figure.run"
        case .checkIns:
            return "checkmark.circle.fill"
        case .experiments:
            return "flask.fill"
        }
    }

    var tint: Color {
        switch self {
        case .workouts:
            return MindSensePalette.warning
        case .checkIns:
            return MindSensePalette.success
        case .experiments:
            return MindSensePalette.signalCool
        }
    }

    init?(eventKind: DemoEventKind) {
        switch eventKind {
        case .session:
            self = .workouts
        case .checkIn:
            self = .checkIns
        case .experiment:
            self = .experiments
        default:
            return nil
        }
    }
}

private struct TrendOverlayEvent: Identifiable, Equatable {
    let id: UUID
    let time: Date
    let type: TrendEventOverlayType
    let title: String
}

private struct TrendOverlayCount: Identifiable {
    let type: TrendEventOverlayType
    let count: Int

    var id: TrendEventOverlayType { type }
}

private struct TrendComparisonSummary {
    let currentAverage: Double
    let previousAverage: Double

    var delta: Double { currentAverage - previousAverage }
    var percentDelta: Double {
        guard abs(previousAverage) > 0.01 else { return 0 }
        return (delta / previousAverage) * 100
    }
}

private enum RecoveryAnchorType: String, CaseIterable, Identifiable {
    case sleep
    case walk
    case breathing
    case noMeetingBlock

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep:
            return "Sleep"
        case .walk:
            return "Walk"
        case .breathing:
            return "Breathing"
        case .noMeetingBlock:
            return "No-meeting block"
        }
    }

    var icon: String {
        switch self {
        case .sleep:
            return "moon.stars.fill"
        case .walk:
            return "figure.walk"
        case .breathing:
            return "wind"
        case .noMeetingBlock:
            return "calendar.badge.clock"
        }
    }

    var reminderBody: String {
        switch self {
        case .sleep:
            return "Start your sleep anchor routine and protect the next hour."
        case .walk:
            return "Take your recovery walk to keep your rhythm stable."
        case .breathing:
            return "Run your breathing anchor to reset load before it builds."
        case .noMeetingBlock:
            return "Protect your no-meeting recovery block."
        }
    }

    var notificationIdentifier: String {
        "mindsense.recovery_anchor.\(rawValue)"
    }

    var defaultCalendarBlockMinutes: Int? {
        switch self {
        case .noMeetingBlock:
            return 45
        case .sleep, .walk, .breathing:
            return nil
        }
    }
}

struct DataView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.mindSenseTabBarOverlayClearance) private var tabBarOverlayClearance
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @AppStorage("notifications.recoveryWindow") private var recoveryWindowNotificationsEnabled = true
    @AppStorage("data.recoveryAnchor.type") private var recoveryAnchorTypeRawValue = RecoveryAnchorType.sleep.rawValue
    @AppStorage("data.recoveryAnchor.hour") private var recoveryAnchorHour = 21
    @AppStorage("data.recoveryAnchor.minute") private var recoveryAnchorMinute = 30
    @AppStorage("data.recoveryAnchor.reminderEnabled") private var recoveryAnchorReminderEnabled = true
    @AppStorage("data.recoveryAnchor.planActive") private var recoveryAnchorPlanActive = false
    @AppStorage("data.recoveryAnchor.adherenceCount") private var recoveryAnchorAdherenceCount = 0
    @AppStorage("data.recoveryAnchor.lastTrackedDay") private var recoveryAnchorLastTrackedDay = ""

    private enum DataSubmode: String, CaseIterable, Identifiable {
        case patterns = "Trends"
        case plans = "Plans"
        case experiments = "Experiments"
        case history = "History"

        var id: String { rawValue }
    }

    @State private var submode: DataSubmode = .patterns
    @State private var window: TrendWindow = .seven
    @State private var selectedPoint: TrendPoint?
    @State private var selectedSignal: SignalFocus = .readiness
    @State private var selectedExperimentID: UUID?
    @State private var showTrendFilterSheet = false
    @State private var showCoverageDiagnostics = false
    @State private var trendComparePreviousWindow = false
    @State private var trendSmoothing: TrendSmoothing = .none
    @State private var trendDayFilter: TrendDayFilter = .allDays
    @State private var trendEventOverlays: Set<TrendEventOverlayType> = Set(TrendEventOverlayType.allCases)

    @State private var showCompletionSheet = false
    @State private var completionShift = 1.0
    @State private var completionSummary = ""
    @State private var completionHelped = true
    @State private var completionDecision: ExperimentOutcomeDecision = .keep
    @State private var recoveryWindowCalendarDraft: RecoveryWindowCalendarDraft?
    @State private var selectedWakeAnchorMissReason: ExperimentMissReason?
    @State private var selectedHistoryEpisode: StressEpisodeRecord?
    @State private var didAppear = false

    private let lowCoverageThreshold = 68

    private var rawTrendPoints: [TrendPoint] {
        store.trendPoints(for: window)
    }

    private var trendPoints: [TrendPoint] {
        let filtered = rawTrendPoints.filter { trendDayFilter.includes($0.time) }
        return smoothedTrendPoints(filtered, smoothing: trendSmoothing)
    }

    private var trendCompareSupported: Bool {
        window == .seven
    }

    private var shouldShowTrendComparison: Bool {
        trendComparePreviousWindow && trendCompareSupported
    }

    private var trendComparisonPoints: [TrendPoint]? {
        guard shouldShowTrendComparison else { return nil }
        guard !trendPoints.isEmpty else { return nil }

        let contextPoints = store.trendPoints(for: .fourteen)
        let midpoint = contextPoints.count / 2
        guard midpoint > 0 else { return nil }

        let previousWindowPoints = Array(contextPoints.prefix(midpoint))
        let filteredPrevious = previousWindowPoints.filter { trendDayFilter.includes($0.time) }
        let smoothedPrevious = smoothedTrendPoints(filteredPrevious, smoothing: trendSmoothing)

        return alignedTrendPoints(smoothedPrevious, to: trendPoints)
    }

    private var trendComparisonSummary: TrendComparisonSummary? {
        guard shouldShowTrendComparison,
              let comparison = trendComparisonPoints,
              !comparison.isEmpty,
              !trendPoints.isEmpty else { return nil }

        let currentAverage = trendPoints.map(trendMetricValue).reduce(0, +) / Double(max(trendPoints.count, 1))
        let previousAverage = comparison.map(trendMetricValue).reduce(0, +) / Double(max(comparison.count, 1))
        return .init(currentAverage: currentAverage, previousAverage: previousAverage)
    }

    private var trendOverlayEvents: [TrendOverlayEvent] {
        guard let start = trendPoints.first?.time,
              let end = trendPoints.last?.time else { return [] }

        return store.demoEventHistory
            .filter { $0.timestamp >= start && $0.timestamp <= end }
            .compactMap { record in
                guard let overlayType = TrendEventOverlayType(eventKind: record.kind) else { return nil }
                guard trendEventOverlays.contains(overlayType) else { return nil }
                guard trendDayFilter.includes(record.timestamp) else { return nil }
                return TrendOverlayEvent(
                    id: record.id,
                    time: record.timestamp,
                    type: overlayType,
                    title: record.title
                )
            }
            .sorted { lhs, rhs in
                if lhs.time == rhs.time {
                    return lhs.type.rawValue < rhs.type.rawValue
                }
                return lhs.time < rhs.time
            }
    }

    private var trendOverlayCounts: [TrendOverlayCount] {
        TrendEventOverlayType.allCases.compactMap { type in
            let count = trendOverlayEvents.filter { $0.type == type }.count
            guard count > 0 else { return nil }
            return TrendOverlayCount(type: type, count: count)
        }
    }

    private var activeTrendFilterSummaryLine: String {
        var segments = [
            "Window \(window.rawValue)",
            "Day filter \(trendDayFilter.rawValue)",
            "Smoothing \(trendSmoothing.rawValue)"
        ]
        if trendComparePreviousWindow {
            segments.append("Compare prior window")
        }
        return segments.joined(separator: " • ")
    }

    private var activeTrendFilterDetailLine: String {
        let overlaySummary: String
        if trendOverlayCounts.isEmpty {
            overlaySummary = "Overlays: none."
        } else {
            let chips = trendOverlayCounts
                .map { "\($0.type.title) \($0.count)" }
                .joined(separator: ", ")
            overlaySummary = "Overlays: \(chips)."
        }

        let comparisonSummary: String
        if shouldShowTrendComparison, let comparison = trendComparisonSummary {
            comparisonSummary = trendComparisonDetailText(for: comparison)
        } else if trendComparePreviousWindow && !trendCompareSupported {
            comparisonSummary = "Previous-window compare is currently available on 7D."
        } else {
            comparisonSummary = "Previous-window compare is off."
        }

        return "\(overlaySummary) \(comparisonSummary)"
    }

    private var trendExportPayload: String {
        var lines: [String] = []
        lines.append("MindSense Trend Export")
        lines.append("Signal,\(selectedSignal.metric.title)")
        lines.append("Window,\(window.rawValue)")
        lines.append("Smoothing,\(trendSmoothing.rawValue)")
        lines.append("Day Filter,\(trendDayFilter.rawValue)")
        lines.append("Compare Previous Window,\(shouldShowTrendComparison ? "On" : "Off")")
        if let comparison = trendComparisonSummary {
            lines.append("Current Avg,\(comparison.currentAverage.formatted(.number.precision(.fractionLength(1))))")
            lines.append("Previous Avg,\(comparison.previousAverage.formatted(.number.precision(.fractionLength(1))))")
            lines.append("Delta,\(comparison.delta.formatted(.number.precision(.fractionLength(1))))")
        }
        lines.append("")
        lines.append("Trend Points")
        lines.append("timestamp,readiness,load,consistency")
        let formatter = ISO8601DateFormatter()
        for point in trendPoints {
            lines.append([
                formatter.string(from: point.time),
                point.readiness.formatted(.number.precision(.fractionLength(1))),
                point.load.formatted(.number.precision(.fractionLength(1))),
                inferredConsistency(for: point).formatted(.number.precision(.fractionLength(1)))
            ].joined(separator: ","))
        }

        if !trendOverlayEvents.isEmpty {
            lines.append("")
            lines.append("Event Overlay")
            lines.append("timestamp,type,title")
            for event in trendOverlayEvents {
                let safeTitle = event.title.replacingOccurrences(of: ",", with: " ")
                lines.append("\(formatter.string(from: event.time)),\(event.type.title),\(safeTitle)")
            }
        }

        return lines.joined(separator: "\n")
    }

    private var shouldShowRecoveryAnchorPlanner: Bool {
        selectedSignal == .consistency && insightNarrative.localizedCaseInsensitiveContains("anchor")
    }

    private var recoveryAnchorType: RecoveryAnchorType {
        RecoveryAnchorType(rawValue: recoveryAnchorTypeRawValue) ?? .sleep
    }

    private var recoveryAnchorTypeBinding: Binding<RecoveryAnchorType> {
        Binding {
            recoveryAnchorType
        } set: { newValue in
            recoveryAnchorTypeRawValue = newValue.rawValue
        }
    }

    private var recoveryAnchorScheduleBinding: Binding<Date> {
        Binding {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = recoveryAnchorHour
            components.minute = recoveryAnchorMinute
            return calendar.date(from: components) ?? Date()
        } set: { newDate in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
            recoveryAnchorHour = components.hour ?? recoveryAnchorHour
            recoveryAnchorMinute = components.minute ?? recoveryAnchorMinute
        }
    }

    private var recoveryAnchorTimeLabel: String {
        recoveryAnchorScheduleBinding.wrappedValue.formatted(date: .omitted, time: .shortened)
    }

    private var recoveryAnchorTrackingDayStamp: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private var recoveryAnchorTrackedToday: Bool {
        recoveryAnchorLastTrackedDay == recoveryAnchorTrackingDayStamp
    }

    private var recoveryAnchorAdherenceLine: String {
        if recoveryAnchorTrackedToday {
            return "Adherence tracked today. Total check-ins logged: \(recoveryAnchorAdherenceCount)."
        }
        return "Track adherence after you complete the anchor. Total check-ins logged: \(recoveryAnchorAdherenceCount)."
    }

    private var recoveryAnchorNoMeetingSchedule: RecoveryWindowSchedule? {
        guard let durationMinutes = recoveryAnchorType.defaultCalendarBlockMinutes else { return nil }
        let start = recoveryAnchorScheduleBinding.wrappedValue
        let end = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: start) ?? start.addingTimeInterval(Double(durationMinutes) * 60)
        return .init(startTime: start, endTime: end)
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

    private var attributionEditEpisodes: [StressEpisodeRecord] {
        let ranked = store.recentStressEpisodes.sorted { lhs, rhs in
            let lhsNeedsReview = lhs.attributionFeedback == nil || !lhs.hasContext
            let rhsNeedsReview = rhs.attributionFeedback == nil || !rhs.hasContext
            if lhsNeedsReview == rhsNeedsReview {
                return lhs.start > rhs.start
            }
            return lhsNeedsReview && !rhsNeedsReview
        }
        return Array(ranked.prefix(8))
    }

    private var whatIsWorkingSummary: DemoWhatIsWorkingSummary {
        store.whatIsWorkingSummary
    }

    private var recoveryWindowSchedule: RecoveryWindowSchedule? {
        guard let start = whatIsWorkingSummary.bestRecoveryWindowStart,
              let end = whatIsWorkingSummary.bestRecoveryWindowEnd else {
            return nil
        }
        return .init(startTime: start, endTime: end)
    }

    private var resolvedState: ScreenMode {
        store.screenMode(for: .data)
    }

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    private var isCoverageLow: Bool {
        store.demoDataCoveragePercent < lowCoverageThreshold
    }

    private var coverageReasonLine: String {
        let reasons = lowCoverageReasons
        guard !reasons.isEmpty else {
            return "Coverage is low because recent signal collection is incomplete."
        }
        return "Coverage is low because: \(reasons.joined(separator: "; "))."
    }

    private var lowCoverageReasons: [String] {
        let quality = store.demoHealthProfile.quality
        var reasons: [String] = []

        let missingHRVDays = max(0, 7 - capturedDays(from: quality.hrvAvailability))
        if missingHRVDays > 0 {
            reasons.append("missing HRV \(missingHRVDays)/7 days")
        }

        let missingOvernightNights = max(0, 7 - capturedDays(from: quality.sleepCoverage))
        if missingOvernightNights > 0 {
            let nightLabel = missingOvernightNights == 1 ? "night" : "nights"
            reasons.append("watch not worn overnight \(missingOvernightNights) \(nightLabel)")
        }

        return Array(reasons.prefix(2))
    }

    private func isWakeAnchorExperiment(_ experiment: Experiment) -> Bool {
        experiment.focus == .consistency && experiment.title.localizedCaseInsensitiveContains("wake anchor")
    }

    private var selectedWakeAnchorAutoFill: ExperimentWakeAnchorAutoFill? {
        guard let selectedExperiment,
              selectedExperiment.status == .active,
              selectedExperiment.checkInDaysCompleted < selectedExperiment.durationDays,
              isWakeAnchorExperiment(selectedExperiment) else { return nil }
        return store.wakeAnchorAutoFillSuggestion(for: selectedExperiment)
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

            if isWakeAnchorExperiment(selectedExperiment) {
                return nil
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

    private var tabBarCollapseScrollRunway: CGFloat {
        switch submode {
        case .experiments:
            return 220
        case .patterns, .plans, .history:
            return 96
        }
    }

    private var bottomContentPadding: CGFloat {
        switch submode {
        case .patterns, .plans, .experiments:
            return MindSenseLayout.pageBottom + MindSenseLayout.tabBarClearance(
                measuredOverlay: tabBarOverlayClearance,
                tier: .expanded
            )
        case .history:
            return MindSenseLayout.pageBottom + MindSenseLayout.tabBarClearance(
                measuredOverlay: tabBarOverlayClearance,
                tier: .standard
            )
        }
    }

    private var shouldShowStickyExperimentCTA: Bool {
        if case .ready = resolvedState, submode == .experiments, experimentCTA != nil {
            return true
        }
        return false
    }

    private var stickyExperimentDockSubtitle: String? {
        guard let selectedExperiment else { return nil }
        return "Selected: \(selectedExperiment.title)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                ScreenStateContainer(state: resolvedState, retryAction: { store.retryCoreScreen(.data) }) {
                    VStack(spacing: MindSenseRhythm.section) {
                        commandDeck
                            .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)
                        activeModeContent
                            .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)
                        // Keep a short scroll runway so tab-bar minimize can trigger on shorter layouts.
                        Color.clear
                            .frame(height: tabBarCollapseScrollRunway)
                            .accessibilityHidden(true)
                    }
                    .mindSensePageInsets(bottom: bottomContentPadding)
                }
            }
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
            .safeAreaInset(edge: .bottom) {
                if shouldShowStickyExperimentCTA, let experimentCTA {
                    MindSenseDoItNowDock(subtitle: stickyExperimentDockSubtitle) {
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
            .sheet(isPresented: $showCompletionSheet) {
                if let selectedExperiment {
                    ExperimentCompletionSheet(
                        perceivedShift: $completionShift,
                        summary: $completionSummary,
                        helped: $completionHelped,
                        decision: $completionDecision,
                        evaluation: store.experimentEvaluationPreview(for: selectedExperiment),
                        scenarioTitle: store.demoScenario.title,
                        onCancel: {
                            completionHelped = true
                            completionDecision = .keep
                            showCompletionSheet = false
                        },
                        onSubmit: submitExperimentCompletion
                    )
                }
            }
            .sheet(isPresented: $showTrendFilterSheet) {
                TrendFilterSheet(
                    window: $window,
                    comparePreviousWindow: $trendComparePreviousWindow,
                    smoothing: $trendSmoothing,
                    dayFilter: $trendDayFilter,
                    eventOverlays: $trendEventOverlays,
                    compareSupported: trendCompareSupported,
                    sharePayload: trendExportPayload,
                    shareTitle: "\(selectedSignal.metric.title) trend"
                )
            }
            .sheet(item: $recoveryWindowCalendarDraft) { draft in
                RecoveryWindowCalendarEditor(draft: draft) { action in
                    handleRecoveryCalendarEditorAction(action)
                }
            }
            .sheet(isPresented: $showCoverageDiagnostics) {
                NavigationStack {
                    AppleHealthPermissionsView()
                }
            }
            .sheet(item: $selectedHistoryEpisode) { episode in
                TodayEpisodeDetailSheet(
                    episode: episode,
                    cognitivePrompt: store.episodeCognitivePrompt(for: episode),
                    recommendedDurationLabel: store.presetDefinition(for: episode.recommendedPreset)?.durationLabel ?? "3 min",
                    onSaveContext: { episodeID, tags, note in
                        store.saveStressEpisodeContext(
                            episodeID: episodeID,
                            tags: tags.sorted(),
                            note: note
                        )
                        if let updated = store.recentStressEpisodes.first(where: { $0.id == episodeID }) {
                            selectedHistoryEpisode = updated
                        }
                    },
                    onSaveFeedback: { episodeID, feedback in
                        store.saveStressEpisodeAttributionFeedback(
                            episodeID: episodeID,
                            feedback: feedback
                        )
                        if let updated = store.recentStressEpisodes.first(where: { $0.id == episodeID }) {
                            selectedHistoryEpisode = updated
                        }
                    },
                    onStartRecommended: { selectedEpisode in
                        store.openRegulatePreset(
                            selectedEpisode.recommendedPreset,
                            startImmediately: true,
                            source: "episode:\(selectedEpisode.id.uuidString)|data_episode_detail_start"
                        )
                        selectedHistoryEpisode = nil
                    }
                )
            }
            .onAppear {
                let firstAppearance = !didAppear
                if firstAppearance {
                    didAppear = true
                    selectedSignal = store.intentMode.preferredSignalFocus
                }
                if selectedExperimentID == nil {
                    selectedExperimentID = focusExperiments.first?.id
                }
                store.prepareCoreScreen(.data)
                if firstAppearance {
                    store.track(event: .screenView, surface: .data)
                }
            }
            .onChange(of: window) { _, newWindow in
                if newWindow != .seven {
                    trendComparePreviousWindow = false
                }
                if reduceMotion {
                    selectedPoint = nil
                } else {
                    withAnimation(MindSenseMotion.chartInteraction) {
                        selectedPoint = nil
                    }
                }
                store.track(event: .chartInteraction, surface: .data, metadata: ["window": newWindow.rawValue])
            }
            .onChange(of: trendSmoothing) { _, newValue in
                selectedPoint = nil
                store.track(
                    event: .chartInteraction,
                    surface: .data,
                    metadata: ["smoothing": newValue.rawValue.lowercased()]
                )
            }
            .onChange(of: trendDayFilter) { _, newValue in
                selectedPoint = nil
                store.track(
                    event: .chartInteraction,
                    surface: .data,
                    metadata: ["day_filter": newValue.analyticsValue]
                )
            }
            .onChange(of: trendComparePreviousWindow) { _, isEnabled in
                guard trendCompareSupported || !isEnabled else {
                    trendComparePreviousWindow = false
                    return
                }
                selectedPoint = nil
                store.track(
                    event: .chartInteraction,
                    surface: .data,
                    metadata: ["compare_previous_window": isEnabled ? "on" : "off"]
                )
            }
            .onChange(of: selectedSignal) { _, _ in
                self.selectedExperimentID = focusExperiments.first?.id
                selectedWakeAnchorMissReason = nil
            }
            .onChange(of: store.experiments) { _, _ in
                if let selectedExperimentID,
                   !store.experiments.contains(where: { $0.id == selectedExperimentID && $0.focus == selectedSignal }) {
                    self.selectedExperimentID = focusExperiments.first?.id
                }
                selectedWakeAnchorMissReason = nil
            }
            .onChange(of: store.intentMode) { _, _ in
                selectedSignal = store.intentMode.preferredSignalFocus
                selectedExperimentID = focusExperiments.first?.id
                selectedWakeAnchorMissReason = nil
            }
            .onChange(of: store.demoScenario) { _, _ in
                selectedPoint = nil
                self.selectedExperimentID = focusExperiments.first?.id
                selectedWakeAnchorMissReason = nil
                store.prepareCoreScreen(.data)
            }
        }
    }

    private var commandDeck: some View {
        MindSenseTabHero(
            label: AppIA.data,
            title: "One focus, one workspace.",
            detail: "Convert \(store.demoScenario.title) trends into plans, run experiments, and review history.",
            metric: submode.rawValue,
            icon: "chart.xyaxis.line",
            tone: .accent,
            watermarkTint: MindSensePalette.accent
        ) {
            MindSenseSegmentedControl(
                options: DataSubmode.allCases,
                selection: $submode,
                title: { $0.rawValue },
                enablesHorizontalScrollFallback: true,
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

            HStack(spacing: 8) {
                PillChip(label: store.intentMode.shortTitle, state: .selected)
                switch submode {
                case .patterns, .experiments:
                    PillChip(label: selectedSignal.metric.title, state: .unselected)
                case .plans:
                    PillChip(label: store.primaryRecommendation.preset.title, state: .unselected)
                case .history:
                    PillChip(label: "Recent activity", state: .unselected)
                }
                if submode == .patterns {
                    PillChip(label: "Window \(window.rawValue)", state: .unselected)
                }
            }
        }
    }

    private var signalFocusChipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.orderedSignalFocuses) { focus in
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
                    title: "Pattern signals",
                    subtitle: "Tap a signal to inspect multi-day movement.",
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
            MindSenseCollapsibleSection(
                model: .init(
                    title: "What's working for you",
                    subtitle: "Weekly learning from sessions and context signals.",
                    icon: "lightbulb"
                ),
                storageKey: "ui.collapse.data.whats_working",
                collapsedSummary: "Top protocol: \(whatIsWorkingSummary.topProtocol)"
            ) {
                whatIsWorkingRow(
                    label: "Most effective protocol",
                    value: whatIsWorkingSummary.topProtocol,
                    supportingText: whatIsWorkingSummary.topProtocolEvidence
                )
                MindSenseSectionDivider(emphasis: 0.12)
                whatIsWorkingRow(
                    label: "Most common trigger",
                    value: whatIsWorkingSummary.topTrigger
                )
                MindSenseSectionDivider(emphasis: 0.12)
                whatIsWorkingRow(
                    label: "Best recovery window",
                    value: whatIsWorkingSummary.bestRecoveryWindow,
                    supportingText: whatIsWorkingSummary.bestRecoveryWindowEvidence
                )

                if let recoveryWindowSchedule {
                    MindSenseSectionDivider(emphasis: 0.12)
                    recoveryWindowActionRow(schedule: recoveryWindowSchedule)
                }
            }
        }
    }

    private func whatIsWorkingRow(label: String, value: String, supportingText: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.7)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if let supportingText, !supportingText.isEmpty {
                    Text(supportingText)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(minHeight: supportingText == nil ? 34 : 44, alignment: .leading)
    }

    private func recoveryWindowActionRow(schedule: RecoveryWindowSchedule) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Make this window actionable")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Protect this window") {
                scheduleRecoveryWindowCalendarBlock(for: schedule)
            }
            .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary, minHeight: 42))
            .accessibilityIdentifier("data_protect_recovery_window_cta")

            Button("Remind me when this window starts") {
                scheduleRecoveryWindowReminder(for: schedule)
            }
            .buttonStyle(MindSenseButtonStyle(hierarchy: .text, minHeight: 40))
            .accessibilityIdentifier("data_recovery_window_reminder_cta")
        }
    }

    @ViewBuilder
    private var activeModeContent: some View {
        switch submode {
        case .patterns:
            signalsTrendStripBlock
            trendBlock
            whatsWorkingBlock
            if loadValue >= 88 {
                EscalationGuidanceView(context: .sustainedHighLoad)
            }
        case .plans:
            plansBlock
            whatsWorkingBlock
        case .experiments:
            experimentsBlock
        case .history:
            weeklySummaryBlock
            historyAttributionBlock
            whatsWorkingBlock
            historyTimelineBlock
        }
    }

    private var trendBlock: some View {
        FocusSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Pattern explorer",
                    subtitle: "Inspect the selected signal across the chosen window.",
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
                        Text("\(selectedSignal.metric.title) pattern")
                            .font(MindSenseTypography.bodyStrong)
                    }

                    DataTrendChart(
                        points: trendPoints,
                        comparisonPoints: trendComparisonPoints,
                        overlayEvents: trendOverlayEvents,
                        selectedSignal: selectedSignal,
                        selectedPoint: $selectedPoint
                    )
                        .frame(height: 220)

                    Text("X-axis: Date • Y-axis: \(selectedSignal.metric.title) score (%)")
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        dataMetaPill("Window \(window.rawValue)")
                        dataMetaPill("Rec. confidence \(store.confidencePercent)%")
                    }

                    MindSenseSummaryDisclosureText(
                        summary: activeTrendFilterSummaryLine,
                        detail: activeTrendFilterDetailLine,
                        collapsedLabel: "Show active filters",
                        expandedLabel: "Hide filter details"
                    )

                    HStack {
                        Text("Share the filtered chart as CSV and summary.")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 8)

                        Button {
                            showTrendFilterSheet = true
                            store.triggerHaptic(intent: .selection)
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                                .font(MindSenseTypography.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if isCoverageLow {
                InsetSurface {
                    MindSenseSectionHeader(
                        model: .init(
                            title: "Coverage needs attention",
                            subtitle: "Low coverage can reduce pattern reliability.",
                            icon: "exclamationmark.triangle"
                        )
                    )
                    MindSenseSummaryDisclosureText(
                        summary: coverageSummaryLine,
                        detail: coverageReasonLine,
                        collapsedLabel: "Why coverage matters",
                        expandedLabel: "Hide coverage details"
                    )

                    Button("Do this to improve coverage") {
                        showCoverageDiagnostics = true
                        store.track(event: .secondaryActionTapped, surface: .data, action: "open_coverage_diagnostics")
                        store.triggerHaptic(intent: .selection)
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary, minHeight: 44))
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
                        title: "Pattern insight",
                        subtitle: "\(selectedSignal.coachTitle) • \(store.intentMode.title)",
                        icon: "brain.head.profile"
                    )
                )
                Text(insightNarrative)
                    .font(MindSenseTypography.bodyStrong)
                    .fixedSize(horizontal: false, vertical: true)
                MindSenseSummaryDisclosureText(
                    summary: selectedSignal.coachTitle,
                    detail: selectedSignal.coachBody,
                    collapsedLabel: "Why this signal matters",
                    expandedLabel: "Hide rationale"
                )

                if shouldShowRecoveryAnchorPlanner {
                    recoveryAnchorPlannerBlock
                } else {
                    Button("Start suggested plan") {
                        launchRecommendedAction(source: "data_trend_insight")
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                }
            }
        }
    }

    private var plansBlock: some View {
        FocusSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Plan workspace",
                    subtitle: "Turn pattern findings into one action plan and one measurement plan.",
                    icon: "list.bullet.rectangle.portrait"
                )
            )

            InsetSurface {
                HStack(alignment: .top, spacing: 10) {
                    MindSenseIconBadge(
                        systemName: recommendedPresetIcon(for: store.primaryRecommendation.preset),
                        tint: MindSensePalette.signalCool,
                        style: .filled,
                        size: 28
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.primaryRecommendation.preset.title)
                            .font(MindSenseTypography.bodyStrong)
                        Text(store.primaryRecommendation.summaryLine)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)
                    dataMetaPill("\(store.primaryRecommendation.timeMinutes) min")
                }

                RecommendationRationaleView(
                    estimate: "Why now",
                    whyRecommended: store.primaryRecommendation.why
                )

                Button("Start this plan") {
                    launchRecommendedAction(source: "data_plan_workspace")
                }
                .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 48))
            }

            InsetSurface {
                MindSenseSectionHeader(
                    model: .init(
                        title: "Measurement plan",
                        subtitle: "Capture this today to sharpen tomorrow's recommendation.",
                        icon: "checklist"
                    )
                )

                Text(store.todayMeasurementPlanLine)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Next best follow-through")
                    .font(MindSenseTypography.bodyStrong)
                Text(weeklySummary.nextBestAction)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var weeklySummaryBlock: some View {
        InsetSurface {
            MindSenseCollapsibleSection(
                model: .init(
                    title: "History summary",
                    subtitle: "Wins and risks observed in recent activity.",
                    icon: "clock.arrow.circlepath"
                ),
                storageKey: "ui.collapse.data.history_summary",
                collapsedSummary: "\(weeklySummary.wins.count) wins • \(weeklySummary.risks.count) risks"
            ) {
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
            }
        }
    }

    private var historyAttributionBlock: some View {
        FocusSurface {
            MindSenseCollapsibleSection(
                model: .init(
                    title: "Edit later",
                    subtitle: "Revisit attribution after the moment has passed.",
                    icon: "square.and.pencil"
                ),
                storageKey: "ui.collapse.data.edit_later",
                collapsedSummary: attributionEditEpisodes.isEmpty
                    ? "No episodes waiting for review."
                    : "\(attributionEditEpisodes.count) episodes waiting for attribution review"
            ) {
                if attributionEditEpisodes.isEmpty {
                    Text("No episodes yet. Stress episodes will appear here for later review.")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(attributionEditEpisodes) { episode in
                            attributionEditRow(episode)
                        }
                    }
                }
            }
        }
    }

    private func attributionEditRow(_ episode: StressEpisodeRecord) -> some View {
        HStack(alignment: .top, spacing: 10) {
            MindSenseIconBadge(
                systemName: "waveform.path.ecg",
                tint: MindSensePalette.warning,
                style: .filled,
                size: 28
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("\(episode.start.formattedDateLabel()) \(episode.start.formattedTimeLabel())-\(episode.end.formattedTimeLabel())")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)

                Text("\(episode.likelyDriver.title) • attribution confidence \(episode.confidence)%")
                    .font(MindSenseTypography.bodyStrong)
                    .fixedSize(horizontal: false, vertical: true)

                Text(attributionStatusLine(for: episode))
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button("Edit later") {
                selectedHistoryEpisode = episode
                store.triggerHaptic(intent: .selection)
                store.track(
                    event: .secondaryActionTapped,
                    surface: .data,
                    action: "history_edit_later_opened"
                )
            }
            .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary, fullWidth: false, minHeight: 40))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func attributionStatusLine(for episode: StressEpisodeRecord) -> String {
        let feedbackLine = episode.attributionFeedback == nil ? "Feedback pending" : "Feedback captured"
        let contextLine = episode.hasContext ? "context captured" : "context pending"
        return "\(feedbackLine) • \(contextLine)"
    }

    private var historyTimelineBlock: some View {
        FocusSurface {
            MindSenseCollapsibleSection(
                model: .init(
                    title: "Recent activity",
                    subtitle: "Latest events from sessions, check-ins, and experiments.",
                    icon: "clock"
                ),
                storageKey: "ui.collapse.data.recent_activity",
                collapsedSummary: historySections.isEmpty
                    ? "No recent activity yet."
                    : "\(historySections.count) day groups • \(historySections.reduce(0) { partial, section in partial + section.events.count }) events"
            ) {
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
    }

    private var experimentsBlock: some View {
        PrimarySurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "7-day experiments",
                    subtitle: "Run one focused experiment with one daily yes/no check-in.",
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
                experimentSelectionRow(experiment)
            }

            if let selectedExperiment {
                selectedExperimentDetailSection(selectedExperiment)
            }
        }
    }

    private func experimentSelectionRow(_ experiment: Experiment) -> some View {
        let selected = experiment.id == selectedExperiment?.id
        let isActive = experiment.status == .active

        return Button {
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

                experimentSelectionProgressBlock(experiment)
                experimentSelectionCompletionBlock(experiment)
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

    @ViewBuilder
    private func experimentSelectionProgressBlock(_ experiment: Experiment) -> some View {
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
    }

    @ViewBuilder
    private func experimentSelectionCompletionBlock(_ experiment: Experiment) -> some View {
        if experiment.status == .completed, let result = experiment.result {
            Text("Result: \(result.summary)")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if let decision = result.decision {
                let helpedLabel = result.helped == true ? "Helped" : (result.helped == false ? "Didn’t help" : "Unrated")
                let confidenceDeltaText = {
                    if let before = result.confidenceBeforePercent, let after = result.confidenceAfterPercent {
                        return " • Recommendation confidence \(before)%->\(after)%"
                    }
                    return ""
                }()
                Text("Decision: \(decision.title) • \(helpedLabel)\(confidenceDeltaText)")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .monospacedDigit()
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
        .accessibilityLabel("Selected trend point readiness \(readinessValue) percent, load \(loadValue) percent, consistency \(consistencyValue) percent")
    }

    private func readoutPill(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
            Text("\(value)%")
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

    private func wakeAnchorPing(for experiment: Experiment) -> some View {
        let suggestedMet = selectedWakeAnchorAutoFill?.suggestedMet
        return InsetSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("Wake anchor met?")
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(.primary)

                MindSenseSummaryDisclosureText(
                    summary: "One daily ping: tap Yes or No.",
                    detail: "If No, add an optional reason tag.",
                    collapsedLabel: "How this check-in works",
                    expandedLabel: "Hide check-in details"
                )

                if let autoFill = selectedWakeAnchorAutoFill {
                    Text(
                        "Auto-filled from sleep start/end \(sleepWindowLabel(for: autoFill)). Suggested: \(autoFill.suggestedMet ? "Yes" : "No")."
                    )
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Button("Yes") {
                        submitWakeAnchorCheckIn(met: true, experiment: experiment)
                    }
                    .accessibilityIdentifier("data_wake_anchor_yes_cta")
                    .buttonStyle(
                        MindSenseButtonStyle(
                            hierarchy: suggestedMet == false ? .secondary : .primary,
                            minHeight: 44
                        )
                    )

                    Button("No") {
                        submitWakeAnchorCheckIn(met: false, experiment: experiment)
                    }
                    .accessibilityIdentifier("data_wake_anchor_no_cta")
                    .buttonStyle(
                        MindSenseButtonStyle(
                            hierarchy: suggestedMet == false ? .primary : .secondary,
                            minHeight: 44
                        )
                    )
                }

                Text("If No, optional reason")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(ExperimentMissReason.allCases) { reason in
                        Button {
                            selectedWakeAnchorMissReason = selectedWakeAnchorMissReason == reason ? nil : reason
                            store.triggerHaptic(intent: .selection)
                        } label: {
                            PillChip(
                                label: reason.title,
                                state: selectedWakeAnchorMissReason == reason ? .selected : .unselected
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("data_wake_anchor_reason_\(reason.rawValue)")
                    }
                }
            }
        }
    }

    private func sleepWindowLabel(for autoFill: ExperimentWakeAnchorAutoFill) -> String {
        let start = autoFill.sleepStartAt.formatted(date: .omitted, time: .shortened)
        let end = autoFill.sleepEndAt.formatted(date: .omitted, time: .shortened)
        return "\(start)-\(end)"
    }

    private var coverageSummaryLine: String {
        if let first = lowCoverageReasons.first {
            return "Coverage is low: \(first)."
        }
        return "Coverage is low because recent signal collection is incomplete."
    }

    private func submitWakeAnchorCheckIn(met: Bool, experiment: Experiment) {
        let usedAutoFill = selectedWakeAnchorAutoFill != nil
        let reason = met ? nil : selectedWakeAnchorMissReason
        store.logExperimentDay(
            experiment.id,
            wakeAnchorMet: met,
            missReason: reason,
            usedAutoFill: usedAutoFill
        )
        var metadata = ["id": experiment.id.uuidString]
        if let reason {
            metadata["reason"] = reason.rawValue
        }
        metadata["source"] = usedAutoFill ? "auto_fill" : "manual"
        store.track(
            event: .primaryCTATapped,
            surface: .data,
            action: met ? "wake_anchor_yes" : "wake_anchor_no",
            metadata: metadata
        )
        selectedWakeAnchorMissReason = nil
        store.triggerHaptic(intent: .primary)
    }

    @ViewBuilder
    private func selectedExperimentDetailSection(_ selectedExperiment: Experiment) -> some View {
        RecommendationRationaleView(
            estimate: selectedExperiment.estimate,
            whyRecommended: "\(selectedExperiment.rationale) Next: \(selectedExperiment.nextStep)"
        )

        if selectedExperiment.status == .active,
           selectedExperiment.checkInDaysCompleted < selectedExperiment.durationDays,
           isWakeAnchorExperiment(selectedExperiment) {
            wakeAnchorPing(for: selectedExperiment)
        }

        if experimentCTA != nil {
            MindSenseSummaryDisclosureText(
                summary: "Use the sticky action below for the next experiment step.",
                detail: "We only pin a bottom CTA when the selected experiment has one clear next action, which reduces duplicate buttons inside the card stack.",
                collapsedLabel: "Why the sticky action is shown",
                expandedLabel: "Hide CTA rationale"
            )
        }
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
            summary: completionSummary,
            helped: completionHelped,
            decision: completionDecision
        )
        completionShift = 1
        completionSummary = ""
        completionHelped = true
        completionDecision = .keep
        showCompletionSheet = false
        store.triggerHaptic(intent: .success)
    }

    @ViewBuilder
    private var recoveryAnchorPlannerBlock: some View {
        InsetSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Turn insight into a plan",
                    subtitle: "Choose one non-negotiable recovery anchor, schedule it, and track adherence.",
                    icon: "checklist"
                )
            )

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Choose anchor type")
                        .font(MindSenseTypography.bodyStrong)
                    Picker("Anchor type", selection: recoveryAnchorTypeBinding) {
                        ForEach(RecoveryAnchorType.allCases) { anchorType in
                            Label(anchorType.title, systemImage: anchorType.icon)
                                .tag(anchorType)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack(spacing: 8) {
                        Image(systemName: recoveryAnchorType.icon)
                            .foregroundStyle(MindSensePalette.signalCool)
                        Text(recoveryAnchorType.title)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("2. Set schedule + reminder")
                        .font(MindSenseTypography.bodyStrong)
                    DatePicker(
                        "Anchor time",
                        selection: recoveryAnchorScheduleBinding,
                        displayedComponents: .hourAndMinute
                    )
                    Toggle("Daily reminder", isOn: $recoveryAnchorReminderEnabled)
                        .font(MindSenseTypography.caption)
                    Text("Scheduled for \(recoveryAnchorTimeLabel).")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Button(recoveryAnchorPlanActive ? "Update anchor plan" : "Save anchor plan") {
                        saveRecoveryAnchorPlan(source: "data_trend_insight_anchor")
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 44))

                    if let schedule = recoveryAnchorNoMeetingSchedule {
                        Button("Add block") {
                            scheduleRecoveryWindowCalendarBlock(for: schedule)
                        }
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary, minHeight: 44))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("3. Track adherence")
                        .font(MindSenseTypography.bodyStrong)
                    Text(recoveryAnchorAdherenceLine)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(recoveryAnchorTrackedToday ? "Adherence tracked today" : "Track adherence") {
                        trackRecoveryAnchorAdherence()
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false, minHeight: 40))
                    .disabled(!recoveryAnchorPlanActive || recoveryAnchorTrackedToday)
                }
            }
        }
    }

    private func launchRecommendedAction(source: String) {
        let recommendation = store.primaryRecommendation
        store.openRegulatePreset(recommendation.preset, startImmediately: true, source: source)
        store.track(
            event: .primaryCTATapped,
            surface: .data,
            action: "start_mapped_\(recommendation.preset.rawValue)",
            metadata: ["source": source]
        )
        store.triggerHaptic(intent: .primary)
    }

    private func saveRecoveryAnchorPlan(source: String) {
        recoveryAnchorPlanActive = true

        if recoveryAnchorReminderEnabled {
            scheduleRecoveryAnchorReminder(source: source)
        } else {
            let identifiers = RecoveryAnchorType.allCases.map(\.notificationIdentifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            store.showActionFeedback(.saved, detail: "\(recoveryAnchorType.title) anchor saved for \(recoveryAnchorTimeLabel).")
            store.track(
                event: .actionCompleted,
                surface: .data,
                action: "recovery_anchor_plan_saved",
                metadata: [
                    "source": source,
                    "anchor": recoveryAnchorType.rawValue,
                    "reminder": "off",
                    "time": recoveryAnchorTimeLabel
                ]
            )
            store.triggerHaptic(intent: .success)
        }
    }

    private func trackRecoveryAnchorAdherence() {
        guard recoveryAnchorPlanActive, !recoveryAnchorTrackedToday else { return }
        recoveryAnchorAdherenceCount += 1
        recoveryAnchorLastTrackedDay = recoveryAnchorTrackingDayStamp
        store.showActionFeedback(.saved, detail: "\(recoveryAnchorType.title) anchor adherence logged.")
        store.track(
            event: .actionCompleted,
            surface: .data,
            action: "recovery_anchor_adherence_logged",
            metadata: [
                "anchor": recoveryAnchorType.rawValue,
                "total": "\(recoveryAnchorAdherenceCount)"
            ]
        )
        store.triggerHaptic(intent: .success)
    }

    private func scheduleRecoveryAnchorReminder(source: String) {
        Task {
            do {
                let center = UNUserNotificationCenter.current()
                let granted = try await requestNotificationAuthorization(center: center)
                guard granted else {
                    await MainActor.run {
                        store.showActionFeedback(.updated, detail: "Notification access is required to schedule the anchor reminder.")
                        store.track(event: .secondaryActionTapped, surface: .data, action: "recovery_anchor_reminder_denied")
                        store.triggerHaptic(intent: .warning)
                    }
                    return
                }

                let content = UNMutableNotificationContent()
                content.title = "\(recoveryAnchorType.title) anchor"
                content.body = recoveryAnchorType.reminderBody
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: DateComponents(hour: recoveryAnchorHour, minute: recoveryAnchorMinute),
                    repeats: true
                )
                let request = UNNotificationRequest(
                    identifier: recoveryAnchorType.notificationIdentifier,
                    content: content,
                    trigger: trigger
                )

                let allAnchorIdentifiers = RecoveryAnchorType.allCases.map(\.notificationIdentifier)
                center.removePendingNotificationRequests(withIdentifiers: allAnchorIdentifiers)
                try await addNotificationRequest(center: center, request: request)

                await MainActor.run {
                    store.showActionFeedback(.saved, detail: "\(recoveryAnchorType.title) anchor saved with a daily reminder at \(recoveryAnchorTimeLabel).")
                    store.track(
                        event: .actionCompleted,
                        surface: .data,
                        action: "recovery_anchor_plan_saved",
                        metadata: [
                            "source": source,
                            "anchor": recoveryAnchorType.rawValue,
                            "reminder": "on",
                            "time": recoveryAnchorTimeLabel
                        ]
                    )
                    store.triggerHaptic(intent: .success)
                }
            } catch {
                await MainActor.run {
                    store.showActionFeedback(.updated, detail: "Unable to schedule the anchor reminder right now.")
                    store.track(
                        event: .secondaryActionTapped,
                        surface: .data,
                        action: "recovery_anchor_reminder_error",
                        metadata: ["reason": error.localizedDescription]
                    )
                    store.triggerHaptic(intent: .warning)
                }
            }
        }
    }

    private func scheduleRecoveryWindowCalendarBlock(for schedule: RecoveryWindowSchedule) {
        Task {
            do {
                let eventStore = EKEventStore()
                let granted = try await requestCalendarAccess(eventStore: eventStore)
                guard granted else {
                    await MainActor.run {
                        store.showActionFeedback(.updated, detail: "Calendar access is required to add a recurring block.")
                        store.track(event: .secondaryActionTapped, surface: .data, action: "recovery_window_calendar_denied")
                        store.triggerHaptic(intent: .warning)
                    }
                    return
                }

                guard let defaultCalendar = eventStore.defaultCalendarForNewEvents,
                      let occurrence = schedule.nextOccurrence else {
                    await MainActor.run {
                        store.showActionFeedback(.updated, detail: "Unable to prepare a calendar block for this window.")
                        store.track(event: .secondaryActionTapped, surface: .data, action: "recovery_window_calendar_unavailable")
                        store.triggerHaptic(intent: .warning)
                    }
                    return
                }

                let event = EKEvent(eventStore: eventStore)
                event.calendar = defaultCalendar
                event.title = "MindSense Recovery Window"
                event.startDate = occurrence.start
                event.endDate = occurrence.end
                event.notes = "Protected recurring block based on your best recovery window."
                event.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil))

                await MainActor.run {
                    recoveryWindowCalendarDraft = .init(eventStore: eventStore, event: event)
                    store.track(
                        event: .secondaryActionTapped,
                        surface: .data,
                        action: "recovery_window_calendar_opened",
                        metadata: ["start": schedule.startTimeLabel]
                    )
                    store.triggerHaptic(intent: .selection)
                }
            } catch {
                await MainActor.run {
                    store.showActionFeedback(.updated, detail: "Calendar access failed. Check Calendar permissions in Settings.")
                    store.track(
                        event: .secondaryActionTapped,
                        surface: .data,
                        action: "recovery_window_calendar_error",
                        metadata: ["reason": error.localizedDescription]
                    )
                    store.triggerHaptic(intent: .warning)
                }
            }
        }
    }

    private func scheduleRecoveryWindowReminder(for schedule: RecoveryWindowSchedule) {
        Task {
            do {
                let center = UNUserNotificationCenter.current()
                let granted = try await requestNotificationAuthorization(center: center)
                guard granted else {
                    await MainActor.run {
                        store.showActionFeedback(.updated, detail: "Notification access is required to schedule this reminder.")
                        store.track(event: .secondaryActionTapped, surface: .data, action: "recovery_window_reminder_denied")
                        store.triggerHaptic(intent: .warning)
                    }
                    return
                }

                let content = UNMutableNotificationContent()
                content.title = "Recovery window started"
                content.body = "Protect this block for focused work or restoration."
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: schedule.startDateComponents,
                    repeats: true
                )
                let request = UNNotificationRequest(
                    identifier: "mindsense.recovery_window_start",
                    content: content,
                    trigger: trigger
                )

                center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
                try await addNotificationRequest(center: center, request: request)

                await MainActor.run {
                    recoveryWindowNotificationsEnabled = true
                    store.showActionFeedback(.saved, detail: "Daily reminder set for \(schedule.startTimeLabel).")
                    store.track(
                        event: .actionCompleted,
                        surface: .data,
                        action: "recovery_window_reminder_scheduled",
                        metadata: ["time": schedule.startTimeLabel]
                    )
                    store.triggerHaptic(intent: .success)
                }
            } catch {
                await MainActor.run {
                    store.showActionFeedback(.updated, detail: "Unable to schedule the reminder right now.")
                    store.track(
                        event: .secondaryActionTapped,
                        surface: .data,
                        action: "recovery_window_reminder_error",
                        metadata: ["reason": error.localizedDescription]
                    )
                    store.triggerHaptic(intent: .warning)
                }
            }
        }
    }

    private func handleRecoveryCalendarEditorAction(_ action: EKEventEditViewAction) {
        recoveryWindowCalendarDraft = nil

        switch action {
        case .saved:
            store.showActionFeedback(.saved, detail: "Recurring calendar block added.")
            store.track(event: .actionCompleted, surface: .data, action: "recovery_window_calendar_saved")
            store.triggerHaptic(intent: .success)
        case .canceled:
            store.track(event: .secondaryActionTapped, surface: .data, action: "recovery_window_calendar_cancelled")
        case .deleted:
            store.track(event: .secondaryActionTapped, surface: .data, action: "recovery_window_calendar_deleted")
        @unknown default:
            break
        }
    }

    private func requestCalendarAccess(eventStore: EKEventStore) async throws -> Bool {
        try await eventStore.requestFullAccessToEvents()
    }

    private func requestNotificationAuthorization(center: UNUserNotificationCenter) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func addNotificationRequest(center: UNUserNotificationCenter, request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
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
        submode = .patterns
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

    private func trendMetricValue(for point: TrendPoint) -> Double {
        switch selectedSignal {
        case .readiness:
            return point.readiness
        case .load:
            return point.load
        case .consistency:
            return inferredConsistency(for: point)
        }
    }

    private func inferredConsistency(for point: TrendPoint) -> Double {
        let spread = abs(point.readiness - point.load)
        return max(45, 92 - spread)
    }

    private func smoothedTrendPoints(_ points: [TrendPoint], smoothing: TrendSmoothing) -> [TrendPoint] {
        let radius = smoothing.radius
        guard radius > 0, points.count > 2 else { return points }

        return points.enumerated().map { index, point in
            let lower = max(0, index - radius)
            let upper = min(points.count - 1, index + radius)
            let window = points[lower...upper]
            let count = Double(window.count)
            let readiness = window.reduce(0) { $0 + $1.readiness } / count
            let load = window.reduce(0) { $0 + $1.load } / count
            return TrendPoint(index: point.index, time: point.time, readiness: readiness, load: load)
        }
    }

    private func alignedTrendPoints(_ source: [TrendPoint], to target: [TrendPoint]) -> [TrendPoint] {
        guard !source.isEmpty, !target.isEmpty else { return [] }
        if source.count == target.count {
            return zip(target, source).enumerated().map { offset, pair in
                TrendPoint(index: offset, time: pair.0.time, readiness: pair.1.readiness, load: pair.1.load)
            }
        }

        let sourceCount = source.count
        let targetCount = target.count
        return target.enumerated().map { targetIndex, targetPoint in
            let progress = targetCount <= 1 ? 0 : Double(targetIndex) / Double(targetCount - 1)
            let sourcePosition = progress * Double(max(sourceCount - 1, 0))
            let lowerIndex = Int(sourcePosition.rounded(.down))
            let upperIndex = Int(sourcePosition.rounded(.up))
            let weight = sourcePosition - Double(lowerIndex)
            let lowerPoint = source[min(max(lowerIndex, 0), sourceCount - 1)]
            let upperPoint = source[min(max(upperIndex, 0), sourceCount - 1)]
            let readiness = lowerPoint.readiness + (upperPoint.readiness - lowerPoint.readiness) * weight
            let load = lowerPoint.load + (upperPoint.load - lowerPoint.load) * weight
            return TrendPoint(index: targetIndex, time: targetPoint.time, readiness: readiness, load: load)
        }
    }

    private func trendComparisonPillText(for summary: TrendComparisonSummary) -> String {
        let directionSymbol: String
        switch selectedSignal {
        case .readiness, .consistency:
            directionSymbol = summary.delta >= 0 ? "+" : ""
        case .load:
            directionSymbol = summary.delta <= 0 ? "" : "+"
        }
        return "Vs prior 7D \(directionSymbol)\(Int(summary.delta.rounded()))%"
    }

    private func trendComparisonDetailText(for summary: TrendComparisonSummary) -> String {
        let current = summary.currentAverage.formatted(.number.precision(.fractionLength(1)))
        let prior = summary.previousAverage.formatted(.number.precision(.fractionLength(1)))
        let deltaPrefix = summary.delta >= 0 ? "+" : ""
        let delta = "\(deltaPrefix)\(summary.delta.formatted(.number.precision(.fractionLength(1))))%"
        let pctPrefix = summary.percentDelta >= 0 ? "+" : ""
        let pctValue = "\(pctPrefix)\(summary.percentDelta.formatted(.number.precision(.fractionLength(0))))%"
        return "Current avg \(current)% vs prior \(prior)% (\(delta), \(pctValue))"
    }

    private func capturedDays(from qualityPercent: Int) -> Int {
        let bounded = max(0, min(100, qualityPercent))
        return Int((Double(bounded) * 7.0 / 100.0).rounded())
    }
}

private struct RecoveryWindowSchedule {
    let startTime: Date
    let endTime: Date

    var startTimeLabel: String {
        startTime.formatted(date: .omitted, time: .shortened)
    }

    var startDateComponents: DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: startTime)
    }

    var nextOccurrence: (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        var startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        startComponents.year = calendar.component(.year, from: now)
        startComponents.month = calendar.component(.month, from: now)
        startComponents.day = calendar.component(.day, from: now)

        var endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        endComponents.year = calendar.component(.year, from: now)
        endComponents.month = calendar.component(.month, from: now)
        endComponents.day = calendar.component(.day, from: now)

        guard var nextStart = calendar.date(from: startComponents),
              var nextEnd = calendar.date(from: endComponents) else {
            return nil
        }

        if nextEnd <= nextStart {
            nextEnd = calendar.date(byAdding: .day, value: 1, to: nextEnd) ?? nextEnd
        }

        if nextStart <= now {
            nextStart = calendar.date(byAdding: .day, value: 1, to: nextStart) ?? nextStart
            nextEnd = calendar.date(byAdding: .day, value: 1, to: nextEnd) ?? nextEnd
        }

        return (start: nextStart, end: nextEnd)
    }
}

private struct RecoveryWindowCalendarDraft: Identifiable {
    let id = UUID()
    let eventStore: EKEventStore
    let event: EKEvent
}

private struct RecoveryWindowCalendarEditor: UIViewControllerRepresentable {
    let draft: RecoveryWindowCalendarDraft
    let onComplete: (EKEventEditViewAction) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = draft.eventStore
        controller.event = draft.event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        private let onComplete: (EKEventEditViewAction) -> Void

        init(onComplete: @escaping (EKEventEditViewAction) -> Void) {
            self.onComplete = onComplete
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            DispatchQueue.main.async {
                self.onComplete(action)
            }
        }
    }
}

private struct TrendFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var window: TrendWindow
    @Binding var comparePreviousWindow: Bool
    @Binding var smoothing: TrendSmoothing
    @Binding var dayFilter: TrendDayFilter
    @Binding var eventOverlays: Set<TrendEventOverlayType>
    let compareSupported: Bool
    let sharePayload: String
    let shareTitle: String

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

                    InsetSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            MindSenseSectionHeader(
                                model: .init(
                                    title: "Compare",
                                    subtitle: compareSupported
                                        ? "Compare current 7D pattern vs the prior 7D window."
                                        : "Previous-window compare is currently available on 7D.",
                                    icon: "arrow.left.arrow.right"
                                )
                            )

                            Toggle("Compare vs previous window", isOn: $comparePreviousWindow)
                                .disabled(!compareSupported)
                        }
                    }

                    InsetSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            MindSenseSectionHeader(
                                model: .init(
                                    title: "Smoothing",
                                    subtitle: "Light reduces noise; heavy emphasizes the baseline pattern.",
                                    icon: "waveform.path.ecg"
                                )
                            )

                            MindSenseSegmentedControl(
                                options: TrendSmoothing.allCases,
                                selection: $smoothing,
                                title: { $0.rawValue }
                            )
                        }
                    }

                    InsetSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            MindSenseSectionHeader(
                                model: .init(
                                    title: "Day filter",
                                    subtitle: "Compare weekday vs weekend behavior without changing the metric focus.",
                                    icon: "calendar"
                                )
                            )

                            MindSenseSegmentedControl(
                                options: TrendDayFilter.allCases,
                                selection: $dayFilter,
                                title: { $0.rawValue }
                            )
                        }
                    }

                    InsetSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            MindSenseSectionHeader(
                                model: .init(
                                    title: "Events overlay",
                                    subtitle: "Plot workouts, check-ins, and experiments directly on the chart timeline.",
                                    icon: "sparkles"
                                )
                            )

                            ForEach(TrendEventOverlayType.allCases) { overlayType in
                                Toggle(isOn: binding(for: overlayType)) {
                                    HStack(spacing: 8) {
                                        Image(systemName: overlayType.icon)
                                            .foregroundStyle(overlayType.tint)
                                        Text(overlayType.title)
                                            .font(MindSenseTypography.bodyStrong)
                                    }
                                }
                            }
                        }
                    }

                    InsetSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            MindSenseSectionHeader(
                                model: .init(
                                    title: "Export / share",
                                    subtitle: "Share the chart summary plus filtered trend data as CSV.",
                                    icon: "square.and.arrow.up"
                                )
                            )

                            ShareLink(item: sharePayload) {
                                Label("Export chart data", systemImage: "square.and.arrow.up")
                                    .font(MindSenseTypography.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
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
            }
        }
        .mindSenseSheetPresentationChrome()
    }

    private func binding(for overlayType: TrendEventOverlayType) -> Binding<Bool> {
        Binding {
            eventOverlays.contains(overlayType)
        } set: { isEnabled in
            if isEnabled {
                eventOverlays.insert(overlayType)
            } else {
                eventOverlays.remove(overlayType)
            }
        }
    }
}

private struct DataTrendChart: View {
    let points: [TrendPoint]
    let comparisonPoints: [TrendPoint]?
    let overlayEvents: [TrendOverlayEvent]
    let selectedSignal: SignalFocus
    @Binding var selectedPoint: TrendPoint?

    var body: some View {
        Chart {
            if let comparisonPoints {
                ForEach(comparisonPoints) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Prior \(selectedSignal.metric.title)", metricValue(for: point))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(signalColor.opacity(0.42))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [7, 5]))
                }
            }

            ForEach(points) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value(selectedSignal.metric.title, metricValue(for: point))
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(signalColor)
                .lineStyle(StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round))

                AreaMark(
                    x: .value("Time", point.time),
                    y: .value(selectedSignal.metric.title, metricValue(for: point))
                )
                .foregroundStyle(signalColor.opacity(0.14))
            }

            ForEach(overlayEvents) { event in
                PointMark(
                    x: .value("Event time", event.time),
                    y: .value("Event overlay lane", overlayLaneY(for: event.type))
                )
                .symbolSize(42)
                .foregroundStyle(event.type.tint)
                .opacity(0.92)
            }

            if let selectedPoint {
                RuleMark(x: .value("Selected", selectedPoint.time))
                    .foregroundStyle(MindSensePalette.strokeStrong)

                PointMark(
                    x: .value("Selected point", selectedPoint.time),
                    y: .value("Selected value", metricValue(for: selectedPoint))
                )
                .foregroundStyle(signalColor)
            }
        }
        .chartLegend(position: .top) {
            HStack(spacing: 12) {
                legendItem(title: selectedSignal.metric.title, color: signalColor)
                if comparisonPoints != nil {
                    legendItem(title: "Prior window", color: signalColor.opacity(0.42))
                }
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
            AxisMarks(position: .leading, values: .stride(by: 20)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let number = value.as(Double.self) {
                        Text("\(Int(number.rounded()))%")
                    }
                }
            }
        }
        .chartYScale(domain: 0 ... 100)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(selectedSignal.metric.title) trend chart")
        .accessibilityValue(chartVoiceOverSummary)
        .accessibilityHint(points.isEmpty ? "No chart data available." : "Summarizes the visible trend. Drag on the chart to inspect points visually.")
    }

    private var signalColor: Color {
        switch selectedSignal {
        case .readiness:
            return MindSensePalette.success
        case .load:
            return MindSensePalette.warning
        case .consistency:
            return MindSensePalette.signalCool
        }
    }

    private func metricValue(for point: TrendPoint) -> Double {
        switch selectedSignal {
        case .readiness:
            return point.readiness
        case .load:
            return point.load
        case .consistency:
            return inferredConsistency(for: point)
        }
    }

    private func inferredConsistency(for point: TrendPoint) -> Double {
        let spread = abs(point.readiness - point.load)
        return max(45, 92 - spread)
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

    private func overlayLaneY(for type: TrendEventOverlayType) -> Double {
        switch type {
        case .workouts:
            return 96
        case .checkIns:
            return 92
        case .experiments:
            return 88
        }
    }

    private var chartVoiceOverSummary: String {
        guard let first = points.first, let last = points.last else {
            return "No data available for the selected window."
        }

        let startValue = Int(metricValue(for: first).rounded())
        let endValue = Int(metricValue(for: last).rounded())
        let dayCount = visibleDayCount

        let directionPhrase: String
        if endValue > startValue {
            directionPhrase = "increased"
        } else if endValue < startValue {
            directionPhrase = "decreased"
        } else {
            directionPhrase = "stayed the same"
        }

        var fragments: [String] = [
            "\(selectedSignal.metric.title) \(directionPhrase) from \(startValue) to \(endValue) percent over \(dayCount) \(dayCount == 1 ? "day" : "days")."
        ]

        if comparisonPoints != nil {
            fragments.append("Prior window comparison is shown.")
        }

        if !overlayEvents.isEmpty {
            fragments.append("\(overlayEvents.count) event \(overlayEvents.count == 1 ? "overlay" : "overlays") visible.")
        }

        if let selectedPoint {
            let selectedValue = Int(metricValue(for: selectedPoint).rounded())
            fragments.append("Selected point \(selectedPoint.time.formatted(.dateTime.month().day())): \(selectedValue) percent.")
        }

        return fragments.joined(separator: " ")
    }

    private var visibleDayCount: Int {
        guard let first = points.first?.time, let last = points.last?.time else { return 0 }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: first)
        let end = calendar.startOfDay(for: last)
        let span = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(1, span + 1)
    }
}

private struct ExperimentCompletionSheet: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @Binding var perceivedShift: Double
    @Binding var summary: String
    @Binding var helped: Bool
    @Binding var decision: ExperimentOutcomeDecision
    let evaluation: ExperimentEvaluationPreview
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
                            what: "Evaluate outcome + decide keep/modify/stop",
                            why: "Close the loop with a concrete decision",
                            expectedEffect: "Higher-quality next recommendations",
                            time: "About 1 min"
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Did it help?")
                                .font(MindSenseTypography.bodyStrong)
                            Picker("Did it help?", selection: $helped) {
                                Text("Yes").tag(true)
                                Text("No").tag(false)
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Before/after deltas")
                                .font(MindSenseTypography.bodyStrong)

                            deltaLine(
                                label: "Readiness",
                                before: evaluation.beforeMetrics.readiness,
                                after: evaluation.afterMetrics.readiness
                            )
                            deltaLine(
                                label: "Load",
                                before: evaluation.beforeMetrics.load,
                                after: evaluation.afterMetrics.load
                            )
                            deltaLine(
                                label: "Consistency",
                                before: evaluation.beforeMetrics.consistency,
                                after: evaluation.afterMetrics.consistency
                            )

                            let confidenceBeforeLabel = confidenceLabel(for: evaluation.confidenceBeforePercent)
                            let confidenceAfterLabel = confidenceLabel(for: evaluation.confidenceAfterPercent)
                            Text(
                                "Recommendation confidence: \(evaluation.confidenceBeforePercent)% (\(confidenceBeforeLabel)) -> \(evaluation.confidenceAfterPercent)% (\(confidenceAfterLabel))"
                            )
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Decide next")
                                .font(MindSenseTypography.bodyStrong)
                            Picker("Decide next", selection: $decision) {
                                ForEach(ExperimentOutcomeDecision.allCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

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

    private func deltaLine(label: String, before: Int, after: Int) -> some View {
        let delta = after - before
        let deltaText = delta == 0 ? "0" : (delta > 0 ? "+\(delta)" : "\(delta)")
        return HStack(spacing: 8) {
            Text(label)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(before) -> \(after) (\(deltaText))")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func confidenceLabel(for percent: Int) -> String {
        if percent >= 82 {
            return "Strong"
        }
        if percent >= 62 {
            return "Moderate"
        }
        return "Emerging"
    }
}
