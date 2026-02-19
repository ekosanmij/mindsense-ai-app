import SwiftUI

@main
struct MindSense_AI_v1_0_0App: App {
    @StateObject private var store = MindSenseStore()
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(
                    AppearanceMode(rawValue: appearanceMode)?.colorScheme
                )
                .onOpenURL { url in
                    _ = store.handleIncomingURL(url)
                }
        }
    }
}
