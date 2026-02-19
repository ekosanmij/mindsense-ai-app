import Foundation

struct RecommendationEngine {
    struct Context {
        let scenario: DemoScenario
        let metrics: DemoMetricSnapshot
        let baseMetrics: DemoMetricSnapshot
        let confidenceScore: Double
        let stressSignals: Int
        let recoverySignals: Int
        let caffeineSignals: Int
    }

    static func primaryRecommendation(
        context: Context,
        presets: [DemoRegulatePreset],
        fallback: DemoRecommendation
    ) -> DemoRecommendation {
        let load = context.metrics.load
        let readiness = context.metrics.readiness
        let consistency = context.metrics.consistency

        switch context.scenario {
        case .highStressDay:
            if load >= 78 || context.stressSignals >= 3 {
                return recommendation(
                    for: .calmNow,
                    what: "Run Calm now before your next pressure block.",
                    why: "Load is elevated (\(load)) and recent stress markers are stacking.",
                    context: context,
                    presets: presets,
                    fallback: fallback
                )
            }
            if readiness >= 66, load <= 72 {
                return recommendation(
                    for: .focusPrep,
                    what: "Run Focus prep before your next high-consequence task.",
                    why: "Readiness has recovered enough to convert this window into higher output quality.",
                    context: context,
                    presets: presets,
                    fallback: fallback
                )
            }
            return recommendation(
                for: .sleepDownshift,
                what: "Protect tonight with Sleep downshift before bed.",
                why: "Consistency is at \(consistency), so evening regulation prevents next-day carryover.",
                context: context,
                presets: presets,
                fallback: fallback
            )

        case .balancedDay:
            if readiness - load >= 16, consistency >= 72 {
                return recommendation(
                    for: .focusPrep,
                    what: "Run Focus prep before your deepest work block.",
                    why: "Readiness is stronger than load right now (\(readiness - load)), creating a good window for focused work.",
                    context: context,
                    presets: presets,
                    fallback: fallback
                )
            }
            if load >= 65 || context.stressSignals > context.recoverySignals {
                return recommendation(
                    for: .calmNow,
                    what: "Run Calm now to keep this balanced day from drifting upward.",
                    why: "Current load and recent stress actions are pushing the trend above baseline.",
                    context: context,
                    presets: presets,
                    fallback: fallback
                )
            }
            return recommendation(
                for: .sleepDownshift,
                what: "Use Sleep downshift to lock in today's stable rhythm.",
                why: "Consistency compounding is your strongest lever in this scenario.",
                context: context,
                presets: presets,
                fallback: fallback
            )

        case .recoveryWeek:
            if consistency < 82 || context.stressSignals >= 2 {
                return recommendation(
                    for: .sleepDownshift,
                    what: "Prioritize Sleep downshift to protect recovery momentum tonight.",
                    why: "Recovery scenarios lose gains fastest when consistency softens.",
                    context: context,
                    presets: presets,
                    fallback: fallback
                )
            }
            if readiness >= 82, load <= 45 {
                return recommendation(
                    for: .focusPrep,
                    what: "Run Focus prep before one intentional performance block.",
                    why: "Readiness is high while load is contained, creating a low-cost performance window.",
                    context: context,
                    presets: presets,
                    fallback: fallback
                )
            }
            return recommendation(
                for: .calmNow,
                what: "Run Calm now between task transitions.",
                why: "Short regulation reps preserve low arousal and prevent rebound strain.",
                context: context,
                presets: presets,
                fallback: fallback
            )
        }
    }

    static func projectedLoadDeltaInTwoHours(for preset: RegulatePresetID, context: Context) -> Int {
        let baseDelta: Int = switch (context.scenario, preset) {
        case (.highStressDay, .calmNow): -6
        case (.highStressDay, .focusPrep): -4
        case (.highStressDay, .sleepDownshift): -3
        case (.balancedDay, .calmNow): -4
        case (.balancedDay, .focusPrep): -3
        case (.balancedDay, .sleepDownshift): -2
        case (.recoveryWeek, .calmNow): -3
        case (.recoveryWeek, .focusPrep): -2
        case (.recoveryWeek, .sleepDownshift): -2
        }

        let confidenceBoost = Int(((context.confidenceScore - 0.65) * 10).rounded())
        let stressPenalty = max(0, context.stressSignals - context.recoverySignals)
        return max(-12, min(2, baseDelta + confidenceBoost - stressPenalty))
    }

