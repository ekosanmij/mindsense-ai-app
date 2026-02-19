import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: MindSenseStore
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        ZStack(alignment: .top) {
            routedContent
                .transition(MindSenseMotion.screenTransition(reduceMotion: reduceMotion))

            if let banner = store.banner {
                NotificationBannerView(banner: banner)
                    .padding(.top, 12)
                    .transition(MindSenseMotion.cardTransition(reduceMotion: reduceMotion))
                    .zIndex(10)
            }
        }
        .animation(reduceMotion ? nil : MindSenseMotion.screen, value: store.appState)
        .animation(reduceMotion ? nil : MindSenseMotion.confirmation, value: store.banner)
    }

    @ViewBuilder
    private var routedContent: some View {
        switch AppStateResolver.rootRoute(appState: store.appState, hasSeenIntro: store.hasSeenIntro) {
        case .launching:
            LaunchView()

        case .intro:
            IntroView()

        case .auth:
            AuthView()

        case .onboarding:
            OnboardingView()

        case .ready:
            MainShellView()
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MindSenseStore())
    }
}
#endif
