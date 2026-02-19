import SwiftUI

struct ProfileAccessMenu: View {
    var body: some View {
        NavigationLink {
            SettingsView()
        } label: {
            profileIcon
        }
        .accessibilityLabel("Open settings")
    }

    private var profileIcon: some View {
        MindSenseIconBadge(
            systemName: "person.crop.circle.fill",
            tint: MindSensePalette.signalCool,
            style: .filled,
            size: 34
        )
        .frame(minWidth: 44, minHeight: 44)
    }
}
