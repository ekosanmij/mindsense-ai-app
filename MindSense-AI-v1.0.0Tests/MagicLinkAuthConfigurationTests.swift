import XCTest
@testable import MindSense_AI_v1_0_0

@MainActor
final class AppleSignInSessionFlowTests: XCTestCase {
    func testCompleteSignInWithAppleStoresCredentialEmail() {
        clearAuthState()
        let store = MindSenseStore()

        let message = store.completeSignInWithApple(
            userID: "apple-user-1",
            email: "User@Example.com",
            fullName: nil
        )

        XCTAssertNil(message)
        XCTAssertEqual(store.session?.email, "user@example.com")
        XCTAssertEqual(store.session?.appleUserID, "apple-user-1")
    }

    func testCompleteSignInWithAppleUsesCachedEmailWhenEmailIsNotReturned() {
        clearAuthState()
        let firstStore = MindSenseStore()
        XCTAssertNil(
            firstStore.completeSignInWithApple(
                userID: "apple-user-2",
                email: "cached@example.com",
                fullName: nil
            )
        )
        firstStore.signOut()

        let secondStore = MindSenseStore()
        let message = secondStore.completeSignInWithApple(
            userID: "apple-user-2",
            email: nil,
            fullName: nil
        )

        XCTAssertNil(message)
        XCTAssertEqual(secondStore.session?.email, "cached@example.com")
        XCTAssertEqual(secondStore.session?.appleUserID, "apple-user-2")
    }

    func testCompleteSignInWithAppleCreatesFallbackEmailWhenNoEmailExists() {
        clearAuthState()
        let store = MindSenseStore()

        let message = store.completeSignInWithApple(
            userID: "USER-XYZ_123",
            email: nil,
            fullName: nil
        )

        XCTAssertNil(message)
        XCTAssertEqual(store.session?.email, "apple-userxyz123@mindsense.local")
    }

    func testCompleteSignInWithApplePersistsDisplayNameFromFullName() {
        clearAuthState()
        let store = MindSenseStore()

        var name = PersonNameComponents()
        name.givenName = "Taylor"
        name.familyName = "Ng"

        let message = store.completeSignInWithApple(
            userID: "apple-user-3",
            email: "person@example.com",
            fullName: name
        )

        XCTAssertNil(message)
        XCTAssertEqual(store.session?.displayName, "Taylor Ng")
    }

    override func tearDown() {
        clearAuthState()
        super.tearDown()
    }

    private func clearAuthState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "auth.fallback_session_email")
        defaults.removeObject(forKey: "auth.session.email.v2")
        defaults.removeObject(forKey: "auth.session.apple_user_id.v1")
        defaults.removeObject(forKey: "auth.session.display_name.v1")
        defaults.removeObject(forKey: "auth.magic_link.pending.v1")

        let keys = defaults.dictionaryRepresentation().keys
        for key in keys where key.hasPrefix("auth.apple.email_lookup.") {
            defaults.removeObject(forKey: key)
        }
    }
}
