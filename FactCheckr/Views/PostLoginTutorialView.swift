import SwiftUI

private enum PostLoginPhase: Equatable {
    case welcome
    case pasteLink
    case analyzing
    case result
}

struct PostLoginTutorialView: View {
    @ObservedObject var analyzeViewModel: AnalyzeViewModel
    var onFinish: (AnalysisHistoryEntry) -> Void
    var onSkip: () -> Void

    @State private var phase: PostLoginPhase = .welcome
    @State private var urlText = ""
    @State private var pasteHighlight = false
    @State private var heroAppeared = false
    @State private var demoEntry: AnalysisHistoryEntry?

    private let fullURL = DemoAnalysisProvider.demoURL

    var body: some View {
        ZStack {
            FCBackground()

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(spacing: 24) {
                        switch phase {
                        case .welcome:
                            welcomeContent
                        case .pasteLink:
                            pasteContent
                        case .analyzing:
                            analyzingContent
                        case .result:
                            resultContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }

                bottomBar
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.08)) {
                heroAppeared = true
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            if phase == .pasteLink {
                Button {
                    withAnimation { phase = .welcome }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FCTheme.accentLight)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 24, height: 24)
            }

            Spacer()

            if phase != .result {
                Button(Loc.t(.onboardingSkip)) {
                    finishTutorial(saveDemo: false)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FCTheme.textMuted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Welcome

    private var welcomeContent: some View {
        VStack(spacing: 24) {
            heroIcon(systemName: "hand.wave.fill", tint: FCTheme.green)

            VStack(spacing: 10) {
                Text(Loc.t(.postLoginWelcomeTitle))
                    .font(FCTheme.heading(28))
                    .foregroundStyle(FCTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(Loc.t(.postLoginWelcomeSub))
                    .font(.body)
                    .foregroundStyle(FCTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            tokensBadge

            demoArticleCard

            Text(Loc.t(.postLoginWelcomeHint))
                .font(.subheadline)
                .foregroundStyle(FCTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private var tokensBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "gift.fill")
                .foregroundStyle(FCTheme.orange)
            Text(Loc.t(.postLoginTokensBadge))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FCTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(FCTheme.orange.opacity(0.12))
        .overlay(
            Capsule()
                .stroke(FCTheme.orange.opacity(0.35), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private var demoArticleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "newspaper.fill")
                    .foregroundStyle(FCTheme.accentLight)
                Text("rp.pl")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FCTheme.textMuted)
                Spacer()
                Text(Loc.t(.postLoginDemoFreeTag))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(FCTheme.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FCTheme.green.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(DemoAnalysisProvider.demoArticleTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(FCTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(Loc.t(.postLoginDemoArticleTeaser))
                .font(.caption)
                .foregroundStyle(FCTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous))
    }

    // MARK: - Paste

    private var pasteContent: some View {
        VStack(spacing: 20) {
            heroIcon(systemName: "doc.on.clipboard.fill", tint: FCTheme.accentLight)

            VStack(spacing: 8) {
                Text(Loc.t(.postLoginPasteTitle))
                    .font(FCTheme.heading(24))
                    .foregroundStyle(FCTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(Loc.t(.postLoginPasteSub))
                    .font(.subheadline)
                    .foregroundStyle(FCTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                TextField("https://…", text: .constant(urlText), axis: .vertical)
                    .lineLimit(2...4)
                    .font(.body)
                    .foregroundStyle(FCTheme.textPrimary)
                    .padding(16)
                    .background(FCTheme.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                            .stroke(
                                pasteHighlight ? FCTheme.accent.opacity(0.7) : FCTheme.borderLight,
                                lineWidth: pasteHighlight ? 2 : 1
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
                    .animation(.easeInOut(duration: 0.25), value: pasteHighlight)

                if urlText.isEmpty {
                    FCSecondaryButton(
                        title: Loc.t(.postLoginPasteButton),
                        icon: "doc.on.clipboard"
                    ) {
                        Task { await animatePaste() }
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(FCTheme.green)
                        Text(Loc.t(.postLoginLinkReady))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(FCTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.caption)
                    .foregroundStyle(FCTheme.green)
                Text(Loc.t(.postLoginPasteFreeHint))
                    .font(.caption)
                    .foregroundStyle(FCTheme.textMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FCTheme.green.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous))
        }
    }

    // MARK: - Analyzing

    private var analyzingContent: some View {
        VStack(spacing: 24) {
            heroIcon(systemName: "checkmark.shield.fill", tint: FCTheme.accentLight, pulse: true)

            Text(Loc.t(.postLoginAnalyzingTitle))
                .font(FCTheme.heading(22))
                .foregroundStyle(FCTheme.textPrimary)
                .multilineTextAlignment(.center)

            FCAnalysisProgressView(
                endpoint: .article,
                stages: analyzeViewModel.pipelineStages,
                stageDetail: analyzeViewModel.detail,
                researchProgress: analyzeViewModel.researchProgress,
                now: analyzeViewModel.progressTick
            )
            .padding(16)
            .background(FCTheme.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous)
                    .stroke(FCTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous))
        }
    }

    // MARK: - Result

    private var resultContent: some View {
        VStack(spacing: 16) {
            demoBanner

            if let demoEntry {
                FCAnalysisResultView(entry: demoEntry, onCheckAnother: nil)
            }
        }
    }

    private var demoBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(FCTheme.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(Loc.t(.postLoginDemoBadge))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FCTheme.textPrimary)
                Text(Loc.t(.postLoginDemoBadgeSub))
                    .font(.caption)
                    .foregroundStyle(FCTheme.textMuted)
            }
            Spacer()
        }
        .padding(14)
        .background(FCTheme.orange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                .stroke(FCTheme.orange.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    // MARK: - Bottom bar

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(FCTheme.border)

            Group {
                switch phase {
                case .welcome:
                    FCPrimaryButton(title: Loc.t(.postLoginTryDemo), icon: "play.fill") {
                        withAnimation { phase = .pasteLink }
                    }
                case .pasteLink:
                    FCPrimaryButton(
                        title: Loc.t(.check),
                        icon: "checkmark.shield",
                        disabled: urlText.isEmpty || analyzeViewModel.isRunning
                    ) {
                        startDemoAnalysis()
                    }
                case .analyzing:
                    EmptyView()
                case .result:
                    FCPrimaryButton(title: Loc.t(.postLoginFinishButton), icon: "arrow.right") {
                        finishTutorial(saveDemo: true)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(FCTheme.bgPrimary.opacity(0.95))
    }

    // MARK: - Helpers

    private func heroIcon(systemName: String, tint: Color, pulse: Bool = false) -> some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.15))
                .frame(width: 88, height: 88)
            Image(systemName: systemName)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(tint)
                .scaleEffect(pulse && analyzeViewModel.isRunning ? 1.05 : 1)
                .animation(
                    pulse && analyzeViewModel.isRunning
                        ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                        : .default,
                    value: analyzeViewModel.isRunning
                )
        }
        .scaleEffect(heroAppeared ? 1 : 0.6)
        .opacity(heroAppeared ? 1 : 0)
    }

    private func animatePaste() async {
        Haptics.impact(.light)
        pasteHighlight = true
        urlText = ""
        let target = fullURL

        for index in target.indices {
            urlText.append(target[index])
            try? await Task.sleep(nanoseconds: 12_000_000)
        }

        try? await Task.sleep(nanoseconds: 250_000_000)
        pasteHighlight = false
        Haptics.selection()
    }

    private func startDemoAnalysis() {
        Haptics.impact(.medium)
        withAnimation { phase = .analyzing }
        Task {
            await analyzeViewModel.runDemoAnalysis()
            demoEntry = DemoAnalysisProvider.makeHistoryEntry()
            withAnimation { phase = .result }
            Haptics.forVerdict(VerdictCategory.from(analysis: demoEntry?.response.analysis))
        }
    }

    private func finishTutorial(saveDemo: Bool) {
        if saveDemo, let demoEntry {
            AnalysisHistoryStore.shared.save(demoEntry)
            onFinish(demoEntry)
        } else {
            onSkip()
        }
    }
}
