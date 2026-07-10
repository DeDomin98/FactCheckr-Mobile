import SwiftUI

struct AuthView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var authManager: AuthManager
    var onAuthenticated: () -> Void
    var onContinueAsGuest: (() -> Void)?

    enum Step { case choice, email }

    @State private var step: Step = .choice
    @State private var isSignUp = false

    var body: some View {
        AuthScreen(
            title: title,
            subtitle: subtitle
        ) {
            VStack(spacing: 16) {
                if !authManager.isConfigured {
                    inlineWarning(Loc.t(.firebaseNotConfigured))
                }

                switch step {
                case .choice:
                    choiceContent
                case .email:
                    emailContent
                }
            }
            .animation(.easeInOut(duration: 0.25), value: step)
        }
        .onChange(of: isSignUp) { _ in clearMessages() }
        .onChange(of: step) { _ in clearMessages() }
    }

    private var title: String {
        switch step {
        case .choice: return Loc.t(.authWelcomeTitle)
        case .email: return isSignUp ? Loc.t(.createAccount) : Loc.t(.signIn)
        }
    }

    private var subtitle: String {
        switch step {
        case .choice: return Loc.t(.authChoiceSubtitle)
        case .email: return isSignUp ? Loc.t(.authEmailSignupSub) : Loc.t(.authEmailSigninSub)
        }
    }

    // MARK: - Step 1: choose method

    private var choiceContent: some View {
        VStack(spacing: 12) {
            AppleSignInButtonStyle(
                isLoading: authViewModel.socialLoading == .apple,
                disabled: !authManager.isConfigured || authViewModel.socialLoading != nil
            ) {
                Task {
                    if await authViewModel.signInWithApple(authManager: authManager) {
                        onAuthenticated()
                    }
                }
            }

            GoogleSignInButtonStyle(
                isLoading: authViewModel.socialLoading == .google,
                disabled: !authManager.isConfigured || authViewModel.socialLoading != nil
            ) {
                Task {
                    if await authViewModel.signInWithGoogle(authManager: authManager) {
                        onAuthenticated()
                    }
                }
            }

            orDivider

            FCSecondaryButton(title: Loc.t(.continueEmail), icon: "envelope.fill") {
                isSignUp = false
                step = .email
            }

            if let onContinueAsGuest {
                Button(action: onContinueAsGuest) {
                    Text(Loc.t(.continueAsGuest))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FCTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }

            if let error = authViewModel.errorMessage {
                inlineError(error)
            }

            Text(Loc.t(.authTerms))
                .font(.caption2)
                .foregroundStyle(FCTheme.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }

    // MARK: - Step 2: email form

    private var emailContent: some View {
        VStack(spacing: 16) {
            Button {
                step = .choice
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text(Loc.t(.otherMethods))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(FCTheme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Picker("", selection: $isSignUp) {
                Text(Loc.t(.segLogin)).tag(false)
                Text(Loc.t(.segRegister)).tag(true)
            }
            .pickerStyle(.segmented)

            fieldLabel(Loc.t(.email))
            FCTextField(placeholder: "twoj@email.com", text: $authViewModel.email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)

            fieldLabel(Loc.t(.password))
            FCTextField(placeholder: "••••••••", text: $authViewModel.password, isSecure: true)
                .textContentType(isSignUp ? .newPassword : .password)

            if isSignUp {
                fieldLabel(Loc.t(.confirmPassword))
                FCTextField(placeholder: "••••••••", text: $authViewModel.confirmPassword, isSecure: true)
                    .textContentType(.newPassword)
            }

            if let error = authViewModel.errorMessage {
                inlineError(error)
            }
            if let success = authViewModel.successMessage {
                inlineSuccess(success)
            }

            FCPrimaryButton(
                title: isSignUp ? Loc.t(.createAccount) : Loc.t(.signIn),
                icon: isSignUp ? "person.badge.plus" : "arrow.right",
                isLoading: authViewModel.isLoading,
                disabled: !authManager.isConfigured
            ) {
                Task { await submit() }
            }
        }
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(FCTheme.border).frame(height: 1)
            Text(Loc.t(.or))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(FCTheme.textMuted)
                .fixedSize()
            Rectangle().fill(FCTheme.border).frame(height: 1)
        }
        .padding(.vertical, 2)
    }

    private func submit() async {
        let ok: Bool
        if isSignUp {
            ok = await authViewModel.signUp(authManager: authManager)
        } else {
            ok = await authViewModel.signIn(authManager: authManager)
        }
        if ok { onAuthenticated() }
    }

    private func clearMessages() {
        authViewModel.errorMessage = nil
        authViewModel.successMessage = nil
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(FCTheme.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Social buttons (styled to match HIG)

struct AppleSignInButtonStyle: View {
    var isLoading: Bool
    var disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.black)
                } else {
                    Image(systemName: "applelogo")
                        .font(.system(size: 18, weight: .medium))
                    Text(Loc.t(.continueApple))
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(.black)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
            .opacity(disabled ? 0.5 : 1)
        }
        .disabled(disabled || isLoading)
    }
}

struct GoogleSignInButtonStyle: View {
    var isLoading: Bool
    var disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(Color(hex: 0x3C4043))
                } else {
                    Image("GoogleLogo")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 20, height: 20)
                    Text(Loc.t(.continueGoogle))
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(Color(hex: 0x3C4043))
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
            .opacity(disabled ? 0.5 : 1)
        }
        .disabled(disabled || isLoading)
    }
}

private func inlineWarning(_ text: String) -> some View {
    HStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle.fill")
        Text(text).font(.caption)
    }
    .foregroundStyle(FCTheme.orange)
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(FCTheme.orange.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous))
}

private func inlineError(_ text: String) -> some View {
    HStack(spacing: 8) {
        Image(systemName: "xmark.circle.fill")
        Text(text).font(.caption)
    }
    .foregroundStyle(FCTheme.red)
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(FCTheme.red.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous))
}

private func inlineSuccess(_ text: String) -> some View {
    HStack(spacing: 8) {
        Image(systemName: "checkmark.circle.fill")
        Text(text).font(.caption)
    }
    .foregroundStyle(FCTheme.green)
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(FCTheme.green.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous))
}
