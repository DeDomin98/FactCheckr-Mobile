import Foundation

/// Per-account store of favorited analyses. Keeps the full entry so a favorite
/// stays available even after it scrolls out of the recent history window.
final class FavoritesStore {
    static let shared = FavoritesStore()
    private let keyPrefix = "fc_favorites_v1_"

    var activeUID: String?

    private init() {}

    private func key(for uid: String?) -> String {
        keyPrefix + (uid?.isEmpty == false ? uid! : "guest")
    }

    func load() -> [AnalysisHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: key(for: activeUID)),
              let items = try? JSONDecoder().decode([AnalysisHistoryEntry].self, from: data) else {
            return []
        }
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    func ids() -> Set<String> {
        Set(load().map { $0.id })
    }

    func isFavorite(_ id: String) -> Bool {
        load().contains { $0.id == id }
    }

    /// Toggles favorite state and returns the new state (`true` == now favorited).
    @discardableResult
    func toggle(_ entry: AnalysisHistoryEntry) -> Bool {
        var items = load()
        if let index = items.firstIndex(where: { $0.id == entry.id }) {
            items.remove(at: index)
            persist(items)
            return false
        }
        items.insert(entry, at: 0)
        persist(items)
        return true
    }

    func remove(id: String) {
        persist(load().filter { $0.id != id })
    }

    private func persist(_ items: [AnalysisHistoryEntry]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key(for: activeUID))
    }
}
