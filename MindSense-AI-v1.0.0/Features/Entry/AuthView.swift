import SwiftUI

private enum AuthFormMode: String, CaseIterable {
    case signIn = "Sign In"
    case create = "Create Account"
}

private enum AuthFormField: Hashable {
    case email
    case password
    case confirmPassword
}

struct AuthView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    @State private var mode: AuthFormMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var inlineMessage = ""
    @State private var inlineSeverity: BannerSeverity = .info
    @State private var didAppear = false
    @FocusState private var focusedField: AuthFormField?

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MindSenseRhythm.section) {
                authHeader
                    .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)

                FocusSurface {
                    VStack(alignment: .leading, spacing: MindSenseRhythm.regular) {
                        MindSenseSectionHeader(
                            model: .init(
                                title: mode == .signIn ? "Sign in" : "Create account",
                                subtitle: "Use email and password to continue setup."
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
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .password
                                }
                        }

                        authField(title: "Password", isFocused: focusedField == .password) {
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(mode == .create ? .next : .go)
                                .onSubmit {
                                    if mode == .create {
                                        focusedField = .confirmPassword
                                    } else {
                                        submitAuth()
                                    }
                                }
                        }

                        if mode == .create {
                            authField(title: "Confirm password", isFocused: focusedField == .confirmPassword) {
                                SecureField("Confirm password", text: $confirmPassword)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .confirmPassword)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        submitAuth()
                                    }
                            }
                            .transition(MindSenseMotion.cardTransition(reduceMotion: reduceMotion))
                        }

                        if !inlineMessage.isEmpty {
                            InlineStatusView(text: inlineMessage, severity: inlineSeverity)
                                .transition(MindSenseMotion.cardTransition(reduceMotion: reduceMotion))
                        }

                        MindSenseSectionDivider(emphasis: 0.3)

                        Button(mode == .signIn ? "Sign In" : "Create Account") {
                            submitAuth()
                        }
                        .accessibilityIdentifier("auth_primary_cta")
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 52))

                        if mode == .signIn {
                            Button("Forgot password?") {
                                inlineSeverity = .info
                                inlineMessage = "Reset email sent. Check your inbox to continue."
                            }
                            .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                        }

                        if AppFeatureFlags.demoControlsEnabled {
                            VStack(alignment: .leading, spacing: 6) {
                                MindSenseSectionDivider(emphasis: 0.2)
                                Text("Optional")
                                    .font(MindSenseTypography.micro)
                                    .foregroundStyle(.secondary)
                                    .tracking(0.8)
                                Button("Continue in Demo Mode") {
                                    store.startDemoMode()
                                }
                                .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                            }
                        }
                    }
                }
                .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)
            }
            .mindSensePageInsets()
            .animation(reduceMotion ? nil : MindSenseMotion.confirmation, value: inlineMessage)
            .animation(reduceMotion ? nil : MindSenseMotion.confirmation, value: mode)
        }
        .mindSensePageBackground()
        .onAppear {
            didAppear = true
        }
        .onChange(of: mode) { _, newMode in
            focusedField = nil
            if newMode == .signIn {
                confirmPassword = ""
            }
        }
    }

    private var authHeader: some View {
        InsetSurface {
            HStack(spacing: 8) {
                MindSenseIconBadge(
                    systemName: "lock.shield.fill",
                    tint: MindSensePalette.signalCoolStrong,
                    style: .filled,
                    size: 30
                )
                Text("Secure access")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(MindSensePalette.signalCoolStrong)
                    .tracking(1)
                Spacer()
                PillChip(label: "Secure auth", state: .selected)
            }

            MindSenseSectionHeader(
                model: .init(
                    title: mode == .signIn ? "Sign in to continue setup" : "Create your secure account",
                    subtitle: "Your account keeps baseline, check-ins, and experiments synchronized."
                )
            )

            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MindSensePalette.signalCool)
                Text("Credentials are used only for account access and sync.")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var modeSelector: some View {
        MindSenseSegmentedControl(
            options: AuthFormMode.allCases,
            selection: $mode,
            title: { $0.rawValue },
            onSelectionChanged: { _ in
                store.triggerHaptic(intent: .selection)
            }
        )
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

    private func submitAuth() {
        focusedField = nil
        store.triggerHaptic(intent: .primary)

        let result: String?
        if mode == .signIn {
            result = store.signIn(email: email, password: password)
        } else {
            result = store.createAccount(
                email: email,
                password: password,
                confirm: confirmPassword
            )
        }

        if let message = result {
            inlineSeverity = .error
            inlineMessage = message
            store.triggerHaptic(intent: .error)
        } else {
            inlineSeverity = .success
            inlineMessage = mode == .signIn ? "Sign in successful." : "Account created."
        }
    }
}
