import Foundation

/// Persists URLs the user tried to analyze while offline, so we can retry later.
enum OfflineAnalysisQueue {
    private static let key = "fc_offline_analysis_queue_v1"

    private struct Item: Codable {
        let url: String
        let createdAt: TimeInterval
    }

    private static func load() -> [Item] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([Item].self, from: data) else {
            return []
        }
        return items
    }

    private static func persist(_ items: [Item]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func enqueue(_ url: String) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var items = load()
        items.removeAll { urlsRoughlyMatch($0.url, trimmed) }
        items.insert(Item(url: trimmed, createdAt: Date().timeIntervalSince1970), at: 0)
        if items.count > 20 { items = Array(items.prefix(20)) }
        persist(items)
    }

    static func peek() -> String? {
        load().first?.url
    }

    static func allURLs() -> [String] {
        load().map(\.url)
    }

    @discardableResult
    static func dequeue(_ url: String) -> Bool {
        var items = load()
        let before = items.count
        items.removeAll { urlsRoughlyMatch($0.url, url) }
        persist(items)
        return items.count < before
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    static var count: Int { load().count }
}
