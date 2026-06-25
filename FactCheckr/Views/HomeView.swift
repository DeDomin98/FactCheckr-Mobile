import SwiftUI

struct HomeView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var analyzeViewModel: AnalyzeViewModel
    @ObservedObject var authManager: AuthManager
    @ObservedObject var dashboardViewModel: DashboardViewModel
    var onResult: (AnalysisHistoryEntry) -> Void
    var onLoginRequired: () -> Void
    var onOpenAccount: () -> Void
    @Binding var sharedURLToAnalyze: String?

    @State private var activeEndpoint: AnalyzeEndpoint = .article
    @State private var showHomeCheckTip = ContextualTipStore.isVisible(.homeCheck)
    @State private var showShareTip = ContextualTipStore.shouldShowShareTip

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if authManager.isLoggedIn {
                    welcomeHeader
                }

                if showShareTip && !analyzeViewModel.isRunning {
                    FCTipBanner(
                        icon: "bell.badge.fill",
                        tint: FCTheme.green,
                        title: Loc.t(.tipShareTitle),
                        message: Loc.t(.tipShareMessage)
                    ) {
                        showShareTip = false
                        ContextualTipStore.dismiss(.shareBackground)
                    }
                } else if showHomeCheckTip && !analyzeViewModel.isRunning {
                    FCTipBanner(
                        icon: "lightbulb.fill",
                        tint: FCTheme.accentLight,
                        title: Loc.t(.tipHomeTitle),
                        message: Loc.t(.tipHomeMessage)
                    ) {
                        showHomeCheckTip = false
                        ContextualTipStore.dismiss(.homeCheck)
                    }
                }

                header
                inputSection

                if analyzeViewModel.isRunning {
                    checkerResultCard {
                        VStack(alignment: .leading, spacing: 16) {
                            if let url = homeViewModel.extractedURL {
                                FCMediaPreviewHeader(sourceUrl: url, compact: true)
                                Divider().overlay(FCTheme.border)
                            }
                            FCAnalysisProgressView(
                                endpoint: activeEndpoint,
                                stages: analyzeViewModel.pipelineStages,
                                stageDetail: analyzeViewModel.detail,
                                researchProgress: analyzeViewModel.researchProgress,
                                now: analyzeViewModel.progressTick
                            )
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let error = analyzeViewModel.errorMessage, !analyzeViewModel.isRunning {
                    inlineErrorBanner(error)
                    if analyzeViewModel.requiresLogin {
                        FCPrimaryButton(title: Loc.t(.login), icon: "person.fill") {
                            onLoginRequired()
                        }
                    } else if analyzeViewModel.requiresEmailVerification {
                        emailVerificationBanner
                    } else {
                        FCSecondaryButton(title: Loc.t(.retry), icon: "arrow.clockwise") {
                            Task { await runAnalysis() }
                        }
                    }
                }

                if !homeViewModel.recentEntries.isEmpty && !analyzeViewModel.isRunning {
                    recentSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 100)
        }
        .scrollDismissesKeyboard(.interactively)
        .animation(.easeOut(duration: 0.35), value: analyzeViewModel.isRunning)
        .onAppear {
            homeViewModel.refreshRecent()
            showShareTip = ContextualTipStore.shouldShowShareTip
            Task { await dashboardViewModel.refresh(authManager: authManager) }
        }
        .onChange(of: sharedURLToAnalyze) { url in
            guard let url else { return }
            homeViewModel.urlText = url
            sharedURLToAnalyze = nil
            Task { await runAnalysis() }
        }
    }

    private var welcomeHeader: some View {
        let name = dashboardViewModel.profile?.displayName
            ?? authManager.user?.displayName
            ?? authManager.user?.email?.components(separatedBy: "@").first
            ?? Loc.t(.userFallback)
        let locked = authManager.requiresEmailVerification
        return Button(action: onOpenAccount) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(FCTheme.accent.opacity(0.15))
                        .overlay(Circle().stroke(FCTheme.accent.opacity(0.5), lineWidth: 2))
                    Text(String(name.prefix(1)).uppercased())
                        .font(.headline.weight(.bold))
                        .foregroundStyle(FCTheme.accentLight)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(Loc.t(.greetingPrefix)), \(name)!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FCTheme.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Image(systemName: locked ? "lock.fill" : "bolt.shield.fill")
                            .font(.caption2)
                        Text(locked
                             ? Loc.t(.verifyToAnalyze)
                             : String(format: Loc.t(.quotaRemainingFmt), dashboardViewModel.quotaRemaining, dashboardViewModel.quotaLimit))
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(locked ? FCTheme.orange : FCTheme.accentLight)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FCTheme.textMuted)
            }
            .padding(14)
            .background(FCTheme.bgCard)
            .overlay(FCTopAccentLine())
            .overlay(
                RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous)
                    .stroke(FCTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Loc.t(.homeTitle))
                .font(FCTheme.heading(26))
                .foregroundStyle(FCTheme.textPrimary)
            Text(Loc.t(.homeSubtitle))
                .font(.subheadline)
                .foregroundStyle(FCTheme.textSecondary)
        }
    }

    private var inputSection: some View {
        VStack(spacing: 12) {
            TextField("https://…", text: $homeViewModel.urlText, axis: .vertical)
                .lineLimit(3...8)
                .font(.body)
                .foregroundStyle(FCTheme.textPrimary)
                .tint(FCTheme.accent)
                .padding(16)
                .background(FCTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                        .stroke(
                            homeViewModel.urlValidationError != nil ? FCTheme.red.opacity(0.5) : FCTheme.borderLight,
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
                .disabled(analyzeViewModel.isRunning)

            if let validationError = homeViewModel.urlValidationError {
                Text(validationError)
                    .font(.caption)
                    .foregroundStyle(FCTheme.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                FCSecondaryButton(title: Loc.t(.paste), icon: "doc.on.clipboard") {
                    homeViewModel.pasteFromClipboard()
                }
                .disabled(analyzeViewModel.isRunning)

                FCPrimaryButton(
                    title: Loc.t(.check),
                    icon: "checkmark.shield",
                    isLoading: analyzeViewModel.isRunning,
                    disabled: !homeViewModel.canSubmit || analyzeViewModel.isRunning
                ) {
                    Task { await runAnalysis() }
                }
            }
        }
    }

    private func checkerResultCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FCTheme.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous)
                    .stroke(FCTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous))
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Loc.t(.recentChecks))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FCTheme.textSecondary)

            ForEach(homeViewModel.recentEntries) { entry in
                Button {
                    onResult(entry)
                } label: {
                    recentRow(entry)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func recentRow(_ entry: AnalysisHistoryEntry) -> some View {
        HStack(spacing: 12) {
            VerdictBadge(category: VerdictCategory.from(analysis: entry.response.analysis), compact: true)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title.fcDisplay)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FCTheme.textPrimary)
                    .lineLimit(2)
                Text(entry.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(FCTheme.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FCTheme.textMuted)
        }
        .padding(14)
        .background(FCTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    private var emailVerificationBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Loc.t(.verifyEmailContinue))
                .font(.caption)
                .foregroundStyle(FCTheme.orange)
            FCSecondaryButton(title: Loc.t(.resend), icon: "envelope") {
                Task { try? await authManager.resendVerificationEmail() }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous))
    }

    private func inlineErrorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.caption)
        }
        .foregroundStyle(FCTheme.orange)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous))
    }

    private func runAnalysis() async {
        guard let url = homeViewModel.extractedURL else { return }
        Haptics.impact(.medium)
        activeEndpoint = pickEndpoint(url)
        analyzeViewModel.reset()
        await analyzeViewModel.analyze(url: url, endpoint: activeEndpoint, authManager: authManager)
        if let result = analyzeViewModel.result {
            let entry = AnalysisHistoryEntry(sourceUrl: url, endpoint: activeEndpoint, response: result)
            AnalysisHistoryStore.shared.save(entry)
            homeViewModel.refreshRecent()
            homeViewModel.clearInput()
            ContextualTipStore.markFirstAnalysisCompleted()
            showHomeCheckTip = false
            Task { await dashboardViewModel.refresh(authManager: authManager) }
            onResult(entry)
        }
    }
}
