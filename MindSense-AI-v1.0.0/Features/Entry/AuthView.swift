import SwiftUI

private enum AuthFormField: Hashable {
    case email
}

struct AuthView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    @State private var mode: MagicLinkIntent = .signIn
    @State private var email = ""
    @State private var inlineMessage = ""
    @State private var inlineSeverity: BannerSeverity = .info
    @State private var isSubmitting = false
    @State private var didAppear = false
    @FocusState private var focusedField: AuthFormField?

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    private var screenTitle: String {
        "Account"
    }

    private var primaryActionTitle: String {
        if isSubmitting {
            return "Sending magic link..."
        }
        if let pending = store.pendingMagicLinkRequest,
           pending.email == normalizedEmail,
           !pending.isExpired {
            return "Resend magic link"
        }
        switch mode {
        case .signIn:
            return "Send sign-in link"
        case .createAccount:
            return "Send sign-up link"
        }
    }

    private var bottomContentPadding: CGFloat {
        110
    }

    private var normalizedEmail: String {
        email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MindSenseRhythm.section) {
                    authHeader
                        .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)

                    FocusSurface {
                        VStack(alignment: .leading, spacing: MindSenseRhythm.regular) {
                            MindSenseSectionHeader(
                                model: .init(
                                    title: "Email access link",
                                    subtitle: mode == .signIn
                                        ? "Use your email to receive a secure sign-in link."
                                        : "Create your account with a one-time secure email link."
                                )
                            )

                            modeSelector

                            MindSenseSectionDivider(emphasis: 0.24)

                            authField(title: "Email", isFocused: focusedField == .email) {
                                TextField("name@example.com", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        submitMagicLinkRequest()
                                    }
                            }

                            magicLinkStatusCard

                            if !inlineMessage.isEmpty {
                                InlineStatusView(text: inlineMessage, severity: inlineSeverity)
                                    .transition(MindSenseMotion.cardTransition(reduceMotion: reduceMotion))
                            }

                            InsetSurface {
                                MindSenseSectionHeader(
                                    model: .init(
                                        title: "Integration",
                                        subtitle: "Configuration currently active for auth routing."
                                    )
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.magicLinkProviderLine)
                                        .font(MindSenseTypography.caption)
                                        .foregroundStyle(.secondary)
                                    Text(store.magicLinkRouteLine)
                                        .font(MindSenseTypography.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(store.magicLinkDeliveryLine)
                                        .font(MindSenseTypography.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text("Link expiry: \(store.magicLinkTTLMinutes) minutes")
                                        .font(MindSenseTypography.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                        }
                    }
                    .disabled(isSubmitting)
                    .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)
                }
                .mindSensePageInsets(bottom: bottomContentPadding)
                .animation(reduceMotion ? nil : MindSenseMotion.confirmation, value: inlineMessage)
                .animation(reduceMotion ? nil : MindSenseMotion.confirmation, value: mode)
            }
            .scrollBounceBehavior(.always, axes: .vertical)
            .mindSensePageBackground()
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

                    Button(primaryActionTitle) {
                        submitMagicLinkRequest()
                    }
                    .accessibilityIdentifier("auth_primary_cta")
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 52))
                    .disabled(isSubmitting)
                }
            }
            .onAppear {
                didAppear = true
                if email.isEmpty, let pending = store.pendingMagicLinkRequest {
                    email = pending.email
                }
                store.track(event: .screenView, surface: .auth)
            }
            .onChange(of: mode) { _, _ in
                focusedField = nil
                inlineMessage = ""
            }
        }
    }

    private var authHeader: some View {
        MindSenseCommandDeck(
            label: screenTitle,
            title: mode == .signIn ? "Sign in with magic link" : "Create account with magic link",
            detail: "No password required. A secure one-time link is sent to your email.",
            metric: "\(store.magicLinkTTLMinutes) min expiry"
        )
    }

    private var modeSelector: some View {
        MindSenseSegmentedControl(
            options: MagicLinkIntent.allCases,
            selection: $mode,
            title: { $0.title },
            onSelectionChanged: { _ in
                store.triggerHaptic(intent: .selection)
            }
        )
    }

    @ViewBuilder
    private var magicLinkStatusCard: some View {
        if let pending = store.pendingMagicLinkRequest {
            InsetSurface {
                MindSenseSectionHeader(
                    model: .init(
                        title: pending.isExpired ? "Magic link expired" : "Magic link sent",
                        subtitle: pending.isExpired
                            ? "Request a new link to continue."
                            : "Sent to \(pending.email). Expires at \(pending.expiresAt.formatted(date: .omitted, time: .shortened))."
                    )
                )

                if let previewURL = store.magicLinkDebugPreviewURL {
                    VStack(alignment: .leading, spacing: 6) {
                        MindSenseSectionDivider(emphasis: 0.2)
                        Text("Preview link")
                            .font(MindSenseTypography.micro)
                            .foregroundStyle(.secondary)
                            .tracking(0.8)
                        Text(previewURL.absoluteString)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)

                        Button("Complete using preview link") {
                            completePendingMagicLinkFromPreview()
                        }
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary, fullWidth: false, minHeight: 40))
                    }
                }

                HStack(spacing: MindSenseSpacing.sm) {
                    Button("Resend") {
                        resendMagicLink()
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                    .disabled(isSubmitting)

                    Button("Cancel request") {
                        store.cancelPendingMagicLinkRequest()
                        inlineSeverity = .info
                        inlineMessage = "Pending magic link cleared."
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                    .disabled(isSubmitting)
                }
            }
            .transition(MindSenseMotion.cardTransition(reduceMotion: reduceMotion))
        }
    }

    private func authField<Content: View>(title: String, isFocused: Bool, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(MindSenseTypography.caption)
                .foregroundStyle(isFocused ? MindSensePalette.signalCoolStrong : .secondary)

            content()
                .font(MindSenseTypography.body)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                        .fill(MindSenseSurfaceLevel.base.fill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                        .stroke(isFocused ? MindSensePalette.strokeEdge : MindSensePalette.strokeSubtle, lineWidth: 1)
                )
                .animation(reduceMotion ? nil : MindSenseMotion.selection, value: isFocused)
        }
    }

    private func submitMagicLinkRequest() {
        guard !isSubmitting else { return }
        focusedField = nil
        isSubmitting = true
        inlineSeverity = .info
        inlineMessage = "Sending magic link..."
        store.triggerHaptic(intent: .primary)

        Task { @MainActor in
            if let message = await store.requestMagicLink(email: email, intent: mode) {
                inlineSeverity = .error
                inlineMessage = message
                store.triggerHaptic(intent: .error)
            } else {
                inlineSeverity = .success
                inlineMessage = "Magic link sent. Check your inbox for \(normalizedEmail)."
            }
            isSubmitting = false
        }
    }

    private func resendMagicLink() {
        guard !isSubmitting else { return }
        isSubmitting = true
        inlineSeverity = .info
        inlineMessage = "Sending magic link..."

        Task { @MainActor in
            if let message = await store.resendMagicLink() {
                inlineSeverity = .error
                inlineMessage = message
                store.triggerHaptic(intent: .error)
            } else {
                inlineSeverity = .success
                inlineMessage = "A new magic link was sent."
                store.triggerHaptic(intent: .success)
            }
            isSubmitting = false
        }
    }

    private func completePendingMagicLinkFromPreview() {
        if let message = store.completePendingMagicLinkForDebug() {
            inlineSeverity = .error
            inlineMessage = message
            store.triggerHaptic(intent: .error)
        } else {
            inlineSeverity = .success
            inlineMessage = "Magic link verified."
        }
    }
}
