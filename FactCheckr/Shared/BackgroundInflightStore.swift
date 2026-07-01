import Foundation

/// Tracks URLs currently being analyzed in a background URLSession (started from Share).
enum BackgroundInflightStore {
    private static let key = "fc_bg_inflight_v1"
    private static let maxAge: TimeInterval = 15 * 60

    private struct Item: Codable {
        let url: String
        let uid: String
        let startedAt: TimeInterval
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConfig.identifier)
    }

    private static func load() -> [Item] {
        guard let data = defaults?.data(forKey: key),
              let items = try? JSONDecoder().decode([Item].self, from: data) else {
            return []
        }
        let cutoff = Date().timeIntervalSince1970 - maxAge
        return items.filter { $0.startedAt >= cutoff }
    }

    private static func persist(_ items: [Item]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults?.set(data, forKey: key)
    }

    static func markStarted(url: String, uid: String) {
        var items = load()
        items.removeAll { $0.uid == uid && urlsRoughlyMatch($0.url, url) }
        items.append(Item(url: url, uid: uid, startedAt: Date().timeIntervalSince1970))
        if items.count > 30 { items = Array(items.suffix(30)) }
        persist(items)
    }

    static func clear(url: String, uid: String) {
        var items = load()
        items.removeAll { $0.uid == uid && urlsRoughlyMatch($0.url, url) }
        persist(items)
    }

    static func isInflight(url: String, uid: String?) -> Bool {
        guard let uid else { return false }
        return load().contains { $0.uid == uid && urlsRoughlyMatch($0.url, url) }
    }

    static func removeAll(for uid: String) {
        persist(load().filter { $0.uid != uid })
    }
}
