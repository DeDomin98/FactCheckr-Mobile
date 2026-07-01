import Foundation

enum LocalUserDataCleaner {
    static func clearAll(for uid: String) {
        AnalysisHistoryStore.shared.clearAll(uid: uid)
        FavoritesStore.shared.clearAll(uid: uid)
        BackgroundAnalysisStore.removeAll(for: uid)
        BackgroundInflightStore.removeAll(for: uid)
        PostLoginTutorialStore.clear(for: uid)
        AppGroupTokenStore.clear()
        SharedLinkStore.clearPendingURL()
    }
}
