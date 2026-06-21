import SwiftUI

struct OnboardingView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            FCBackground()

            VStack(spacing: 32) {
                Spacer()

                FCLogo(size: 64)

                VStack(spacing: 16) {
                    Text("Fact Checkr")
                        .font(FCTheme.heading(28))
                        .foregroundStyle(FCTheme.textPrimary)

                    Text("Sprawdzaj wiarygodność artykułów i filmów z YouTube oraz TikToka dzięki analizie AI.")
                        .font(.body)
                        .foregroundStyle(FCTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }

                Spacer()

                FCPrimaryButton(title: "Zaczynamy", icon: "arrow.right") {
                    OnboardingStore.markSeen()
                    onContinue()
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
        }
    }
}
