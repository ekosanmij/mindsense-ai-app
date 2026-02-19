import SwiftUI

struct QAToolsView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    @State private var didAppear = false

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    private var scenarioBinding: Binding<DemoScenario> {
        Binding {
            store.demoScenario
        } set: { value in
            store.triggerHaptic(intent: .selection)
            store.switchDemoScenario(value)
            store.track(event: .secondaryActionTapped, surface: .settings, action: "scenario_switched")
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MindSenseRhythm.section) {
                MindSenseCommandDeck(
                    label: AppIA.qaTools,
                    title: "Validation controls",
                    detail: "Visible only in internal debug builds.",
                    metric: "Debug only"
                )
                .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)

                scenarioSection
                    .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)

                if AppFeatureFlags.guidedPathEnabled {
                    guidedPathSection
                        .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)
                }

                demoDataSection
                    .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)

                if AppFeatureFlags.kpiScorecardEnabled {
                    kpiSection
                        .mindSenseStaggerEntrance(4, isPresented: didAppear, reduceMotion: reduceMotion)
                }
            }
            .mindSensePageInsets()
        }
        .mindSensePageBackground()
        .navigationTitle(AppIA.qaTools)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MindSenseNavTitleLockup(title: AppIA.qaTools)
            }
        }
        .onAppear {
            didAppear = true
            store.track(event: .screenView, surface: .settings, metadata: ["view": "qa_tools"])
        }
    }

    private var scenarioSection: some View {
        FocusSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Context profile",
                    subtitle: "Switch context and watch Today, Regulate, and Data update immediately."
                )
            )

            MindSenseSegmentedControl(
                options: DemoScenario.allCases,
                selection: scenarioBinding,
                title: { $0.title }
            )
        }
    }

    private var guidedPathSection: some View {
        FocusSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Guided validation path",
                    subtitle: "Structured QA walkthrough across core tabs."
                )
            )

            if let guidedLine = store.guidedPathStatusLine {
                InsetSurface {
                    Text(guidedLine)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let nextLabel = store.guidedPathNextLabel {
                Text(nextLabel)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Button(store.guidedPathPrimaryActionLabel ?? "Start guided path") {
                if store.guidedDemoPathStep == nil {
                    store.startGuidedDemoPath()
                } else if store.guidedDemoPathStep == .settings {
                    store.completeGuidedDemoPath()
                } else {
                    store.advanceGuidedDemoPath()
                }
                store.triggerHaptic(intent: .primary)
            }
            .buttonStyle(MindSenseButtonStyle(hierarchy: .primary))
        }
    }

    private var demoDataSection: some View {
        FocusSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Data controls",
                    subtitle: "Reset and mutate data for deterministic QA checks."
                )
            )

            debugActionButton("Reset data", hierarchy: .secondary, haptic: .warning) {
                store.resetDemoDataForCurrentScenario()
            }

            debugActionButton("Fast-forward day", hierarchy: .secondary, haptic: .selection) {
                store.fastForwardDemoDay(by: 1)
            }

            debugActionButton("Inject stress event", hierarchy: .secondary, haptic: .warning) {
                store.injectStressEvent()
            }
        }
    }

    private var kpiSection: some View {
        PrimarySurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Product KPI scorecard",
                    subtitle: "Review activation, retention, and session completion metrics."
                )
            )

            NavigationLink {
                KPIScorecardView()
            } label: {
                HStack {
                    MindSenseIconBadge(systemName: "chart.bar.doc.horizontal", tint: MindSensePalette.accent, style: .filled, size: 32)
                    Text("Open KPI scorecard")
                        .font(MindSenseTypography.bodyStrong)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
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
            .buttonStyle(.plain)
        }
    }

    private func debugActionButton(
        _ title: String,
        hierarchy: MindSenseButtonHierarchy,
        haptic: MindSenseHapticIntent,
        action: @escaping () -> Void
    ) -> some View {
        Button(title) {
            action()
            store.triggerHaptic(intent: haptic)
        }
        .buttonStyle(MindSenseButtonStyle(hierarchy: hierarchy, fullWidth: false))
    }
}
