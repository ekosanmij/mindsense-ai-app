import SwiftUI

struct PostActivationPaywallSheet: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @State private var didAppear = false

    let onMaybeLater: () -> Void
    let onStartTrial: () -> Void

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MindSenseCommandDeck(
                        label: "MindSense Plus",
                        title: "Continue your momentum with premium intelligence",
                        detail: "You unlocked your first completed regulate session. Plus extends this into a weekly performance narrative.",
                        metric: "7-day trial"
                    )
                    .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)

                    FocusSurface {
                        MindSenseSectionHeader(model: .init(title: "Why this unlock matters"))

                        Text("Your first session proves the behavior is sustainable. Plus turns daily usage into a long-horizon signal system so recommendations improve week over week.")
                            .font(MindSenseTypography.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)

                    PrimarySurface {
                        MindSenseSectionHeader(model: .init(title: "Plus value narrative"))

                        benefitRow(
                            title: "Confidence over time",
                            detail: "Extended trend windows and richer confidence framing show whether changes are noise or real progression."
                        )
                        MindSenseSectionDivider(emphasis: 0.18)
                        benefitRow(
                            title: "Compounding experiments",
                            detail: "Unlimited experiment history lets you compare what worked across contexts instead of relying on memory."
                        )
                        MindSenseSectionDivider(emphasis: 0.18)
                        benefitRow(
                            title: "Executive weekly summaries",
                            detail: "Weekly habit scorecards convert raw check-ins into a clear performance and risk narrative."
                        )
                    }
                    .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)

                    Button("Start 7-day trial", action: onStartTrial)
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .primary))
                        .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)

                    Button("Maybe later", action: onMaybeLater)
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                        .mindSenseStaggerEntrance(4, isPresented: didAppear, reduceMotion: reduceMotion)
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("MindSense Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "MindSense Plus")
                }
            }
            .onAppear {
                didAppear = true
            }
        }
    }

    private func benefitRow(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            MindSenseIconBadge(systemName: "sparkles", tint: MindSensePalette.signalCool, style: .filled, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MindSenseTypography.bodyStrong)
                Text(detail)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
