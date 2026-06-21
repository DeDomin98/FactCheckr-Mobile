import SwiftUI

struct AnalyzeView: View {
    @ObservedObject var viewModel: AnalyzeViewModel
    let url: String
    let endpoint: AnalyzeEndpoint
    @ObservedObject var authManager: AuthManager
    var onComplete: (AnalysisResponse) -> Void
    var onLoginRequired: () -> Void
    var onVerifyEmailRequired: () -> Void
    var onCancel: () -> Void

    private var stages: [AnalysisStage] {
        endpoint == .article
            ? [.scraping, .analyzing, .judging]
            : [.transcribing, .extracting, .researching, .judging]
    }

    private var progressValue: Double {
        guard let idx = stages.firstIndex(of: viewModel.stage) else {
            return viewModel.isRunning ? 0.1 : 1.0
        }
        return Double(idx + 1) / Double(stages.count)
    }

    var body: some View {
        ZStack {
            FCBackground()

            VStack(spacing: 28) {
                if viewModel.isRunning {
                    runningContent
                } else if viewModel.errorMessage != nil {
                    errorContent
                }

                Spacer()

                Button("Anuluj", role: .cancel) { onCancel() }
                    .foregroundStyle(FCTheme.textMuted)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .navigationTitle("Analiza")
        .navigationBarTitleDisplayMode(.inline)
        .task { await startAnalysis() }
    }

    private var runningContent: some View {
        VStack(spacing: 24) {
            FCLogo(size: 52)

            Text("Analizuję treść…")
                .font(.title3.weight(.bold))
                .foregroundStyle(FCTheme.textPrimary)

            VStack(spacing: 8) {
                ProgressView(value: progressValue)
                    .tint(FCTheme.accent)
                Text("\(Int(progressValue * 100))%")
                    .font(.caption)
                    .foregroundStyle(FCTheme.textMuted)
            }

            FCCard {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                        let isActive = viewModel.stage == stage
                        let isDone = (stages.firstIndex(of: viewModel.stage) ?? -1) > index
                        FCStageStep(stage: stage, isActive: isActive, isDone: isDone)
                    }
                }
            }

            if let detail = viewModel.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(FCTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Text(url)
                .font(.caption2)
                .foregroundStyle(FCTheme.textMuted)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var errorContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(FCTheme.orange)

            Text(viewModel.errorMessage ?? "Nieznany błąd")
                .multilineTextAlignment(.center)
                .foregroundStyle(FCTheme.textSecondary)

            if viewModel.requiresLogin {
                FCPrimaryButton(title: "Zaloguj się / Zarejestruj", icon: "person.badge.plus") {
                    onLoginRequired()
                }
            } else if viewModel.requiresEmailVerification {
                FCPrimaryButton(title: "Potwierdź e-mail", icon: "envelope.badge") {
                    onVerifyEmailRequired()
                }
            }

            FCSecondaryButton(title: "Spróbuj ponownie", icon: "arrow.clockwise") {
                Task { await startAnalysis() }
            }
        }
    }

    private func startAnalysis() async {
        viewModel.reset()
        viewModel.isRunning = true
        await viewModel.analyze(url: url, endpoint: endpoint, authManager: authManager)
        if let result = viewModel.result {
            onComplete(result)
        }
    }
}
