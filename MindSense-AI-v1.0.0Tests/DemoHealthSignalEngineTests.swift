import XCTest
@testable import MindSense_AI_v1_0_0

final class DemoHealthSignalEngineTests: XCTestCase {
    func testSeededProfileHasPermissionsAndEpisodes() {
        let profile = DemoHealthSignalEngine.seededProfile(
            for: .balancedDay,
            demoDay: DemoScenario.balancedDay.defaultDay,
            now: Date()
        )

        XCTAssertTrue(profile.isConnected)
        XCTAssertEqual(profile.permissions.count, DemoHealthSignalType.allCases.count)
        XCTAssertFalse(profile.stressEpisodes.isEmpty)
        XCTAssertFalse(profile.timelineSegments.isEmpty)
        XCTAssertGreaterThan(profile.quality.score, 0)
    }

    func testRefreshedProfileUpdatesSyncWhenRequested() {
        let baseline = DemoHealthSignalEngine.seededProfile(
            for: .highStressDay,
            demoDay: DemoScenario.highStressDay.defaultDay,
            now: Date().addingTimeInterval(-7_200)
        )
        let now = Date()

        let refreshed = DemoHealthSignalEngine.refreshedProfile(
            existing: baseline,
            scenario: .highStressDay,
            metrics: .init(load: 84, readiness: 58, consistency: 63),
            demoDay: DemoScenario.highStressDay.defaultDay,
            completedSessionCount: 2,
            activeExperimentAdherence: 68,
            now: now,
            updateSyncTimestamp: true
        )

        XCTAssertGreaterThanOrEqual(refreshed.sync.lastSyncAt, now.addingTimeInterval(-1))
        XCTAssertFalse(refreshed.quality.actionHint.isEmpty)
    }

    func testDeletingDerivedProfileClearsTimelineAndEpisodes() {
        let seeded = DemoHealthSignalEngine.seededProfile(
            for: .recoveryWeek,
            demoDay: DemoScenario.recoveryWeek.defaultDay,
            now: Date()
        )

        let cleared = DemoHealthSignalEngine.deletingDerivedProfile(existing: seeded, now: Date())

        XCTAssertTrue(cleared.stressEpisodes.isEmpty)
        XCTAssertTrue(cleared.timelineSegments.isEmpty)
        XCTAssertLessThan(cleared.quality.score, seeded.quality.score)
    }
}
