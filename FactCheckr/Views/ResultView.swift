import SwiftUI

struct ResultView: View {
    let entry: AnalysisHistoryEntry
    var onCheckAnother: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var isFavorite: Bool = false

    var body: some View {
        ScrollView {
            FCAnalysisResultView(entry: entry, onCheckAnother: onCheckAnother)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
        }
        .background(FCBackground())
        .navigationTitle(Loc.t(.resultTitle))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(FCTheme.bgPrimary.opacity(0.98), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Haptics.selection()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FCTheme.accentLight)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Loc.t(.back))
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundStyle(isFavorite ? FCTheme.orange : FCTheme.accentLight)
                    }

                    Button {
                        Haptics.impact(.light)
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(FCTheme.accentLight)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareReportSheet(entry: entry)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear { isFavorite = FavoritesStore.shared.isFavorite(entry.id) }
    }

    private func toggleFavorite() {
        let now = FavoritesStore.shared.toggle(entry)
        isFavorite = now
        Haptics.impact(now ? .light : .soft)
    }
}

struct VerdictBadge: View {
    let category: VerdictCategory
    var compact: Bool = false

    var body: some View {
        Text(category.localizedLabel)
            .font(compact ? .caption2.weight(.bold) : .subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 8 : 14)
            .padding(.vertical, compact ? 4 : 8)
            .background(category.color)
            .clipShape(Capsule())
    }
}
