import SwiftUI

struct RegisterView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var authManager: AuthManager
    var onSuccess: () -> Void
    var onLogin: () -> Void
    var onDismiss: (() -> Void)?

    var body: some View {
        AuthScreen(
            title: "Dołącz do early access",
            subtitle: "Utwórz konto i otrzymaj 5 darmowych analiz. Bez karty kredytowej."
        ) {
            VStack(spacing: 16) {
                if !authManager.isConfigured {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Firebase nie jest skonfigurowany.")
                            .font(.caption)
                    }
                    .foregroundStyle(FCTheme.orange)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FCTheme.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous))
                }

                fieldLabel("E-mail") {
                    FCTextField(placeholder: "twoj@email.com", text: $authViewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                }

                fieldLabel("Hasło") {
                    FCTextField(placeholder: "min. 6 znaków", text: $authViewModel.password, isSecure: true)
                        .textContentType(.newPassword)
                }

                fieldLabel("Powtórz hasło") {
                    FCTextField(placeholder: "••••••••", text: $authViewModel.confirmPassword, isSecure: true)
                        .textContentType(.newPassword)
                }

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(FCTheme.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let success = authViewModel.successMessage {
                    Text(success)
                        .font(.caption)
                        .foregroundStyle(FCTheme.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                FCPrimaryButton(
                    title: "Zarejestruj się",
                    icon: "sparkles",
                    isLoading: authViewModel.isLoading,
                    disabled: !authManager.isConfigured
                ) {
                    Task {
                        if await authViewModel.signUp(authManager: authManager) {
                            onSuccess()
                        }
                    }
                }

                FCSecondaryButton(title: "Mam już konto", icon: "arrow.left") {
                    onLogin()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if onDismiss != nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { onDismiss?() }
                        .foregroundStyle(FCTheme.textMuted)
                }
            }
        }
    }

    @ViewBuilder
    private func fieldLabel<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(FCTheme.textMuted)
            content()
        }
    }
}
