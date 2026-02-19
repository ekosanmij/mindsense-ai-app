import Foundation

enum MindSenseDeltaEngine {
    static func sessionOutcome(direction: SessionImpactDirection, intensity: Int) -> DemoMetricDelta {
        switch direction {
        case .better:
            return .init(
                load: -(intensity * 2),
                readiness: intensity * 2,
                consistency: 1
            )
        case .same:
            return .init(load: -1, readiness: 1, consistency: 1)
        case .worse:
            return .init(
                load: intensity * 2,
                readiness: -(intensity * 2),
                consistency: -1
            )
        }
    }

    static func experimentCheckIn(focus: SignalFocus) -> DemoMetricDelta {
        switch focus {
        case .load:
            return .init(load: -2, readiness: 1, consistency: 1)
        case .readiness:
            return .init(load: -1, readiness: 2, consistency: 1)
        case .consistency:
            return .init(load: -1, readiness: 1, consistency: 2)
        }
    }

    static func completedExperiment(focus: SignalFocus, perceivedChange: Int) -> DemoMetricDelta {
        let scaled = max(-5, min(5, perceivedChange))
        switch focus {
        case .load:
            return .init(load: -scaled, readiness: max(0, scaled / 2), consistency: 1)
        case .readiness:
            return .init(load: -1, readiness: scaled, consistency: 1)
        case .consistency:
            return .init(load: -1, readiness: 1, consistency: scaled)
        }
    }

    static func fastForwardedDays(_ days: Int, scenario: DemoScenario) -> DemoMetricDelta {
        switch scenario {
        case .highStressDay:
            return .init(load: min(8, days + 2), readiness: -min(6, days + 1), consistency: -max(1, days / 2))
        case .balancedDay:
            return .init(load: max(-1, days / 2), readiness: min(4, days), consistency: min(3, max(1, days / 2)))
        case .recoveryWeek:
            return .init(load: -min(4, days), readiness: min(5, days + 1), consistency: min(4, days))
        }
    }

    static func experimentCompletionSummary(
        scenarioTitle: String,
        focusTitle: String,
        adherence: Int,
        perceivedChange: Int
    ) -> String {
        let trendDirection: String
        if perceivedChange > 0 {
            trendDirection = "improvement"
        } else if perceivedChange < 0 {
            trendDirection = "decline"
        } else {
            trendDirection = "stable outcome"
        }

        return "\(scenarioTitle): \(focusTitle) experiment finished with \(adherence)% adherence and \(trendDirection) (\(perceivedChange))."
    }

    static func sessionEffectMetrics(
        direction: SessionImpactDirection,
        intensity: Int,
        preset: RegulatePresetID,
        scenario: DemoScenario,
        quality: RegulateMeasurementQuality
    ) -> RegulateEffectMetrics {
        let bounded = max(1, min(5, intensity))

        let presetBoost: Int = switch preset {
        case .calmNow: 2
        case .focusPrep: 1
        case .sleepDownshift: 3
        }

        let scenarioBoost: Int = switch scenario {
        case .highStressDay: 2
        case .balancedDay: 1
        case .recoveryWeek: 1
        }

        let base = bounded + presetBoost + scenarioBoost

        switch direction {
        case .better:
            return .init(
                heartRateDownshiftBPM: min(14, base + 1),
                hrvShiftMS: min(18, base + 3),
                recoverySlope: base >= 8 ? .strong : .moderate,
                quality: quality
            )
        case .same:
            return .init(
                heartRateDownshiftBPM: max(1, bounded / 2),
                hrvShiftMS: max(1, bounded / 2),
                recoverySlope: .moderate,
                quality: .estimated
            )
        case .worse:
            return .init(
                heartRateDownshiftBPM: -max(2, bounded + 1),
                hrvShiftMS: -max(1, bounded / 2),
                recoverySlope: .slow,
                quality: .estimated
            )
        }
    }
}
