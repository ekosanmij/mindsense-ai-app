import Foundation
import SwiftUI
import UIKit
import Combine

enum AppLaunchState {
    case launching
    case signedOut
    case needsOnboarding
    case ready
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum BannerSeverity {
    case success
    case info
    case warning
    case error

    var color: Color {
        switch self {
        case .success:
            return MindSensePalette.success
        case .info:
            return MindSensePalette.accent
        case .warning:
            return MindSensePalette.warning
        case .error:
            return .red
        }
    }
}

struct AppBanner: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let detail: String
    let severity: BannerSeverity
}

struct AuthSession: Codable {
    let email: String
    let appleUserID: String?
    let displayName: String?

    init(email: String, appleUserID: String? = nil, displayName: String? = nil) {
        self.email = email
        self.appleUserID = appleUserID
        self.displayName = displayName
    }
}

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case connectHealth
    case notifications
    case baseline
    case firstCheckIn

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .connectHealth:
            return "Connect Health"
        case .notifications:
            return "Enable Notifications"
        case .baseline:
            return "Start Baseline"
        case .firstCheckIn:
            return "First Check-in"
        }
    }

    var icon: String {
        switch self {
        case .connectHealth:
            return "waveform.path.ecg"
        case .notifications:
            return "bell.badge"
        case .baseline:
            return "chart.line.uptrend.xyaxis"
        case .firstCheckIn:
            return "checkmark.seal.fill"
        }
    }

    var benefit: String {
        switch self {
        case .connectHealth:
            return "Personalized load/readiness data guidance."
        case .notifications:
            return "Timely downshift nudges and weekly review reminders."
        case .baseline:
            return "Start 7-14 day calibration for stable trend confidence."
        case .firstCheckIn:
            return "Unlock your daily guidance flow with your first status capture."
        }
    }

    var cta: String {
        switch self {
        case .connectHealth:
            return "Grant Health Permission"
        case .notifications:
            return "Grant Notification Permission"
        case .baseline:
            return "Start Baseline"
        case .firstCheckIn:
            return "Complete Check-in"
        }
    }

    var isRequiredForActivation: Bool {
        switch self {
        case .baseline, .firstCheckIn:
            return true
        case .connectHealth, .notifications:
            return false
        }
    }

    static var activationSteps: [OnboardingStep] {
        allCases.filter(\.isRequiredForActivation)
    }
}

struct OnboardingProgress: Codable {
    var completedRaw: [Int] = []
    var baselineStart: Date?
    var firstCheckInValue: Int?

    var completedSet: Set<Int> {
        get { Set(completedRaw) }
        set { completedRaw = Array(newValue).sorted() }
    }

    var completedCount: Int {
        completedSet.count
    }

    mutating func markComplete(_ step: OnboardingStep) {
        var set = completedSet
        set.insert(step.rawValue)
        completedSet = set
    }

    func isComplete(_ step: OnboardingStep) -> Bool {
        completedSet.contains(step.rawValue)
    }

    var isFullyComplete: Bool {
        OnboardingStep.activationSteps.allSatisfy { isComplete($0) }
    }
}

enum AppIA {
    // Canonical IA map. UI labels, specs, tests, and analytics should reference only this set.
    static let today = "Today"
    static let regulate = "Regulate"
    static let data = "Data"
    static let community = "Community"
    static let settings = "Settings"
    static let qaTools = "QA Tools"
}

enum AppFeatureFlags {
    static var demoControlsEnabled: Bool {
        false
    }

    static var communityEnabled: Bool { false }
    static var kpiScorecardEnabled: Bool { false }
    static var guidedPathEnabled: Bool { false }
}

enum MainTab: Int, CaseIterable, Hashable {
    case today
    case regulate
    case data

    var title: String {
        switch self {
        case .today:
            return AppIA.today
        case .regulate:
            return AppIA.regulate
        case .data:
            return AppIA.data
        }
    }

    var icon: String {
        switch self {
        case .today:
            return "sun.max.circle.fill"
        case .regulate:
            return "waveform.path.ecg"
        case .data:
            return "chart.xyaxis.line"
        }
    }
}

enum UXSurface: String {
    case intro
    case auth
    case onboarding
    case today
    case regulate
    case data
    case community
    case settings
    case global
}

enum UXEvent: String {
    case appOpened = "app_opened"
    case screenView = "screen_view"
    case navigationTabChanged = "navigation_tab_changed"
    case primaryCTATapped = "primary_cta_tapped"
    case secondaryActionTapped = "secondary_action_tapped"
    case actionCompleted = "action_completed"
    case chartInteraction = "chart_interaction"
    case settingAutosaved = "setting_autosaved"
    case onboardingCompleted = "onboarding_completed"
    case onboardingStepCompleted = "onboarding_step_completed"
    case onboardingDroppedOff = "onboarding_drop_off"
    case sessionStarted = "session_started"
    case sessionOutcomeRecorded = "session_outcome_recorded"
    case experimentStarted = "experiment_started"
    case experimentDayLogged = "experiment_day_logged"
    case experimentCompleted = "experiment_completed"
    case paywallPresented = "paywall_presented"
    case paywallDismissed = "paywall_dismissed"
    case kpiReviewed = "kpi_reviewed"
}

enum MindSenseHapticIntent {
    case primary
    case selection
    case success
    case warning
    case error
}

enum RegulatePresetID: String, CaseIterable, Codable {
    case calmNow = "calm_now"
    case focusPrep = "focus_prep"
    case sleepDownshift = "sleep_downshift"

    var title: String {
        switch self {
        case .calmNow:
            return "Calm now"
        case .focusPrep:
            return "Focus prep"
        case .sleepDownshift:
            return "Sleep downshift"
        }
    }
}

enum CoreScreenID: String, CaseIterable, Identifiable {
    case today
    case regulate
    case data

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return AppIA.today
        case .regulate:
            return AppIA.regulate
        case .data:
            return AppIA.data
        }
    }
}

enum ActionFeedbackVerb {
    case saved
    case updated
    case applied

    var title: String {
        switch self {
        case .saved:
            return "Saved"
        case .updated:
            return "Updated"
        case .applied:
            return "Applied"
        }
    }

    var severity: BannerSeverity {
        switch self {
        case .saved:
            return .success
        case .updated:
            return .success
        case .applied:
            return .info
        }
    }
}

struct DemoMetricSnapshot: Codable, Equatable {
    var load: Int
    var readiness: Int
    var consistency: Int
}

struct DemoMetricDelta {
    let load: Int
    let readiness: Int
    let consistency: Int

    static let zero = DemoMetricDelta(load: 0, readiness: 0, consistency: 0)

    var isZero: Bool {
        load == 0 && readiness == 0 && consistency == 0
    }
}

struct DemoCheckInDeltaSummary {
    let baselineTitle: String
    let baselineTimestamp: Date
    let loadDelta: Int
    let readinessDelta: Int
    let consistencyDelta: Int
    let explanation: String
}

struct DemoWeeklySummary {
    let wins: [String]
    let risks: [String]
    let nextBestAction: String
}

enum DataTrendDirection {
    case up
    case down
    case flat
}

struct DataSignalTrendTile: Identifiable {
    let id: String
    let title: String
    let value: String
    let deltaText: String
    let direction: DataTrendDirection
    let linkedFocus: SignalFocus
}

struct DemoWhatIsWorkingSummary {
    let topProtocol: String
    let topTrigger: String
    let bestRecoveryWindow: String
}

enum DemoEventKind: String, Codable, CaseIterable {
    case scenario
    case checkIn
    case reflection
    case session
    case experiment
    case system
}

struct DemoEventRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let title: String
    let detail: String
    let kind: DemoEventKind
    let metricSnapshot: DemoMetricSnapshot?
    let demoDay: Int?
}

struct DemoSavedInsight: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let scenario: DemoScenario
    let title: String
    let detail: String
}

struct DemoRecommendation: Codable, Equatable {
    let preset: RegulatePresetID
    let what: String
    let why: String
    let expectedEffect: String
    let timeMinutes: Int

    var summaryLine: String {
        "What: \(what) Why: \(why) Expected effect: \(expectedEffect) Time: \(timeMinutes) min."
    }
}

struct DemoRegulatePreset: Identifiable, Codable, Equatable {
    let id: RegulatePresetID
    let title: String
    let subtitle: String
    let durationMinutes: Int
    let expectedEffect: String
    let whyNow: String
    let protocolSteps: [String]
    let icon: String

    var durationLabel: String {
        "\(durationMinutes) min"
    }

    var durationSeconds: Int {
        durationMinutes * 60
    }
}

enum DemoScenario: String, CaseIterable, Codable, Identifiable {
    case highStressDay
    case balancedDay
    case recoveryWeek

    var id: String { rawValue }

    var title: String {
        switch self {
        case .highStressDay:
            return "High Stress Day"
        case .balancedDay:
            return "Balanced Day"
        case .recoveryWeek:
            return "Recovery Week"
        }
    }

    var subtitle: String {
        switch self {
        case .highStressDay:
            return "Higher volatility, tighter recovery windows."
        case .balancedDay:
            return "Steady rhythm with manageable load."
        case .recoveryWeek:
            return "Recovery-first rhythm with lower daily strain."
        }
    }

    var defaultDay: Int {
        switch self {
        case .highStressDay:
            return 11
        case .balancedDay:
            return 7
        case .recoveryWeek:
            return 5
        }
    }

    var confidenceBase: Double {
        switch self {
        case .highStressDay:
            return 0.76
        case .balancedDay:
            return 0.84
        case .recoveryWeek:
            return 0.89
        }
    }

    var baseMetrics: DemoMetricSnapshot {
        switch self {
        case .highStressDay:
            return .init(load: 82, readiness: 56, consistency: 62)
        case .balancedDay:
            return .init(load: 50, readiness: 74, consistency: 78)
        case .recoveryWeek:
            return .init(load: 40, readiness: 83, consistency: 87)
        }
    }

    var primaryRecommendation: DemoRecommendation {
        switch self {
        case .highStressDay:
            return .init(
                preset: .calmNow,
                what: "Run Calm now before the next deadline block.",
                why: "Load is climbing faster than readiness reserve this afternoon.",
                expectedEffect: "Lower somatic tension and reduce near-term load by 5 to 8 points.",
                timeMinutes: 3
            )
        case .balancedDay:
            return .init(
                preset: .focusPrep,
                what: "Run Focus prep before your longest concentration block.",
                why: "Readiness is elevated and stable, which is your best leverage window.",
                expectedEffect: "Improve sustained attention and protect readiness through late afternoon.",
                timeMinutes: 5
            )
        case .recoveryWeek:
            return .init(
                preset: .sleepDownshift,
                what: "Run Sleep downshift before evening wind-down.",
                why: "Recovery signals are improving and a stable evening routine compounds gains.",
                expectedEffect: "Reduce late arousal and improve overnight recovery consistency.",
                timeMinutes: 8
            )
        }
    }

    var insightLine: String {
        switch self {
        case .highStressDay:
            return "Load is rising faster than readiness reserve."
        case .balancedDay:
            return "Readiness and load are balanced with room for precision gains."
        case .recoveryWeek:
            return "Recovery is leading. Protect it with consistent low-friction routines."
        }
    }

    var narrative: String {
        switch self {
        case .highStressDay:
            return "Your strongest opportunity is short pre-emptive downshifts before pressure peaks."
        case .balancedDay:
            return "You can convert stable readiness into better output by timing demanding work earlier."
        case .recoveryWeek:
            return "Continue low-friction anchors. Compounding consistency is driving confidence up."
        }
    }
}

struct DemoScenarioProfile {
    let scenario: DemoScenario
    let primaryDrivers: [DriverImpact]
    let secondaryDrivers: [DriverImpact]
    let presets: [DemoRegulatePreset]
    let signalNarratives: [SignalFocus: String]

