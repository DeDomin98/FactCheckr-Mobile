import Foundation

/// Local history cache, scoped per account so signing in/out never shows
/// another user's analyses. `activeUID` selects the bucket; `nil` == guest.
final class AnalysisHistoryStore {
    static let shared = AnalysisHistoryStore()
    private let keyPrefix = "fc_analysis_history_v2_"
    private let legacyKey = "fc_analysis_history_v1"
    private let maxItems = 50

    /// Current account scope. Set on auth changes. `nil` means guest.
    var activeUID: String? {
        didSet {
            guard oldValue != activeUID else { return }
            migrateLegacyIfNeeded()
        }
    }

    private init() {
        migrateLegacyIfNeeded()
    }

    private func storageKey(for uid: String?) -> String {
        keyPrefix + (uid?.isEmpty == false ? uid! : "guest")
    }

    private var currentKey: String { storageKey(for: activeUID) }

    func load() -> [AnalysisHistoryEntry] {
        load(uid: activeUID)
    }

    func load(uid: String?) -> [AnalysisHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey(for: uid)),
              let items = try? JSONDecoder().decode([AnalysisHistoryEntry].self, from: data) else {
            return []
        }
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ entry: AnalysisHistoryEntry) {
        save(entry, uid: activeUID)
    }

    func save(_ entry: AnalysisHistoryEntry, uid: String?) {
        var items = load(uid: uid)
        items.removeAll { $0.sourceUrl == entry.sourceUrl && abs($0.createdAt.timeIntervalSince(entry.createdAt)) < 60 }
        items.insert(entry, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        persist(items, uid: uid)
    }

    func delete(id: String) {
        persist(load().filter { $0.id != id }, uid: activeUID)
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: currentKey)
    }

    func clearAll(uid: String?) {
        UserDefaults.standard.removeObject(forKey: storageKey(for: uid))
    }

    private func persist(_ items: [AnalysisHistoryEntry], uid: String?) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey(for: uid))
    }

    /// One-time migration of the old global history into the current scope.
    private func migrateLegacyIfNeeded() {
        guard let legacy = UserDefaults.standard.data(forKey: legacyKey),
              let items = try? JSONDecoder().decode([AnalysisHistoryEntry].self, from: legacy),
              !items.isEmpty else { return }
        var existing = load()
        let urls = Set(existing.map { $0.sourceUrl })
        existing.append(contentsOf: items.filter { !urls.contains($0.sourceUrl) })
        persist(Array(existing.sorted { $0.createdAt > $1.createdAt }.prefix(maxItems)), uid: activeUID)
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }
}
