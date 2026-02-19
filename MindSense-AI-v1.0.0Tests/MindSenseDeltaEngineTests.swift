import XCTest
@testable import MindSense_AI_v1_0_0

final class MindSenseDeltaEngineTests: XCTestCase {
    func testSessionOutcomeBetterReducesLoadAndRaisesReadiness() {
        let delta = MindSenseDeltaEngine.sessionOutcome(direction: .better, intensity: 3)

        XCTAssertEqual(delta.load, -6)
        XCTAssertEqual(delta.readiness, 6)
        XCTAssertEqual(delta.consistency, 1)
    }

    func testExperimentCheckInDeltaIsDeterministicByFocus() {
        let load = MindSenseDeltaEngine.experimentCheckIn(focus: .load)
        let readiness = MindSenseDeltaEngine.experimentCheckIn(focus: .readiness)
        let consistency = MindSenseDeltaEngine.experimentCheckIn(focus: .consistency)

        XCTAssertEqual(load.load, -2)
        XCTAssertEqual(load.readiness, 1)
        XCTAssertEqual(load.consistency, 1)

        XCTAssertEqual(readiness.load, -1)
        XCTAssertEqual(readiness.readiness, 2)
        XCTAssertEqual(readiness.consistency, 1)

        XCTAssertEqual(consistency.load, -1)
        XCTAssertEqual(consistency.readiness, 1)
        XCTAssertEqual(consistency.consistency, 2)
    }

    func testCompletedExperimentDeltaClampsPerceivedChange() {
        let largePositive = MindSenseDeltaEngine.completedExperiment(focus: .load, perceivedChange: 42)
        let largeNegative = MindSenseDeltaEngine.completedExperiment(focus: .load, perceivedChange: -42)

        XCTAssertEqual(largePositive.load, -5)
        XCTAssertEqual(largeNegative.load, 5)
    }

    func testFastForwardDeltaVariesByScenario() {
        let days = 4
        let stress = MindSenseDeltaEngine.fastForwardedDays(days, scenario: .highStressDay)
        let balanced = MindSenseDeltaEngine.fastForwardedDays(days, scenario: .balancedDay)
        let recovery = MindSenseDeltaEngine.fastForwardedDays(days, scenario: .recoveryWeek)

        XCTAssertGreaterThan(stress.load, 0)
        XCTAssertGreaterThanOrEqual(balanced.readiness, 0)
        XCTAssertLessThan(recovery.load, 0)
    }

    func testExperimentSummaryUsesTrendDirection() {
        let summary = MindSenseDeltaEngine.experimentCompletionSummary(
            scenarioTitle: "Balanced Day",
            focusTitle: "Readiness",
            adherence: 84,
            perceivedChange: -2
        )

        XCTAssertTrue(summary.contains("decline"))
        XCTAssertTrue(summary.contains("84% adherence"))
    }
}