    static func projectedLoadInTwoHours(for preset: RegulatePresetID, context: Context) -> Int {
        let projected = context.metrics.load + projectedLoadDeltaInTwoHours(for: preset, context: context)
        return Int(clamp(Double(projected), min: 8, max: 96))
    }

    static func rankDrivers(baseDrivers: [DriverImpact], context: Context) -> [DriverImpact] {
        let loadDelta = Double(context.metrics.load - context.baseMetrics.load) / 100
        let readinessDelta = Double(context.metrics.readiness - context.baseMetrics.readiness) / 100
        let consistencyDelta = Double(context.metrics.consistency - context.baseMetrics.consistency) / 100

        return baseDrivers
            .map { driver in
                var adjustedImpact = driver.impact

                switch driver.id {
                case "sleep_fragmentation", "stable_sleep", "sleep_rebound":
                    adjustedImpact += (Double(context.stressSignals) * 0.015) - (readinessDelta * 0.18)
                case "deadline_density", "meeting_stack", "moderate_meeting_load":
                    adjustedImpact += (Double(context.stressSignals) * 0.024) + (loadDelta * 0.22)
                case "late_caffeine", "caffeine_timing", "reduced_stimulus":
                    adjustedImpact += (Double(context.caffeineSignals) * 0.04) - (Double(context.recoverySignals) * 0.012)
                case "training_response", "movement_consistency":
                    adjustedImpact += (Double(context.recoverySignals) * 0.028) - (Double(context.stressSignals) * 0.01)
                case "hydration_drag":
                    adjustedImpact += (Double(context.stressSignals) * 0.018) + (loadDelta * 0.16)
                case "screen_exposure":
                    adjustedImpact += (Double(context.stressSignals) * 0.012) - (consistencyDelta * 0.1)
                case "load_taper":
                    adjustedImpact += (Double(context.recoverySignals) * 0.016) - (Double(context.stressSignals) * 0.016)
                case "evening_routine":
                    adjustedImpact += (consistencyDelta * 0.2) + (Double(context.recoverySignals) * 0.01)
                default:
                    adjustedImpact += (Double(context.stressSignals - context.recoverySignals) * 0.01)
                }

                let clampedImpact = clamp(adjustedImpact, min: 0.05, max: 0.62)
                let influenceText: String
                if clampedImpact - driver.impact > 0.03 {
                    influenceText = "rising influence"
                } else if clampedImpact - driver.impact < -0.03 {
                    influenceText = "falling influence"
                } else {
                    influenceText = "stable influence"
                }

                return DriverImpact(
                    id: driver.id,
                    name: driver.name,
                    detail: "\(driver.detail) • \(influenceText)",
                    impact: clampedImpact
                )
            }
            .sorted { lhs, rhs in
                if lhs.impact == rhs.impact {
                    return lhs.name < rhs.name
                }
                return lhs.impact > rhs.impact
            }
    }

    private static func recommendation(
        for presetID: RegulatePresetID,
        what: String,
        why: String,
        context: Context,
        presets: [DemoRegulatePreset],
        fallback: DemoRecommendation
    ) -> DemoRecommendation {
        guard let preset = presets.first(where: { $0.id == presetID }) else {
            return fallback
        }
        let effectLine = preset.expectedEffect
            .replacingOccurrences(of: "Expected effect: ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let projection = projectedLoadDeltaInTwoHours(for: presetID, context: context)
        return DemoRecommendation(
            preset: presetID,
            what: what,
            why: why,
            expectedEffect: "\(effectLine) 2h projected load shift: \(signed(projection)).",
            timeMinutes: preset.durationMinutes
        )
    }

    private static func signed(_ value: Int) -> String {
        if value > 0 {
            return "+\(value)"
        }
        return "\(value)"
    }

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}
