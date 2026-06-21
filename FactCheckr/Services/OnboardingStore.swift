import Foundation

enum OnboardingStore {
    private static let key = "fc_has_seen_onboarding"

    static var hasSeen: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func markSeen() {
        UserDefaults.standard.set(true, forKey: key)
    }
}
