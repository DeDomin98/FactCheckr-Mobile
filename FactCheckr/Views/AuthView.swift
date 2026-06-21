import SwiftUI

struct AuthView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var authManager: AuthManager
    var onAuthenticated: () -> Void

    @State private var isSignUp = false

    var body: some View {
        AuthScreen(
            title: isSignUp ? "Utwórz konto" : "Zaloguj się",
            subtitle: "E-mail i hasło — jeden login do wszystkich analiz."
        ) {
            VStack(spacing: 16) {
                if !authManager.isConfigured {
                    inlineWarning("Firebase nie jest skonfigurowany. Dodaj GoogleService-Info.plist.")
                }

                Picker("Tryb", selection: $isSignUp) {
                    Text("Logowanie").tag(false)
                    Text("Rejestracja").tag(true)
                }
                .pickerStyle(.segmented)

                fieldLabel("E-mail")
                FCTextField(placeholder: "twoj@email.com", text: $authViewModel.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)

                fieldLabel("Hasło")
                FCTextField(placeholder: "••••••••", text: $authViewModel.password, isSecure: true)
                    .textContentType(isSignUp ? .newPassword : .password)

                if isSignUp {
                    fieldLabel("Potwierdź hasło")
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
                    title: isSignUp ? "Utwórz konto" : "Zaloguj się",
                    icon: isSignUp ? "person.badge.plus" : "arrow.right",
                    isLoading: authViewModel.isLoading,
                    disabled: !authManager.isConfigured
                ) {
                    Task { await submit() }
                }
            }
        }
        .onChange(of: isSignUp) { _ in
            authViewModel.errorMessage = nil
            authViewModel.successMessage = nil
        }
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

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(FCTheme.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
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
