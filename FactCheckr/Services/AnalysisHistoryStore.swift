import Foundation

final class AnalysisHistoryStore {
    static let shared = AnalysisHistoryStore()
    private let key = "fc_analysis_history_v1"
    private let maxItems = 50

    private init() {}

    func load() -> [AnalysisHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([AnalysisHistoryEntry].self, from: data) else {
            return []
        }
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ entry: AnalysisHistoryEntry) {
        var items = load()
        items.removeAll { $0.sourceUrl == entry.sourceUrl && abs($0.createdAt.timeIntervalSince(entry.createdAt)) < 60 }
        items.insert(entry, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        persist(items)
    }

    func delete(id: String) {
        persist(load().filter { $0.id != id })
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func persist(_ items: [AnalysisHistoryEntry]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
