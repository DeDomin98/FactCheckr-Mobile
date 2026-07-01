import Foundation

/// One-time contextual tips shown on specific screens after onboarding.
enum ContextualTipStore {
    private static let prefix = "fc_tip_dismissed_"
    private static let shareEligibleKey = "fc_tip_share_eligible"

    enum Tip: String {
        case homeCheck
        case historyBrowse
        case shareBackground
        case shareFavorites
    }

    private static var appGroup: UserDefaults? {
        UserDefaults(suiteName: AppGroupConfig.identifier)
    }

    static func isVisible(_ tip: Tip) -> Bool {
        !UserDefaults.standard.bool(forKey: prefix + tip.rawValue)
    }

    static func dismiss(_ tip: Tip) {
        UserDefaults.standard.set(true, forKey: prefix + tip.rawValue)
    }

    /// Shown until the user has successfully used the share extension at least once.
    static var shouldShowShareFavoritesTip: Bool {
        guard isVisible(.shareFavorites) else { return false }
        return appGroup?.bool(forKey: shareEligibleKey) != true
    }

    static var shouldShowShareTip: Bool {
        appGroup?.bool(forKey: shareEligibleKey) == true && isVisible(.shareBackground)
    }

    static func markFirstAnalysisCompleted() {
        dismiss(.homeCheck)
    }
}
