import XCTest
@testable import MindSense_AI_v1_0_0

final class RecommendationEngineTests: XCTestCase {
    func testHighStressScenarioChoosesCalmNowForHighLoad() {
        let scenario = DemoScenario.highStressDay
        let context = RecommendationEngine.Context(
            scenario: scenario,
            metrics: .init(load: 84, readiness: 54, consistency: 60),
            baseMetrics: scenario.baseMetrics,
            confidenceScore: 0.8,
            stressSignals: 3,
            recoverySignals: 0,
            caffeineSignals: 1
        )

        let recommendation = RecommendationEngine.primaryRecommendation(
            context: context,
            presets: DemoScenarioProfile.make(for: scenario).presets,
            fallback: scenario.primaryRecommendation
        )

        XCTAssertEqual(recommendation.preset, .calmNow)
    }

    func testBalancedScenarioChoosesFocusPrepForStrongSpread() {
        let scenario = DemoScenario.balancedDay
        let context = RecommendationEngine.Context(
            scenario: scenario,
            metrics: .init(load: 46, readiness: 79, consistency: 74),
            baseMetrics: scenario.baseMetrics,
            confidenceScore: 0.86,
            stressSignals: 0,
            recoverySignals: 2,
            caffeineSignals: 0
        )

        let recommendation = RecommendationEngine.primaryRecommendation(
            context: context,
            presets: DemoScenarioProfile.make(for: scenario).presets,
            fallback: scenario.primaryRecommendation
        )

        XCTAssertEqual(recommendation.preset, .focusPrep)
    }

    func testProjectedLoadDeltaAmplifiesDownshiftWhenStressSignalsRise() {
        let scenario = DemoScenario.balancedDay
        let lowStressContext = RecommendationEngine.Context(
            scenario: scenario,
            metrics: scenario.baseMetrics,
            baseMetrics: scenario.baseMetrics,
            confidenceScore: 0.84,
            stressSignals: 0,
            recoverySignals: 2,
            caffeineSignals: 0
        )
        let highStressContext = RecommendationEngine.Context(
            scenario: scenario,
            metrics: scenario.baseMetrics,
            baseMetrics: scenario.baseMetrics,
            confidenceScore: 0.84,
            stressSignals: 4,
            recoverySignals: 0,
            caffeineSignals: 0
        )

        let lowStressDelta = RecommendationEngine.projectedLoadDeltaInTwoHours(for: .calmNow, context: lowStressContext)
        let highStressDelta = RecommendationEngine.projectedLoadDeltaInTwoHours(for: .calmNow, context: highStressContext)

        XCTAssertLessThanOrEqual(highStressDelta, lowStressDelta)
    }

    func testDriverRankingSortsDescending() {
        let scenario = DemoScenario.highStressDay
        let baseDrivers = [
            DriverImpact(id: "deadline_density", name: "Deadlines", detail: "High pressure", impact: 0.2),
            DriverImpact(id: "movement_consistency", name: "Movement", detail: "Daily walk", impact: 0.2),
            DriverImpact(id: "hydration_drag", name: "Hydration", detail: "Low intake", impact: 0.18)
        ]
        let context = RecommendationEngine.Context(
            scenario: scenario,
            metrics: .init(load: 88, readiness: 50, consistency: 58),
            baseMetrics: scenario.baseMetrics,
            confidenceScore: 0.78,
            stressSignals: 3,
            recoverySignals: 0,
            caffeineSignals: 2
        )

        let ranked = RecommendationEngine.rankDrivers(baseDrivers: baseDrivers, context: context)

        XCTAssertEqual(ranked.count, baseDrivers.count)
        XCTAssertTrue(ranked[0].impact >= ranked[1].impact)
        XCTAssertTrue(ranked[1].impact >= ranked[2].impact)
    }
}
