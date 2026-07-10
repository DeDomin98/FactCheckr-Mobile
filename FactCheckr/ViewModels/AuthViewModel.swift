import Foundation
import AuthenticationServices
import GoogleSignIn

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var socialLoading: SocialProvider?
    @Published var errorMessage: String?
    @Published var successMessage: String?

    enum SocialProvider { case apple, google }

    func signInWithApple(authManager: AuthManager) async -> Bool {
        errorMessage = nil
        socialLoading = .apple
        defer { socialLoading = nil }
        do {
            try await authManager.signInWithApple()
            return true
        } catch {
            if !isCancellation(error) {
                errorMessage = mapFirebaseError(error)
            }
            return false
        }
    }

    func signInWithGoogle(authManager: AuthManager) async -> Bool {
        errorMessage = nil
        socialLoading = .google
        defer { socialLoading = nil }
        do {
            try await authManager.signInWithGoogle()
            return true
        } catch {
            if !isCancellation(error) {
                errorMessage = mapFirebaseError(error)
            }
            return false
        }
    }

    private func isCancellation(_ error: Error) -> Bool {
        if let asError = error as? ASAuthorizationError, asError.code == .canceled {
            return true
        }
        if let gidError = error as? GIDSignInError, gidError.code == .canceled {
            return true
        }
        if case SocialAuthError.cancelled = error { return true }
        return false
    }

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
            errorMessage = Loc.t(.authPasswordsMismatch)
            return false
        }
        guard password.count >= 6 else {
            errorMessage = Loc.t(.authPasswordTooShort)
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authManager.signUp(email: email.trimmingCharacters(in: .whitespaces),
                                         password: password)
            successMessage = Loc.t(.authAccountCreated)
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
            errorMessage = Loc.t(.authInvalidEmailPassword)
            return false
        }
        return true
    }

    private func mapFirebaseError(_ error: Error) -> String {
        if let social = error as? SocialAuthError {
            return social.localizedDescription
        }
        let ns = error as NSError
        switch ns.code {
        case 17008: return Loc.t(.authInvalidEmail)
        case 17009, 17011: return Loc.t(.authWrongCredentials)
        case 17007: return Loc.t(.authEmailTaken)
        case 17026: return Loc.t(.authWeakPassword)
        default: return error.localizedDescription
        }
    }
}