    static func make(for scenario: DemoScenario) -> DemoScenarioProfile {
        switch scenario {
        case .highStressDay:
            return .init(
                scenario: scenario,
                primaryDrivers: [
                    .init(id: "sleep_fragmentation", name: "Sleep fragmentation", detail: "3 awakenings", impact: 0.35),
                    .init(id: "deadline_density", name: "Deadline density", detail: "2 urgent deliverables", impact: 0.28),
                    .init(id: "late_caffeine", name: "Late caffeine", detail: "after 2 PM", impact: 0.17)
                ],
                secondaryDrivers: [
                    .init(id: "meeting_stack", name: "Meeting stack", detail: "4 back-to-back meetings", impact: 0.12),
                    .init(id: "hydration_drag", name: "Hydration drag", detail: "below target this morning", impact: 0.08)
                ],
                presets: [
                    .init(
                        id: .calmNow,
                        title: "Calm now",
                        subtitle: "Interrupt sharp load acceleration before the next pressure block.",
                        durationMinutes: 3,
                        expectedEffect: "Expected effect: lower physical strain within 10 to 15 minutes.",
                        whyNow: "Why now: this pattern shows repeated midday load spikes.",
                        protocolSteps: ["30s settling breath", "2m paced cycle", "30s body scan"],
                        icon: "wind"
                    ),
                    .init(
                        id: .focusPrep,
                        title: "Focus prep",
                        subtitle: "Stabilize attention before high-stakes task switching.",
                        durationMinutes: 5,
                        expectedEffect: "Expected effect: steadier concentration in the next work block.",
                        whyNow: "Why now: readiness is fragile, so structured focus entry helps prevent drift.",
                        protocolSteps: ["1m breath alignment", "2m visual focus lock", "2m intention reset"],
                        icon: "scope"
                    ),
                    .init(
                        id: .sleepDownshift,
                        title: "Sleep downshift",
                        subtitle: "Lower evening arousal after high-load days.",
                        durationMinutes: 8,
                        expectedEffect: "Expected effect: smoother transition to sleep onset tonight.",
                        whyNow: "Why now: high daily load increases late sympathetic activation risk.",
                        protocolSteps: ["2m slower exhale", "3m progressive release", "3m low-light unwind"],
                        icon: "moon.stars.fill"
                    )
                ],
                signalNarratives: [
                    .load: "Trend: high midday load volatility. Insight: pre-emptive downshifts should produce the fastest same-day effect.",
                    .readiness: "Trend: readiness drops after stacked pressure windows. Insight: protect short recovery breaks to preserve execution quality.",
                    .consistency: "Trend: routine variability is amplifying stress reactivity. Insight: one fixed anchor can restore predictability quickly."
                ]
            )
        case .balancedDay:
            return .init(
                scenario: scenario,
                primaryDrivers: [
                    .init(id: "moderate_meeting_load", name: "Meeting load", detail: "2 priority calls", impact: 0.24),
                    .init(id: "stable_sleep", name: "Sleep continuity", detail: "1 brief awakening", impact: 0.19),
                    .init(id: "training_response", name: "Training response", detail: "light recovery run", impact: 0.16)
                ],
                secondaryDrivers: [
                    .init(id: "caffeine_timing", name: "Caffeine timing", detail: "before noon", impact: 0.11),
                    .init(id: "screen_exposure", name: "Screen exposure", detail: "moderate evening use", impact: 0.08)
                ],
                presets: [
                    .init(
                        id: .calmNow,
                        title: "Calm now",
                        subtitle: "Quick reset before short stress bursts.",
                        durationMinutes: 3,
                        expectedEffect: "Expected effect: smoother transition between meetings.",
                        whyNow: "Why now: small resets protect balanced trajectories from drift.",
                        protocolSteps: ["30s settling breath", "2m paced cycle", "30s body scan"],
                        icon: "wind"
                    ),
                    .init(
                        id: .focusPrep,
                        title: "Focus prep",
                        subtitle: "Use your strongest readiness window for deep work.",
                        durationMinutes: 5,
                        expectedEffect: "Expected effect: stronger output consistency across one focused block.",
                        whyNow: "Why now: readiness is currently above trend baseline.",
                        protocolSteps: ["1m breath alignment", "2m visual focus lock", "2m intention reset"],
                        icon: "scope"
                    ),
                    .init(
                        id: .sleepDownshift,
                        title: "Sleep downshift",
                        subtitle: "Maintain evening recovery rhythm.",
                        durationMinutes: 8,
                        expectedEffect: "Expected effect: preserve overnight recovery gains.",
                        whyNow: "Why now: steady evenings maintain next-day readiness quality.",
                        protocolSteps: ["2m slower exhale", "3m progressive release", "3m low-light unwind"],
                        icon: "moon.stars.fill"
                    )
                ],
                signalNarratives: [
                    .load: "Trend: load is controlled with predictable midday elevations. Insight: short resets sustain this pattern.",
                    .readiness: "Trend: readiness is strongest in late morning. Insight: front-load cognitively demanding tasks.",
                    .consistency: "Trend: routines are mostly stable. Insight: maintain one non-negotiable recovery anchor."
                ]
            )
        case .recoveryWeek:
            return .init(
                scenario: scenario,
                primaryDrivers: [
                    .init(id: "sleep_rebound", name: "Sleep rebound", detail: "longer deep sleep window", impact: 0.28),
                    .init(id: "load_taper", name: "Load taper", detail: "lighter task density", impact: 0.23),
                    .init(id: "movement_consistency", name: "Movement consistency", detail: "daily low-intensity sessions", impact: 0.18)
                ],
                secondaryDrivers: [
                    .init(id: "evening_routine", name: "Evening routine", detail: "stable wind-down", impact: 0.12),
                    .init(id: "reduced_stimulus", name: "Late stimulus control", detail: "minimal late caffeine", impact: 0.09)
                ],
                presets: [
                    .init(
                        id: .calmNow,
                        title: "Calm now",
                        subtitle: "Maintain low arousal between tasks.",
                        durationMinutes: 3,
                        expectedEffect: "Expected effect: preserve recovery momentum during daytime transitions.",
                        whyNow: "Why now: gentle stabilization prevents rebound stress spikes.",
                        protocolSteps: ["30s settling breath", "2m paced cycle", "30s body scan"],
                        icon: "wind"
                    ),
                    .init(
                        id: .focusPrep,
                        title: "Focus prep",
                        subtitle: "Use renewed readiness for one intentional focus block.",
                        durationMinutes: 5,
                        expectedEffect: "Expected effect: cleaner focus onset with less cognitive drag.",
                        whyNow: "Why now: recovery phase improves attentional bandwidth.",
                        protocolSteps: ["1m breath alignment", "2m visual focus lock", "2m intention reset"],
                        icon: "scope"
                    ),
                    .init(
                        id: .sleepDownshift,
                        title: "Sleep downshift",
                        subtitle: "Lock in recovery gains before bed.",
                        durationMinutes: 8,
                        expectedEffect: "Expected effect: higher overnight recovery consistency.",
                        whyNow: "Why now: this pattern compounds quickest through evening consistency.",
                        protocolSteps: ["2m slower exhale", "3m progressive release", "3m low-light unwind"],
                        icon: "moon.stars.fill"
                    )
                ],
                signalNarratives: [
                    .load: "Trend: load is trending down with lower volatility. Insight: protect boundaries to maintain this slope.",
                    .readiness: "Trend: readiness is elevated and stable. Insight: use selective intensity, then recover deliberately.",
                    .consistency: "Trend: consistency is the strongest signal this week. Insight: repeated low-friction habits are compounding."
                ]
            )
        }
    }
}

struct RegulateLaunchRequest: Equatable {
    let preset: RegulatePresetID
    let startImmediately: Bool
}

enum SessionImpactDirection: String, CaseIterable, Codable, Identifiable {
    case worse
    case same
    case better

    var id: String { rawValue }

    var title: String {
        switch self {
        case .worse:
            return "Worse"
        case .same:
            return "Same"
        case .better:
            return "Better"
        }
    }
}

enum SessionHelpfulness: String, CaseIterable, Codable, Identifiable {
    case yes
    case some
    case no

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yes:
            return "Yes"
        case .some:
            return "Some"
        case .no:
            return "No"
        }
    }
}

enum RegulateMeasurementQuality: String, Codable {
    case estimated
    case live

    var title: String {
        switch self {
        case .estimated:
            return "Estimated"
        case .live:
            return "Live"
        }
    }
}

enum RecoverySlope: String, Codable {
    case slow
    case moderate
    case strong

    var title: String {
        switch self {
        case .slow:
            return "slow"
        case .moderate:
            return "moderate"
        case .strong:
            return "strong"
        }
    }
}

struct RegulateEffectMetrics: Codable, Equatable {
    let heartRateDownshiftBPM: Int
    let hrvShiftMS: Int
    let recoverySlope: RecoverySlope
    let quality: RegulateMeasurementQuality
}

struct SessionOutcome: Codable, Equatable {
    let direction: SessionImpactDirection
    let intensity: Int
    let capturedAt: Date
    let feelRating: Int
    let helpfulness: SessionHelpfulness
    let effectMetrics: RegulateEffectMetrics

    enum CodingKeys: String, CodingKey {
        case direction
        case intensity
        case capturedAt
        case feelRating
        case helpfulness
        case effectMetrics
    }

    init(
        direction: SessionImpactDirection,
        intensity: Int,
        capturedAt: Date,
        feelRating: Int,
        helpfulness: SessionHelpfulness,
        effectMetrics: RegulateEffectMetrics
    ) {
        self.direction = direction
        self.intensity = intensity
        self.capturedAt = capturedAt
        self.feelRating = feelRating
        self.helpfulness = helpfulness
        self.effectMetrics = effectMetrics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        direction = try container.decode(SessionImpactDirection.self, forKey: .direction)
        intensity = try container.decode(Int.self, forKey: .intensity)
        capturedAt = try container.decode(Date.self, forKey: .capturedAt)
        feelRating = try container.decodeIfPresent(Int.self, forKey: .feelRating) ?? 3
        helpfulness = try container.decodeIfPresent(SessionHelpfulness.self, forKey: .helpfulness) ?? Self.fallbackHelpfulness(for: direction)
        effectMetrics = try container.decodeIfPresent(RegulateEffectMetrics.self, forKey: .effectMetrics) ?? .init(
            heartRateDownshiftBPM: 0,
            hrvShiftMS: 0,
            recoverySlope: .moderate,
            quality: .estimated
        )
    }

    private static func fallbackHelpfulness(for direction: SessionImpactDirection) -> SessionHelpfulness {
        switch direction {
        case .better:
            return .yes
        case .same:
            return .some
        case .worse:
            return .no
        }
    }
}

enum RegulateSessionState: String, Codable {
    case inProgress
    case awaitingCheckIn
    case completed
    case cancelled
}

struct RegulateSessionRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let preset: RegulatePresetID
    let startedAt: Date
    var plannedDurationSeconds: Int
    var routineCompletedAt: Date?
    var cancelledAt: Date?
    var state: RegulateSessionState
    var completedAt: Date?
    var source: String
    var outcome: SessionOutcome?

    enum CodingKeys: String, CodingKey {
        case id
        case preset
        case startedAt
        case plannedDurationSeconds
        case routineCompletedAt
        case cancelledAt
        case state
        case completedAt
        case source
        case outcome
    }

    init(
        id: UUID,
        preset: RegulatePresetID,
        startedAt: Date,
        plannedDurationSeconds: Int,
        routineCompletedAt: Date? = nil,
        cancelledAt: Date? = nil,
        state: RegulateSessionState = .inProgress,
        completedAt: Date? = nil,
        source: String,
        outcome: SessionOutcome? = nil
    ) {
        self.id = id
        self.preset = preset
        self.startedAt = startedAt
        self.plannedDurationSeconds = plannedDurationSeconds
        self.routineCompletedAt = routineCompletedAt
        self.cancelledAt = cancelledAt
        self.state = state
        self.completedAt = completedAt
        self.source = source
        self.outcome = outcome
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        preset = try container.decode(RegulatePresetID.self, forKey: .preset)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        plannedDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .plannedDurationSeconds) ?? 180
        routineCompletedAt = try container.decodeIfPresent(Date.self, forKey: .routineCompletedAt)
        cancelledAt = try container.decodeIfPresent(Date.self, forKey: .cancelledAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        source = try container.decode(String.self, forKey: .source)
        outcome = try container.decodeIfPresent(SessionOutcome.self, forKey: .outcome)

        if let state = try container.decodeIfPresent(RegulateSessionState.self, forKey: .state) {
            self.state = state
        } else if cancelledAt != nil {
            self.state = .cancelled
        } else if outcome != nil {
            self.state = .completed
        } else if routineCompletedAt != nil {
            self.state = .awaitingCheckIn
        } else {
            self.state = .inProgress
        }
    }

    var isCompleted: Bool {
        state == .completed && completedAt != nil && outcome != nil
    }

    var isInProgress: Bool {
        state == .inProgress
    }

    var isAwaitingCheckIn: Bool {
        state == .awaitingCheckIn
    }
}

enum CoreMetric: String, CaseIterable, Identifiable {
    case load
    case readiness
    case consistency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .load:
            return "Load"
        case .readiness:
            return "Readiness"
        case .consistency:
            return "Consistency"
        }
    }

    var definition: String {
        switch self {
        case .load:
            return "How taxed your nervous system is right now."
        case .readiness:
            return "How prepared your body is for stress and focus."
        case .consistency:
            return "How steady your routines and recovery patterns are."
        }
    }
}

enum TrendWindow: String, CaseIterable, Identifiable {
    case seven = "7D"
    case fourteen = "14D"
    case thirty = "30D"

    var id: String { rawValue }

    var points: Int {
        switch self {
        case .seven:
            return 21
        case .fourteen:
            return 28
        case .thirty:
            return 30
        }
    }

    var stepHours: Double {
        switch self {
        case .seven:
            return 8
        case .fourteen:
            return 12
        case .thirty:
            return 24
        }
    }
}

enum SignalFocus: String, CaseIterable, Identifiable, Codable {
    case readiness
    case load
    case consistency

    var id: String { rawValue }

    var metric: CoreMetric {
        switch self {
        case .readiness:
            return .readiness
        case .load:
            return .load
        case .consistency:
            return .consistency
        }
    }

    var coachTitle: String {
        switch self {
        case .readiness:
            return "Readiness is setting your capacity."
        case .load:
            return "Load spikes need earlier downshifts."
        case .consistency:
            return "Consistency is improving predictability."
        }
    }

    var coachBody: String {
        switch self {
        case .readiness:
            return "Use your strongest readiness windows for high-focus work and protect evening recovery."
        case .load:
            return "Midday downshifts and caffeine timing produce the fastest load control."
        case .consistency:
            return "Small repeated actions outperform intense one-off efforts over multi-week windows."
        }
    }
}

struct TrendPoint: Identifiable, Equatable {
    let index: Int
    let time: Date
    let readiness: Double
    let load: Double

    var id: Int { index }
}

struct DriverImpact: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let detail: String
    let impact: Double

    init(id: String = UUID().uuidString, name: String, detail: String, impact: Double) {
        self.id = id
        self.name = name
        self.detail = detail
        self.impact = impact
    }
}

struct Intervention: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let duration: String
}

enum ExperimentStatus: String, Codable, CaseIterable {
    case planned
    case active
    case completed

    var title: String {
        switch self {
        case .planned:
            return "Planned"
        case .active:
            return "Active"
        case .completed:
            return "Completed"
        }
    }
}

struct ExperimentResult: Codable, Equatable {
    let perceivedChange: Int
    let summary: String
    let completedAt: Date
}

