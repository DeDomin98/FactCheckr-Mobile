import SwiftUI

struct AuthScreen<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            FCBackground()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        FCLogo(size: 48)
                        Text(title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(FCTheme.textPrimary)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(FCTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    FCCard {
                        content
                    }
                }
                .padding(20)
            }
        }
    }
}

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var authManager: AuthManager
    var onSuccess: () -> Void
    var onRegister: () -> Void
    var onDismiss: (() -> Void)?

    var body: some View {
        AuthScreen(
            title: "Zaloguj się",
            subtitle: "5 darmowych analiz po rejestracji. Darmowy dostęp w early access."
        ) {
            VStack(spacing: 16) {
                if !authManager.isConfigured {
                    warningBanner("Firebase nie jest skonfigurowany. Dodaj GoogleService-Info.plist.")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("E-mail")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FCTheme.textMuted)
                    FCTextField(placeholder: "twoj@email.com", text: $authViewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Hasło")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FCTheme.textMuted)
                    FCTextField(placeholder: "••••••••", text: $authViewModel.password, isSecure: true)
                        .textContentType(.password)
                }

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(FCTheme.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                FCPrimaryButton(
                    title: "Zaloguj się",
                    icon: "arrow.right",
                    isLoading: authViewModel.isLoading,
                    disabled: !authManager.isConfigured
                ) {
                    Task {
                        if await authViewModel.signIn(authManager: authManager) {
                            onSuccess()
                        }
                    }
                }

                FCSecondaryButton(title: "Utwórz konto", icon: "person.badge.plus") {
                    onRegister()
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
}

private func warningBanner(_ text: String) -> some View {
    HStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle.fill")
        Text(text)
            .font(.caption)
    }
    .foregroundStyle(FCTheme.orange)
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(FCTheme.orange.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous))
}
