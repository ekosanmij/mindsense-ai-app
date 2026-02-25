import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @State private var didAppear = false

    @State private var inlineMessage = ""
    @State private var inlineSeverity: BannerSeverity = .info
    @State private var isSubmitting = false
    @State private var didTrackScreenView = false

    private let highlights: [(title: String, detail: String, icon: String)] = [
        ("Resume instantly", "Your trend context, check-ins, and session history are ready.", "chart.xyaxis.line"),
        ("One secure tap", "Use your Apple ID with no password reset friction.", "lock.shield.fill"),
        ("Same routine", "Notifications, quiet hours, and settings stay in place.", "clock.badge.checkmark")
    ]

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
                .mindSensePageBackground()

            AuthAmbientBackground()
                .padding(.top, -34)

            ScrollView {
                VStack(spacing: MindSenseRhythm.section) {
                    welcomeHero
                        .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(title: "What continues", subtitle: "No re-setup required.")
                        )

                        ForEach(Array(highlights.enumerated()), id: \.element.title) { index, item in
                            highlightRow(item)

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
                    .accessibilityIdentifier("auth_apple_cta")
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
            .scrollBounceBehavior(.always, axes: .vertical)
        }
        .onAppear {
            didAppear = true
            if !didTrackScreenView {
                didTrackScreenView = true
                store.track(event: .screenView, surface: .auth)
            }
        }
    }

    private var welcomeHero: some View {
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
                PillChip(label: "Welcome back", state: .selected)
            }

            MindSenseSectionHeader(
                model: .init(
                    title: "Your guidance flow is ready",
                    subtitle: "Continue with Apple to jump right back in."
                )
            )
        }
    }

    private func highlightRow(_ item: (title: String, detail: String, icon: String)) -> some View {
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
                inlineSeverity = .success
                inlineMessage = "Signed in. Opening your account."
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

private struct AuthAmbientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                MindSensePalette.signalCoolSoft.opacity(0.26),
                MindSensePalette.glowWarmSoft.opacity(0.18),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(maxWidth: .infinity)
        .frame(height: 246)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
