import SwiftUI

struct KPIScorecardView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @State private var didAppear = false
    @State private var animateBars = false

    private var scorecard: ProductKPIScorecard {
        store.productKPIs
    }

    private var portfolioScore: Int {
        let values = [
            scorecard.activationRate,
            scorecard.d1RetentionRate,
            scorecard.d7RetentionRate,
            scorecard.sessionStartRate,
            scorecard.sessionCompletionRate
        ]
        return Int((values.reduce(0, +) / Double(values.count) * 100).rounded())
    }

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MindSenseRhythm.section) {
                MindSenseCommandDeck(
                    label: "Scorecard",
                    title: "Executive analytics view",
                    detail: "Activation and retention indicators consolidated into one performance view.",
                    metric: scorecard.generatedAt.formatted(date: .abbreviated, time: .shortened)
                )
                .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)

                InsetSurface {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Portfolio health")
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                            Text("\(portfolioScore)")
                                .font(MindSenseTypography.metricDisplay)
                                .foregroundStyle(MindSensePalette.signalCoolStrong)
                                .monospacedDigit()
                            Text("Composite KPI index")
                                .font(MindSenseTypography.metricCaption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        MindSenseIconBadge(systemName: "chart.xyaxis.line", tint: MindSensePalette.signalCool, style: .filled, size: 44)
                    }
                }
                .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)

                PrimarySurface {
                    MindSenseSectionHeader(model: .init(title: "Core indicators", subtitle: "Performance view by funnel stage"))

                    metricTile(title: "Activation", value: scorecard.activationRate, tint: MindSensePalette.signalCool)
                    metricTile(title: "D1 retention", value: scorecard.d1RetentionRate, tint: MindSensePalette.success)
                    metricTile(title: "D7 retention", value: scorecard.d7RetentionRate, tint: MindSensePalette.signalCoolStrong)
                    metricTile(title: "Session start rate", value: scorecard.sessionStartRate, tint: MindSensePalette.warning)
                    metricTile(title: "Session completion rate", value: scorecard.sessionCompletionRate, tint: MindSensePalette.signalCool)
                }
                .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)

                InsetSurface {
                    MindSenseSectionHeader(model: .init(title: "Weekly review"))
                    Text(reviewStatus)
                        .font(MindSenseTypography.body)
                        .foregroundStyle(.secondary)

                    Button("Mark reviewed this week") {
                        store.markKPIReviewedNow()
                        store.showBanner(title: "Scorecard reviewed", detail: "Weekly KPI review timestamp saved.", severity: .success)
                        store.triggerHaptic(intent: .success)
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .primary))
                    .accessibilityIdentifier("kpi_mark_reviewed_cta")
                }
                .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)
            }
            .mindSensePageInsets()
        }
        .mindSensePageBackground()
        .navigationTitle("KPI scorecard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MindSenseNavTitleLockup(title: "KPI scorecard")
            }
        }
        .onAppear {
            didAppear = true
            if reduceMotion {
                animateBars = true
            } else {
                withAnimation(MindSenseMotion.completionSpring) {
                    animateBars = true
                }
            }
        }
    }

    private var reviewStatus: String {
        guard let reviewedAt = store.kpiLastReviewedAt else {
            return "No weekly review recorded yet."
        }
        return "Last reviewed: \(reviewedAt.formatted(date: .abbreviated, time: .shortened))."
    }

    private func metricTile(title: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(MindSenseTypography.bodyStrong)
                Spacer()
                Text(value.formatted(.percent.precision(.fractionLength(0))))
                    .font(MindSenseTypography.metricBody)
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }
            metricBar(value: value, tint: tint)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
    }

    private func metricBar(value: Double, tint: Color) -> some View {
        GeometryReader { proxy in
            let normalized = max(0.05, value)
            let width = proxy.size.width * (animateBars ? normalized : 0.05)
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(MindSenseSurfaceLevel.glass.fill)
                Capsule(style: .continuous)
                    .fill(tint)
                    .frame(width: width)
            }
        }
        .frame(height: 8)
        .animation(reduceMotion ? nil : MindSenseMotion.selection, value: animateBars)
    }
}
