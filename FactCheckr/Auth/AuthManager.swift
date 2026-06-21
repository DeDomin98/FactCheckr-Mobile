import Foundation
import FirebaseAuth
import FirebaseCore

func configureFirebaseIfPossible() {
    guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
        print("[Firebase] GoogleService-Info.plist brak - auth wyłączony, UI działa.")
        return
    }
    FirebaseApp.configure()
}

func needsEmailVerification(_ user: User) -> Bool {
    let isPassword = user.providerData.contains { $0.providerID == "password" }
    return isPassword && !user.isEmailVerified
}

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var user: User?
    @Published private(set) var isConfigured: Bool
    @Published var errorMessage: String?

    var isLoggedIn: Bool { user != nil }
    var requiresEmailVerification: Bool {
        guard let user else { return false }
        return needsEmailVerification(user)
    }

    private var authListener: AuthStateDidChangeListenerHandle?

    private init() {
        isConfigured = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        if isConfigured {
            authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                Task { @MainActor in
                    self?.user = user
                }
            }
            user = Auth.auth().currentUser
        }
    }

    func signIn(email: String, password: String) async throws {
        guard isConfigured else {
            throw AuthError.notConfigured
        }
        errorMessage = nil
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        user = result.user
    }

    func signUp(email: String, password: String) async throws {
        guard isConfigured else {
            throw AuthError.notConfigured
        }
        errorMessage = nil
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        user = result.user
        let token = try await result.user.getIDToken()
        try await APIClient.shared.sendVerificationEmail(idToken: token)
    }

    func signOut() throws {
        guard isConfigured else { return }
        try Auth.auth().signOut()
        user = nil
    }

    func getIDToken() async throws -> String? {
        guard isConfigured, let user else { return nil }
        return try await user.getIDToken()
    }

    func reloadUser() async throws {
        guard isConfigured, let user else { return }
        try await user.reload()
        self.user = Auth.auth().currentUser
    }

    func resendVerificationEmail() async throws {
        guard isConfigured, let user else {
            throw AuthError.notConfigured
        }
        let token = try await user.getIDToken()
        try await APIClient.shared.sendVerificationEmail(idToken: token)
    }

    enum AuthError: LocalizedError {
        case notConfigured

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Firebase nie jest skonfigurowany. Dodaj GoogleService-Info.plist."
            }
        }
    }
}
