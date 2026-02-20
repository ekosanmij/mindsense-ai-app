import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject private var store: MindSenseStore

    @State private var inlineMessage = ""
    @State private var inlineSeverity: BannerSeverity = .info
    @State private var isSubmitting = false
    @State private var didTrackScreenView = false

    private var screenTitle: String {
        "Account"
    }

    private var bottomContentPadding: CGFloat {
        124
    }

    private var statusTransition: AnyTransition {
        .opacity
    }

    private var commandTitle: String {
        "Continue with Apple"
    }

    private var commandDetail: String {
        if inlineSeverity == .success {
            return "Signed in. Opening your account."
        }
        if isSubmitting {
            return "Verifying your Apple ID."
        }
        return "One secure account for the full MindSense experience."
    }

    private var commandMetric: String {
        if inlineSeverity == .success {
            return "Connected"
        }
        if isSubmitting {
            return "Working"
        }
        return "Apple ID"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.clear
                    .mindSensePageBackground()

                AuthAmbientBackground()
                    .padding(.top, -34)

                ScrollView {
                    VStack(spacing: MindSenseRhythm.section) {
                        authHeader

                        FocusSurface {
                            VStack(alignment: .leading, spacing: MindSenseRhythm.regular) {
                                MindSenseSectionHeader(
                                    model: .init(
                                        title: "Secure sign in",
                                        subtitle: "Use the Apple ID on this device.",
                                        icon: "apple.logo"
                                    )
                                )

                                InsetSurface {
                                    VStack(alignment: .leading, spacing: 10) {
                                        authPoint(icon: "lock.shield.fill", text: "Private by default.")
                                        MindSenseSectionDivider(emphasis: 0.14)
                                        authPoint(icon: "checkmark.seal.fill", text: "No passwords and no email links.")
                                    }
                                }

                                if !inlineMessage.isEmpty {
                                    InlineStatusView(text: inlineMessage, severity: inlineSeverity)
                                        .transition(statusTransition)
                                }
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            MindSenseLogoWatermark(height: 110, tint: MindSensePalette.signalCoolStrong)
                                .padding(.top, 8)
                                .padding(.trailing, 6)
                        }
                    }
                    .mindSensePageInsets(bottom: bottomContentPadding)
                }
                .scrollBounceBehavior(.always, axes: .vertical)
            }
            .navigationTitle(screenTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: screenTitle)
                }
            }
            .safeAreaInset(edge: .bottom) {
                MindSenseBottomActionDock {
                    Spacer()
                        .frame(height: 12)

                    appleButton
                }
            }
            .onAppear {
                if !didTrackScreenView {
                    didTrackScreenView = true
                    store.track(event: .screenView, surface: .auth)
                }
            }
        }
    }

    private var authHeader: some View {
        MindSenseCommandDeck(
            label: screenTitle,
            title: commandTitle,
            detail: commandDetail,
            metric: commandMetric
        )
        .transition(statusTransition)
    }

    private var appleButton: some View {
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            handleAppleAuthorization(result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous))
        .disabled(isSubmitting)
        .opacity(isSubmitting ? 0.8 : 1)
        .accessibilityIdentifier("auth_apple_cta")
    }

    private func authPoint(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MindSensePalette.signalCoolStrong)
                .padding(.top, 1)

            Text(text)
                .font(MindSenseTypography.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
