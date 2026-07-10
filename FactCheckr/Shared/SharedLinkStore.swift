import Foundation

enum ShareDeepLink {
    static let scheme = "factcheckr"

    /// Otwiera główną appkę — URL jest w App Group, nie w query (unika limitów długości).
    static var openAppURL: URL {
        URL(string: "\(scheme)://analyze") ?? URL(fileURLWithPath: "/")
    }

    static func isAppOpenURL(_ url: URL) -> Bool {
        url.scheme?.lowercased() == scheme && url.host?.lowercased() == "analyze"
    }
}

enum SharedLinkStore {
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConfig.identifier)
    }

    static func savePendingURL(_ url: String) {
        defaults?.set(url, forKey: AppGroupConfig.pendingURLKey)
    }

    static func peekPendingURL() -> String? {
        defaults?.string(forKey: AppGroupConfig.pendingURLKey)
    }

    static func consumePendingURL() -> String? {
        guard let url = defaults?.string(forKey: AppGroupConfig.pendingURLKey) else { return nil }
        defaults?.removeObject(forKey: AppGroupConfig.pendingURLKey)
        return url
    }

    static func clearPendingURL() {
        defaults?.removeObject(forKey: AppGroupConfig.pendingURLKey)
    }
}
