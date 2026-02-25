import SwiftUI

struct ProfileAccessMenu: View {
    @State private var showGlossary = false

    var body: some View {
        Menu {
            NavigationLink {
                SettingsView()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

            Button {
                showGlossary = true
            } label: {
                Label("Glossary", systemImage: "text.book.closed")
            }
        } label: {
            profileIcon
        }
        .sheet(isPresented: $showGlossary) {
            MindSenseGlossarySheet()
        }
        .accessibilityLabel("Profile and access")
        .accessibilityHint("Open settings or glossary.")
    }

    private var profileIcon: some View {
        MindSenseIconBadge(
            systemName: "person.crop.circle.fill",
            tint: MindSensePalette.signalCool,
            style: .filled,
            size: MindSenseControlSize.profileBadge
        )
        .frame(minWidth: 44, minHeight: 44)
    }
}
