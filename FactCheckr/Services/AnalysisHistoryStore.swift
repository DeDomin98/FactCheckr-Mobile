import Foundation

/// Local history cache, scoped per account so signing in/out never shows
/// another user's analyses. `activeUID` selects the bucket; `nil` == guest.
final class AnalysisHistoryStore {
    static let shared = AnalysisHistoryStore()
    private let keyPrefix = "fc_analysis_history_v2_"
    private let deletedIdsPrefix = "fc_analysis_deleted_ids_v1_"
    private let deletedUrlsPrefix = "fc_analysis_deleted_urls_v1_"
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

    private func deletedIdsKey(for uid: String?) -> String {
        deletedIdsPrefix + (uid?.isEmpty == false ? uid! : "guest")
    }

    private func deletedUrlsKey(for uid: String?) -> String {
        deletedUrlsPrefix + (uid?.isEmpty == false ? uid! : "guest")
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
        let deleted = deletedIds(uid: uid)
        return items
            .filter { !deleted.contains($0.id) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ entry: AnalysisHistoryEntry) {
        save(entry, uid: activeUID)
    }

    func save(_ entry: AnalysisHistoryEntry, uid: String?) {
        // A fresh analysis of the same URL should replace older local copies
        // and clear any prior "deleted" tombstone for that URL.
        unmarkDeleted(url: entry.sourceUrl, uid: uid)
        unmarkDeleted(id: entry.id, uid: uid)

        var items = load(uid: uid)
        items.removeAll {
            $0.id == entry.id ||
            ($0.sourceUrl == entry.sourceUrl && abs($0.createdAt.timeIntervalSince(entry.createdAt)) < 60)
        }
        // Keep only the newest local entry per URL when saving a re-check.
        items.removeAll { $0.sourceUrl == entry.sourceUrl && $0.createdAt <= entry.createdAt }
        items.insert(entry, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        persist(items, uid: uid)
    }

    func delete(id: String) {
        delete(id: id, uid: activeUID)
    }

    func delete(id: String, uid: String?) {
        let items = load(uid: uid)
        let url = items.first { $0.id == id }?.sourceUrl
        persist(items.filter { $0.id != id }, uid: uid)
        markDeleted(id: id, uid: uid)
        if let url {
            markDeleted(url: url, uid: uid)
        }
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: currentKey)
        UserDefaults.standard.removeObject(forKey: deletedIdsKey(for: activeUID))
        UserDefaults.standard.removeObject(forKey: deletedUrlsKey(for: activeUID))
    }

    func clearAll(uid: String?) {
        UserDefaults.standard.removeObject(forKey: storageKey(for: uid))
        UserDefaults.standard.removeObject(forKey: deletedIdsKey(for: uid))
        UserDefaults.standard.removeObject(forKey: deletedUrlsKey(for: uid))
    }

    func deletedIds(uid: String? = nil) -> Set<String> {
        let key = deletedIdsKey(for: uid ?? activeUID)
        guard let arr = UserDefaults.standard.array(forKey: key) as? [String] else { return [] }
        return Set(arr)
    }

    func deletedUrls(uid: String? = nil) -> Set<String> {
        let key = deletedUrlsKey(for: uid ?? activeUID)
        guard let arr = UserDefaults.standard.array(forKey: key) as? [String] else { return [] }
        return Set(arr)
    }

    func isDeleted(id: String, url: String, uid: String? = nil) -> Bool {
        deletedIds(uid: uid).contains(id) || deletedUrls(uid: uid).contains(url)
    }

    private func markDeleted(id: String, uid: String?) {
        var ids = deletedIds(uid: uid)
        ids.insert(id)
        UserDefaults.standard.set(Array(ids), forKey: deletedIdsKey(for: uid))
    }

    private func markDeleted(url: String, uid: String?) {
        var urls = deletedUrls(uid: uid)
        urls.insert(url)
        UserDefaults.standard.set(Array(urls), forKey: deletedUrlsKey(for: uid))
    }

    private func unmarkDeleted(id: String, uid: String?) {
        var ids = deletedIds(uid: uid)
        guard ids.remove(id) != nil else { return }
        UserDefaults.standard.set(Array(ids), forKey: deletedIdsKey(for: uid))
    }

    private func unmarkDeleted(url: String, uid: String?) {
        var urls = deletedUrls(uid: uid)
        guard urls.remove(url) != nil else { return }
        UserDefaults.standard.set(Array(urls), forKey: deletedUrlsKey(for: uid))
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
