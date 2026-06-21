import SwiftUI

struct VerifyEmailInfoView: View {
    @ObservedObject var authManager: AuthManager
    @State private var isSending = false
    @State private var message: String?
    @State private var isError = false

    var onVerified: () -> Void
    var onSignOut: () -> Void

    var body: some View {
        ZStack {
            FCBackground()

            ScrollView {
                VStack(spacing: 24) {
                    FCLogo(size: 56)

                    Text("Potwierdź adres e-mail")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(FCTheme.textPrimary)

                    Text("Wysłaliśmy link weryfikacyjny na \(authManager.user?.email ?? "twój e-mail"). Kliknij link, a następnie wróć do aplikacji.")
                        .font(.subheadline)
                        .foregroundStyle(FCTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    FCCard {
                        VStack(spacing: 14) {
                            HStack(spacing: 10) {
                                Image(systemName: "envelope.open.fill")
                                    .foregroundStyle(FCTheme.accentLight)
                                Text("Sprawdź skrzynkę odbiorczą i folder spam")
                                    .font(.caption)
                                    .foregroundStyle(FCTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if let message {
                                Text(message)
                                    .font(.caption)
                                    .foregroundStyle(isError ? FCTheme.red : FCTheme.green)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            FCPrimaryButton(
                                title: "Wyślij ponownie e-mail",
                                icon: "paperplane.fill",
                                isLoading: isSending
                            ) {
                                Task { await resend() }
                            }

                            FCSecondaryButton(title: "Sprawdź status weryfikacji", icon: "arrow.triangle.2.circlepath") {
                                Task { await checkVerification() }
                            }
                        }
                    }

                    Button("Wyloguj się", role: .destructive) {
                        try? authManager.signOut()
                        onSignOut()
                    }
                    .font(.subheadline)
                    .foregroundStyle(FCTheme.red.opacity(0.85))
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .navigationTitle("Weryfikacja")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func resend() async {
        isSending = true
        message = nil
        defer { isSending = false }
        do {
            try await authManager.resendVerificationEmail()
            message = "E-mail weryfikacyjny wysłany ponownie."
            isError = false
        } catch {
            message = error.localizedDescription
            isError = true
        }
    }

    private func checkVerification() async {
        do {
            try await authManager.reloadUser()
            if !authManager.requiresEmailVerification {
                message = "E-mail potwierdzony!"
                isError = false
                onVerified()
            } else {
                message = "E-mail nadal niepotwierdzony. Sprawdź skrzynkę."
                isError = true
            }
        } catch {
            message = error.localizedDescription
            isError = true
        }
    }
}
