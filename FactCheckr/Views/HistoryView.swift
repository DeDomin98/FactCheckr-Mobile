import SwiftUI

struct HistoryView: View {
    var refreshToken: Int = 0
    @State private var entries: [AnalysisHistoryEntry] = []
    var onSelect: (AnalysisHistoryEntry) -> Void

    var body: some View {
        Group {
            if entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(entries) { entry in
                            Button {
                                onSelect(entry)
                            } label: {
                                historyRow(entry)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    AnalysisHistoryStore.shared.delete(id: entry.id)
                                    reload()
                                } label: {
                                    Label("Usuń", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear { reload() }
        .onChange(of: refreshToken) { _ in reload() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(FCTheme.textMuted)
            Text("Brak historii")
                .font(FCTheme.heading(18))
                .foregroundStyle(FCTheme.textPrimary)
            Text("Twoje sprawdzenia pojawią się tutaj.")
                .font(.subheadline)
                .foregroundStyle(FCTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 80)
    }

    private func historyRow(_ entry: AnalysisHistoryEntry) -> some View {
        HStack(spacing: 12) {
            VerdictBadge(category: VerdictCategory.from(analysis: entry.response.analysis), compact: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FCTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 8) {
                    Text(entry.type)
                        .font(.caption2)
                        .foregroundStyle(FCTheme.textMuted)
                    Text(entry.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(FCTheme.textMuted)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FCTheme.textMuted)
        }
        .padding(14)
        .background(FCTheme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    private func reload() {
        entries = AnalysisHistoryStore.shared.load()
    }
}
