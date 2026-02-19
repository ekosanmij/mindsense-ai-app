import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @State private var checkInValue = 5.0
    @State private var inlineMessage = ""
    @State private var inlineSeverity: BannerSeverity = .info
    @State private var didAppear = false

    private var activationSteps: [OnboardingStep] {
        OnboardingStep.activationSteps
    }

    private var activeStep: OnboardingStep {
        activationSteps.first(where: { !store.onboarding.isComplete($0) }) ?? activationSteps.last ?? .firstCheckIn
    }

    private var stepNumber: Int {
        guard let index = activationSteps.firstIndex(of: activeStep) else {
            return 1
        }
        return index + 1
    }

    private var requiresEscalationCopy: Bool {
        activeStep == .firstCheckIn && checkInValue >= 9
    }

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MindSenseRhythm.section) {
                onboardingHeader
                    .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)

                FocusSurface {
                    VStack(alignment: .leading, spacing: MindSenseRhythm.regular) {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Activation",
                                subtitle: "Two required steps, then optional setup in Settings."
                            )
                        )

                        progressHero

                        stepContent(
                            icon: activeStep.icon,
                            title: activeStep.title,
                            body: activeStep.benefit
                        )
                        .id(activeStep.rawValue)
                        .frame(maxWidth: .infinity, minHeight: 94, alignment: .topLeading)
                        .transition(MindSenseMotion.cardTransition(reduceMotion: reduceMotion))

                        if activeStep == .firstCheckIn {
                            InsetSurface {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current load")
                                        .font(MindSenseTypography.bodyStrong)

                                    Slider(value: $checkInValue, in: 0...10, step: 1)

                                    HStack {
                                        Text("Calm")
                                        Spacer()
                                        Text("High")
                                    }
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(.secondary)

                                    PillChip(label: "Selected \(Int(checkInValue.rounded())) / 10", state: .unselected)
                                }
                            }
                        }

                        Text("Health and notification permissions can be enabled later in Settings.")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if !inlineMessage.isEmpty {
                            InlineStatusView(text: inlineMessage, severity: inlineSeverity)
                                .transition(MindSenseMotion.cardTransition(reduceMotion: reduceMotion))
                        }

                        Button(activeStep.cta) {
                            completeActiveStep()
                        }
                        .accessibilityIdentifier("onboarding_primary_cta")
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 52))
                    }
                }
                .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)

                if requiresEscalationCopy {
                    EscalationGuidanceView(context: .sustainedHighLoad)
                        .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)
                }
            }
            .mindSensePageInsets()
            .animation(reduceMotion ? nil : MindSenseMotion.cardReveal, value: activeStep)
        }
        .mindSensePageBackground()
        .onAppear {
            didAppear = true
        }
    }

    private var onboardingHeader: some View {
        InsetSurface {
            HStack(spacing: 8) {
                MindSenseIconBadge(
                    systemName: "bolt.heart.fill",
                    tint: MindSensePalette.signalCoolStrong,
                    style: .filled,
                    size: 30
                )
                Text("Onboarding")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(MindSensePalette.signalCoolStrong)
                    .tracking(1)
                Spacer()
                PillChip(label: "Step \(stepNumber)/\(activationSteps.count)", state: .selected)
            }

            MindSenseSectionHeader(
                model: .init(
                    title: "Activate \(AppIA.today) in under 45 seconds",
                    subtitle: "Step \(stepNumber) of \(activationSteps.count)."
                )
            )
        }
    }

    private var progressHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Step \(stepNumber) of \(activationSteps.count)")
                    .font(MindSenseTypography.metricCaption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(store.onboardingPercent * 100))%")
                    .font(MindSenseTypography.metricBody)
                    .foregroundStyle(MindSensePalette.signalCoolStrong)
            }

            HStack(spacing: 10) {
                ForEach(activationSteps) { step in
                    Capsule(style: .continuous)
                        .fill(stepRailColor(step))
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func stepContent(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            MindSenseIconBadge(systemName: icon, tint: MindSensePalette.signalCool, style: .filled, size: 40)

            VStack(alignment: .leading, spacing: 8) {
                Text(title.mindSenseHeadlineSafe)
                    .font(MindSenseTypography.titleCompact)
                Text(body)
                    .font(MindSenseTypography.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func stepRailColor(_ step: OnboardingStep) -> Color {
        if store.onboarding.isComplete(step) {
            return MindSensePalette.signalCool
        }
        if step == activeStep {
            return MindSensePalette.signalCoolStrong
        }
        return MindSensePalette.strokeSubtle
    }

    private func completeActiveStep() {
        guard store.canComplete(step: activeStep) else {
            inlineSeverity = .warning
            inlineMessage = "Complete the current step first."
            store.triggerHaptic(intent: .warning)
            return
        }

        store.triggerHaptic(intent: .primary)

        switch activeStep {
        case .baseline:
            inlineSeverity = .success
            inlineMessage = "Baseline started."
            store.completeOnboarding(step: .baseline)

        case .firstCheckIn:
            inlineSeverity = .success
            inlineMessage = "Check-in captured."
            store.completeOnboarding(step: .firstCheckIn, checkInValue: Int(checkInValue.rounded()))

        default:
            store.completeOnboarding(step: activeStep)
        }
    }
}
