import SwiftUI

private enum AuthFormField: Hashable {
    case email
}

private enum AuthProgressStep: Int, CaseIterable, Identifiable {
    case enterEmail
    case checkInbox
    case verify

    var id: Int { rawValue }

    var chipTitle: String {
        switch self {
        case .enterEmail:
            return "1 Email"
        case .checkInbox:
            return "2 Inbox"
        case .verify:
            return "3 Verify"
        }
    }

    var hint: String {
        switch self {
        case .enterEmail:
            return "Enter your email to request a secure one-time link."
        case .checkInbox:
            return "Open your inbox and tap the most recent MindSense link."
        case .verify:
            return "Return to MindSense and continue from your verified session."
        }
    }
}

struct AuthView: View {
    @EnvironmentObject private var store: MindSenseStore

    @State private var mode: MagicLinkIntent = .signIn
    @State private var email = ""
    @State private var inlineMessage = ""
    @State private var inlineSeverity: BannerSeverity = .info
    @State private var isSubmitting = false
    @State private var didTrackScreenView = false
    @State private var showDebugPreview = false
    @FocusState private var focusedField: AuthFormField?

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

    private var activePendingRequest: PendingMagicLinkRequest? {
        store.pendingMagicLinkRequest
    }

    private var progressStep: AuthProgressStep {
        if inlineSeverity == .success && inlineMessage.localizedCaseInsensitiveContains("verified") {
            return .verify
        }
        if isSubmitting || (activePendingRequest?.isExpired == false) {
            return .checkInbox
        }
        return .enterEmail
    }

    private var statusTransition: AnyTransition {
        .opacity
    }

    private var commandTitle: String {
        switch mode {
        case .signIn:
            return "Sign in with one secure email link"
        case .createAccount:
            return "Create your account with one secure email link"
        }
    }

    private var commandDetail: String {
        if let pending = activePendingRequest, !pending.isExpired {
            return "A link is active for \(pending.email). Use the most recent email to continue."
        }
        switch mode {
        case .signIn:
            return "No password required. Request a sign-in link and continue from your inbox."
        case .createAccount:
            return "No password setup. Request a sign-up link and continue from your inbox."
        }
    }

    private var commandMetric: String {
        if let pending = activePendingRequest, !pending.isExpired {
            return "Inbox check"
        }
        return "\(store.magicLinkTTLMinutes) min expiry"
    }

    private var normalizedEmail: String {
        email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
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
                                        title: "Email access",
                                        subtitle: mode == .signIn
                                            ? "Use your email to receive a secure sign-in link."
                                            : "Use your email to create your account with a secure sign-up link.",
                                        icon: "lock.shield.fill"
                                    )
                                )

                                modeSelector

                                flowPreview

                                MindSenseSectionDivider(emphasis: 0.24)

                                emailField

                                helperHint

                                if isSubmitting {
                                    submittingState
                                        .transition(statusTransition)
                                }

                                if !inlineMessage.isEmpty {
                                    InlineStatusView(text: inlineMessage, severity: inlineSeverity)
                                        .transition(statusTransition)
                                }
                            }
                        }
                        .disabled(isSubmitting)
                        .overlay(alignment: .topTrailing) {
                            MindSenseLogoWatermark(height: 110, tint: MindSensePalette.signalCoolStrong)
                                .padding(.top, 8)
                                .padding(.trailing, 6)
                        }

                        magicLinkStatusCard
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

                    Button {
                        submitMagicLinkRequest()
                    } label: {
                        primaryButtonLabel
                    }
                    .accessibilityIdentifier("auth_primary_cta")
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 52))
                    .disabled(isSubmitting)
                }
            }
            .onAppear {
                if email.isEmpty, let pending = store.pendingMagicLinkRequest {
                    email = pending.email
                }
                if !didTrackScreenView {
                    didTrackScreenView = true
                    store.track(event: .screenView, surface: .auth)
                }
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
            title: commandTitle,
            detail: commandDetail,
            metric: commandMetric
        )
        .id(mode)
        .transition(statusTransition)
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

    private var flowPreview: some View {
        InsetSurface {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ForEach(AuthProgressStep.allCases) { step in
                        PillChip(label: step.chipTitle, state: chipState(for: step))
                            .frame(maxWidth: .infinity)
                    }
                }

                Text(progressStep.hint)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var emailField: some View {
        authField(title: "Email", isFocused: focusedField == .email) {
            HStack(spacing: 8) {
                Image(systemName: "envelope")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(focusedField == .email ? MindSensePalette.signalCoolStrong : .secondary)

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

                if !email.isEmpty {
                    Button {
                        email = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear email")
                }
            }
        }
    }

    private var helperHint: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MindSensePalette.signalCool)
                .padding(.top, 1)
                .accessibilityHidden(true)

            Text("Use the email you want linked to this account. You can request another link after the cooldown.")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var submittingState: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)

            Text("Sending magic link...")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                .fill(MindSenseSurfaceLevel.glass.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var magicLinkStatusCard: some View {
        if let pending = activePendingRequest {
            PrimarySurface(tone: pending.isExpired ? .warning : .accent) {
                MindSenseSectionHeader(
                    model: .init(
                        title: pending.isExpired ? "Magic link expired" : "Check your inbox",
                        subtitle: pending.isExpired
                            ? "Request a new link to continue."
                            : "Sent to \(pending.email). Expires at \(pending.expiresAt.formatted(date: .omitted, time: .shortened)).",
                        icon: pending.isExpired ? "clock.fill" : "paperplane.fill"
                    )
                )

                HStack(spacing: 8) {
                    PillChip(
                        label: pending.intent == .signIn ? "Sign in link" : "Sign up link",
                        state: .selected
                    )
                    PillChip(
                        label: pending.isExpired ? "Expired" : "Active",
                        state: pending.isExpired ? .disabled : .unselected
                    )
                }

                if let previewURL = store.magicLinkDebugPreviewURL {
                    DisclosureGroup(isExpanded: $showDebugPreview) {
                        VStack(alignment: .leading, spacing: 8) {
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
                        .padding(.top, 6)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(MindSensePalette.signalCoolStrong)
                            Text("Debug preview link")
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                        }
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
            .transition(statusTransition)
        }
    }

    private var primaryButtonLabel: some View {
        HStack(spacing: 8) {
            if isSubmitting {
                ProgressView()
                    .controlSize(.small)
                    .tint(MindSensePalette.onAccent)
            }
            Text(primaryActionTitle)
        }
    }

    private func chipState(for step: AuthProgressStep) -> MindSenseChipState {
        if step.rawValue <= progressStep.rawValue {
            return .selected
        }
        return .disabled
    }

    private func authField<Content: View>(title: String, isFocused: Bool, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(MindSenseTypography.caption)
                .foregroundStyle(isFocused ? MindSensePalette.signalCoolStrong : .secondary)

            content()
                .font(MindSenseTypography.body)
                .padding(.horizontal, 12)
                .frame(minHeight: 46)
                .background(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                        .fill(MindSenseSurfaceLevel.base.fill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                        .stroke(isFocused ? MindSensePalette.strokeEdge : MindSensePalette.strokeSubtle, lineWidth: 1)
                )
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
