import XCTest
@testable import MindSense_AI_v1_0_0

final class AppleSessionPersistenceTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!
    private var persistence: MindSensePersistenceService!

    override func setUp() {
        super.setUp()
        suiteName = "AppleSessionPersistenceTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        persistence = MindSensePersistenceService(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        persistence = nil
        super.tearDown()
    }

    func testPersistSessionRoundTripsAppleMetadata() {
        persistence.persistSession(
            email: "User@Example.com",
            appleUserID: "apple-abc",
            displayName: "Taylor Ng"
        )

        let session = persistence.loadSession()

        XCTAssertEqual(session?.email, "user@example.com")
        XCTAssertEqual(session?.appleUserID, "apple-abc")
        XCTAssertEqual(session?.displayName, "Taylor Ng")
    }

    func testLoadSessionFallsBackToLegacyEmailKey() {
        defaults.set("legacy@example.com", forKey: "auth.fallback_session_email")

        let session = persistence.loadSession()

        XCTAssertEqual(session?.email, "legacy@example.com")
        XCTAssertNil(session?.appleUserID)
    }

    func testPersistKnownAppleEmailIsNormalized() {
        persistence.persistKnownAppleEmail("Alias@Example.com", for: "apple-xyz")

        XCTAssertEqual(persistence.loadKnownAppleEmail(for: "apple-xyz"), "alias@example.com")
    }
}
