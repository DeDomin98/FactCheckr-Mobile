import Foundation

/// Stores a short-lived Firebase ID token in the shared App Group container so the
/// share extension can run authenticated analyses in the background without opening
/// the host app. Firebase ID tokens are valid for ~1 hour; we treat anything older
/// than 55 minutes as stale.
enum AppGroupTokenStore {
    private static let tokenKey = "fc_id_token"
    private static let uidKey = "fc_id_token_uid"
    private static let savedAtKey = "fc_id_token_saved_at"
    private static let maxAge: TimeInterval = 55 * 60

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConfig.identifier)
    }

    static func save(token: String, uid: String) {
        defaults?.set(token, forKey: tokenKey)
        defaults?.set(uid, forKey: uidKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: savedAtKey)
    }

    static func clear() {
        defaults?.removeObject(forKey: tokenKey)
        defaults?.removeObject(forKey: uidKey)
        defaults?.removeObject(forKey: savedAtKey)
    }

    static var uid: String? {
        defaults?.string(forKey: uidKey)
    }

    /// Returns the stored token if it is present and recent enough to be accepted
    /// by the backend, otherwise `nil`.
    static func validToken() -> (token: String, uid: String)? {
        guard let defaults,
              let token = defaults.string(forKey: tokenKey),
              let uid = defaults.string(forKey: uidKey),
              !token.isEmpty else { return nil }
        let savedAt = defaults.double(forKey: savedAtKey)
        guard savedAt > 0, Date().timeIntervalSince1970 - savedAt < maxAge else { return nil }
        return (token, uid)
    }
}
