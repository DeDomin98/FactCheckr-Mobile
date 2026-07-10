import SwiftUI

struct AuthScreen<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            FCBackground()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        FCLogo(size: 64, glow: true)
                        Text(title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(FCTheme.textPrimary)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(FCTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    FCCard {
                        content
                    }
                }
                .padding(20)
            }
        }
    }
}
