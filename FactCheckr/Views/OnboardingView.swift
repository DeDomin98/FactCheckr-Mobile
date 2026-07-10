import SwiftUI

private enum OnboardingLayout {
    case bullets
    case steps
}

private struct OnboardingPage: Identifiable {
    let id: Int
    let icon: String
    let tint: Color
    let titleKey: LocKey
    let subtitleKey: LocKey
    let layout: OnboardingLayout
    let itemKeys: [LocKey]
}

struct OnboardingView: View {
    var onContinue: () -> Void

    @State private var page = 0
    @State private var heroAppeared = false

    private var pages: [OnboardingPage] {
        // Keep onboarding short — detailed Share/YouTube flows live in contextual tips.
        [
            OnboardingPage(
                id: 0,
                icon: "checkmark.shield.fill",
                tint: FCTheme.green,
                titleKey: .onboardingPage1Title,
                subtitleKey: .onboardingPage1Sub,
                layout: .bullets,
                itemKeys: [.onboardingPage1Feat1, .onboardingPage1Feat2, .onboardingPage1Feat3]
            ),
            OnboardingPage(
                id: 1,
                icon: "doc.text.magnifyingglass",
                tint: Color(red: 0.45, green: 0.72, blue: 1),
                titleKey: .onboardingPage2Title,
                subtitleKey: .onboardingPage2Sub,
                layout: .bullets,
                itemKeys: [.onboardingPage2Feat1, .onboardingPage2Feat2, .onboardingPage2Feat3]
            ),
            OnboardingPage(
                id: 2,
                icon: "doc.on.clipboard.fill",
                tint: FCTheme.accentLight,
                titleKey: .onboardingPage3Title,
                subtitleKey: .onboardingPage3Sub,
                layout: .steps,
                itemKeys: [.onboardingPasteStep1, .onboardingPasteStep2, .onboardingPasteStep3]
            ),
            OnboardingPage(
                id: 3,
                icon: "person.crop.circle.badge.checkmark",
                tint: FCTheme.orange,
                titleKey: .onboardingPage7Title,
                subtitleKey: .onboardingPage7Sub,
                layout: .bullets,
                itemKeys: [.onboardingPage7Feat1, .onboardingPage7Feat2, .onboardingPage7Feat3]
            )
        ]
    }

    var body: some View {
        ZStack {
            FCBackground()

            VStack(spacing: 0) {
                headerBar

                TabView(selection: $page) {
                    ForEach(pages) { item in
                        pageContent(item)
                            .tag(item.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: page)

                pageIndicator
                    .padding(.bottom, 16)

                FCPrimaryButton(
                    title: page == pages.count - 1 ? Loc.t(.getStarted) : Loc.t(.onboardingNext),
                    icon: page == pages.count - 1 ? "arrow.right" : "chevron.right"
                ) {
                    advance()
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                heroAppeared = true
            }
        }
        .onChange(of: page) { _ in
            heroAppeared = false
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.05)) {
                heroAppeared = true
            }
        }
    }

    private var headerBar: some View {
        HStack {
            if page == 0 {
                FCLogo(size: 32, glow: false)
            } else {
                Color.clear.frame(width: 32, height: 32)
            }
            Spacer()
            Text(String(format: Loc.t(.onboardingStepFmt), page + 1) + " / \(pages.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FCTheme.textMuted)
            Spacer()
            if page < pages.count - 1 {
                Button(Loc.t(.onboardingSkip)) {
                    finish()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FCTheme.textMuted)
            } else {
                Color.clear.frame(width: 44, height: 1)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .frame(height: 52)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(pages) { item in
                Capsule()
                    .fill(item.id == page ? FCTheme.accentLight : Color.white.opacity(0.18))
                    .frame(width: item.id == page ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.35), value: page)
            }
        }
    }

    private func pageContent(_ item: OnboardingPage) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if item.id == 0 {
                    FCLogo(size: 72, glow: true)
                        .padding(.top, 8)
                        .scaleEffect(heroAppeared ? 1 : 0.9)
                        .opacity(heroAppeared ? 1 : 0)
                } else {
                    heroIcon(for: item)
                }

                VStack(spacing: 8) {
                    Text(Loc.t(item.titleKey))
                        .font(FCTheme.heading(24))
                        .foregroundStyle(FCTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(Loc.t(item.subtitleKey))
                        .font(.subheadline)
                        .foregroundStyle(FCTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 4)

                switch item.layout {
                case .bullets:
                    bulletCard(for: item)
                case .steps:
                    stepsCard(for: item)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }

    private func heroIcon(for item: OnboardingPage) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [item.tint.opacity(0.22), item.tint.opacity(0.04)],
                        center: .center,
                        startRadius: 8,
                        endRadius: 68
                    )
                )
                .frame(width: 120, height: 120)

            Circle()
                .stroke(item.tint.opacity(0.35), lineWidth: 1.5)
                .frame(width: 96, height: 96)

            Image(systemName: item.icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(item.tint)
        }
        .scaleEffect(heroAppeared ? 1 : 0.88)
        .opacity(heroAppeared ? 1 : 0)
        .padding(.top, 4)
    }

    private func bulletCard(for item: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(item.itemKeys.enumerated()), id: \.offset) { index, key in
                if index > 0 {
                    Divider()
                        .overlay(FCTheme.border)
                        .padding(.leading, 52)
                }

                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(item.tint)
                        .frame(width: 28, height: 28)
                        .background(item.tint.opacity(0.14))
                        .clipShape(Circle())

                    Text(Loc.t(key))
                        .font(.subheadline)
                        .foregroundStyle(FCTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .staggeredAppear(index: index, appeared: heroAppeared)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onboardingListCard()
    }

    private func stepsCard(for item: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(item.itemKeys.enumerated()), id: \.offset) { index, key in
                if index > 0 {
                    Divider()
                        .overlay(FCTheme.border)
                        .padding(.leading, 52)
                }

                HStack(alignment: .top, spacing: 14) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(item.tint)
                        .clipShape(Circle())
                        .padding(.top, 1)

                    Text(Loc.t(key))
                        .font(.subheadline)
                        .foregroundStyle(FCTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .staggeredAppear(index: index, appeared: heroAppeared)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onboardingListCard()
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation { page += 1 }
            Haptics.selection()
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.impact(.light)
        OnboardingStore.markSeen()
        onContinue()
    }
}

private extension View {
    func onboardingListCard() -> some View {
        background(FCTheme.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                    .stroke(FCTheme.borderLight, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    func staggeredAppear(index: Int, appeared: Bool) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(.easeOut(duration: 0.32).delay(0.06 + Double(index) * 0.05), value: appeared)
    }
}
