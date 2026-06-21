import SwiftUI

struct FCAnalysisProgressView: View {
    let endpoint: AnalyzeEndpoint
    let stages: [PipelineStageItem]
    let stageDetail: String?
    let researchProgress: String?
    let now: Date

    private var isVideo: Bool { endpoint != .article }

    private var progressFraction: Double {
        guard !stages.isEmpty else { return 0 }
        let done = stages.filter { $0.status == .done }.count
        return Double(done) / Double(stages.count)
    }

    var body: some View {
        Group {
            if isVideo {
                videoProgress
            } else {
                articleProgress
            }
        }
        .fcFadeInUp()
    }

    private var articleProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(stages) { stage in
                articleStageRow(stage)
            }
            if let stageDetail, !stageDetail.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text(stageDetail)
                        .font(.caption)
                }
                .foregroundStyle(FCTheme.textMuted)
                .padding(.leading, 26)
            }
        }
        .padding(.vertical, 8)
    }

    private func articleStageRow(_ stage: PipelineStageItem) -> some View {
        HStack(spacing: 10) {
            stageIcon(stage, pulse: false)
                .frame(width: 20)
            Text(stageLabel(stage))
                .font(.system(size: 15, weight: stage.status == .active ? .medium : .regular))
                .foregroundStyle(stageColor(stage))
            Spacer()
            if let elapsed = elapsedText(stage) {
                Text(elapsed)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(FCTheme.textMuted.opacity(0.8))
            }
        }
        .opacity(stage.status == .pending ? 0.5 : 1)
    }

    private var videoProgress: some View {
        VStack(spacing: 16) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FCTheme.border)
                        .frame(height: 3)
                    Capsule()
                        .fill(progressGradient)
                        .frame(width: geo.size.width * progressFraction, height: 3)
                        .animation(.easeOut(duration: 0.5), value: progressFraction)
                }
            }
            .frame(height: 3)

            VStack(spacing: 6) {
                ForEach(stages) { stage in
                    videoStageRow(stage)
                }
            }

            if let stageDetail, !stageDetail.isEmpty {
                Text(stageDetail)
                    .font(.caption)
                    .foregroundStyle(FCTheme.textSecondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var progressGradient: LinearGradient {
        switch endpoint {
        case .youtube:
            return LinearGradient(colors: [.red, Color(hex: 0xCC0000)], startPoint: .leading, endPoint: .trailing)
        case .tiktok:
            return LinearGradient(colors: [FCTheme.tiktok, FCTheme.accent, FCTheme.tiktokCyan], startPoint: .leading, endPoint: .trailing)
        default:
            return LinearGradient(colors: [FCTheme.accent, FCTheme.green], startPoint: .leading, endPoint: .trailing)
        }
    }

    private func videoStageRow(_ stage: PipelineStageItem) -> some View {
        HStack(spacing: 10) {
            stageIcon(stage, pulse: true)
                .frame(width: 20)
            Text(stageLabel(stage))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(stageColor(stage))
            Spacer()
            if let elapsed = elapsedText(stage) {
                Text(elapsed)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(stage.status == .done ? FCTheme.green : FCTheme.textMuted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(stage.status == .active ? FCTheme.tiktok.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func stageIcon(_ stage: PipelineStageItem, pulse: Bool) -> some View {
        switch stage.status {
        case .active:
            if pulse {
                FCPulseIcon(systemName: stage.id.icon, color: FCTheme.textPrimary)
            } else {
                FCStageSpinner()
            }
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(FCTheme.green)
        case .error:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(FCTheme.red)
        case .pending:
            Image(systemName: "circle")
                .foregroundStyle(FCTheme.textMuted.opacity(0.35))
        }
    }

    private func stageLabel(_ stage: PipelineStageItem) -> String {
        var label = stage.id.label(endpoint: endpoint, isVideoSecurityLabel: isVideo && stage.id == .pow)
        if stage.id == .researching, let researchProgress, !researchProgress.isEmpty {
            label += " (\(researchProgress) twierdzeń)"
        }
        return label
    }

    private func stageColor(_ stage: PipelineStageItem) -> Color {
        switch stage.status {
        case .active: return FCTheme.accent
        case .done: return FCTheme.green
        case .error: return FCTheme.red
        case .pending: return FCTheme.textMuted
        }
    }

    private func elapsedText(_ stage: PipelineStageItem) -> String? {
        guard let start = stage.startedAt else { return nil }
        let end = stage.finishedAt ?? (stage.status == .active ? now : nil)
        guard let end else { return nil }
        let seconds = end.timeIntervalSince(start)
        if stage.status == .done {
            return String(format: "(%.1fs)", seconds)
        }
        return String(format: "(%.0fs)", seconds)
    }
}
