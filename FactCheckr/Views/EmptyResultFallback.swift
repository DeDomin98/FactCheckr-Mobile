import SwiftUI

struct EmptyResultFallback: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.questionmark")
                .font(.largeTitle)
                .foregroundStyle(FCTheme.textMuted)
            Text("Brak wyniku do wyświetlenia")
                .foregroundStyle(FCTheme.textSecondary)
            FCPrimaryButton(title: "Wróć do analizy", icon: "arrow.left") { onDismiss() }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FCBackground())
    }
}
