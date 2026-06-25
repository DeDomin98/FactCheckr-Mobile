import SwiftUI

private struct OnboardingPage: Identifiable {
    let id: Int
    let icon: String
    let tint: Color
    let titleKey: LocKey
    let subtitleKey: LocKey
}

struct OnboardingView: View {
    var onContinue: () -> Void

    @State private var page = 0
    @State private var appeared = false

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(id: 0, icon: "sparkles", tint: FCTheme.accentLight, titleKey: .onboardingPage1Title, subtitleKey: .onboardingPage1Sub),
            OnboardingPage(id: 1, icon: "play.rectangle.on.rectangle.fill", tint: FCTheme.youtube, titleKey: .onboardingPage2Title, subtitleKey: .onboardingPage2Sub),
            OnboardingPage(id: 2, icon: "square.and.arrow.up.fill", tint: FCTheme.green, titleKey: .onboardingPage3Title, subtitleKey: .onboardingPage3Sub)
        ]
    }

    var body: some View {
        ZStack {
            FCBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if page < pages.count - 1 {
                        Button(Loc.t(.onboardingSkip)) {
                            finish()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FCTheme.textMuted)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .frame(height: 44)

                TabView(selection: $page) {
                    ForEach(pages) { item in
                        pageContent(item)
                            .tag(item.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: page)

                HStack(spacing: 8) {
                    ForEach(pages) { item in
                        Capsule()
                            .fill(item.id == page ? FCTheme.accentLight : Color.white.opacity(0.18))
                            .frame(width: item.id == page ? 22 : 7, height: 7)
                            .animation(.spring(response: 0.35), value: page)
                    }
                }
                .padding(.bottom, 24)

                FCPrimaryButton(
                    title: page == pages.count - 1 ? Loc.t(.getStarted) : Loc.t(.onboardingNext),
                    icon: page == pages.count - 1 ? "arrow.right" : "chevron.right"
                ) {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                        Haptics.selection()
                    } else {
                        finish()
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private func pageContent(_ item: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)

            ZStack {
                Circle()
                    .fill(item.tint.opacity(0.12))
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(item.tint.opacity(0.28), lineWidth: 1)
                    .frame(width: 120, height: 120)
                Image(systemName: item.icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(item.tint)
            }
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 14) {
                if item.id == 0 {
                    FCLogo(size: 56, glow: true)
                        .padding(.bottom, 4)
                }

                Text(Loc.t(item.titleKey))
                    .font(FCTheme.heading(26))
                    .foregroundStyle(FCTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(Loc.t(item.subtitleKey))
                    .font(.body)
                    .foregroundStyle(FCTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 12)
            }
            .padding(.horizontal, 20)
            .offset(y: appeared ? 0 : 18)
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
    }

    private func finish() {
        Haptics.impact(.light)
        OnboardingStore.markSeen()
        onContinue()
    }
}
