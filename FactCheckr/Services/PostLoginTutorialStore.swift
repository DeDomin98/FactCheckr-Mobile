import Foundation

/// One-time interactive tutorial shown after a new account is created.
enum PostLoginTutorialStore {
    private static let pendingUIDKey = "fc_post_login_tutorial_pending_uid"

    private static func seenKey(uid: String) -> String {
        "fc_post_login_tutorial_seen_\(uid)"
    }

    static func schedule(for uid: String) {
        UserDefaults.standard.set(uid, forKey: pendingUIDKey)
    }

    static func shouldShow(for uid: String) -> Bool {
        guard UserDefaults.standard.string(forKey: pendingUIDKey) == uid else { return false }
        return !UserDefaults.standard.bool(forKey: seenKey(uid: uid))
    }

    static func markSeen(for uid: String) {
        UserDefaults.standard.set(true, forKey: seenKey(uid: uid))
        if UserDefaults.standard.string(forKey: pendingUIDKey) == uid {
            UserDefaults.standard.removeObject(forKey: pendingUIDKey)
        }
    }

    static func clear(for uid: String) {
        UserDefaults.standard.removeObject(forKey: seenKey(uid: uid))
        if UserDefaults.standard.string(forKey: pendingUIDKey) == uid {
            UserDefaults.standard.removeObject(forKey: pendingUIDKey)
        }
    }
}
