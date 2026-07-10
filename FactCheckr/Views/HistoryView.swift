import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var authManager: AuthManager
    var refreshToken: Int = 0
    var onSelect: (AnalysisHistoryEntry) -> Void

    private var entries: [AnalysisHistoryEntry] { viewModel.filteredHistory }
    @State private var showHistoryTip = ContextualTipStore.isVisible(.historyBrowse)

    var body: some View {
        VStack(spacing: 0) {
            if showHistoryTip && !entries.isEmpty {
                FCTipBanner(
                    icon: "magnifyingglass.circle.fill",
                    tint: FCTheme.accentLight,
                    title: Loc.t(.tipHistoryTitle),
                    message: Loc.t(.tipHistoryMessage)
                ) {
                    showHistoryTip = false
                    ContextualTipStore.dismiss(.historyBrowse)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }

            searchAndFilters

            Group {
                if viewModel.isLoading && viewModel.history.isEmpty {
                    loadingState
                } else if entries.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
        }
        .onAppear { Task { await viewModel.refresh(authManager: authManager) } }
        .onChange(of: refreshToken) { _ in
            Task { await viewModel.refresh(authManager: authManager) }
        }
    }

    private var searchAndFilters: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(FCTheme.textMuted)
                TextField(Loc.t(.historySearchPlaceholder), text: $viewModel.searchQuery)
                    .font(.subheadline)
                    .foregroundStyle(FCTheme.textPrimary)
                    .tint(FCTheme.accent)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(FCTheme.textMuted)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FCTheme.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                    .stroke(FCTheme.borderLight, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(
                        title: Loc.t(.filterFavorites),
                        icon: "star.fill",
                        selected: viewModel.showFavoritesOnly
                    ) {
                        Haptics.selection()
                        viewModel.showFavoritesOnly.toggle()
                    }

                    ForEach(ThreatFilter.allCases, id: \.self) { filter in
                        filterChip(
                            title: filter.localizedLabel,
                            icon: nil,
                            selected: viewModel.threatFilter == filter && !viewModel.showFavoritesOnly
                        ) {
                            Haptics.selection()
                            viewModel.showFavoritesOnly = false
                            viewModel.threatFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func filterChip(title: String, icon: String?, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon).font(.caption2)
                }
                Text(title).font(.caption.weight(.semibold))
            }
            .foregroundStyle(selected ? .white : FCTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(selected ? FCTheme.accent : FCTheme.bgCard)
            .overlay(
                Capsule().stroke(selected ? Color.clear : FCTheme.border, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(entries) { entry in
                    historyRow(entry)
                        .contentShape(Rectangle())
                        .onTapGesture { onSelect(entry) }
                        .contextMenu {
                            Button {
                                viewModel.toggleFavorite(entry)
                            } label: {
                                Label(
                                    viewModel.isFavorite(entry.id) ? Loc.t(.removeFromFavorites) : Loc.t(.addToFavorites),
                                    systemImage: viewModel.isFavorite(entry.id) ? "star.slash" : "star"
                                )
                            }
                            Button(role: .destructive) {
                                viewModel.deleteEntry(entry.id)
                            } label: {
                                Label(Loc.t(.deleteFromHistory), systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .refreshable { await viewModel.refresh(authManager: authManager) }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView().tint(FCTheme.accent)
            Text(Loc.t(.historyLoading))
                .font(.subheadline)
                .foregroundStyle(FCTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 80)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: viewModel.showFavoritesOnly ? "star" : "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(FCTheme.textMuted)
            Text(viewModel.hasActiveFilters ? Loc.t(.historyNoResults) : Loc.t(.historyEmptyTitle))
                .font(FCTheme.heading(18))
                .foregroundStyle(FCTheme.textPrimary)
            Text(emptySubtitle)
                .font(.subheadline)
                .foregroundStyle(FCTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .padding(.bottom, 80)
    }

    private var emptySubtitle: String {
        if viewModel.hasActiveFilters { return Loc.t(.historyNoResultsHint) }
        return authManager.isLoggedIn ? Loc.t(.historyEmptyLoggedIn) : Loc.t(.historyEmptyLoggedOut)
    }

    private func historyRow(_ entry: AnalysisHistoryEntry) -> some View {
        let endpoint = MediaPreviewHelper.endpoint(for: entry.sourceUrl)
        return HStack(spacing: 12) {
            VerdictBadge(category: VerdictCategory.from(analysis: entry.response.analysis), compact: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(MediaPreviewHelper.displayTitle(for: entry).fcDisplay)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FCTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Image(systemName: FCTheme.endpointIcon(endpoint))
                        .font(.caption2)
                        .foregroundStyle(FCTheme.endpointColor(endpoint))
                    Text(endpoint.localizedLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(FCTheme.endpointColor(endpoint))
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(FCTheme.textMuted)
                    Text(entry.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(FCTheme.textMuted)
                }
            }

            Spacer(minLength: 0)

            Button {
                viewModel.toggleFavorite(entry)
            } label: {
                Image(systemName: viewModel.isFavorite(entry.id) ? "star.fill" : "star")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(viewModel.isFavorite(entry.id) ? FCTheme.orange : FCTheme.textMuted)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .padding(.leading, 2)
        .background(FCTheme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }
}