struct Experiment: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let durationDays: Int
    let hypothesis: String
    let focus: SignalFocus
    let nextStep: String
    let estimate: String
    let rationale: String
    var status: ExperimentStatus
    var startedAt: Date?
    var targetEndDate: Date?
    var checkInDaysCompleted: Int
    var checkInLog: [Date]
    var result: ExperimentResult?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case durationDays
        case hypothesis
        case focus
        case nextStep
        case estimate
        case rationale
        case status
        case startedAt
        case targetEndDate
        case checkInDaysCompleted
        case checkInLog
        case result
    }

    init(
        id: UUID,
        title: String,
        durationDays: Int,
        hypothesis: String,
        focus: SignalFocus,
        nextStep: String,
        estimate: String,
        rationale: String,
        status: ExperimentStatus,
        startedAt: Date?,
        targetEndDate: Date?,
        checkInDaysCompleted: Int,
        checkInLog: [Date] = [],
        result: ExperimentResult?
    ) {
        self.id = id
        self.title = title
        self.durationDays = durationDays
        self.hypothesis = hypothesis
        self.focus = focus
        self.nextStep = nextStep
        self.estimate = estimate
        self.rationale = rationale
        self.status = status
        self.startedAt = startedAt
        self.targetEndDate = targetEndDate
        self.checkInDaysCompleted = checkInDaysCompleted
        self.checkInLog = checkInLog
        self.result = result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        durationDays = try container.decode(Int.self, forKey: .durationDays)
        hypothesis = try container.decode(String.self, forKey: .hypothesis)
        focus = try container.decode(SignalFocus.self, forKey: .focus)
        nextStep = try container.decode(String.self, forKey: .nextStep)
        estimate = try container.decode(String.self, forKey: .estimate)
        rationale = try container.decode(String.self, forKey: .rationale)
        status = try container.decode(ExperimentStatus.self, forKey: .status)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
        targetEndDate = try container.decodeIfPresent(Date.self, forKey: .targetEndDate)
        checkInDaysCompleted = try container.decodeIfPresent(Int.self, forKey: .checkInDaysCompleted) ?? 0
        checkInLog = try container.decodeIfPresent([Date].self, forKey: .checkInLog) ?? []
        result = try container.decodeIfPresent(ExperimentResult.self, forKey: .result)
    }

    var isOverdue: Bool {
        guard status == .active, let targetEndDate else { return false }
        return Date() > targetEndDate
    }

    var adherencePercent: Int {
        let normalizedCompletedDays = min(max(checkInDaysCompleted, 0), max(durationDays, 1))
        if status == .completed {
            let completionRatio = Double(normalizedCompletedDays) / Double(max(durationDays, 1))
            return Int((min(max(completionRatio, 0), 1) * 100).rounded())
        }
        guard status == .active else {
            return 0
        }
        guard let startedAt else {
            return 0
        }
        let dayStart = Calendar.current.startOfDay(for: startedAt)
        let today = Calendar.current.startOfDay(for: Date())
        let elapsedDays = (Calendar.current.dateComponents([.day], from: dayStart, to: today).day ?? 0) + 1
        let denominator = max(1, min(durationDays, elapsedDays))
        let ratio = Double(normalizedCompletedDays) / Double(denominator)
        return Int((min(max(ratio, 0), 1) * 100).rounded())
    }
}

struct AnalyticsEventRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let event: String
    let timestamp: Date
    let metadata: [String: String]
}

struct ProductKPIScorecard {
    let activationRate: Double
    let d1RetentionRate: Double
    let d7RetentionRate: Double
    let sessionStartRate: Double
    let sessionCompletionRate: Double
    let generatedAt: Date
}

enum GuidedDemoPathStep: Int, CaseIterable, Codable {
    case today
    case regulate
    case data
    case settings

    var title: String {
        switch self {
        case .today:
            return AppIA.today
        case .regulate:
            return AppIA.regulate
        case .data:
            return AppIA.data
        case .settings:
            return AppIA.qaTools
        }
    }

    var indexLabel: String {
        "\(rawValue + 1)/\(Self.allCases.count)"
    }

    var tabDestination: MainTab? {
        switch self {
        case .today:
            return .today
        case .regulate:
            return .regulate
        case .data:
            return .data
        case .settings:
            return nil
        }
    }
}

@MainActor
final class MindSenseStore: ObservableObject {
    @Published var appState: AppLaunchState = .launching
    @Published var hasSeenIntro = false
    @Published var session: AuthSession?
    @Published var onboarding = OnboardingProgress()
    @Published var banner: AppBanner?
    @Published var selectedTab: MainTab = .today
    @Published var regulateLaunchRequest: RegulateLaunchRequest?
    @Published var activeRegulateSession: RegulateSessionRecord?
    @Published var regulateSessionHistory: [RegulateSessionRecord] = []
    @Published var experiments: [Experiment] = []
    @Published var demoScenario: DemoScenario = .balancedDay
    @Published var demoMetrics: DemoMetricSnapshot = DemoScenario.balancedDay.baseMetrics
    @Published var demoEventHistory: [DemoEventRecord] = []
    @Published var demoHealthProfile: DemoHealthProfile = MindSenseDemoSeedCatalog.seededHealthProfile(
        for: .balancedDay,
        demoDay: DemoScenario.balancedDay.defaultDay
    )
    @Published var demoSavedInsights: [DemoSavedInsight] = []
    @Published var demoLastUpdatedAt: Date = Date()
    @Published var demoDay: Int = DemoScenario.balancedDay.defaultDay
    @Published var demoDataIssue: String?
    @Published var guidedDemoPathStep: GuidedDemoPathStep?
    @Published private(set) var coreScreenStates: [CoreScreenID: ScreenMode] = [:]
    @Published var shouldPresentPostActivationPaywall = false
    @Published var kpiLastReviewedAt: Date?
    private(set) var analyticsEvents: [AnalyticsEventRecord] = []

    private let persistence = MindSensePersistenceService()
    private let bootstrap = MindSenseBootstrapService()
    private let defaults = UserDefaults.standard
    private var bannerTask: Task<Void, Never>?
    private let primaryImpactFeedback = UIImpactFeedbackGenerator(style: .soft)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private static let analyticsTimestampFormatter = ISO8601DateFormatter()
    private static let relativeDateFormatter = RelativeDateTimeFormatter()

    init() {
        bootstrap.seedDefaultsIfNeeded()
        bootstrap.applyLaunchOverridesIfNeeded()
        startLaunchSequence()
    }

