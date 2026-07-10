import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices

func configureFirebaseIfPossible() {
    guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
        print("[Firebase] GoogleService-Info.plist brak - auth wyłączony, UI działa.")
        return
    }
    guard FirebaseApp.app() == nil else { return }
    FirebaseApp.configure()
    if let clientID = FirebaseApp.app()?.options.clientID {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }
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
    /// Becomes `true` once Firebase Auth has reported its initial persisted session state.
    @Published private(set) var isAuthStateReady = false
    @Published var errorMessage: String?

    var isLoggedIn: Bool { user != nil }
    var requiresEmailVerification: Bool {
        guard let user else { return false }
        return needsEmailVerification(user)
    }

    private var authListener: AuthStateDidChangeListenerHandle?

    private init() {
        configureFirebaseIfPossible()
        isConfigured = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        if isConfigured {
            authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                Task { @MainActor in
                    self?.user = user
                    self?.isAuthStateReady = true
                    self?.onAuthChanged(user)
                }
            }
            user = Auth.auth().currentUser
            isAuthStateReady = true
            AnalysisHistoryStore.shared.activeUID = user?.uid
        } else {
            isAuthStateReady = true
        }
    }

    /// Mirrors the web's `onAuthStateChanged`: scope local data to the account,
    /// make sure the Firestore user document exists, and keep a fresh ID token in
    /// the App Group so the share extension can analyze in the background.
    private func onAuthChanged(_ user: User?) {
        AnalysisHistoryStore.shared.activeUID = user?.uid
        guard let user else {
            AppGroupTokenStore.clear()
            return
        }
        Task {
            await UserProfileService.shared.ensureUserProfile(
                uid: user.uid,
                email: user.email,
                displayName: user.displayName,
                photoURL: user.photoURL?.absoluteString
            )
            await self.refreshSharedToken()
        }
    }

    /// Stores a fresh Firebase ID token in the shared App Group container so the
    /// share extension can run authenticated analyses without opening the app.
    func refreshSharedToken() async {
        guard isConfigured, let user = Auth.auth().currentUser else {
            AppGroupTokenStore.clear()
            return
        }
        self.user = user
        do {
            let token = try await user.getIDToken(forcingRefresh: false)
            AppGroupTokenStore.save(token: token, uid: user.uid)
        } catch {
            // Retry once with a forced refresh before giving up.
            do {
                let token = try await user.getIDToken(forcingRefresh: true)
                AppGroupTokenStore.save(token: token, uid: user.uid)
            } catch {
                // Keep any previously stored token; it may still be valid.
            }
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
        PostLoginTutorialStore.schedule(for: result.user.uid)
        let token = try await result.user.getIDToken()
        try await APIClient.shared.sendVerificationEmail(idToken: token)
    }

    // MARK: - Sign in with Apple

    private var appleCoordinator: AppleSignInCoordinator?

    func signInWithApple() async throws {
        guard isConfigured else { throw AuthError.notConfigured }
        errorMessage = nil

        let rawNonce = NonceFactory.random()
        let coordinator = AppleSignInCoordinator()
        appleCoordinator = coordinator
        defer { appleCoordinator = nil }

        let credential = try await coordinator.signIn(hashedNonce: NonceFactory.sha256(rawNonce))

        guard let identityToken = credential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            throw SocialAuthError.appleTokenMissing
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: credential.fullName
        )

        let result = try await Auth.auth().signIn(with: firebaseCredential)

        if let fullName = credential.fullName,
           (result.user.displayName ?? "").isEmpty {
            let formatter = PersonNameComponentsFormatter()
            let name = formatter.string(from: fullName)
            if !name.isEmpty {
                let change = result.user.createProfileChangeRequest()
                change.displayName = name
                try? await change.commitChanges()
            }
        }
        user = result.user
    }

    // MARK: - Google Sign In

    @MainActor
    func signInWithGoogle() async throws {
        guard isConfigured else { throw AuthError.notConfigured }
        errorMessage = nil

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw SocialAuthError.missingClientID
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let presenter = UIApplication.shared.topViewController else {
            throw SocialAuthError.noPresenter
        }

        let gidResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        guard let idToken = gidResult.user.idToken?.tokenString else {
            throw SocialAuthError.googleTokenMissing
        }
        let accessToken = gidResult.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        let result = try await Auth.auth().signIn(with: credential)
        user = result.user
    }

    func handleURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    func signOut() throws {
        guard isConfigured else { return }
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
        user = nil
    }

    func getIDToken(forceRefresh: Bool = false) async throws -> String? {
        guard isConfigured, let user = Auth.auth().currentUser else { return nil }
        self.user = user
        return try await user.getIDToken(forcingRefresh: forceRefresh)
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

    enum DeleteAccountError: LocalizedError {
        case notConfigured
        case reauthenticationRequired
        case remoteDataDeletionFailed

        var errorDescription: String? {
            switch self {
            case .notConfigured: return Loc.t(.deleteAccountNotConfigured)
            case .reauthenticationRequired: return Loc.t(.deleteAccountReauth)
            case .remoteDataDeletionFailed: return Loc.t(.deleteAccountRemoteFailed)
            }
        }
    }

    /// Permanently deletes the Firebase account and user data. Pass `password` for email/password accounts.
    func deleteAccount(password: String? = nil) async throws {
        guard isConfigured, let user = Auth.auth().currentUser else {
            throw DeleteAccountError.notConfigured
        }
        let uid = user.uid

        if let email = user.email,
           user.providerData.contains(where: { $0.providerID == "password" }),
           let password, !password.isEmpty {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await user.reauthenticate(with: credential)
        }

        do {
            try await UserProfileService.shared.deleteAllUserData(uid: uid)
        } catch {
            throw DeleteAccountError.remoteDataDeletionFailed
        }

        LocalUserDataCleaner.clearAll(for: uid)

        do {
            try await user.delete()
        } catch let error as NSError {
            if error.domain == AuthErrorDomain,
               AuthErrorCode(rawValue: error.code) == .requiresRecentLogin {
                throw DeleteAccountError.reauthenticationRequired
            }
            throw error
        }

        GIDSignIn.sharedInstance.signOut()
        self.user = nil
        AnalysisHistoryStore.shared.activeUID = nil
        FavoritesStore.shared.activeUID = nil
    }

    var usesEmailPasswordProvider: Bool {
        user?.providerData.contains(where: { $0.providerID == "password" }) == true
    }

    enum AuthError: LocalizedError {
        case notConfigured

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return Loc.t(.firebaseNotConfiguredShort)
            }
        }
    }
}
