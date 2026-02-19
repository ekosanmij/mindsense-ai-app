import Foundation

enum AppRootRoute: Equatable {
    case launching
    case intro
    case auth
    case onboarding
    case ready
}

struct AppStateResolver {
    enum Event {
        case launchDataLoaded(session: AuthSession?, onboarding: OnboardingProgress)
        case signedOut
        case onboardingCompleted
        case sessionRestored(onboarding: OnboardingProgress)
    }

    static func reduce(state: AppLaunchState, event: Event) -> AppLaunchState {
        switch event {
        case let .launchDataLoaded(session, onboarding):
            launchDestination(session: session, onboarding: onboarding)
        case .signedOut:
            .signedOut
        case .onboardingCompleted:
            .ready
        case let .sessionRestored(onboarding):
            onboarding.isFullyComplete ? .ready : .needsOnboarding
        }
    }

    static func launchDestination(session: AuthSession?, onboarding: OnboardingProgress) -> AppLaunchState {
        guard session != nil else {
            return .signedOut
        }
        return onboarding.isFullyComplete ? .ready : .needsOnboarding
    }

    static func rootRoute(appState: AppLaunchState, hasSeenIntro: Bool) -> AppRootRoute {
        switch appState {
        case .launching:
            return .launching
        case .signedOut:
            return hasSeenIntro ? .auth : .intro
        case .needsOnboarding:
            return .onboarding
        case .ready:
            return .ready
        }
    }
}