    var userDisplayName: String {
        if let displayName = session?.displayName,
           !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return displayName
        }
        guard let email = session?.email else { return "Friend" }
        return email.split(separator: "@").first.map(String.init)?.capitalized ?? "Friend"
    }

    var scenarioProfile: DemoScenarioProfile {
        DemoScenarioProfile.make(for: demoScenario)
    }

    var regulatePresetCatalog: [DemoRegulatePreset] {
        scenarioProfile.presets
    }

    var rankedRegulatePresetCatalog: [DemoRegulatePreset] {
        regulatePresetCatalog.sorted {
            presetRankScore(for: $0.id) > presetRankScore(for: $1.id)
        }
    }

    var primaryRecommendation: DemoRecommendation {
        RecommendationEngine.primaryRecommendation(
            context: recommendationContext,
            presets: regulatePresetCatalog,
            fallback: demoScenario.primaryRecommendation
        )
    }

    private var recommendationContext: RecommendationEngine.Context {
        .init(
            scenario: demoScenario,
            metrics: demoMetrics,
            baseMetrics: demoScenario.baseMetrics,
            confidenceScore: confidenceScore,
            stressSignals: recentStressSignalCount(),
            recoverySignals: recentRecoverySignalCount(),
            caffeineSignals: recentKeywordCount(["caffeine"])
        )
    }

    private var rankedTodayDrivers: [DriverImpact] {
        rankedDriversForToday()
    }

    var todayPrimaryDrivers: [DriverImpact] {
        Array(rankedTodayDrivers.prefix(3))
    }

    var todaySecondaryDrivers: [DriverImpact] {
        Array(rankedTodayDrivers.dropFirst(3).prefix(3))
    }

    var todayInsightHeadline: String {
        if let delta = latestCheckInDeltaSummary {
            return "Since \(delta.baselineTitle), load \(signed(delta.loadDelta)), readiness \(signed(delta.readinessDelta))"
        }
        return demoScenario.insightLine
    }

    var todayInsightDetail: String {
        if let delta = latestCheckInDeltaSummary {
            return delta.explanation
        }
        return demoScenario.narrative
    }

    var demoDataCoverageScore: Double {
        let eventCoverage = min(Double(demoEventHistory.count) / 18, 1)
        let checkInCoverage = min(Double(demoEventHistory.filter { $0.kind == .checkIn }.count) / 6, 1)
        let sessionCoverage = min(Double(regulateSessionHistory.filter { $0.isCompleted }.count) / 3, 1)
        let experimentCoverage = min(Double(experiments.reduce(0) { $0 + $1.checkInDaysCompleted }) / 7, 1)
        return clamp(
            (eventCoverage * 0.35) + (checkInCoverage * 0.25) + (sessionCoverage * 0.25) + (experimentCoverage * 0.15),
            min: 0.12,
            max: 1
        )
    }

    var demoDataCoveragePercent: Int {
        Int((demoDataCoverageScore * 100).rounded())
    }

    var confidenceScore: Double {
        let coverageFactor = (demoDataCoverageScore - 0.5) * 0.22
        let loopFactor = hasCompletedTodayPrimaryLoop ? 0.05 : 0
        let adherenceFactor = Double(activeExperiment?.adherencePercent ?? 0) / 320
        let cancelledCount = Double(regulateSessionHistory.filter { $0.state == .cancelled }.count)
        let cancellationPenalty = min(cancelledCount * 0.012, 0.09)
        return clamp(
            demoScenario.confidenceBase + coverageFactor + loopFactor + adherenceFactor - cancellationPenalty,
            min: 0.42,
            max: 0.98
        )
    }

    var confidencePercent: Int {
        Int((confidenceScore * 100).rounded())
    }

    var confidenceLabel: String {
        if confidencePercent >= 82 {
            return "Strong"
        }
        if confidencePercent >= 62 {
            return "Moderate"
        }
        return "Emerging"
    }

    var confidenceStatusLine: String {
        "Confidence \(confidenceLabel) \(confidencePercent)% • coverage \(demoDataCoveragePercent)%"
    }

    var lastUpdatedLabel: String {
        demoLastUpdatedAt.formatted(date: .omitted, time: .shortened)
    }

    var healthDataQualityScore: Int {
        demoHealthProfile.quality.score
    }

    var healthLastSyncRelativeLabel: String {
        Self.relativeDateFormatter.localizedString(for: demoHealthProfile.sync.lastSyncAt, relativeTo: Date())
    }

    var healthSourceStatusLine: String {
        "Source: \(demoHealthProfile.sync.sourceLabel) • Last update \(healthLastSyncRelativeLabel) • Data quality \(healthDataQualityScore)"
    }

    var healthQualityDiagnostics: [(String, Int)] {
        demoHealthProfile.quality.diagnostics
    }

    var healthPermissions: [DemoHealthPermissionStatus] {
        demoHealthProfile.permissions
    }

    var stressTimelineSegments: [StressTimelineSegment] {
        demoHealthProfile.timelineSegments
    }

    var recentStressEpisodes: [StressEpisodeRecord] {
        demoHealthProfile.sortedEpisodes
    }

    var latestStressEpisodeNeedingContext: StressEpisodeRecord? {
        let now = Date()
        return recentStressEpisodes.first {
            !$0.hasContext &&
            $0.end <= now &&
            now.timeIntervalSince($0.end) <= (8 * 3_600)
        }
    }

    var whatIfPreviewLine: String {
        let preset = primaryRecommendation.preset
        let projected = projectedLoadInTwoHours(for: preset)
        let delta = projectedLoadDeltaInTwoHours(for: preset)
        return "If you run \(preset.title) now, projected load in 2h: \(projected) (\(signed(delta)))."
    }

    var todayCognitivePrompt: String {
        switch primaryRecommendation.preset {
        case .calmNow:
            return "Shift from urgency to control: what is the next 2-minute action you can finish well?"
        case .focusPrep:
            return "Anchor process over pressure: what single input will make this block successful?"
        case .sleepDownshift:
            return "Trade stimulation for recovery: what can you reduce in the next 30 minutes?"
        }
    }

    func episodeCognitivePrompt(for episode: StressEpisodeRecord) -> String {
        switch (episode.likelyDriver, episode.recommendedPreset) {
        case (.cognitive, .focusPrep):
            return "Switch from outcome pressure to process control: what single input matters most in the next 10 minutes?"
        case (.cognitive, .calmNow):
            return "Slow the pace before you push: take one longer exhale, then choose one task to finish fully."
        case (.cognitive, .sleepDownshift):
            return "Lower stimulation before recovery: what can you pause now so your system can settle earlier tonight?"
        case (.social, _):
            return "Reset after social load: unclench shoulders, then decide what boundary keeps the next block clean."
        case (.environmental, _):
            return "Reduce sensory drag: name one distraction to remove in the next 2 minutes and do it now."
        case (.physical, _):
            return "Downshift body tension first: soften jaw, lengthen exhale, and let attention settle on one anchor."
        }
    }

    var todayMeasurementPlanLine: String {
        if healthDataQualityScore >= 72 {
            return "Measurement plan: track HR downshift + recovery slope and capture a 1-tap reflection."
        }
        return "Measurement plan: estimate physiological shift from nearest samples, then capture 1-tap reflection."
    }

    var latestCheckInDeltaSummary: DemoCheckInDeltaSummary? {
        latestDeltaSinceCheckIn()
    }

    var weeklySummary: DemoWeeklySummary {
        buildWeeklySummary()
    }

    var dataSignalTrendTiles: [DataSignalTrendTile] {
        buildDataSignalTrendTiles()
    }

    var whatIsWorkingSummary: DemoWhatIsWorkingSummary {
        buildWhatIsWorkingSummary()
    }

    var savedInsightsForCommunity: [DemoSavedInsight] {
        if demoSavedInsights.isEmpty {
            return buildFallbackSavedInsights()
        }
        return demoSavedInsights.sorted(by: { $0.timestamp > $1.timestamp })
    }

    var guidedPathStatusLine: String? {
        guard let step = guidedDemoPathStep else { return nil }
        return "Guided tour \(step.indexLabel): \(step.title)"
    }

    var guidedPathNextLabel: String? {
        guard let step = guidedDemoPathStep else { return nil }
        if step == .settings {
            return "Finish tour"
        }
        return "Next: \(nextGuidedStep(after: step)?.title ?? AppIA.qaTools)"
    }

    var guidedPathPrimaryActionLabel: String? {
        guard let step = guidedDemoPathStep else { return nil }
        if step == .settings {
            return "Complete guided tour"
        }
        return "Continue guided tour"
    }

    var resumeLabel: String? {
        if let activeRegulateSession {
            if activeRegulateSession.isInProgress {
                return "Resume active session"
            }
            if activeRegulateSession.isAwaitingCheckIn {
                return "Resume post-session check-in"
            }
        }
        if let activeExperiment {
            return "Resume day \(min(activeExperiment.checkInDaysCompleted + 1, activeExperiment.durationDays)) experiment"
        }
        return nil
    }

    var baselineText: String {
        let day = baselineDay
        return "Baseline Day \(day) of 14"
    }

    var baselineDay: Int {
        guard let start = onboarding.baselineStart else {
            return 8
        }
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(1, min(14, days + 1))
    }

    var onboardingPercent: Double {
        let requiredSteps = OnboardingStep.activationSteps
        guard !requiredSteps.isEmpty else {
            return 1
        }
        let completedRequiredSteps = requiredSteps.filter { onboarding.isComplete($0) }.count
        return Double(completedRequiredSteps) / Double(requiredSteps.count)
    }

    var latestCompletedSession: RegulateSessionRecord? {
        regulateSessionHistory.first(where: { $0.isCompleted })
    }

    var latestSessionEffectLine: String? {
        guard let outcome = latestCompletedSession?.outcome else { return nil }
        let heartShift = outcome.effectMetrics.heartRateDownshiftBPM
        let heartLine = heartShift >= 0 ? "-\(heartShift) bpm" : "+\(abs(heartShift)) bpm"
        return "HR \(heartLine) • recovery \(outcome.effectMetrics.recoverySlope.title) • \(outcome.effectMetrics.quality.title.lowercased())"
    }

    var hasReachedActivationMilestone: Bool {
        latestCompletedSession != nil
    }

    var hasCompletedTodayPrimaryLoop: Bool {
        if let latest = latestCompletedSession {
            return Calendar.current.isDateInToday(latest.startedAt)
        }
        return false
    }

    var activeExperiment: Experiment? {
        experiments.first(where: { $0.status == .active })
    }

    var completedExperiments: [Experiment] {
        experiments.filter { $0.status == .completed }
    }

    var productKPIs: ProductKPIScorecard {
        let opens = analyticsEvents.filter { $0.event == UXEvent.appOpened.rawValue }
        let activations = analyticsEvents.filter { $0.event == UXEvent.onboardingCompleted.rawValue }
        let sessionStarts = analyticsEvents.filter { $0.event == UXEvent.sessionStarted.rawValue }
        let sessionCompletions = analyticsEvents.filter { $0.event == UXEvent.sessionOutcomeRecorded.rawValue }

        let activationRate = ratio(activations.count, opens.count)
        let sessionStartRate = ratio(sessionStarts.count, opens.count)
        let sessionCompletionRate = ratio(sessionCompletions.count, sessionStarts.count)
        let d1RetentionRate = retentionRate(dayOffset: 1)
        let d7RetentionRate = retentionRate(dayOffset: 7)

        return ProductKPIScorecard(
            activationRate: activationRate,
            d1RetentionRate: d1RetentionRate,
            d7RetentionRate: d7RetentionRate,
            sessionStartRate: sessionStartRate,
            sessionCompletionRate: sessionCompletionRate,
            generatedAt: Date()
        )
    }

    func openRegulatePreset(_ preset: RegulatePresetID, startImmediately: Bool) {
        selectedTab = .regulate
        regulateLaunchRequest = .init(preset: preset, startImmediately: startImmediately)
    }

    func consumeRegulateLaunchRequest() -> RegulateLaunchRequest? {
        let request = regulateLaunchRequest
        regulateLaunchRequest = nil
        return request
    }

    func screenMode(for screen: CoreScreenID) -> ScreenMode {
        coreScreenStates[screen] ?? resolvedScreenState(for: screen)
    }

    func prepareCoreScreen(_ screen: CoreScreenID) {
        coreScreenStates[screen] = resolvedScreenState(for: screen)
    }

    func retryCoreScreen(_ screen: CoreScreenID) {
        if demoDataIssue != nil {
            repairDemoData()
            return
        }
        prepareCoreScreen(screen)
    }

    func switchDemoScenario(_ scenario: DemoScenario) {
        guard demoScenario != scenario else { return }

        if activeRegulateSession != nil {
            cancelRegulateSession(reason: "scenario_switched")
        }

        demoScenario = scenario
        demoMetrics = scenario.baseMetrics
        demoDay = scenario.defaultDay
        regulateSessionHistory = []
        experiments = MindSenseDemoSeedCatalog.defaultExperiments(for: scenario)
        demoEventHistory = MindSenseDemoSeedCatalog.seededEvents(for: scenario)
        demoHealthProfile = MindSenseDemoSeedCatalog.seededHealthProfile(for: scenario, demoDay: scenario.defaultDay)
        demoSavedInsights = []
        guidedDemoPathStep = nil
        demoDataIssue = nil
        persistDemoScenario()
        persistDemoMetrics()
        persistDemoDay()
        persistRegulateSessionHistory()
        persistExperiments()
        persistDemoEvents()
        persistDemoHealthProfile()
        persistDemoSavedInsights()
        persistGuidedDemoPathStep()
        updateDemoLastUpdated()
        refreshCoreScreensLoadingThenReady()

        showActionFeedback(.applied, detail: "\(scenario.title) is now active.")
        track(
            event: .actionCompleted,
            surface: .global,
            action: "scenario_switched",
            metadata: ["scenario": scenario.rawValue]
        )
    }

    func showActionFeedback(_ verb: ActionFeedbackVerb, detail: String) {
        showBanner(title: verb.title, detail: detail, severity: verb.severity)
    }

    func resumeWhereLeftOff() {
        if activeRegulateSession != nil {
            selectedTab = .regulate
            return
        }
        if activeExperiment != nil {
            selectedTab = .data
        }
    }

    func startGuidedDemoPath() {
        guidedDemoPathStep = .today
        selectedTab = .today
        persistGuidedDemoPathStep()
        showActionFeedback(.applied, detail: "Guided tour started: Today -> Regulate -> Data -> QA Tools.")
        track(event: .actionCompleted, surface: .settings, action: "guided_tour_started")
    }

    func advanceGuidedDemoPath() {
        guard let step = guidedDemoPathStep else { return }

        switch step {
        case .today:
            guidedDemoPathStep = .regulate
            selectedTab = .regulate
            showActionFeedback(.updated, detail: "Step 2: Regulate.")
        case .regulate:
            guidedDemoPathStep = .data
            selectedTab = .data
            showActionFeedback(.updated, detail: "Step 3: Data.")
        case .data:
            guidedDemoPathStep = .settings
            showActionFeedback(.updated, detail: "Step 4: Open QA Tools from the profile menu.")
        case .settings:
            completeGuidedDemoPath()
            return
        }

        persistGuidedDemoPathStep()
        track(event: .secondaryActionTapped, surface: .global, action: "guided_tour_advanced", metadata: ["step": "\(step.rawValue + 1)"])
    }

    func completeGuidedDemoPath() {
        guidedDemoPathStep = nil
        persistGuidedDemoPathStep()
        showActionFeedback(.saved, detail: "Guided tour completed.")
        track(event: .actionCompleted, surface: .global, action: "guided_tour_completed")
    }

    func resetDemoDataForCurrentScenario() {
        if activeRegulateSession != nil {
            cancelRegulateSession(reason: "data_reset")
        }
        demoMetrics = demoScenario.baseMetrics
        demoDay = demoScenario.defaultDay
        regulateSessionHistory = []
        activeRegulateSession = nil
        experiments = MindSenseDemoSeedCatalog.defaultExperiments(for: demoScenario)
        demoEventHistory = MindSenseDemoSeedCatalog.seededEvents(for: demoScenario)
        demoHealthProfile = MindSenseDemoSeedCatalog.seededHealthProfile(for: demoScenario, demoDay: demoScenario.defaultDay)
        demoSavedInsights = []
        persistActiveRegulateSession()
        persistRegulateSessionHistory()
        persistExperiments()
        persistDemoMetrics()
        persistDemoDay()
        persistDemoEvents()
        persistDemoHealthProfile()
        persistDemoSavedInsights()
        updateDemoLastUpdated()
        refreshCoreScreensLoadingThenReady()
        showActionFeedback(.updated, detail: "\(demoScenario.title) data reset.")
        track(event: .actionCompleted, surface: .settings, action: "data_reset")
    }

    func fastForwardDemoDay(by days: Int = 1) {
        let boundedDays = max(1, min(7, days))
        bumpDemoDay(by: boundedDays)
        appendDemoEvent(
            title: "Day advanced",
            detail: "Fast-forwarded \(boundedDays) day\(boundedDays == 1 ? "" : "s") for storytelling.",
            kind: .system,
            delta: MindSenseDeltaEngine.fastForwardedDays(boundedDays, scenario: demoScenario)
        )
        showActionFeedback(.applied, detail: "Moved to day \(demoDay).")
        track(event: .secondaryActionTapped, surface: .settings, action: "day_fast_forwarded", metadata: ["days": "\(boundedDays)"])
    }

    func injectStressEvent() {
        appendDemoEvent(
            title: "Stress event injected",
            detail: "Unexpected pressure block added to simulate real-world volatility.",
            kind: .system,
            delta: .init(load: 6, readiness: -4, consistency: -2)
        )
        showActionFeedback(.applied, detail: "Stress event injected into timeline.")
        track(event: .secondaryActionTapped, surface: .settings, action: "stress_event_injected")
    }

    func resyncDemoHealthData() {
        refreshDemoHealthSignals(updateSyncTimestamp: true)
        showActionFeedback(.updated, detail: "Health data resynced.")
        track(event: .secondaryActionTapped, surface: .settings, action: "health_resync")
    }

    func rebuildDemoHealthDerivedData() {
        demoHealthProfile = DemoHealthSignalEngine.rebuiltDerivedProfile(
            existing: demoHealthProfile,
            scenario: demoScenario,
            demoDay: demoDay,
            now: Date()
        )
        persistDemoHealthProfile()
        showActionFeedback(.updated, detail: "Derived health baseline rebuilt.")
        track(event: .secondaryActionTapped, surface: .settings, action: "health_rebuilt")
    }

    func deleteDemoHealthDerivedData() {
        demoHealthProfile = DemoHealthSignalEngine.deletingDerivedProfile(
            existing: demoHealthProfile,
            now: Date()
        )
        persistDemoHealthProfile()
        showActionFeedback(.saved, detail: "Health-derived metrics cleared.")
        track(event: .actionCompleted, surface: .settings, action: "health_derived_deleted")
    }

    func saveStressEpisodeContext(
        episodeID: UUID,
        tags: Set<String>,
        note: String
    ) {
        guard let index = demoHealthProfile.stressEpisodes.firstIndex(where: { $0.id == episodeID }) else { return }

        let cleanedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        demoHealthProfile.stressEpisodes[index].userTags = tags.sorted()
        demoHealthProfile.stressEpisodes[index].userNote = cleanedNote.isEmpty ? nil : cleanedNote
        persistDemoHealthProfile()

        if !tags.isEmpty || !cleanedNote.isEmpty {
            let tagLine = tags.isEmpty ? "No tags" : tags.sorted().joined(separator: ", ")
            appendDemoEvent(
                title: "Stress context captured",
                detail: "Episode labeled with \(tagLine).",
                kind: .reflection,
                delta: .zero
            )
        }

        showActionFeedback(.saved, detail: "Stress context saved and applied to attribution.")
        track(event: .actionCompleted, surface: .today, action: "stress_context_saved")
    }

    func saveStressEpisodeAttributionFeedback(
        episodeID: UUID,
        feedback: StressEpisodeAttributionFeedback
    ) {
        guard let index = demoHealthProfile.stressEpisodes.firstIndex(where: { $0.id == episodeID }) else { return }
        demoHealthProfile.stressEpisodes[index].attributionFeedback = feedback
        persistDemoHealthProfile()

        appendDemoEvent(
            title: "Episode attribution reviewed",
            detail: "Marked \(feedback.title.lowercased()) for episode attribution.",
            kind: .reflection,
            delta: .zero
        )
        showActionFeedback(.saved, detail: "Episode feedback captured.")
        track(
            event: .actionCompleted,
            surface: .today,
            action: "stress_episode_feedback_saved",
            metadata: ["feedback": feedback.rawValue]
        )
    }

    func appendDemoEvent(
        title: String,
        detail: String,
        kind: DemoEventKind,
        delta: DemoMetricDelta = DemoMetricDelta(load: 0, readiness: 0, consistency: 0)
    ) {
        applyMetricDelta(delta)
        let event = DemoEventRecord(
            id: UUID(),
            timestamp: Date(),
            title: title,
            detail: detail,
            kind: kind,
            metricSnapshot: demoMetrics,
            demoDay: demoDay
        )
        demoEventHistory.insert(event, at: 0)
        demoEventHistory = Array(demoEventHistory.prefix(80))
        persistDemoEvents()
        refreshDemoHealthSignals(updateSyncTimestamp: false)
        updateDemoLastUpdated()
    }

    func saveTodayCheckIn(loadScore: Int, tags: Set<String>, showFeedback: Bool = true) {
        let bounded = max(0, min(10, loadScore))
        let delta = DemoMetricDelta(
            load: max(-3, min(5, bounded - 5)),
            readiness: max(-4, min(2, 4 - bounded)),
            consistency: tags.isEmpty ? 0 : 1
        )
        let tagLine = tags.isEmpty ? "No context tags" : tags.sorted().joined(separator: ", ")
        appendDemoEvent(
            title: "Check-in \(bounded)/10",
            detail: "Tags: \(tagLine)",
            kind: .checkIn,
            delta: delta
        )
        if bounded <= 3 || bounded >= 8 {
            saveInsight(
                title: "Check-in \(bounded)/10 captured",
                detail: bounded >= 8
                    ? "High-load signal captured. Prioritize short downshifts before next pressure block."
                    : "Low-load window captured. This is a leverage moment for focus quality."
            )
        }
        if showFeedback {
            showActionFeedback(.saved, detail: "Check-in captured and model state updated.")
        }
        track(
            event: .actionCompleted,
            surface: .today,
            action: "check_in_saved",
            metadata: ["load_score": "\(bounded)"]
        )
    }

    func quickLog(tag: String) {
        let normalized = tag.lowercased()
        let delta: DemoMetricDelta
        switch normalized {
        case "caffeine":
            delta = .init(load: 2, readiness: -1, consistency: 0)
        case "exercise":
            delta = .init(load: -2, readiness: 2, consistency: 1)
        case "social":
            delta = .init(load: -1, readiness: 1, consistency: 1)
        default:
            delta = .zero
        }
        appendDemoEvent(
            title: "\(tag) logged",
            detail: "Added to today's context history.",
            kind: .reflection,
            delta: delta
        )
        showActionFeedback(.saved, detail: "\(tag) entry added.")
    }

    func beginRegulateSession(preset: RegulatePresetID, source: String) -> RegulateSessionRecord {
        let duration = regulatePresetCatalog.first(where: { $0.id == preset })?.durationSeconds ?? 180
        let session = RegulateSessionRecord(
            id: UUID(),
            preset: preset,
            startedAt: Date(),
            plannedDurationSeconds: duration,
            routineCompletedAt: nil,
            cancelledAt: nil,
            state: .inProgress,
            completedAt: nil,
            source: source,
            outcome: nil
        )
        activeRegulateSession = session
        persistActiveRegulateSession()
        appendDemoEvent(
            title: "\(preset.title) started",
            detail: "Timer set for \(duration / 60) min.",
            kind: .session
        )
        track(event: .sessionStarted, surface: .regulate, action: "start_\(preset.rawValue)", metadata: ["source": source])
        return session
    }

    func syncActiveRegulateSessionState(now: Date = Date()) {
        guard var session = activeRegulateSession else { return }
        guard session.state == .inProgress else { return }
        let elapsed = Int(now.timeIntervalSince(session.startedAt))
        guard elapsed >= session.plannedDurationSeconds else { return }
        session.state = .awaitingCheckIn
        session.routineCompletedAt = now
        activeRegulateSession = session
        persistActiveRegulateSession()
        showActionFeedback(.updated, detail: "Session complete. Save your impact check-in.")
    }

    func activeSessionElapsedSeconds(now: Date = Date()) -> Int {
        guard let activeRegulateSession else { return 0 }
        if let routineCompletedAt = activeRegulateSession.routineCompletedAt {
            return Int(routineCompletedAt.timeIntervalSince(activeRegulateSession.startedAt))
        }
        return max(0, Int(now.timeIntervalSince(activeRegulateSession.startedAt)))
    }

    func activeSessionRemainingSeconds(now: Date = Date()) -> Int {
        guard let activeRegulateSession else { return 0 }
        let remaining = activeRegulateSession.plannedDurationSeconds - activeSessionElapsedSeconds(now: now)
        return max(0, remaining)
    }

    func completeRegulateSessionEarly() {
        guard var session = activeRegulateSession else { return }
        guard session.state == .inProgress else { return }
        session.state = .awaitingCheckIn
        session.routineCompletedAt = Date()
        activeRegulateSession = session
        persistActiveRegulateSession()
        appendDemoEvent(
            title: "\(session.preset.title) finished",
            detail: "Session completed. Awaiting post-session check-in.",
            kind: .session
        )
        showActionFeedback(.updated, detail: "Session finished. Capture outcome now.")
    }

    func cancelRegulateSession(reason: String) {
        guard var session = activeRegulateSession else { return }
        session.state = .cancelled
        session.cancelledAt = Date()
        session.completedAt = Date()
        activeRegulateSession = nil
        regulateSessionHistory.insert(session, at: 0)
        regulateSessionHistory = Array(regulateSessionHistory.prefix(50))
        persistActiveRegulateSession()
        persistRegulateSessionHistory()
        appendDemoEvent(
            title: "\(session.preset.title) cancelled",
            detail: "Session cancelled before impact check-in.",
            kind: .session,
            delta: .init(load: 1, readiness: -1, consistency: -1)
        )
        showActionFeedback(.updated, detail: "Session cancelled.")
        track(
            event: .secondaryActionTapped,
            surface: .regulate,
            action: "session_cancelled",
            metadata: ["reason": reason, "preset": session.preset.rawValue]
        )
    }

    func recordRegulateOutcome(
        direction: SessionImpactDirection,
        intensity: Int,
        feelRating: Int,
        helpfulness: SessionHelpfulness
    ) {
        guard var session = activeRegulateSession else { return }
        if session.state == .inProgress {
            session.state = .awaitingCheckIn
            session.routineCompletedAt = Date()
        }
        guard session.state == .awaitingCheckIn else { return }

        let bounded = max(1, min(5, intensity))
        let boundedFeeling = max(1, min(5, feelRating))
        let effect = MindSenseDeltaEngine.sessionEffectMetrics(
            direction: direction,
            intensity: bounded,
            preset: session.preset,
            scenario: demoScenario,
            quality: measurementQuality(for: session.preset)
        )
        session.state = .completed
        session.completedAt = Date()
        session.outcome = SessionOutcome(
            direction: direction,
            intensity: bounded,
            capturedAt: Date(),
            feelRating: boundedFeeling,
            helpfulness: helpfulness,
            effectMetrics: effect
        )
        activeRegulateSession = nil
        regulateSessionHistory.insert(session, at: 0)
        regulateSessionHistory = Array(regulateSessionHistory.prefix(50))
        persistActiveRegulateSession()
        persistRegulateSessionHistory()
        applyMetricDelta(MindSenseDeltaEngine.sessionOutcome(direction: direction, intensity: bounded))
        let heartShiftLine = effect.heartRateDownshiftBPM >= 0
            ? "HR downshift -\(effect.heartRateDownshiftBPM) bpm"
            : "HR drift +\(abs(effect.heartRateDownshiftBPM)) bpm"
        appendDemoEvent(
            title: "\(session.preset.title) outcome saved",
            detail: "\(heartShiftLine), recovery \(effect.recoverySlope.title), rating \(boundedFeeling)/5.",
            kind: .session
        )
        saveInsight(
            title: "\(session.preset.title): \(direction.title) \(bounded)/5",
            detail: "Context \(demoScenario.title). \(heartShiftLine). HRV shift +\(effect.hrvShiftMS) ms."
        )
        bumpDemoDay(by: 1)

        track(
            event: .sessionOutcomeRecorded,
            surface: .regulate,
            action: "outcome_\(direction.rawValue)",
            metadata: [
                "intensity": "\(bounded)",
                "preset": session.preset.rawValue,
                "helpfulness": helpfulness.rawValue,
                "feeling": "\(boundedFeeling)"
            ]
        )
        showActionFeedback(.saved, detail: "Session impact applied across Today and Data.")
        maybePresentPostActivationPaywall()
    }

    func startExperiment(_ id: UUID) {
        guard let index = experiments.firstIndex(where: { $0.id == id }) else { return }
        guard experiments[index].status != .active else { return }
        if let activeIndex = experiments.firstIndex(where: { $0.status == .active }) {
            experiments[activeIndex].status = .planned
            experiments[activeIndex].startedAt = nil
            experiments[activeIndex].targetEndDate = nil
            experiments[activeIndex].checkInDaysCompleted = 0
            experiments[activeIndex].checkInLog = []
            experiments[activeIndex].result = nil
        }

        experiments[index].status = .active
        experiments[index].startedAt = Date()
        experiments[index].targetEndDate = Calendar.current.date(byAdding: .day, value: experiments[index].durationDays - 1, to: Date())
        experiments[index].checkInDaysCompleted = 0
        experiments[index].checkInLog = []
        experiments[index].result = nil
        persistExperiments()
        appendDemoEvent(
            title: "\(experiments[index].title) started",
            detail: "Day 1 of \(experiments[index].durationDays) is ready.",
            kind: .experiment
        )
        showActionFeedback(.applied, detail: "Experiment started.")
        track(event: .experimentStarted, surface: .data, action: "experiment_started", metadata: ["id": id.uuidString])
    }

    func logExperimentDay(_ id: UUID) {
        guard let index = experiments.firstIndex(where: { $0.id == id }) else { return }
        guard experiments[index].status == .active else { return }
        experiments[index].checkInDaysCompleted = min(experiments[index].durationDays, experiments[index].checkInDaysCompleted + 1)
        experiments[index].checkInLog.append(Date())
        bumpDemoDay(by: 1)
        applyMetricDelta(MindSenseDeltaEngine.experimentCheckIn(focus: experiments[index].focus))
        persistExperiments()
        appendDemoEvent(
            title: "\(experiments[index].title) day \(experiments[index].checkInDaysCompleted) logged",
            detail: "Adherence \(experiments[index].adherencePercent)%.",
            kind: .experiment
        )
        if experiments[index].adherencePercent >= 70 {
            saveInsight(
                title: "\(experiments[index].title): adherence \(experiments[index].adherencePercent)%",
                detail: "Consistent logging is increasing your confidence coverage."
            )
        }
        showActionFeedback(.updated, detail: "Experiment day logged.")
        track(event: .experimentDayLogged, surface: .data, action: "experiment_day_logged", metadata: ["id": id.uuidString, "days": "\(experiments[index].checkInDaysCompleted)"])
    }

    func completeExperiment(_ id: UUID, perceivedChange: Int, summary: String) {
        guard let index = experiments.firstIndex(where: { $0.id == id }) else { return }
        guard experiments[index].status == .active else { return }
        let perceived = max(-5, min(5, perceivedChange))
        let adherence = Int((Double(min(experiments[index].durationDays, experiments[index].checkInDaysCompleted)) / Double(max(experiments[index].durationDays, 1)) * 100).rounded())
        let generated = MindSenseDeltaEngine.experimentCompletionSummary(
            scenarioTitle: demoScenario.title,
            focusTitle: experiments[index].focus.metric.title,
            adherence: adherence,
            perceivedChange: perceived
        )
        let userSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)

        experiments[index].status = .completed
        experiments[index].checkInDaysCompleted = max(experiments[index].durationDays, experiments[index].checkInDaysCompleted)
        experiments[index].result = .init(
            perceivedChange: perceived,
            summary: userSummary.isEmpty ? generated : "\(generated) \(userSummary)",
            completedAt: Date()
        )
        applyMetricDelta(MindSenseDeltaEngine.completedExperiment(focus: experiments[index].focus, perceivedChange: perceived))
        persistExperiments()
        appendDemoEvent(
            title: "\(experiments[index].title) completed",
            detail: "Result captured with adherence \(adherence)%.",
            kind: .experiment
        )
        saveInsight(
            title: "\(experiments[index].title) result",
            detail: experiments[index].result?.summary ?? generated
        )
        showActionFeedback(.saved, detail: "Experiment result saved.")
        track(event: .experimentCompleted, surface: .data, action: "experiment_completed", metadata: ["id": id.uuidString])
    }

    func markKPIReviewedNow() {
        let now = Date()
        kpiLastReviewedAt = now
        persistence.setKPIReviewedAt(now)
        track(event: .kpiReviewed, surface: .settings, action: "weekly_review_marked")
    }

    func dismissPostActivationPaywall(accepted: Bool) {
        shouldPresentPostActivationPaywall = false
        persistence.setPaywallSeen(true)
        track(event: .paywallDismissed, surface: .global, action: accepted ? "accepted" : "dismissed")
    }

    func completeIntro() {
        hasSeenIntro = true
        persistence.setHasSeenIntro(true)
        track(event: .primaryCTATapped, surface: .intro, action: "continue_to_auth")
    }

    func completeSignInWithApple(
        userID: String,
        email: String?,
        fullName: PersonNameComponents?
    ) -> String? {
        let normalizedUserID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedUserID.isEmpty else {
            return "Apple sign-in didn’t return a valid account identifier."
        }

        let normalizedProvidedEmail = normalizedEmail(from: email ?? "")
        let emailSource: String
        let resolvedEmail: String
        if isValidEmail(normalizedProvidedEmail) {
            resolvedEmail = normalizedProvidedEmail
            emailSource = "credential"
            persistence.persistKnownAppleEmail(normalizedProvidedEmail, for: normalizedUserID)
        } else if let knownEmail = persistence.loadKnownAppleEmail(for: normalizedUserID),
                  isValidEmail(knownEmail) {
            resolvedEmail = knownEmail
            emailSource = "cached"
        } else {
            resolvedEmail = generatedFallbackAppleEmail(for: normalizedUserID)
            emailSource = "generated"
        }

        let displayName = resolvedDisplayName(from: fullName)
        persistSession(
            email: resolvedEmail,
            appleUserID: normalizedUserID,
            displayName: displayName
        )

        track(
            event: .actionCompleted,
            surface: .auth,
            action: "apple_sign_in_completed",
            metadata: [
                "email_source": emailSource,
                "has_name": displayName == nil ? "false" : "true"
            ]
        )
        triggerHaptic(intent: .success)
        return nil
    }

    func signOut() {
        persistence.clearSession()
        session = nil
        onboarding = OnboardingProgress()
        appState = AppStateResolver.reduce(state: appState, event: .signedOut)
        selectedTab = .today
        regulateLaunchRequest = nil
        activeRegulateSession = nil
        regulateSessionHistory = []
        experiments = MindSenseDemoSeedCatalog.defaultExperiments(for: .balancedDay)
        demoScenario = .balancedDay
        demoMetrics = DemoScenario.balancedDay.baseMetrics
        demoEventHistory = MindSenseDemoSeedCatalog.seededEvents(for: .balancedDay)
        demoHealthProfile = MindSenseDemoSeedCatalog.seededHealthProfile(for: .balancedDay, demoDay: DemoScenario.balancedDay.defaultDay)
        demoSavedInsights = []
        demoLastUpdatedAt = Date()
        demoDay = DemoScenario.balancedDay.defaultDay
        demoDataIssue = nil
        guidedDemoPathStep = nil
        coreScreenStates = [:]
        shouldPresentPostActivationPaywall = false
        persistence.setPaywallSeen(false)
        persistence.clearOnboardingTimer()
        persistence.clearDemoState()
        persistExperiments()
        track(event: .actionCompleted, surface: .global, action: "sign_out")
    }

    func canComplete(step: OnboardingStep) -> Bool {
        let activationSteps = OnboardingStep.activationSteps
        guard let index = activationSteps.firstIndex(of: step) else {
            return true
        }
        guard index > 0 else {
            return true
        }
        let previousStep = activationSteps[index - 1]
        return onboarding.isComplete(previousStep)
    }

    func completeOnboarding(step: OnboardingStep, checkInValue: Int? = nil) {
        startOnboardingTimerIfNeeded()

        guard canComplete(step: step) else {
            showBanner(
                title: "Complete required steps in order",
                detail: "Finish the current step to keep setup moving.",
                severity: .warning
            )
            return
        }

        switch step {
        case .baseline:
            if onboarding.baselineStart == nil {
                onboarding.baselineStart = Date()
            }
        case .firstCheckIn:
            onboarding.firstCheckInValue = checkInValue
        default:
            break
        }

        onboarding.markComplete(step)
        persistOnboarding()

        if onboarding.isFullyComplete {
            appState = AppStateResolver.reduce(state: appState, event: .onboardingCompleted)
            showBanner(title: "Setup complete", detail: "Daily guidance is ready.", severity: .success)
            let completionMS = onboardingCompletionMS()
            track(
                event: .onboardingCompleted,
                surface: .onboarding,
                metadata: [
                    "step": "\(OnboardingStep.activationSteps.count)",
                    "completion_ms": "\(completionMS ?? 0)"
                ]
            )
            persistence.clearOnboardingTimer()
        } else {
            let progress = Int(onboardingPercent * 100)
            let stepIndex = OnboardingStep.activationSteps.firstIndex(of: step).map { $0 + 1 } ?? (step.rawValue + 1)
            showBanner(
                title: "Milestone reached",
                detail: "\(progress)% complete.",
                severity: .success
            )
            track(event: .onboardingStepCompleted, surface: .onboarding, metadata: ["step": "\(stepIndex)"])
        }

        triggerHaptic(intent: .success)
    }

    func showBanner(title: String, detail: String, severity: BannerSeverity) {
        let value = AppBanner(title: title, detail: detail, severity: severity)
        banner = value

        bannerTask?.cancel()
        bannerTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if self.banner == value {
                    self.banner = nil
                }
            }
        }
    }

    func clearBanner() {
        bannerTask?.cancel()
        banner = nil
    }

    func track(event: UXEvent, surface: UXSurface? = nil, action: String? = nil, metadata: [String: String] = [:]) {
        var context = metadata
        if let surface {
            context["surface"] = surface.rawValue
        }
        if let action {
            context["action"] = action
        }
        track(event: event.rawValue, metadata: context)
    }

    func track(event: String, metadata: [String: String] = [:]) {
        var context = metadata
        let now = Date()
        context["timestamp"] = Self.analyticsTimestampFormatter.string(from: now)
        analyticsEvents.append(
            .init(
                id: UUID(),
                event: event,
                timestamp: now,
                metadata: context
            )
        )
        let maxEvents = 400
        if analyticsEvents.count > maxEvents {
            analyticsEvents.removeFirst(analyticsEvents.count - maxEvents)
        }
        persistAnalyticsEvents()
    }

    func triggerHaptic(intent: MindSenseHapticIntent) {
        guard hapticsEnabled else { return }

        switch intent {
        case .primary:
            primaryImpactFeedback.impactOccurred(intensity: 0.62)
            primaryImpactFeedback.prepare()
        case .selection:
            selectionFeedback.selectionChanged()
            selectionFeedback.prepare()
        case .success:
            primaryImpactFeedback.impactOccurred(intensity: 0.55)
            primaryImpactFeedback.prepare()
        case .warning:
            notificationFeedback.notificationOccurred(.warning)
            notificationFeedback.prepare()
        case .error:
            notificationFeedback.notificationOccurred(.error)
            notificationFeedback.prepare()
        }
    }

    func triggerHaptic(style: UINotificationFeedbackGenerator.FeedbackType) {
        switch style {
        case .success:
            triggerHaptic(intent: .success)
        case .warning:
            triggerHaptic(intent: .warning)
        case .error:
            triggerHaptic(intent: .error)
        @unknown default:
            triggerHaptic(intent: .selection)
        }
    }

    private var hapticsEnabled: Bool {
        if defaults.object(forKey: "enableHaptics") == nil {
            return true
        }
        return defaults.bool(forKey: "enableHaptics")
    }

    private func startLaunchSequence() {
        let launchStart = Date()
        appState = .launching

        hasSeenIntro = persistence.hasSeenIntro
        session = loadSession()
        if let currentEmail = session?.email {
            onboarding = loadOnboarding(for: currentEmail)
        } else {
            onboarding = OnboardingProgress()
        }
        if session != nil {
            analyticsEvents = loadAnalyticsEvents()
            kpiLastReviewedAt = persistence.kpiReviewedAt
            activeRegulateSession = loadActiveRegulateSession()
            regulateSessionHistory = loadRegulateSessionHistory()
            demoScenario = loadDemoScenario()
            demoMetrics = loadDemoMetrics(for: demoScenario)
            demoEventHistory = loadDemoEvents()
            demoSavedInsights = loadDemoSavedInsights()
            demoDay = loadDemoDay(for: demoScenario)
            demoHealthProfile = loadDemoHealthProfile(for: demoScenario, demoDay: demoDay)
            guidedDemoPathStep = loadGuidedDemoPathStep()
            demoLastUpdatedAt = persistence.demoLastUpdatedAt
            experiments = loadExperiments()
            if experiments.isEmpty {
                experiments = MindSenseDemoSeedCatalog.defaultExperiments(for: demoScenario)
                persistExperiments()
            }
            if let activeRegulateSession, activeRegulateSession.isCompleted {
                self.activeRegulateSession = nil
                persistActiveRegulateSession()
            }
            syncActiveRegulateSessionState()
            refreshDemoHealthSignals(updateSyncTimestamp: false)
            refreshCoreScreensLoadingThenReady()
        } else {
            analyticsEvents = []
            kpiLastReviewedAt = nil
            activeRegulateSession = nil
            regulateSessionHistory = []
            demoScenario = .balancedDay
            demoMetrics = DemoScenario.balancedDay.baseMetrics
            demoEventHistory = []
            demoSavedInsights = []
            demoDay = DemoScenario.balancedDay.defaultDay
            demoHealthProfile = MindSenseDemoSeedCatalog.seededHealthProfile(
                for: .balancedDay,
                demoDay: DemoScenario.balancedDay.defaultDay
            )
            guidedDemoPathStep = nil
            demoLastUpdatedAt = Date()
            experiments = []
            demoDataIssue = nil
            coreScreenStates = [:]
        }
        shouldPresentPostActivationPaywall = false
        if session != nil, !onboarding.isFullyComplete {
            startOnboardingTimerIfNeeded()
        } else {
            persistence.clearOnboardingTimer()
        }

        Task {
            let launchDelay: UInt64 = ProcessInfo.processInfo.arguments.contains("-uitest-ready")
                ? 80_000_000
                : 0
            if launchDelay > 0 {
                try? await Task.sleep(nanoseconds: launchDelay)
            }
            await MainActor.run {
                self.appState = self.computeLaunchDestination()
                let launchMS = Int(Date().timeIntervalSince(launchStart) * 1000)
                self.track(event: .appOpened, metadata: ["state": "\(self.appState)", "launch_ms": "\(launchMS)"])
            }
        }
    }

    private func computeLaunchDestination() -> AppLaunchState {
        AppStateResolver.reduce(
            state: appState,
            event: .launchDataLoaded(session: session, onboarding: onboarding)
        )
    }

    private func loadSession() -> AuthSession? {
        persistence.loadSession()
    }

    private func persistSession(
        email: String,
        appleUserID: String? = nil,
        displayName: String? = nil
    ) {
        let normalized = normalizedEmail(from: email)

        persistence.persistSession(
            email: normalized,
            appleUserID: appleUserID,
            displayName: normalizedDisplayName(displayName)
        )

        session = AuthSession(
            email: normalized,
            appleUserID: appleUserID,
            displayName: normalizedDisplayName(displayName)
        )
        onboarding = loadOnboarding(for: normalized)
        activeRegulateSession = loadActiveRegulateSession()
        regulateSessionHistory = loadRegulateSessionHistory()
        demoScenario = loadDemoScenario()
        demoMetrics = loadDemoMetrics(for: demoScenario)
        demoEventHistory = loadDemoEvents()
        demoSavedInsights = loadDemoSavedInsights()
        demoDay = loadDemoDay(for: demoScenario)
        demoHealthProfile = loadDemoHealthProfile(for: demoScenario, demoDay: demoDay)
        guidedDemoPathStep = loadGuidedDemoPathStep()
        demoLastUpdatedAt = persistence.demoLastUpdatedAt
        experiments = loadExperiments()
        analyticsEvents = loadAnalyticsEvents()
        kpiLastReviewedAt = persistence.kpiReviewedAt
        if experiments.isEmpty {
            experiments = MindSenseDemoSeedCatalog.defaultExperiments(for: demoScenario)
            persistExperiments()
        }
        refreshDemoHealthSignals(updateSyncTimestamp: false)
        refreshCoreScreensLoadingThenReady()
        appState = AppStateResolver.reduce(
            state: appState,
            event: .sessionRestored(onboarding: onboarding)
        )
        if appState == .needsOnboarding {
            startOnboardingTimerIfNeeded()
        } else {
            persistence.clearOnboardingTimer()
        }
    }

    private func persistOnboarding() {
        guard let email = session?.email else { return }
        persistence.persistOnboarding(onboarding, for: email)
    }

    private func loadOnboarding(for email: String) -> OnboardingProgress {
        persistence.loadOnboarding(for: email)
    }

    private func onboardingKey(for email: String) -> String {
        persistence.onboardingKey(for: email)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), trimmed.contains(".") else {
            return false
        }
        return trimmed.count >= 5
    }

    private func normalizedEmail(from rawEmail: String) -> String {
        rawEmail
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func normalizedDisplayName(_ rawName: String?) -> String? {
        guard let rawName else { return nil }
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func resolvedDisplayName(from components: PersonNameComponents?) -> String? {
        guard let components else { return session?.displayName }
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        let formatted = formatter.string(from: components)
        if let normalized = normalizedDisplayName(formatted) {
            return normalized
        }

        let first = components.givenName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let last = components.familyName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let joined = [first, last]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return normalizedDisplayName(joined)
    }

    private func generatedFallbackAppleEmail(for userID: String) -> String {
        let fragment = sanitizedIdentifierFragment(from: userID)
        return "apple-\(fragment)@mindsense.local"
    }

    private func sanitizedIdentifierFragment(from value: String) -> String {
        let lowered = value.lowercased()
        let compact = lowered.unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .prefix(14)
        let fragment = String(String.UnicodeScalarView(compact))
        return fragment.isEmpty ? "user" : fragment
    }

    private func ratio(_ numerator: Int, _ denominator: Int) -> Double {
        guard denominator > 0 else { return 0 }
        return Double(numerator) / Double(denominator)
    }

    private func startOnboardingTimerIfNeeded() {
        persistence.startOnboardingTimerIfNeeded()
    }

    private func onboardingCompletionMS() -> Int? {
        persistence.onboardingCompletionMS()
    }

    private func retentionRate(dayOffset: Int) -> Double {
        let opens = analyticsEvents
            .filter { $0.event == UXEvent.appOpened.rawValue }
            .sorted(by: { $0.timestamp < $1.timestamp })
        guard let firstOpen = opens.first else { return 0 }
        guard let dayStart = Calendar.current.date(byAdding: .day, value: dayOffset, to: firstOpen.timestamp) else {
            return 0
        }
        guard let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) else {
            return 0
        }
        let retained = opens.contains { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
        return retained ? 1 : 0
    }

    private func maybePresentPostActivationPaywall() {
        guard hasReachedActivationMilestone else { return }
        guard !persistence.paywallSeen else { return }
        shouldPresentPostActivationPaywall = true
        track(event: .paywallPresented, surface: .global, action: "post_activation_offer")
    }

    private func persistRegulateSessionHistory() {
        persistence.persistRegulateSessionHistory(regulateSessionHistory)
    }

    private func loadRegulateSessionHistory() -> [RegulateSessionRecord] {
        let result = persistence.loadRegulateSessionHistory()
        if let issue = result.issue {
            markDemoDataIssue(issue)
        }
        return result.value
    }

    private func persistActiveRegulateSession() {
        persistence.persistActiveRegulateSession(activeRegulateSession)
    }

    private func loadActiveRegulateSession() -> RegulateSessionRecord? {
        let result = persistence.loadActiveRegulateSession()
        if let issue = result.issue {
            markDemoDataIssue(issue)
        }
        return result.value
    }

    private func persistExperiments() {
        persistence.persistExperiments(experiments)
    }

    private func loadExperiments() -> [Experiment] {
        let result = persistence.loadExperiments()
        if let issue = result.issue {
            markDemoDataIssue(issue)
        }
        return result.value
    }

    private func persistAnalyticsEvents() {
        persistence.persistAnalyticsEvents(analyticsEvents)
    }

    private func loadAnalyticsEvents() -> [AnalyticsEventRecord] {
        persistence.loadAnalyticsEvents()
    }

    private func persistDemoScenario() {
        persistence.persistDemoScenario(demoScenario)
    }

    private func loadDemoScenario() -> DemoScenario {
        persistence.loadDemoScenario()
    }

    private func persistDemoMetrics() {
        persistence.persistDemoMetrics(demoMetrics)
    }

    private func loadDemoMetrics(for scenario: DemoScenario) -> DemoMetricSnapshot {
        let result = persistence.loadDemoMetrics(fallback: scenario.baseMetrics)
        if let issue = result.issue {
            markDemoDataIssue(issue)
        }
        return result.value
    }

    private func persistDemoEvents() {
        persistence.persistDemoEvents(demoEventHistory)
    }

    private func loadDemoEvents() -> [DemoEventRecord] {
        let seeded = MindSenseDemoSeedCatalog.seededEvents(for: demoScenario)
        let result = persistence.loadDemoEvents(fallback: seeded)
        if let issue = result.issue {
            markDemoDataIssue(issue)
        }
        return result.value
    }

    private func persistDemoHealthProfile() {
        persistence.persistDemoHealthProfile(demoHealthProfile)
    }

    private func loadDemoHealthProfile(for scenario: DemoScenario, demoDay: Int) -> DemoHealthProfile {
        let seeded = MindSenseDemoSeedCatalog.seededHealthProfile(for: scenario, demoDay: demoDay)
        let result = persistence.loadDemoHealthProfile(fallback: seeded)
        if let issue = result.issue {
            markDemoDataIssue(issue)
        }
        return result.value
    }

    private func refreshDemoHealthSignals(updateSyncTimestamp: Bool) {
        demoHealthProfile = DemoHealthSignalEngine.refreshedProfile(
            existing: demoHealthProfile,
            scenario: demoScenario,
            metrics: demoMetrics,
            demoDay: demoDay,
            completedSessionCount: regulateSessionHistory.filter(\.isCompleted).count,
            activeExperimentAdherence: activeExperiment?.adherencePercent ?? 0,
            now: Date(),
            updateSyncTimestamp: updateSyncTimestamp
        )
        persistDemoHealthProfile()
    }

    private func persistDemoSavedInsights() {
        persistence.persistDemoSavedInsights(demoSavedInsights)
    }

    private func loadDemoSavedInsights() -> [DemoSavedInsight] {
        let result = persistence.loadDemoSavedInsights()
        if let issue = result.issue {
            markDemoDataIssue(issue)
        }
        return result.value
    }

    private func persistGuidedDemoPathStep() {
        persistence.persistGuidedDemoPathStep(guidedDemoPathStep)
    }

    private func loadGuidedDemoPathStep() -> GuidedDemoPathStep? {
        persistence.loadGuidedDemoPathStep()
    }

    private func persistDemoDay() {
        persistence.persistDemoDay(demoDay)
    }

    private func loadDemoDay(for scenario: DemoScenario) -> Int {
        persistence.loadDemoDay(fallback: scenario.defaultDay)
    }

    private func markDemoDataIssue(_ message: String) {
        if demoDataIssue == nil {
            demoDataIssue = message
        }
    }

    private func repairDemoData() {
        demoDataIssue = nil
        demoScenario = .balancedDay
        demoMetrics = DemoScenario.balancedDay.baseMetrics
        demoDay = DemoScenario.balancedDay.defaultDay
        demoEventHistory = MindSenseDemoSeedCatalog.seededEvents(for: .balancedDay)
        demoHealthProfile = MindSenseDemoSeedCatalog.seededHealthProfile(for: .balancedDay, demoDay: DemoScenario.balancedDay.defaultDay)
        demoSavedInsights = []
        guidedDemoPathStep = nil
        experiments = MindSenseDemoSeedCatalog.defaultExperiments(for: .balancedDay)
        persistDemoScenario()
        persistDemoMetrics()
        persistDemoDay()
        persistDemoEvents()
        persistDemoHealthProfile()
        persistDemoSavedInsights()
        persistGuidedDemoPathStep()
        persistExperiments()
        refreshCoreScreensLoadingThenReady()
        showActionFeedback(.updated, detail: "Data reloaded from defaults.")
    }

    private func refreshCoreScreensLoadingThenReady() {
        for screen in CoreScreenID.allCases {
            coreScreenStates[screen] = resolvedScreenState(for: screen)
        }
    }

    private func resolvedScreenState(for screen: CoreScreenID) -> ScreenMode {
        if let demoDataIssue {
            return .error(
                .init(
                    title: "Data issue",
                    message: demoDataIssue
                )
            )
        }

        switch screen {
        case .today:
            if todayPrimaryDrivers.isEmpty {
                return .empty(
                    .init(
                        title: "No driver data yet",
                        message: "Refresh data or add a check-in to rebuild today's context."
                    )
                )
            }
        case .regulate:
            if regulatePresetCatalog.isEmpty {
                return .empty(
                    .init(
                        title: "No protocols available",
                        message: "Refresh data to load a regulate protocol set."
                    )
                )
            }
        case .data:
            if experiments.isEmpty {
                return .empty(
                    .init(
                        title: "No experiments available",
                        message: "Refresh data to load experiment templates."
                    )
                )
            }
        }

        return .ready
    }

    private func updateDemoLastUpdated() {
        let now = Date()
        demoLastUpdatedAt = now
        persistence.setDemoLastUpdatedAt(now)
    }

    private func applyMetricDelta(_ delta: DemoMetricDelta) {
        demoMetrics.load = Int(clamp(Double(demoMetrics.load + delta.load), min: 8, max: 96))
        demoMetrics.readiness = Int(clamp(Double(demoMetrics.readiness + delta.readiness), min: 8, max: 98))
        demoMetrics.consistency = Int(clamp(Double(demoMetrics.consistency + delta.consistency), min: 10, max: 99))
        persistDemoMetrics()
    }

    private func bumpDemoDay(by value: Int) {
        guard value != 0 else { return }
        demoDay = max(1, min(35, demoDay + value))
        persistDemoDay()
    }

    func presetDefinition(for presetID: RegulatePresetID) -> DemoRegulatePreset? {
        regulatePresetCatalog.first(where: { $0.id == presetID })
    }

    func insightNarrative(for focus: SignalFocus) -> String {
        scenarioProfile.signalNarratives[focus] ?? focus.coachBody
    }

    func trendPoints(for window: TrendWindow) -> [TrendPoint] {
        let now = Date()
        let stepSeconds = window.stepHours * 3600
        let volatility: Double
        let readinessAnchor = Double(demoMetrics.readiness)
        let loadAnchor = Double(demoMetrics.load)
        let dayAdjustment = Double(demoDay - demoScenario.defaultDay) * 0.35
        let completedImpact = Double(regulateSessionHistory.lazy.filter(\.isCompleted).count) * 0.18
        let experimentImpact = Double(experiments.lazy.filter { $0.status == .completed }.count) * 0.22

        switch demoScenario {
        case .highStressDay:
            volatility = 1.0
        case .balancedDay:
            volatility = 0.72
        case .recoveryWeek:
            volatility = 0.58
        }

        return (0..<window.points).map { index in
            let t = Double(index)
            let drift = t / Double(max(window.points - 1, 1))

            let readinessWave = (sin(t * 0.66) * 4.4 + cos(t * 0.22) * 2.1) * volatility
            let loadWave = (cos(t * 0.61 + 0.9) * 4.2 + sin(t * 0.27 + 1.4) * 2.0) * volatility

            let readiness = clamp(
                (readinessAnchor - 6 + (12 * drift)) + readinessWave + dayAdjustment + completedImpact + experimentImpact,
                min: 20,
                max: 98
            )
            let load = clamp(
                (loadAnchor + 6 - (11 * drift)) + loadWave - dayAdjustment - completedImpact - experimentImpact,
                min: 12,
                max: 96
            )

            let age = Double(window.points - 1 - index)
            let date = now.addingTimeInterval(-(age * stepSeconds))

            return TrendPoint(index: index, time: date, readiness: readiness, load: load)
        }
    }

    func projectedLoadDeltaInTwoHours(for preset: RegulatePresetID) -> Int {
        RecommendationEngine.projectedLoadDeltaInTwoHours(for: preset, context: recommendationContext)
    }

    func projectedLoadInTwoHours(for preset: RegulatePresetID) -> Int {
        RecommendationEngine.projectedLoadInTwoHours(for: preset, context: recommendationContext)
    }

    func expectedEffectConfidence(for preset: RegulatePresetID) -> Int {
        let history = regulateSessionHistory.filter {
            $0.preset == preset && $0.state == .completed && $0.outcome != nil
        }
        let qualityBonus = Double(healthDataQualityScore) * 0.12
        let baseline = 54.0 + qualityBonus
        guard !history.isEmpty else {
            return Int(
                clamp(
                    (baseline + presetRankScore(for: preset) * 6).rounded(),
                    min: 42,
                    max: 95
                )
            )
        }

        let rewardMean = history
            .compactMap(\.outcome)
            .map(sessionReward)
            .reduce(0, +) / Double(history.count)
        let confidence = baseline + (rewardMean * 18) + (Double(min(history.count, 8)) * 2.2)
        return Int(clamp(confidence.rounded(), min: 45, max: 97))
    }

    func previewSessionEffectMetrics(
        preset: RegulatePresetID,
        direction: SessionImpactDirection,
        intensity: Int
    ) -> RegulateEffectMetrics {
        MindSenseDeltaEngine.sessionEffectMetrics(
            direction: direction,
            intensity: intensity,
            preset: preset,
            scenario: demoScenario,
            quality: measurementQuality(for: preset)
        )
    }

    func experimentEffectEstimate(for experiment: Experiment) -> String {
        let adherence = experiment.adherencePercent
        let confidence: String
        if adherence >= 75 {
            confidence = "moderate confidence"
        } else if adherence >= 45 {
            confidence = "emerging confidence"
        } else {
            confidence = "low confidence"
        }

        let effectLine: String
        switch experiment.focus {
        case .readiness:
            effectLine = "Readiness +\(max(1, adherence / 22))"
        case .load:
            effectLine = "Stress episode frequency -\(max(4, adherence / 6))%"
        case .consistency:
            effectLine = "Consistency +\(max(1, adherence / 24))"
        }

        return "\(effectLine) (\(confidence))"
    }

    private func presetRankScore(for preset: RegulatePresetID) -> Double {
        let baseScenarioScore: Double = switch (demoScenario, preset) {
        case (.highStressDay, .calmNow): 1.0
        case (.highStressDay, .focusPrep): 0.82
        case (.highStressDay, .sleepDownshift): 0.66
        case (.balancedDay, .focusPrep): 1.0
        case (.balancedDay, .calmNow): 0.88
        case (.balancedDay, .sleepDownshift): 0.72
        case (.recoveryWeek, .sleepDownshift): 1.0
        case (.recoveryWeek, .focusPrep): 0.8
        case (.recoveryWeek, .calmNow): 0.77
        }

        let historyOutcomes = regulateSessionHistory.filter {
            $0.preset == preset && $0.state == .completed && $0.outcome != nil
        }
        let historyReward = historyOutcomes
            .compactMap(\.outcome)
            .map(sessionReward)
            .reduce(0, +)
        let historyAdjustment = historyOutcomes.isEmpty
            ? 0
            : (historyReward / Double(historyOutcomes.count)) * 0.32

        let stateAdjustment: Double
        switch preset {
        case .calmNow:
            stateAdjustment = demoMetrics.load > 70 ? 0.2 : -0.06
        case .focusPrep:
            stateAdjustment = demoMetrics.readiness - demoMetrics.load > 8 ? 0.2 : 0
        case .sleepDownshift:
            stateAdjustment = demoMetrics.consistency < 70 ? 0.16 : 0.06
        }

        return baseScenarioScore + historyAdjustment + stateAdjustment
    }

    private func sessionReward(_ outcome: SessionOutcome) -> Double {
        let directionScore: Double = switch outcome.direction {
        case .better: 1.0
        case .same: 0.42
        case .worse: -0.45
        }
        let heartReward = Double(outcome.effectMetrics.heartRateDownshiftBPM) / 12.0
        let hrvReward = Double(outcome.effectMetrics.hrvShiftMS) / 16.0
        let feelingReward = Double(outcome.feelRating - 3) / 3.0
        let helpfulnessReward: Double = switch outcome.helpfulness {
        case .yes: 0.42
        case .some: 0.14
        case .no: -0.3
        }
        return directionScore + heartReward + hrvReward + feelingReward + helpfulnessReward
    }

    private func measurementQuality(for preset: RegulatePresetID) -> RegulateMeasurementQuality {
        if preset == .calmNow && healthDataQualityScore >= 78 {
            return .live
        }
        return .estimated
    }

    func experimentCorrelationInsight(for experiment: Experiment) -> String {
        switch experiment.focus {
        case .readiness:
            return "On days this was done before 11am, afternoon HR drift stayed lower."
        case .load:
            return "When this was completed before pressure blocks, peak episode intensity declined."
        case .consistency:
            return "When repeated at the same time, recovery windows became more predictable."
        }
    }

    private func rankedDriversForToday() -> [DriverImpact] {
        RecommendationEngine.rankDrivers(
            baseDrivers: scenarioProfile.primaryDrivers + scenarioProfile.secondaryDrivers,
            context: recommendationContext
        )
    }

    private func latestDeltaSinceCheckIn() -> DemoCheckInDeltaSummary? {
        guard let baseline = demoEventHistory.first(where: { $0.kind == .checkIn && $0.metricSnapshot != nil }),
              let snapshot = baseline.metricSnapshot else {
            return nil
        }

        let delta = DemoMetricDelta(
            load: demoMetrics.load - snapshot.load,
            readiness: demoMetrics.readiness - snapshot.readiness,
            consistency: demoMetrics.consistency - snapshot.consistency
        )

        let eventsSince = eventsSince(eventID: baseline.id)
        let explanation = checkInDeltaExplanation(delta: delta, sinceEvents: eventsSince)

        return DemoCheckInDeltaSummary(
            baselineTitle: baseline.title.lowercased(),
            baselineTimestamp: baseline.timestamp,
            loadDelta: delta.load,
            readinessDelta: delta.readiness,
            consistencyDelta: delta.consistency,
            explanation: explanation
        )
    }

    private func checkInDeltaExplanation(delta: DemoMetricDelta, sinceEvents: [DemoEventRecord]) -> String {
        var fragments: [String] = []

        if delta.load < 0 {
            fragments.append("Load is down \(abs(delta.load)) points")
        } else if delta.load > 0 {
            fragments.append("Load is up \(delta.load) points")
        }

        if delta.readiness > 0 {
            fragments.append("readiness is up \(delta.readiness)")
        } else if delta.readiness < 0 {
            fragments.append("readiness is down \(abs(delta.readiness))")
        }

        if delta.consistency != 0 {
            fragments.append("consistency shifted \(signed(delta.consistency))")
        }

        let outcomesSaved = sinceEvents.filter { $0.title.localizedCaseInsensitiveContains("outcome saved") }.count
        let stressEvents = sinceEvents.reduce(into: 0) { count, event in
            let text = normalizedEventText(event)
            if text.contains("stress") || text.contains("cancelled") {
                count += 1
            }
        }
        let experimentLogs = sinceEvents.filter { $0.kind == .experiment }.count

        if outcomesSaved > 0 {
            fragments.append("driven by \(outcomesSaved) completed regulate session\(outcomesSaved == 1 ? "" : "s")")
        }
        if experimentLogs > 0 {
            fragments.append("reinforced by \(experimentLogs) experiment log\(experimentLogs == 1 ? "" : "s")")
        }
        if stressEvents > 0 {
            fragments.append("with \(stressEvents) stress indicator\(stressEvents == 1 ? "" : "s") still active")
        }

        if fragments.isEmpty {
            return "No major shift yet since the last check-in. Add one regulate session or experiment log to create measurable change."
        }

        let headline = fragments.prefix(2).joined(separator: ", ")
        if fragments.count <= 2 {
            return "\(headline)."
        }
        return "\(headline). \(fragments.dropFirst(2).joined(separator: ", "))."
    }

    private func buildDataSignalTrendTiles() -> [DataSignalTrendTile] {
        let points = trendPoints(for: .seven)
        let readinessRecent = average(points.suffix(7).map(\.readiness)) ?? Double(demoMetrics.readiness)
        let readinessPrior = average(points.dropLast(7).suffix(7).map(\.readiness)) ?? Double(demoScenario.baseMetrics.readiness)
        let readinessDelta = Int((readinessRecent - readinessPrior).rounded())

        let currentWeekStart = weekWindowStartDate()
        let priorWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart)
            ?? currentWeekStart.addingTimeInterval(-(7 * 86_400))
        let currentSpikes = recentStressEpisodes.filter { $0.end >= currentWeekStart }.count
        let priorSpikes = recentStressEpisodes.filter {
            $0.end >= priorWeekStart && $0.end < currentWeekStart
        }.count
        let spikesDelta = currentSpikes - priorSpikes

        let sleepConsistency = demoHealthProfile.quality.sleepCoverage
        let consistencyShift = demoMetrics.consistency - demoScenario.baseMetrics.consistency
        let priorSleepConsistency = max(25, min(99, sleepConsistency - Int((Double(consistencyShift) * 0.35).rounded())))
        let sleepDelta = sleepConsistency - priorSleepConsistency

        return [
            .init(
                id: "readiness_7d",
                title: "Readiness",
                value: "\(Int(readinessRecent.rounded()))",
                deltaText: dataDeltaLabel(readinessDelta, unit: "pts"),
                direction: trendDirection(for: readinessDelta),
                linkedFocus: .readiness
            ),
            .init(
                id: "activation_spikes",
                title: "Activation spikes",
                value: "\(currentSpikes)/wk",
                deltaText: dataDeltaLabel(spikesDelta, unit: "wk"),
                direction: trendDirection(for: spikesDelta),
                linkedFocus: .load
            ),
            .init(
                id: "sleep_consistency",
                title: "Sleep consistency",
                value: "\(sleepConsistency)",
                deltaText: dataDeltaLabel(sleepDelta, unit: "pts"),
                direction: trendDirection(for: sleepDelta),
                linkedFocus: .consistency
            )
        ]
    }

    private func buildWhatIsWorkingSummary() -> DemoWhatIsWorkingSummary {
        let windowStart = weekWindowStartDate()
        let recentCompletedSessions = regulateSessionHistory.filter {
            $0.isCompleted && ($0.completedAt ?? $0.startedAt) >= windowStart
        }

        let topProtocolLine: String
        if recentCompletedSessions.isEmpty {
            let preset = primaryRecommendation.preset
            let duration = presetDefinition(for: preset)?.durationLabel ?? "\(primaryRecommendation.timeMinutes) min"
            topProtocolLine = "\(preset.title) (\(duration))"
        } else {
            let grouped = Dictionary(grouping: recentCompletedSessions, by: \.preset)
            let ranked = grouped.compactMap { preset, sessions -> (preset: RegulatePresetID, reward: Double, count: Int)? in
                let outcomes = sessions.compactMap(\.outcome)
                guard !outcomes.isEmpty else { return nil }
                let reward = outcomes.map(sessionReward).reduce(0, +) / Double(outcomes.count)
                return (preset, reward, sessions.count)
            }
            .sorted {
                if $0.reward == $1.reward {
                    return $0.count > $1.count
                }
                return $0.reward > $1.reward
            }

            if let best = ranked.first,
               let preset = presetDefinition(for: best.preset) {
                topProtocolLine = "\(preset.title) (\(preset.durationLabel))"
            } else {
                let preset = primaryRecommendation.preset
                topProtocolLine = "\(preset.title) (\(primaryRecommendation.timeMinutes) min)"
            }
        }

        let weeklyEpisodes = recentStressEpisodes.filter { $0.end >= windowStart }
        var triggerCounts: [String: Int] = [:]
        for episode in weeklyEpisodes {
            for tag in episode.userTags where !tag.isEmpty {
                triggerCounts[tag, default: 0] += 1
            }
        }
        if triggerCounts.isEmpty {
            for episode in weeklyEpisodes {
                triggerCounts["\(episode.likelyDriver.title) load", default: 0] += 1
            }
        }
        let topTrigger = triggerCounts.max(by: { $0.value < $1.value })?.key ?? "No dominant trigger pattern yet"

        let recoveryWindowLabel = bestRecoveryWindowLabel()
        return .init(
            topProtocol: topProtocolLine,
            topTrigger: normalizedTriggerLabel(topTrigger),
            bestRecoveryWindow: recoveryWindowLabel
        )
    }

    private func bestRecoveryWindowLabel() -> String {
        struct RecoveryRun {
            var start: Date
            var end: Date
            var duration: TimeInterval {
                end.timeIntervalSince(start)
            }
        }

        let segments = demoHealthProfile.timelineSegments
            .filter { $0.state == .recovery }
            .sorted(by: { $0.start < $1.start })
        guard !segments.isEmpty else {
            return "No clear recovery window yet"
        }

        var runs: [RecoveryRun] = []
        for segment in segments {
            if var last = runs.last,
               abs(segment.start.timeIntervalSince(last.end)) <= 1 {
                last.end = segment.end
                runs[runs.count - 1] = last
            } else {
                runs.append(.init(start: segment.start, end: segment.end))
            }
        }

        guard let best = runs.max(by: { $0.duration < $1.duration }) else {
            return "No clear recovery window yet"
        }
        return "\(best.start.formattedTimeLabel())-\(best.end.formattedTimeLabel())"
    }

    private func normalizedTriggerLabel(_ raw: String) -> String {
        switch raw.lowercased() {
        case "meeting":
            return "Meeting load"
        case "caffeine":
            return "Caffeine timing"
        case "commute":
            return "Commute pressure"
        case "conflict":
            return "Social conflict"
        case "noise":
            return "Environmental noise"
        case "screen overload":
            return "Screen overload"
        case "unknown":
            return "Unknown context"
        default:
            return raw
        }
    }

    private func trendDirection(for delta: Int) -> DataTrendDirection {
        if delta > 0 {
            return .up
        }
        if delta < 0 {
            return .down
        }
        return .flat
    }

    private func dataDeltaLabel(_ delta: Int, unit: String) -> String {
        if delta == 0 {
            return "steady vs prior"
        }
        return "\(signed(delta)) \(unit) vs prior"
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func buildWeeklySummary() -> DemoWeeklySummary {
        let events = weeklyWindowEvents()
        let completedSessions = regulateSessionHistory.filter {
            $0.isCompleted && ($0.completedAt ?? $0.startedAt) >= weekWindowStartDate()
        }
        let improvedSessions = completedSessions.filter { $0.outcome?.direction == .better }
        let cancelledSessions = regulateSessionHistory.filter {
            $0.state == .cancelled && ($0.cancelledAt ?? $0.startedAt) >= weekWindowStartDate()
        }
        let activeAdherence = activeExperiment?.adherencePercent ?? 0

        var wins: [String] = []
        if improvedSessions.count > 0 {
            wins.append("\(improvedSessions.count) regulate outcome\(improvedSessions.count == 1 ? "" : "s") improved after completion.")
        }
        if activeAdherence >= 65 {
            wins.append("Experiment adherence reached \(activeAdherence)%, improving data reliability.")
        }
        if demoMetrics.readiness >= demoScenario.baseMetrics.readiness {
            wins.append("Readiness is at or above baseline (\(demoMetrics.readiness)).")
        }
        if wins.isEmpty {
            wins = ["You are still building baseline coverage. One completed regulate session can create your first measurable win."]
        }

        var risks: [String] = []
        if demoMetrics.load >= demoScenario.baseMetrics.load + 8 {
            risks.append("Load is running \(demoMetrics.load - demoScenario.baseMetrics.load) points above baseline.")
        }
        if cancelledSessions.count > 0 {
            risks.append("\(cancelledSessions.count) cancelled session\(cancelledSessions.count == 1 ? "" : "s") reduced session quality.")
        }
        if activeExperiment != nil, activeAdherence > 0, activeAdherence < 50 {
            risks.append("Experiment adherence is \(activeAdherence)% and may weaken result confidence.")
        }
        if recentStressSignalCount() > recentRecoverySignalCount() + 1 {
            risks.append("Recent stress markers outweigh recovery actions.")
        }
        if risks.isEmpty {
            risks = ["No major risk spikes detected; maintain routine consistency to hold trend stability."]
        }

        let nextBest = primaryRecommendation.summaryLine
        _ = events // keeps weekly history logic explicit for future expansion.
        return DemoWeeklySummary(
            wins: Array(wins.prefix(2)),
            risks: Array(risks.prefix(2)),
            nextBestAction: nextBest
        )
    }

    private func weekWindowStartDate() -> Date {
        Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date().addingTimeInterval(-6 * 86_400)
    }

    private func weeklyWindowEvents() -> [DemoEventRecord] {
        let fallback = Array(demoEventHistory.prefix(20))
        let dayFloor = max(1, demoDay - 6)
        let byDemoDay = demoEventHistory.filter { ($0.demoDay ?? demoScenario.defaultDay) >= dayFloor }
        if !byDemoDay.isEmpty {
            return byDemoDay
        }
        let start = weekWindowStartDate()
        let byDate = demoEventHistory.filter { $0.timestamp >= start }
        return byDate.isEmpty ? fallback : byDate
    }

    private func buildFallbackSavedInsights() -> [DemoSavedInsight] {
        var insights: [DemoSavedInsight] = [
            .init(
                id: UUID(),
                timestamp: Date(),
                scenario: demoScenario,
                title: "Next best action",
                detail: primaryRecommendation.summaryLine
            )
        ]

        if let latestOutcome = latestCompletedSession?.outcome {
            insights.append(
                .init(
                    id: UUID(),
                    timestamp: latestCompletedSession?.completedAt ?? Date(),
                    scenario: demoScenario,
                    title: "Latest regulate outcome",
                    detail: "Outcome was \(latestOutcome.direction.title.lowercased()) at \(latestOutcome.intensity)/5."
                )
            )
        }

        if let latestExperiment = completedExperiments.sorted(by: { ($0.result?.completedAt ?? .distantPast) > ($1.result?.completedAt ?? .distantPast) }).first,
           let result = latestExperiment.result {
            insights.append(
                .init(
                    id: UUID(),
                    timestamp: result.completedAt,
                    scenario: demoScenario,
                    title: "\(latestExperiment.title) result",
                    detail: result.summary
                )
            )
        }

        return insights
    }

    private func saveInsight(title: String, detail: String) {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty, !normalizedDetail.isEmpty else { return }

        let duplicateExists = demoSavedInsights.contains(where: {
            $0.title == normalizedTitle &&
            Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .day)
        })
        guard !duplicateExists else { return }

        let insight = DemoSavedInsight(
            id: UUID(),
            timestamp: Date(),
            scenario: demoScenario,
            title: normalizedTitle,
            detail: normalizedDetail
        )
        demoSavedInsights.insert(insight, at: 0)
        demoSavedInsights = Array(demoSavedInsights.prefix(40))
        persistDemoSavedInsights()
    }

    private func nextGuidedStep(after step: GuidedDemoPathStep) -> GuidedDemoPathStep? {
        GuidedDemoPathStep(rawValue: step.rawValue + 1)
    }

    private func eventsSince(eventID: UUID) -> [DemoEventRecord] {
        guard let index = demoEventHistory.firstIndex(where: { $0.id == eventID }) else { return [] }
        if index == 0 {
            return []
        }
        return Array(demoEventHistory.prefix(index))
    }

    private func recentEventWindow() -> [DemoEventRecord] {
        Array(demoEventHistory.prefix(12))
    }

    private func recentStressSignalCount() -> Int {
        recentEventWindow().filter { isStressSignal(event: $0) }.count
    }

    private func recentRecoverySignalCount() -> Int {
        recentEventWindow().filter { isRecoverySignal(event: $0) }.count
    }

    private func recentKeywordCount(_ keywords: [String]) -> Int {
        recentEventWindow().filter { event in
            let text = normalizedEventText(event)
            return keywords.contains(where: { text.contains($0) })
        }.count
    }

    private func isStressSignal(event: DemoEventRecord) -> Bool {
        let text = normalizedEventText(event)
        if text.contains("stress") || text.contains("deadline") || text.contains("conflict") || text.contains("cancelled") || text.contains("caffeine") {
            return true
        }
        return event.kind == .system && text.contains("injected")
    }

    private func isRecoverySignal(event: DemoEventRecord) -> Bool {
        let text = normalizedEventText(event)
        if text.contains("exercise") || text.contains("wind-down") || text.contains("outcome saved") || text.contains("completed") {
            return true
        }
        if event.kind == .experiment && text.contains("logged") {
            return true
        }
        return false
    }

    private func normalizedEventText(_ event: DemoEventRecord) -> String {
        "\(event.title) \(event.detail)".lowercased()
    }

    private func signed(_ value: Int) -> String {
        if value > 0 {
            return "+\(value)"
        }
        return "\(value)"
    }
}

func clamp(_ value: Double, min: Double, max: Double) -> Double {
    Swift.min(Swift.max(value, min), max)
}

extension Date {
    func formattedDateLabel() -> String {
        formatted(date: .abbreviated, time: .omitted)
    }

    func formattedTimeLabel() -> String {
        formatted(date: .omitted, time: .shortened)
    }
}
