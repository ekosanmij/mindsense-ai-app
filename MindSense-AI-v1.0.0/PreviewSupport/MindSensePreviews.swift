import SwiftUI

@MainActor
private enum PreviewStoreFactory {
    static func signedOut() -> MindSenseStore {
        let store = MindSenseStore()
        store.appState = .signedOut
        store.hasSeenIntro = false
        store.session = nil
        return store
    }

    static func authenticatedNeedsOnboarding() -> MindSenseStore {
        let store = MindSenseStore()
        store.appState = .needsOnboarding
        store.hasSeenIntro = true
        store.session = AuthSession(email: "preview@mindsense.ai", isDemo: false)
        store.onboarding = OnboardingProgress()
        return store
    }

    static func ready() -> MindSenseStore {
        let store = MindSenseStore()
        store.appState = .ready
        store.hasSeenIntro = true
        store.session = AuthSession(email: "preview@mindsense.ai", isDemo: false)
        var onboarding = OnboardingProgress()
        OnboardingStep.allCases.forEach { onboarding.markComplete($0) }
        onboarding.baselineStart = Calendar.current.date(byAdding: .day, value: -6, to: Date())
        onboarding.firstCheckInValue = 4
        store.onboarding = onboarding
        return store
    }
}

#if DEBUG
@MainActor
struct MindSenseEntryPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            IntroView()
                .environmentObject(PreviewStoreFactory.signedOut())
                .previewDisplayName("Intro")

            AuthView()
                .environmentObject(PreviewStoreFactory.signedOut())
                .previewDisplayName("Auth")

            OnboardingView()
                .environmentObject(PreviewStoreFactory.authenticatedNeedsOnboarding())
                .previewDisplayName("Onboarding")
        }
    }
}

@MainActor
struct MindSenseShellPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            TodayView()
                .environmentObject(PreviewStoreFactory.ready())
                .previewDisplayName("Today")

            RegulateView()
                .environmentObject(PreviewStoreFactory.ready())
                .previewDisplayName("Regulate")

            DataView()
                .environmentObject(PreviewStoreFactory.ready())
                .previewDisplayName("Data")

            SettingsView()
                .environmentObject(PreviewStoreFactory.ready())
                .previewDisplayName("Settings")

            NavigationStack {
                CommunityView()
            }
            .environmentObject(PreviewStoreFactory.ready())
            .previewDisplayName("Community")
        }
    }
}

@MainActor
struct MindSenseSupportPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                KPIScorecardView()
            }
            .environmentObject(PreviewStoreFactory.ready())
            .previewDisplayName("KPI Scorecard")

            PostActivationPaywallSheet(onMaybeLater: {}, onStartTrial: {})
                .previewDisplayName("Post Activation Paywall")

            ScrollView {
                VStack(spacing: 12) {
                    ScreenStateContainer(state: .loading) {
                        EmptyView()
                    }
                    ScreenStateContainer(
                        state: .empty(.init(title: "No data", message: "No items available for this state."))
                    ) {
                        EmptyView()
                    }
                    ScreenStateContainer(
                        state: .error(.init(title: "Connection error", message: "Could not load remote guidance.")),
                        retryAction: {}
                    ) {
                        EmptyView()
                    }
                }
                .padding(20)
            }
            .mindSensePageBackground()
            .previewDisplayName("Screen States")
        }
    }
}
#endif
