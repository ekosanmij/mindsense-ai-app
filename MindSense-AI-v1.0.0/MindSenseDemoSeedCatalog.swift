import Foundation

enum MindSenseDemoSeedCatalog {
    static func defaultExperiments(for scenario: DemoScenario) -> [Experiment] {
        switch scenario {
        case .highStressDay:
            return [
                Experiment(
                    id: UUID(),
                    title: "Midday calm reset",
                    durationDays: 7,
                    hypothesis: "Structured downshifts before pressure windows should reduce afternoon Load spikes.",
                    focus: .load,
                    nextStep: "What: run Calm now before your highest-stress block. Time: 3 min.",
                    estimate: "Expected effect: reduce afternoon load volatility by ~4-7 points.",
                    rationale: "Why: this scenario shows concentrated midday load acceleration.",
                    status: .planned,
                    startedAt: nil,
                    targetEndDate: nil,
                    checkInDaysCompleted: 0,
                    checkInLog: [],
                    result: nil
                ),
                Experiment(
                    id: UUID(),
                    title: "Protect readiness windows",
                    durationDays: 7,
                    hypothesis: "Deliberately timing demanding tasks into stronger readiness windows should improve execution quality.",
                    focus: .readiness,
                    nextStep: "What: block one high-focus session before noon. Time: 45 min.",
                    estimate: "Expected effect: increase readiness stability by ~3 points over one week.",
                    rationale: "Why: morning readiness decay is currently predictable but preventable.",
                    status: .planned,
                    startedAt: nil,
                    targetEndDate: nil,
                    checkInDaysCompleted: 0,
                    checkInLog: [],
                    result: nil
                ),
                Experiment(
                    id: UUID(),
                    title: "Evening downshift anchor",
                    durationDays: 7,
                    hypothesis: "A fixed low-stimulation evening sequence should improve consistency under stress-heavy days.",
                    focus: .consistency,
                    nextStep: "What: start wind-down at a fixed time nightly. Time: 20 min.",
                    estimate: "Expected effect: improve consistency confidence and next-day stability.",
                    rationale: "Why: high-pressure days are creating late arousal carryover.",
                    status: .planned,
                    startedAt: nil,
                    targetEndDate: nil,
                    checkInDaysCompleted: 0,
                    checkInLog: [],
                    result: nil
                )
            ]
        case .balancedDay:
            return [
                Experiment(
                    id: UUID(),
                    title: "Precision midday reset",
                    durationDays: 7,
                    hypothesis: "Light resets during transition windows should keep Load controlled.",
                    focus: .load,
                    nextStep: "What: run Calm now after lunch transition. Time: 3 min.",
                    estimate: "Expected effect: keep load swings inside a narrower range.",
                    rationale: "Why: this scenario is stable and benefits most from drift prevention.",
                    status: .planned,
                    startedAt: nil,
                    targetEndDate: nil,
                    checkInDaysCompleted: 0,
                    checkInLog: [],
                    result: nil
                ),
                Experiment(
                    id: UUID(),
                    title: "Morning deep-work lock",
                    durationDays: 7,
                    hypothesis: "Using the strongest readiness window for deep work should improve output consistency.",
                    focus: .readiness,
                    nextStep: "What: reserve one uninterrupted morning focus block. Time: 60 min.",
                    estimate: "Expected effect: improve readiness-to-output conversion.",
                    rationale: "Why: readiness is already strong in the morning across this scenario.",
                    status: .planned,
                    startedAt: nil,
                    targetEndDate: nil,
                    checkInDaysCompleted: 0,
                    checkInLog: [],
                    result: nil
                ),
                Experiment(
                    id: UUID(),
                    title: "Fixed wake anchor",
                    durationDays: 7,
                    hypothesis: "Maintaining one wake-time anchor should further improve consistency confidence.",
                    focus: .consistency,
                    nextStep: "What: keep wake time inside a 30-minute range. Time: 7 days.",
                    estimate: "Expected effect: raise consistency trend confidence over the week.",
                    rationale: "Why: stable routines compound quickly in a balanced baseline.",
                    status: .planned,
                    startedAt: nil,
                    targetEndDate: nil,
                    checkInDaysCompleted: 0,
                    checkInLog: [],
                    result: nil
                )
            ]
        case .recoveryWeek:
            return [
                Experiment(
                    id: UUID(),
                    title: "Load floor maintenance",
                    durationDays: 7,
                    hypothesis: "Preserving recovery pacing should keep load low and prevent rebound.",
                    focus: .load,
                    nextStep: "What: add one brief calm reset before late-day tasks. Time: 3 min.",
                    estimate: "Expected effect: maintain low-load trend with minimal variance.",
                    rationale: "Why: recovery weeks fail when late-day strain rebounds.",
                    status: .planned,
                    startedAt: nil,
                    targetEndDate: nil,
                    checkInDaysCompleted: 0,
                    checkInLog: [],
                    result: nil
                ),
                Experiment(
                    id: UUID(),
                    title: "Readiness compounding block",
                    durationDays: 7,
                    hypothesis: "Targeted focus during peak readiness should convert recovery into meaningful output gains.",
                    focus: .readiness,
                    nextStep: "What: run Focus prep then one intentional focus block. Time: 35 min.",
                    estimate: "Expected effect: improve readiness durability through late day.",
                    rationale: "Why: readiness is high and trainable in this scenario.",
                    status: .planned,
                    startedAt: nil,
                    targetEndDate: nil,
                    checkInDaysCompleted: 0,
                    checkInLog: [],
                    result: nil
                ),
                Experiment(
                    id: UUID(),
                    title: "Evening routine consistency",
                    durationDays: 7,
                    hypothesis: "Protecting evening routine timing should harden consistency gains.",
                    focus: .consistency,
                    nextStep: "What: repeat the same wind-down sequence nightly. Time: 20 min.",
                    estimate: "Expected effect: strengthen consistency confidence and morning readiness carryover.",
                    rationale: "Why: consistency is already your strongest signal this week.",
                    status: .planned,
                    startedAt: nil,
                    targetEndDate: nil,
                    checkInDaysCompleted: 0,
                    checkInLog: [],
                    result: nil
                )
            ]
        }
    }

