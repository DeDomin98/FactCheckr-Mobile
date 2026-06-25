import Foundation

enum ThreatFilter: String, CaseIterable {
    case all
    case none
    case medium
    case high

    var label: String {
        switch self {
        case .all: return "Wszystkie"
        case .none: return ThreatLevel.none.label
        case .medium: return ThreatLevel.medium.label
        case .high: return ThreatLevel.high.label
        }
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

    var quotaRemaining: Int {
        guard let profile else { return 0 }
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
        guard quotaLimit > 0 else { return 0 }
        return min(Double(quotaRemaining) / Double(quotaLimit), 1)
    }

    func refresh(authManager: AuthManager) async {
        isLoading = true
        syncError = nil
        defer { isLoading = false }

        if let user = authManager.user {
            let uid = user.uid
            // Scope local history to this account before anything else.
            AnalysisHistoryStore.shared.activeUID = uid
            FavoritesStore.shared.activeUID = uid
            // Pull in any results produced in the background by the share extension.
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

            if !remote.isEmpty {
                // Remote (account) history is the source of truth; keep only local
                // entries that are not represented remotely yet.
                let extras = items.filter { local in
                    !remote.contains { $0.sourceUrl == local.sourceUrl }
                }
                items = (remote + extras).sorted { $0.createdAt > $1.createdAt }
            }

            history = items
        } else {
            AnalysisHistoryStore.shared.activeUID = nil
            FavoritesStore.shared.activeUID = nil
            profile = nil
            history = AnalysisHistoryStore.shared.load()
        }

        favoriteIds = FavoritesStore.shared.ids()
    }

    func deleteEntry(_ id: String) {
        AnalysisHistoryStore.shared.delete(id: id)
        history.removeAll { $0.id == id }
        if expandedId == id { expandedId = nil }
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
