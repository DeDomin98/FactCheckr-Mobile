import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    func signIn(authManager: AuthManager) async -> Bool {
        guard validateEmailPassword() else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authManager.signIn(email: email.trimmingCharacters(in: .whitespaces),
                                         password: password)
            return true
        } catch {
            errorMessage = mapFirebaseError(error)
            return false
        }
    }

    func signUp(authManager: AuthManager) async -> Bool {
        guard validateEmailPassword() else { return false }
        guard password == confirmPassword else {
            errorMessage = "Hasła nie są identyczne."
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "Hasło musi mieć co najmniej 6 znaków."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authManager.signUp(email: email.trimmingCharacters(in: .whitespaces),
                                         password: password)
            successMessage = "Konto utworzone. Sprawdź e-mail weryfikacyjny."
            return true
        } catch let apiError as APIError {
            errorMessage = APIErrorMapper.message(for: apiError)
            return false
        } catch {
            errorMessage = mapFirebaseError(error)
            return false
        }
    }

    private func validateEmailPassword() -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("@"), !password.isEmpty else {
            errorMessage = "Podaj poprawny e-mail i hasło."
            return false
        }
        return true
    }

    private func mapFirebaseError(_ error: Error) -> String {
        let ns = error as NSError
        switch ns.code {
        case 17008: return "Nieprawidłowy adres e-mail."
        case 17009, 17011: return "Nieprawidłowy e-mail lub hasło."
        case 17007: return "Ten adres e-mail jest już zajęty."
        case 17026: return "Hasło jest zbyt słabe."
        default: return error.localizedDescription
        }
    }
}