    static func seededEvents(for scenario: DemoScenario, now: Date = Date()) -> [DemoEventRecord] {
        let baselineEvents: [(String, String, DemoEventKind)] = switch scenario {
        case .highStressDay:
            [
                ("Scenario loaded", "High Stress Day activated.", .scenario),
                ("Morning check-in 7/10", "Deadlines and fragmented sleep logged.", .checkIn),
                ("Caffeine logged", "Late caffeine marker added.", .reflection)
            ]
        case .balancedDay:
            [
                ("Scenario loaded", "Balanced Day activated.", .scenario),
                ("Morning check-in 4/10", "Stable rhythm with moderate load.", .checkIn),
                ("Exercise logged", "Light walk recorded before work block.", .reflection)
            ]
        case .recoveryWeek:
            [
                ("Scenario loaded", "Recovery Week activated.", .scenario),
                ("Morning check-in 3/10", "Low strain and strong sleep trend.", .checkIn),
                ("Wind-down complete", "Evening recovery routine held.", .reflection)
            ]
        }

        return baselineEvents.enumerated().map { index, event in
            let snapshot: DemoMetricSnapshot? = event.2 == .checkIn ? scenario.baseMetrics : nil
            return DemoEventRecord(
                id: UUID(),
                timestamp: now.addingTimeInterval(Double(-(index + 1) * 2_700)),
                title: event.0,
                detail: event.1,
                kind: event.2,
                metricSnapshot: snapshot,
                demoDay: max(1, scenario.defaultDay - min(index, 2))
            )
        }
        .sorted(by: { $0.timestamp > $1.timestamp })
    }

    static func seededHealthProfile(
        for scenario: DemoScenario,
        demoDay: Int,
        now: Date = Date()
    ) -> DemoHealthProfile {
        DemoHealthSignalEngine.seededProfile(
            for: scenario,
            demoDay: demoDay,
            now: now
        )
    }
}
