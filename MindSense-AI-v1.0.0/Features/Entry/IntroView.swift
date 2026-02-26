import SwiftUI
import AuthenticationServices

struct IntroView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @State private var didAppear = false
    @State private var inlineMessage = ""
    @State private var inlineSeverity: BannerSeverity = .info
    @State private var isSubmitting = false
    @State private var showGlossary = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let highlights: [(title: String, detail: String, icon: String)] = [
        ("Status in seconds", "Load, Readiness, and Consistency at a glance.", "gauge.with.dots.needle.bottom.50percent"),
        ("One next action", "Get one clear regulate step with duration.", "figure.mind.and.body"),
        ("Why it was chosen", "See recommendation rationale and confidence in context.", "chart.line.uptrend.xyaxis")
    ]
    private let dailyLoop: [(title: String, detail: String, icon: String)] = [
        ("Today", "Understand your current state and the one next action for today's goal.", "sun.max.fill"),
        ("Regulate", "Run one short protocol, then record whether it helped.", "waveform.path.ecg"),
        ("Data", "Review patterns and experiments so guidance improves over time.", "chart.xyaxis.line")
    ]

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MindSenseRhythm.regular) {
                introHero
                    .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)

                signInCTA
                    .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)

                InsetSurface {
                    MindSenseSectionHeader(
                        model: .init(title: "What you get", subtitle: "Clear status. Clear action.")
                    )

                    ForEach(Array(highlights.enumerated()), id: \.element.title) { index, item in
                        unlockRow(item)

                        if index < highlights.count - 1 {
                            MindSenseSectionDivider(emphasis: 0.12)
                        }
                    }
                }
                .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)

                InsetSurface {
                    MindSenseSectionHeader(
                        model: .init(title: "How MindSense works", subtitle: "One daily loop: Today, Regulate, Data.")
                    )

                    ForEach(Array(dailyLoop.enumerated()), id: \.element.title) { index, item in
                        unlockRow(item)

                        if index < dailyLoop.count - 1 {
                            MindSenseSectionDivider(emphasis: 0.12)
                        }
                    }

                    MindSenseSectionDivider(emphasis: 0.12)

                    Button("Open glossary and terms") {
                        showGlossary = true
                        store.triggerHaptic(intent: .selection)
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                }
                .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)

                if !inlineMessage.isEmpty {
                    InlineStatusView(text: inlineMessage, severity: inlineSeverity)
                        .mindSenseStaggerEntrance(4, isPresented: didAppear, reduceMotion: reduceMotion)
                }
            }
            .mindSensePageInsets()
        }
        .mindSensePageBackground()
        .onAppear {
            didAppear = true
        }
        .sheet(isPresented: $showGlossary) {
            MindSenseGlossarySheet()
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
                PillChip(label: "Setup < 45 sec", state: .unselected)
            }

            MindSenseSectionHeader(
                model: .init(
                    title: "Daily nervous-system guidance, simplified",
                    subtitle: "See your state, do one next step, and learn what works."
                )
            )
        }
    }

    private var signInCTA: some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAppleAuthorization(result)
            }
            .accessibilityIdentifier("intro_primary_cta")
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous))
            .disabled(isSubmitting)
            .opacity(isSubmitting ? 0.84 : 1)

            Text(verticalSizeClass == .compact ? "Continue with Apple to start." : "Continue with Apple. Setup takes under a minute.")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func unlockRow(_ item: (title: String, detail: String, icon: String)) -> some View {
        HStack(alignment: .top, spacing: 12) {
            MindSenseIconBadge(systemName: item.icon, tint: MindSensePalette.signalCool, style: .filled, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(MindSenseTypography.caption.weight(.semibold))
                Text(item.detail)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 48, alignment: .leading)
    }

    private func handleAppleAuthorization(_ result: Result<ASAuthorization, Error>) {
        guard !isSubmitting else { return }
        isSubmitting = true
        inlineSeverity = .info
        inlineMessage = "Authorizing with Apple..."
        store.triggerHaptic(intent: .primary)

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                inlineSeverity = .error
                inlineMessage = "Unsupported Apple credential."
                store.triggerHaptic(intent: .error)
                isSubmitting = false
                return
            }

            if let message = store.completeSignInWithApple(
                userID: credential.user,
                email: credential.email,
                fullName: credential.fullName
            ) {
                inlineSeverity = .error
                inlineMessage = message
                store.triggerHaptic(intent: .error)
            } else {
                store.completeIntro()
                inlineSeverity = .success
                inlineMessage = "Signed in. Opening setup..."
            }

        case .failure(let error):
            inlineSeverity = (error as? ASAuthorizationError)?.code == .canceled ? .info : .error
            inlineMessage = userFacingAppleError(error)
            if (error as? ASAuthorizationError)?.code != .canceled {
                store.triggerHaptic(intent: .error)
            }
        }

        isSubmitting = false
    }

    private func userFacingAppleError(_ error: Error) -> String {
        guard let appleError = error as? ASAuthorizationError else {
            return "Apple sign-in failed. Try again."
        }

        switch appleError.code {
        case .canceled:
            return "Apple sign-in canceled."
        case .notHandled:
            return "Apple sign-in could not be completed."
        case .invalidResponse:
            return "Apple sign-in returned an invalid response."
        case .failed:
            return "Apple sign-in failed. Check Apple ID settings and try again."
        case .unknown:
            return "Apple sign-in failed due to an unknown error."
        @unknown default:
            return "Apple sign-in failed. Try again."
        }
    }
}
