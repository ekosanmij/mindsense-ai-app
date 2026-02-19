import XCTest
@testable import MindSense_AI_v1_0_0

final class AppStateResolverTests: XCTestCase {
    func testLaunchDataLoadedWithoutSessionRoutesToSignedOut() {
        let state = AppStateResolver.reduce(
            state: .launching,
            event: .launchDataLoaded(session: nil, onboarding: OnboardingProgress())
        )

        XCTAssertEqual(state, .signedOut)
    }

    func testLaunchDataLoadedWithSessionAndIncompleteOnboardingRoutesToNeedsOnboarding() {
        let onboarding = OnboardingProgress()
        let state = AppStateResolver.reduce(
            state: .launching,
            event: .launchDataLoaded(
                session: .init(email: "user@example.com"),
                onboarding: onboarding
            )
        )

        XCTAssertEqual(state, .needsOnboarding)
    }

    func testLaunchDataLoadedWithSessionAndCompleteOnboardingRoutesToReady() {
        var onboarding = OnboardingProgress()
        onboarding.markComplete(.baseline)
        onboarding.markComplete(.firstCheckIn)

        let state = AppStateResolver.reduce(
            state: .launching,
            event: .launchDataLoaded(
                session: .init(email: "user@example.com"),
                onboarding: onboarding
            )
        )

        XCTAssertEqual(state, .ready)
    }

    func testSignedOutRouteUsesIntroWhenIntroNotSeen() {
        let route = AppStateResolver.rootRoute(appState: .signedOut, hasSeenIntro: false)
        XCTAssertEqual(route, .intro)
    }

    func testSignedOutRouteUsesAuthWhenIntroSeen() {
        let route = AppStateResolver.rootRoute(appState: .signedOut, hasSeenIntro: true)
        XCTAssertEqual(route, .auth)
    }

    func testOnboardingCompletedTransitionsToReady() {
        let state = AppStateResolver.reduce(state: .needsOnboarding, event: .onboardingCompleted)
        XCTAssertEqual(state, .ready)
    }
}
