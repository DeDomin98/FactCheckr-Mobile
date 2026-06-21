import SwiftUI

struct AccountView: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var authViewModel: AuthViewModel
    var profile: UserProfile?
    var onLogin: () -> Void
    var onRegister: () -> Void
    var onVerifyEmail: () -> Void

    private var planLabel: String {
        guard let profile else { return "FREE" }
        return profile.isTester ? "TESTER" : profile.plan.uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if authManager.isLoggedIn {
                    loggedInContent
                } else {
                    loggedOutContent
                }
                legalSection
                aboutSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var loggedInContent: some View {
        if authManager.requiresEmailVerification {
            FCEmailBanner(onVerify: onVerifyEmail)
        }

        if let user = authManager.user {
            FCWelcomeCard(
                name: user.displayName ?? user.email ?? "Użytkowniku",
                planLabel: planLabel,
                avatarLetter: String((user.email ?? "U").prefix(1))
            )

            FCCard {
                VStack(alignment: .leading, spacing: 14) {
                    row(icon: "envelope.fill", title: "E-mail", value: user.email ?? "—")
                    row(icon: "checkmark.seal.fill", title: "Weryfikacja", value: user.isEmailVerified ? "Potwierdzony" : "Oczekuje")
                    row(icon: "chart.bar.fill", title: "Analizy łącznie", value: "\(profile?.totalAnalyses ?? 0)")
                    row(icon: "number", title: "Wersja", value: AppMetadata.fullVersion)
                }
            }

            FCSecondaryButton(title: "Wyloguj się", icon: "rectangle.portrait.and.arrow.right") {
                try? authManager.signOut()
            }
        }
    }

    @ViewBuilder
    private var loggedOutContent: some View {
        VStack(spacing: 16) {
            FCLogo(size: 64)
            Text("Dołącz do \(AppMetadata.displayName)")
                .font(FCTheme.heading(22))
                .foregroundStyle(FCTheme.textPrimary)
            Text("Early access — 5 darmowych analiz po rejestracji. Bez karty kredytowej.")
                .font(.subheadline)
                .foregroundStyle(FCTheme.textSecondary)
                .multilineTextAlignment(.center)

            FCPrimaryButton(title: "Zaloguj się", icon: "arrow.right") { onLogin() }
            FCSecondaryButton(title: "Utwórz konto", icon: "sparkles") { onRegister() }
        }
        .padding(.vertical, 20)
    }

    private var legalSection: some View {
        FCCard {
            VStack(alignment: .leading, spacing: 10) {
                FCSectionTitle(icon: "hand.raised.fill", title: "Prywatność")
                Link("Polityka prywatności", destination: URL(string: APIConfig.privacyURL)!)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FCTheme.accentLight)
                Text("Wysyłamy tylko URL do analizy i dane konta (e-mail). Nie śledzimy przeglądania.")
                    .font(.caption)
                    .foregroundStyle(FCTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var aboutSection: some View {
        FCCard {
            VStack(alignment: .leading, spacing: 10) {
                FCSectionTitle(icon: "info.circle.fill", title: "O aplikacji")
                Text("\(AppMetadata.displayName) — ochrona przed dezinformacją. Analizuj TikTok, YouTube i artykuły dzięki silnikowi AI.")
                    .font(.caption)
                    .foregroundStyle(FCTheme.textSecondary)
                Link("factcheckrai.com", destination: URL(string: APIConfig.appURL)!)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FCTheme.accentLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func row(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(FCTheme.accentLight)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(FCTheme.textMuted)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FCTheme.textPrimary)
            }
            Spacer()
        }
    }
}
