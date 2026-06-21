import SwiftUI

struct ResultView: View {
    let entry: AnalysisHistoryEntry
    var onCheckAnother: () -> Void

    var body: some View {
        ScrollView {
            FCAnalysisResultView(entry: entry, onCheckAnother: onCheckAnother)
                .padding(20)
                .padding(.bottom, 40)
        }
        .background(FCBackground())
        .navigationTitle("Wynik")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VerdictBadge: View {
    let category: VerdictCategory
    var compact: Bool = false

    var body: some View {
        Text(category.rawValue)
            .font(compact ? .caption2.weight(.bold) : .subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 8 : 14)
            .padding(.vertical, compact ? 4 : 8)
            .background(category.color)
            .clipShape(Capsule())
    }
}
