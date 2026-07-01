import Foundation

/// Queue of analysis results produced in the background (by the share extension or
/// a relaunched app process) that still need to be merged into a given account's
/// local history. Persisted in the shared App Group container.
enum BackgroundAnalysisStore {
    private static let key = "fc_pending_bg_results_v1"

    private struct PendingItem: Codable {
        let uid: String
        let entry: AnalysisHistoryEntry
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConfig.identifier)
    }

    private static func loadAll() -> [PendingItem] {
        guard let data = defaults?.data(forKey: key),
              let items = try? JSONDecoder().decode([PendingItem].self, from: data) else {
            return []
        }
        return items
    }

    private static func persist(_ items: [PendingItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults?.set(data, forKey: key)
    }

    static func add(entry: AnalysisHistoryEntry, uid: String) {
        var items = loadAll()
        items.append(PendingItem(uid: uid, entry: entry))
        if items.count > 100 { items = Array(items.suffix(100)) }
        persist(items)
    }

    /// Returns and removes all pending entries for the given account.
    static func consume(uid: String) -> [AnalysisHistoryEntry] {
        let items = loadAll()
        guard !items.isEmpty else { return [] }
        let mine = items.filter { $0.uid == uid }.map { $0.entry }
        let rest = items.filter { $0.uid != uid }
        persist(rest)
        return mine
    }

    static func peek(entryId: String, uid: String) -> AnalysisHistoryEntry? {
        loadAll().first { $0.uid == uid && $0.entry.id == entryId }?.entry
    }

    static func peek(sourceUrl: String, uid: String) -> AnalysisHistoryEntry? {
        loadAll().first { $0.uid == uid && urlsRoughlyMatch($0.entry.sourceUrl, sourceUrl) }?.entry
    }

    static var hasPending: Bool {
        !loadAll().isEmpty
    }

    static func removeAll(for uid: String) {
        let rest = loadAll().filter { $0.uid != uid }
        persist(rest)
    }
}
