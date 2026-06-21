import SwiftUI

struct HomeView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var analyzeViewModel: AnalyzeViewModel
    @ObservedObject var authManager: AuthManager
    var onResult: (AnalysisHistoryEntry) -> Void
    var onLoginRequired: () -> Void
    @Binding var sharedURLToAnalyze: String?

    @State private var activeEndpoint: AnalyzeEndpoint = .article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                inputSection

                if analyzeViewModel.isRunning {
                    checkerResultCard {
                        FCAnalysisProgressView(
                            endpoint: activeEndpoint,
                            stages: analyzeViewModel.pipelineStages,
                            stageDetail: analyzeViewModel.detail,
                            researchProgress: analyzeViewModel.researchProgress,
                            now: analyzeViewModel.progressTick
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let error = analyzeViewModel.errorMessage, !analyzeViewModel.isRunning {
                    inlineErrorBanner(error)
                    if analyzeViewModel.requiresLogin {
                        FCPrimaryButton(title: "Zaloguj się", icon: "person.fill") {
                            onLoginRequired()
                        }
                    } else if analyzeViewModel.requiresEmailVerification {
                        emailVerificationBanner
                    } else {
                        FCSecondaryButton(title: "Spróbuj ponownie", icon: "arrow.clockwise") {
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
        .onAppear { homeViewModel.refreshRecent() }
        .onChange(of: sharedURLToAnalyze) { url in
            guard let url else { return }
            homeViewModel.urlText = url
            sharedURLToAnalyze = nil
            Task { await runAnalysis() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sprawdź link")
                .font(FCTheme.heading(26))
                .foregroundStyle(FCTheme.textPrimary)
            Text("Wklej URL artykułu lub link do wideo z YouTube / TikTok.")
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
                FCSecondaryButton(title: "Wklej", icon: "doc.on.clipboard") {
                    homeViewModel.pasteFromClipboard()
                }
                .disabled(analyzeViewModel.isRunning)

                FCPrimaryButton(
                    title: "Sprawdź",
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
            Text("Ostatnie sprawdzenia")
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
                Text(entry.title)
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
            Text("Potwierdź adres e-mail, aby kontynuować analizy.")
                .font(.caption)
                .foregroundStyle(FCTheme.orange)
            FCSecondaryButton(title: "Wyślij ponownie", icon: "envelope") {
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
        activeEndpoint = pickEndpoint(url)
        analyzeViewModel.reset()
        await analyzeViewModel.analyze(url: url, endpoint: activeEndpoint, authManager: authManager)
        if let result = analyzeViewModel.result {
            let entry = AnalysisHistoryEntry(sourceUrl: url, endpoint: activeEndpoint, response: result)
            AnalysisHistoryStore.shared.save(entry)
            homeViewModel.refreshRecent()
            homeViewModel.clearInput()
            onResult(entry)
        }
    }
}
