import Foundation

enum ThreatFilter: String, CaseIterable {
    case all
    case none
    case medium
    case high

    var label: String {
        localizedLabel
    }

    var localizedLabel: String {
        switch self {
        case .all: return Loc.t(.filterAll)
        case .none: return Loc.t(.threatCredible)
        case .medium: return Loc.t(.threatSuspicious)
        case .high: return Loc.t(.threatHighRisk)
        }
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var history: [AnalysisHistoryEntry] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var threatFilter: ThreatFilter = .all
    @Published var showFavoritesOnly = false
    @Published var favoriteIds: Set<String> = []
    @Published var expandedId: String?
    @Published var syncError: String?

    var filteredHistory: [AnalysisHistoryEntry] {
        var list = showFavoritesOnly ? FavoritesStore.shared.load() : history
        if threatFilter != .all {
            list = list.filter { $0.threatLevel.rawValue == threatFilter.rawValue }
        }
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.title.lowercased().contains(q) ||
                $0.sourceUrl.lowercased().contains(q) ||
                ($0.verdict?.lowercased().contains(q) ?? false)
            }
        }
        return list
    }

    var hasActiveFilters: Bool {
        threatFilter != .all || showFavoritesOnly ||
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func isFavorite(_ id: String) -> Bool {
        favoriteIds.contains(id)
    }

    func toggleFavorite(_ entry: AnalysisHistoryEntry) {
        let nowFavorite = FavoritesStore.shared.toggle(entry)
        if nowFavorite {
            favoriteIds.insert(entry.id)
            Haptics.impact(.light)
        } else {
            favoriteIds.remove(entry.id)
            Haptics.selection()
        }
    }

    var quotaRemaining: Int? {
        guard let profile else { return nil }
        if profile.isTester {
            let month = String(Date().formatted(.iso8601.year().month()))
            let used = profile.monthlyAnalysisMonth == month ? (profile.monthlyAnalysesUsed ?? 0) : 0
            return max(0, (profile.monthlyAnalysisLimit ?? 50) - used)
        }
        return max(0, profile.freeTokens)
    }

    var quotaLimit: Int {
        guard let profile else { return 5 }
        return profile.isTester ? (profile.monthlyAnalysisLimit ?? 50) : 5
    }

    var quotaPercent: Double {
        guard let remaining = quotaRemaining, quotaLimit > 0 else { return 0 }
        return min(Double(remaining) / Double(quotaLimit), 1)
    }

    func refresh(authManager: AuthManager) async {
        isLoading = true
        syncError = nil
        defer { isLoading = false }

        if let user = authManager.user {
            let uid = user.uid
            AnalysisHistoryStore.shared.activeUID = uid
            FavoritesStore.shared.activeUID = uid
            for entry in BackgroundAnalysisStore.consume(uid: uid) {
                AnalysisHistoryStore.shared.save(entry, uid: uid)
            }

            var items = AnalysisHistoryStore.shared.load()

            let fetchedProfile = await UserProfileService.shared.ensureUserProfile(
                uid: uid,
                email: user.email,
                displayName: user.displayName,
                photoURL: user.photoURL?.absoluteString
            )
            let remote = await UserProfileService.shared.fetchRemoteHistory(uid: uid)
            profile = fetchedProfile

            if !NetworkMonitor.shared.isOnline {
                syncError = Loc.t(.networkOfflineBanner)
            }

            history = Self.mergeHistory(local: items, remote: remote, uid: uid)
        } else {
            AnalysisHistoryStore.shared.activeUID = nil
            FavoritesStore.shared.activeUID = nil
            profile = nil
            history = AnalysisHistoryStore.shared.load()
        }

        favoriteIds = FavoritesStore.shared.ids()
    }

    /// Prefer newer entries per URL; respect local delete tombstones so remote
    /// copies don't resurrect removed checks. A newer local re-check wins over remote.
    static func mergeHistory(
        local: [AnalysisHistoryEntry],
        remote: [AnalysisHistoryEntry],
        uid: String
    ) -> [AnalysisHistoryEntry] {
        let deletedIds = AnalysisHistoryStore.shared.deletedIds(uid: uid)
        let deletedUrls = AnalysisHistoryStore.shared.deletedUrls(uid: uid)
        let localIds = Set(local.map(\.id))

        var bestByURL: [String: AnalysisHistoryEntry] = [:]

        func consider(_ entry: AnalysisHistoryEntry, isLocal: Bool) {
            if deletedIds.contains(entry.id) { return }
            // Tombstones block stale remote copies. Local re-checks clear the
            // URL tombstone on save, so they are allowed through.
            if !isLocal, deletedUrls.contains(entry.sourceUrl), !localIds.contains(entry.id) {
                return
            }
            if let existing = bestByURL[entry.sourceUrl] {
                if entry.createdAt > existing.createdAt {
                    bestByURL[entry.sourceUrl] = entry
                }
            } else {
                bestByURL[entry.sourceUrl] = entry
            }
        }

        for entry in local { consider(entry, isLocal: true) }
        for entry in remote { consider(entry, isLocal: false) }

        return bestByURL.values.sorted { $0.createdAt > $1.createdAt }
    }

    func deleteEntry(_ id: String) {
        let entry = history.first { $0.id == id }
        AnalysisHistoryStore.shared.delete(id: id)
        history.removeAll { $0.id == id }
        if expandedId == id { expandedId = nil }
        FavoritesStore.shared.remove(id: id)
        favoriteIds.remove(id)

        if let entry, let uid = AnalysisHistoryStore.shared.activeUID {
            Task {
                try? await UserProfileService.shared.deleteAnalysis(
                    uid: uid,
                    entryId: entry.id,
                    sourceUrl: entry.sourceUrl
                )
            }
        }
    }

    func clearLocalHistory() {
        AnalysisHistoryStore.shared.clearAll()
        history = []
        expandedId = nil
    }

    func toggleExpanded(_ id: String) {
        expandedId = expandedId == id ? nil : id
    }
}
