import SwiftUI

struct IntroView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @State private var didAppear = false

    private let highlights: [(title: String, detail: String, icon: String)] = [
        ("Status in 10 seconds", "Load, Readiness, and Consistency in one clear view.", "gauge.with.dots.needle.bottom.50percent"),
        ("One next action", "Get one regulate step with duration and expected outcome.", "figure.mind.and.body"),
        ("Rationale built in", "Recommendations include estimate language and why they matter.", "chart.line.uptrend.xyaxis")
    ]

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MindSenseRhythm.section) {
                introHero
                    .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)

                InsetSurface {
                    MindSenseSectionHeader(
                        model: .init(title: "What you get", subtitle: "Clear status, clear action.")
                    )

                    ForEach(Array(highlights.enumerated()), id: \.element.title) { index, item in
                        unlockRow(item)

                        if index < highlights.count - 1 {
                            MindSenseSectionDivider(emphasis: 0.12)
                        }
                    }
                }
                .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)

                Button("Continue with Apple") {
                    store.triggerHaptic(intent: .primary)
                    store.completeIntro()
                }
                .accessibilityIdentifier("intro_primary_cta")
                .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 52))
                .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)
            }
            .mindSensePageInsets()
        }
        .mindSensePageBackground()
        .onAppear {
            didAppear = true
        }
    }

    private var introHero: some View {
        InsetSurface {
            HStack(spacing: 8) {
                MindSenseIconBadge(
                    systemName: "waveform.path.ecg",
                    tint: MindSensePalette.signalCoolStrong,
                    style: .filled,
                    size: 30
                )
                Text("MindSense AI")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(MindSensePalette.signalCoolStrong)
                    .tracking(1)
                Spacer()
                PillChip(label: "Setup < 1 min", state: .selected)
            }

            MindSenseSectionHeader(
                model: .init(
                    title: "Daily nervous-system guidance, simplified",
                    subtitle: "Continue with Apple to start your account."
                )
            )
        }
    }

    private func unlockRow(_ item: (title: String, detail: String, icon: String)) -> some View {
        HStack(alignment: .top, spacing: 12) {
            MindSenseIconBadge(systemName: item.icon, tint: MindSensePalette.signalCool, style: .filled, size: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(MindSenseTypography.bodyStrong)
                Text(item.detail)
                    .font(MindSenseTypography.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 54, alignment: .leading)
    }
}
