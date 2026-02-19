import SwiftUI

struct IntroView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @State private var didAppear = false

    private let highlights: [(title: String, detail: String, icon: String)] = [
        ("Status in 10 seconds", "See Load, Readiness, and Consistency with plain-English definitions.", "gauge.with.dots.needle.bottom.50percent"),
        ("One clear next action", "Get one regulate action with expected outcome and duration.", "figure.mind.and.body"),
        ("Data with rationale", "Each modeled insight includes estimate language and why it was recommended.", "chart.line.uptrend.xyaxis")
    ]

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MindSenseRhythm.section) {
                introHero
                    .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)

                trustLine
                    .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)

                InsetSurface {
                    MindSenseSectionHeader(
                        model: .init(title: "What you unlock", subtitle: "One focused flow from status to action.")
                    )

                    ForEach(Array(highlights.enumerated()), id: \.element.title) { index, item in
                        unlockRow(item)

                        if index < highlights.count - 1 {
                            MindSenseSectionDivider(emphasis: 0.12)
                        }
                    }
                }
                .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)

                Button("Continue to Secure Sign In") {
                    store.triggerHaptic(intent: .primary)
                    store.completeIntro()
                }
                .accessibilityIdentifier("intro_primary_cta")
                .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 52))
                .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)

                Menu("More options") {
                    Button("Restore purchase") {
                        store.showBanner(
                            title: "Restore purchase",
                            detail: "Billing restore can be connected after activation.",
                            severity: .info
                        )
                    }
                }
                .font(MindSenseTypography.bodyStrong)
                .foregroundStyle(.secondary)
                .mindSenseStaggerEntrance(4, isPresented: didAppear, reduceMotion: reduceMotion)
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
                PillChip(label: "Setup < 60s", state: .selected)
            }

            MindSenseSectionHeader(
                model: .init(
                    title: "Clinical guidance for daily nervous-system regulation",
                    subtitle: "Secure sign in unlocks your first regulate session and data baseline."
                )
            )
        }
    }

    private var trustLine: some View {
        InsetSurface {
            HStack(alignment: .top, spacing: 10) {
                MindSenseIconBadge(systemName: "lock.shield.fill", tint: MindSensePalette.signalCoolStrong, style: .filled, size: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Trusted clinical tone")
                        .font(MindSenseTypography.bodyStrong)
                    Text("Encrypted account access, transparent estimate language, and one clear next action every day.")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
