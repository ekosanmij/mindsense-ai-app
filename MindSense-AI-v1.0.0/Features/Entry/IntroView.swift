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
                .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)

                if !inlineMessage.isEmpty {
                    InlineStatusView(text: inlineMessage, severity: inlineSeverity)
                        .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)
                }
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
