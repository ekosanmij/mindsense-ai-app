import SwiftUI

struct LaunchView: View {
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var progressFill: CGFloat = 0.24
    @State private var didAppear = false

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        ZStack {
            Color.clear
                .mindSensePageBackground()

            InsetSurface {
                VStack(spacing: MindSenseRhythm.regular) {
                    HStack(spacing: 8) {
                        MindSenseIconBadge(systemName: "waveform.path.ecg", tint: MindSensePalette.signalCoolStrong, style: .filled, size: 30)
                        Text("MindSense AI")
                            .font(MindSenseTypography.micro)
                            .foregroundStyle(MindSensePalette.signalCoolStrong)
                            .tracking(1)
                        Spacer()
                        PillChip(label: "Loading", state: .selected)
                    }

                    MindSenseSectionHeader(
                        model: .init(
                            title: "Loading your daily snapshot",
                            subtitle: "Syncing baseline, trends, and recommendations."
                        )
                    )

                    GeometryReader { proxy in
                        let width = max(proxy.size.width, 0)
                        ZStack(alignment: .leading) {
                            Capsule(style: .continuous)
                                .fill(MindSenseSurfaceLevel.base.fill)
                                .frame(height: 8)

                            Capsule(style: .continuous)
                                .fill(MindSensePalette.signalCool)
                                .frame(width: width * progressFill, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .frame(maxWidth: 320, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)
        }
        .onAppear {
            didAppear = true

            guard !reduceMotion else {
                progressFill = 0.65
                return
            }
            withAnimation(.linear(duration: 0.75).repeatForever(autoreverses: true)) {
                progressFill = 0.92
            }
        }
        .accessibilityIdentifier("launch_screen_root")
    }
}
