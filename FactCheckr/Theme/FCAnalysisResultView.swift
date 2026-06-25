import SwiftUI

struct FCAnalysisResultView: View {
    let entry: AnalysisHistoryEntry
    var onCheckAnother: (() -> Void)?

    private var response: AnalysisResponse { entry.response }
    private var analysis: AnalysisResult? { response.analysis }
    private var endpoint: AnalyzeEndpoint { pickEndpoint(entry.sourceUrl) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            FCMediaPreviewHeader(sourceUrl: entry.sourceUrl, entry: entry)

            if endpoint == .article {
                FCArticleResultContent(response: response, sourceUrl: entry.sourceUrl)
            } else {
                FCVideoResultContent(response: response, sourceUrl: entry.sourceUrl, endpoint: endpoint)
            }

            if let onCheckAnother {
                FCPrimaryButton(title: Loc.t(.checkAnother), icon: "plus.magnifyingglass", action: onCheckAnother)
            }
        }
        .fcFadeInUp()
        .onAppear {
            Haptics.forVerdict(VerdictCategory.from(analysis: analysis))
        }
    }
}

// MARK: - Article result (score circle + claims & evidence)

struct FCArticleResultContent: View {
    let response: AnalysisResponse
    let sourceUrl: String

    private var analysis: AnalysisResult? { response.analysis }
    private var score: Int { analysis?.credibilityScore ?? 0 }
    private var level: ScoreLevel { .from(score: score) }

    private var manipulationRows: [ManipulationSignal] {
        if let signals = analysis?.manipulationSignals, !signals.isEmpty { return signals }
        return (analysis?.manipulationTechniques ?? []).map {
            ManipulationSignal(label: $0.technique, severity: $0.severity, detail: $0.evidence)
        }
    }

    @State private var pop = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            scoreRow
            badgesRow
            if let summary = analysis?.summary, !summary.isEmpty {
                Text(summary.fcDisplay)
                    .font(.system(size: 15))
                    .foregroundStyle(FCTheme.textSecondary)
                    .lineSpacing(4)
                    .padding(.vertical, 8)
                    .overlay(Rectangle().frame(height: 1).foregroundStyle(FCTheme.border), alignment: .bottom)
            }
            if let es = analysis?.evidenceSummary, (es.totalSources ?? 0) > 0 {
                FCEvidenceSummaryCard(summary: es)
            }
            if let mbfc = analysis?.mbfcResult, mbfc.domain != nil {
                FCMbfcCard(result: mbfc)
            }
            if let assessment = analysis?.assessmentText {
                sectionLabel(Loc.t(.secAnalysis))
                Text(assessment.fcDisplay)
                    .font(.system(size: 15))
                    .foregroundStyle(FCTheme.textSecondary)
                    .lineSpacing(5)
            }
            if let claims = analysis?.claims, !claims.isEmpty {
                sectionLabel(Loc.t(.secClaimsEvidence), count: claims.count)
                VStack(spacing: 10) {
                    ForEach(claims) { claim in
                        FCWebClaimCard(claim: claim)
                    }
                }
            }
            if let indicators = analysis?.indicators, !indicators.isEmpty {
                sectionLabel(Loc.t(.secIndicators))
                VStack(spacing: 8) {
                    ForEach(indicators) { indicator in
                        FCIndicatorRow(indicator: indicator)
                    }
                }
            }
            if !manipulationRows.isEmpty {
                sectionLabel(Loc.t(.secManipulation))
                VStack(spacing: 8) {
                    ForEach(manipulationRows) { signal in
                        FCManipulationRow(signal: signal)
                    }
                }
            }
            if let source = analysis?.sourceAssessment, source.transparency != nil || source.strengths != nil || source.weaknesses != nil {
                sectionLabel(Loc.t(.secSourceAssessment))
                FCSourceAssessmentCard(assessment: source)
            }
            if let missing = analysis?.missingContext, !missing.isEmpty {
                sectionLabel(Loc.t(.secMissingContext))
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(missing.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "puzzlepiece.extension.fill")
                                .font(.caption2)
                                .foregroundStyle(FCTheme.orange)
                                .padding(.top, 2)
                            Text(item.fcDisplay)
                                .font(.system(size: 14))
                                .foregroundStyle(FCTheme.textSecondary)
                        }
                    }
                }
            }
            if let corrected = analysis?.correctedInfo, !corrected.isEmpty {
                sectionLabel(Loc.t(.secCorrection))
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(FCTheme.green)
                    Text(corrected.fcDisplay)
                        .font(.system(size: 14))
                        .foregroundStyle(FCTheme.textSecondary)
                        .lineSpacing(4)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FCTheme.green.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                        .stroke(FCTheme.green.opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
            }
            resultMeta
        }
    }

    @ViewBuilder
    private var badgesRow: some View {
        let model = analysis?.modelUsed ?? response.modelUsed
        let grounded = analysis?.pipelineMetadata?.groundedSearch == true
        let contentType = analysis?.contentType
        let language = analysis?.detectedLanguage
        if model != nil || grounded || contentType != nil || language != nil {
            FCFlowLayout(spacing: 8) {
                if let model {
                    FCResultBadge(icon: "shield.lefthalf.filled", text: model, tint: FCTheme.accentLight)
                }
                if grounded {
                    FCResultBadge(icon: "globe", text: Loc.t(.badgeGrounding), tint: FCTheme.green)
                }
                if let calls = analysis?.pipelineMetadata?.totalAgentCalls, calls > 0 {
                    FCResultBadge(icon: "cpu", text: Loc.t(.badgePipeline), tint: FCTheme.accentLight)
                }
                if let contentType, !MediaPreviewHelper.isGenericMediaLabel(contentType) {
                    FCResultBadge(icon: "tag", text: contentType.fcDisplay, tint: FCTheme.textSecondary)
                }
                if let language {
                    FCResultBadge(icon: "character.bubble", text: language.uppercased(), tint: FCTheme.textSecondary)
                }
            }
        }
    }

    private var scoreRow: some View {
        HStack(alignment: .top, spacing: 20) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(level.background)
                        .overlay(Circle().stroke(level.border, lineWidth: 2))
                    Text("\(score)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(level.color)
                }
                .frame(width: 60, height: 60)
                .scaleEffect(pop ? 1 : 0.55)
                .opacity(pop ? 1 : 0)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1)) {
                        pop = true
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if let verdict = analysis?.verdict {
                        Text(verdict.fcDisplay)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(FCTheme.textPrimary)
                    }
                    Text(scoreHint)
                        .font(.system(size: 12))
                        .foregroundStyle(FCTheme.textMuted)
                        .lineSpacing(3)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 8) {
                miniScore(label: Loc.t(.manipulation), icon: "theatermasks.fill", value: analysis?.manipulationScore ?? 0, inverted: true)
                miniScore(label: Loc.t(.confidence), icon: "shield.fill", value: analysis?.confidenceScore ?? 0, inverted: false)
            }
            .frame(minWidth: 180)
        }
    }

    private var scoreHint: String {
        if score >= 70 { return Loc.t(.scoreHintHigh) }
        if score >= 40 { return Loc.t(.scoreHintMid) }
        return Loc.t(.scoreHintLow)
    }

    private func miniScore(label: String, icon: String, value: Int, inverted: Bool) -> some View {
        HStack(spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 12))
                .foregroundStyle(FCTheme.textMuted)
                .frame(width: 110, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(miniBarColor(value: value, inverted: inverted))
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                        .animation(.easeOut(duration: 0.6), value: value)
                }
            }
            .frame(width: 80, height: 6)
            Text("\(value)/100")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(FCTheme.textSecondary)
        }
    }

    private func miniBarColor(value: Int, inverted: Bool) -> Color {
        if inverted {
            if value > 60 { return FCTheme.red }
            if value > 30 { return FCTheme.orange }
            return FCTheme.green
        }
        if value >= 70 { return FCTheme.green }
        if value >= 40 { return FCTheme.orange }
        return FCTheme.red
    }

    private func sectionLabel(_ title: String, count: Int? = nil) -> some View {
        HStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(FCTheme.textMuted)
            if let count {
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(FCTheme.accentLight)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(FCTheme.accent.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 8)
    }

    private var resultMeta: some View {
        HStack(spacing: 12) {
            if let ms = response.analysisTimeMs {
                Label(String(format: "%.1fs", Double(ms) / 1000), systemImage: "stopwatch")
            }
            if let model = response.modelUsed {
                Label(model, systemImage: "cpu")
            }
        }
        .font(.caption)
        .foregroundStyle(FCTheme.textMuted)
        .padding(.top, 12)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(FCTheme.border), alignment: .top)
    }
}

// MARK: - Video result (SVG-style ring)

struct FCVideoResultContent: View {
    let response: AnalysisResponse
    let sourceUrl: String
    let endpoint: AnalyzeEndpoint

    private var analysis: AnalysisResult? { response.analysis }
    private var score: Int { analysis?.credibilityScore ?? 0 }
    private var level: ScoreLevel { .videoFrom(score: score) }

    private var manipulationRows: [ManipulationSignal] {
        if let signals = analysis?.manipulationSignals, !signals.isEmpty { return signals }
        return (analysis?.manipulationTechniques ?? []).map {
            ManipulationSignal(label: $0.technique, severity: $0.severity, detail: $0.evidence)
        }
    }

    @State private var ringProgress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            scoreHero
            miniStats
            if let summary = analysis?.summary {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel(Loc.t(.secSummary))
                    Text(summary.fcDisplay)
                        .font(.subheadline)
                        .foregroundStyle(FCTheme.textSecondary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FCTheme.bgSecondary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
                }
            }
            if let claims = analysis?.claims, !claims.isEmpty {
                sectionLabel(Loc.t(.secClaims), count: claims.count)
                VStack(spacing: 10) {
                    ForEach(claims) { claim in
                        FCVideoClaimCard(claim: claim)
                    }
                }
            }
            if !manipulationRows.isEmpty {
                sectionLabel(Loc.t(.secManipulation))
                VStack(spacing: 8) {
                    ForEach(manipulationRows) { signal in
                        FCManipulationRow(signal: signal)
                    }
                }
            }
            if let missing = analysis?.missingContext, !missing.isEmpty {
                sectionLabel(Loc.t(.secMissingContext))
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(missing.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "puzzlepiece.extension.fill")
                                .font(.caption2)
                                .foregroundStyle(FCTheme.orange)
                                .padding(.top, 2)
                            Text(item.fcDisplay)
                                .font(.system(size: 14))
                                .foregroundStyle(FCTheme.textSecondary)
                        }
                    }
                }
            }
            if let transcript = response.transcript, !transcript.isEmpty {
                DisclosureGroup(Loc.t(.transcript)) {
                    Text(transcript.fcDisplay)
                        .font(.caption)
                        .foregroundStyle(FCTheme.textSecondary)
                        .padding(.top, 6)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FCTheme.textPrimary)
            }
        }
    }

    private var scoreHero: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(FCTheme.border, lineWidth: 6)
                    .frame(width: 110, height: 110)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(level.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(level.color)
                    Text("/100")
                        .font(.caption2)
                        .foregroundStyle(FCTheme.textMuted)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1)) {
                    ringProgress = CGFloat(score) / 100
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(level.videoLabel)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(level.color)
                if let verdict = analysis?.verdict {
                    Text(verdict.fcDisplay)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FCTheme.textPrimary)
                }
                if let reasoning = analysis?.scoreReasoning {
                    Text(reasoning.fcDisplay)
                        .font(.caption)
                        .foregroundStyle(FCTheme.textMuted)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.bgCard)
        .overlay(alignment: .top) {
            heroAccentLine
        }
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous))
    }

    @ViewBuilder
    private var heroAccentLine: some View {
        let colors: [Color] = endpoint == .youtube
            ? [.red, Color(hex: 0xCC0000)]
            : [FCTheme.tiktok, FCTheme.accent, FCTheme.tiktokCyan]
        LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
            .frame(height: 2)
    }

    private var miniStats: some View {
        HStack(spacing: 0) {
            videoMiniStat(
                value: "\(analysis?.manipulationScore ?? 0)%",
                label: Loc.t(.manipulation),
                color: FCTheme.scoreColor(for: 100 - (analysis?.manipulationScore ?? 0))
            )
            videoMiniStat(
                value: "\(analysis?.confidenceScore ?? 0)%",
                label: Loc.t(.confidenceAI),
                color: FCTheme.accentLight
            )
            videoMiniStat(
                value: "\(analysis?.claims?.count ?? 0)",
                label: Loc.t(.claimsCount),
                color: FCTheme.textPrimary
            )
        }
        .padding(.vertical, 12)
        .background(FCTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    private func videoMiniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(FCTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionLabel(_ title: String, count: Int? = nil) -> some View {
        HStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(FCTheme.textMuted)
            if let count {
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(FCTheme.accentLight)
            }
        }
    }
}

// MARK: - Claim cards

struct FCWebClaimCard: View {
    let claim: Claim
    @State private var expanded = false

    private var breakdown: SourceBreakdown {
        claim.sourceBreakdown ?? SourceBreakdown(confirming: 0, contradicting: 0, neutral: 0)
    }

    private var borderColor: Color {
        let sb = breakdown
        if sb.contradictingCount > sb.confirmingCount { return Color(hex: 0xEF4444) }
        if sb.confirmingCount > 0 && sb.contradictingCount == 0 { return Color(hex: 0x22C55E) }
        if sb.confirmingCount > sb.contradictingCount { return Color(hex: 0xF59E0B) }
        if sb.total == 0 { return Color(hex: 0x9CA3AF) }
        return Color(hex: 0xF59E0B)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            evidenceStrip
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    claimStatusIcon
                    Text(claim.claim.fcDisplay)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(FCTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FCTheme.textMuted)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    if let reason = claim.reason {
                        Text(reason.fcDisplay)
                            .font(.caption)
                            .foregroundStyle(FCTheme.textMuted)
                    }
                    if let summary = claim.researchSummary {
                        Text(summary.fcDisplay)
                            .font(.caption)
                            .foregroundStyle(FCTheme.textSecondary)
                    }
                    if let sources = claim.groundingSources, !sources.isEmpty {
                        ForEach(sources) { source in
                            if let url = source.url, let link = URL(string: url) {
                                Link(destination: link) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "link")
                                            .font(.caption2)
                                        Text((source.title ?? url).fcDisplay)
                                            .font(.caption)
                                            .lineLimit(2)
                                    }
                                    .foregroundStyle(FCTheme.accentLight)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(borderColor)
                .frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var evidenceStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if breakdown.confirmingCount > 0 {
                    evidenceCount(String(format: Loc.t(.evidenceConfirmingFmt), breakdown.confirmingCount), color: FCTheme.green, icon: "checkmark.circle.fill")
                }
                if breakdown.contradictingCount > 0 {
                    evidenceCount(String(format: Loc.t(.evidenceContradictingFmt), breakdown.contradictingCount), color: FCTheme.red, icon: "xmark.circle.fill")
                }
                if breakdown.neutralCount > 0 {
                    evidenceCount(String(format: Loc.t(.evidenceNeutralFmt), breakdown.neutralCount), color: FCTheme.textMuted, icon: "info.circle.fill")
                }
                if breakdown.total == 0 {
                    evidenceCount(Loc.t(.noSources), color: FCTheme.textMuted, icon: "questionmark.circle")
                }
            }
            if breakdown.total > 0 {
                GeometryReader { geo in
                    HStack(spacing: 1) {
                        bar(width: geo.size.width, fraction: CGFloat(breakdown.confirmingCount) / CGFloat(breakdown.total), color: Color(hex: 0x22C55E))
                        bar(width: geo.size.width, fraction: CGFloat(breakdown.contradictingCount) / CGFloat(breakdown.total), color: Color(hex: 0xEF4444))
                        bar(width: geo.size.width, fraction: CGFloat(breakdown.neutralCount) / CGFloat(breakdown.total), color: Color(hex: 0x64748B))
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(10)
        .background(FCTheme.bgSecondary.opacity(0.35))
    }

    private func evidenceCount(_ text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption2.weight(.semibold))
        }
        .foregroundStyle(color)
    }

    private func bar(width: CGFloat, fraction: CGFloat, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: max(0, width * fraction))
    }

    private var claimStatusIcon: some View {
        Image(systemName: statusIcon.name)
            .foregroundStyle(statusIcon.color)
            .font(.caption)
            .padding(.top, 2)
    }

    private var statusIcon: (name: String, color: Color) {
        switch claim.status?.lowercased() {
        case "likely credible": return ("checkmark.circle.fill", FCTheme.green)
        case "likely false", "likely misleading": return ("xmark.circle.fill", FCTheme.red)
        default: return ("questionmark.circle.fill", FCTheme.orange)
        }
    }
}

struct FCVideoClaimCard: View {
    let claim: Claim

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: statusIcon.name)
                    .foregroundStyle(statusIcon.color)
                Text(claim.claim.fcDisplay)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FCTheme.textPrimary)
            }
            if let reason = claim.reason {
                Text(reason.fcDisplay)
                    .font(.caption)
                    .foregroundStyle(FCTheme.textMuted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    private var statusIcon: (name: String, color: Color) {
        switch claim.status?.lowercased() {
        case "likely credible": return ("checkmark.circle.fill", FCTheme.green)
        case "likely false", "likely misleading": return ("xmark.circle.fill", FCTheme.red)
        default: return ("questionmark.circle.fill", FCTheme.orange)
        }
    }
}

struct FCIndicatorRow: View {
    let indicator: Indicator

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            HStack(spacing: 0) {
                Text(indicator.label.fcDisplay)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(FCTheme.textPrimary)
                Text(": \(indicator.detail?.fcDisplay ?? "")")
                    .font(.subheadline)
                    .foregroundColor(FCTheme.textSecondary)
            }
        }
    }

    private var indicatorColor: Color {
        switch indicator.status?.lowercased() {
        case "positive": return FCTheme.green
        case "negative": return FCTheme.red
        default: return FCTheme.orange
        }
    }
}

struct FCManipulationRow: View {
    let signal: ManipulationSignal

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(signal.severity == "high" ? FCTheme.red : FCTheme.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(signal.label.fcDisplay)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FCTheme.textPrimary)
                if let detail = signal.detail {
                    Text(detail.fcDisplay).font(.caption2).foregroundStyle(FCTheme.textMuted)
                }
            }
        }
    }
}

// MARK: - Result badge + flow layout

struct FCResultBadge: View {
    let icon: String
    let text: String
    var tint: Color = FCTheme.accentLight

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.12))
        .overlay(Capsule().stroke(tint.opacity(0.25), lineWidth: 1))
        .clipShape(Capsule())
    }
}

/// Simple wrapping HStack so badges flow onto multiple lines.
struct FCFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [CGFloat] = [0]
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rows.append(0)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? rowWidth : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Evidence summary (global)

struct FCEvidenceSummaryCard: View {
    let summary: EvidenceSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "scalemass.fill")
                    .font(.caption)
                    .foregroundStyle(FCTheme.accentLight)
                Text(Loc.t(.evidenceSummary))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(FCTheme.textPrimary)
                Spacer()
                Text(String(format: Loc.t(.evidenceCountFmt), summary.totalSources ?? 0, summary.totalClaims ?? 0))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(FCTheme.textMuted)
            }
            if summary.total > 0 {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        bar(geo.size.width, CGFloat(summary.confirmingCount) / CGFloat(summary.total), Color(hex: 0x22C55E))
                        bar(geo.size.width, CGFloat(summary.contradictingCount) / CGFloat(summary.total), Color(hex: 0xEF4444))
                        bar(geo.size.width, CGFloat(summary.neutralCount) / CGFloat(summary.total), Color(hex: 0x64748B))
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())
            }
            HStack(spacing: 14) {
                legend(FCTheme.green, "checkmark.circle.fill", String(format: Loc.t(.evidenceConfirmingFmt), summary.confirmingCount))
                legend(FCTheme.red, "xmark.circle.fill", String(format: Loc.t(.evidenceContradictingFmt), summary.contradictingCount))
                legend(FCTheme.textMuted, "info.circle.fill", String(format: Loc.t(.evidenceNeutralFmt), summary.neutralCount))
            }
            Text(Loc.t(.evidenceDisclaimer))
                .font(.caption2)
                .foregroundStyle(FCTheme.textMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.bgSecondary.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    private func bar(_ width: CGFloat, _ fraction: CGFloat, _ color: Color) -> some View {
        Rectangle().fill(color).frame(width: max(0, width * fraction))
    }

    private func legend(_ color: Color, _ icon: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption2.weight(.semibold))
        }
        .foregroundStyle(color)
    }
}

// MARK: - MBFC card

struct FCMbfcCard: View {
    let result: MbfcResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .font(.caption)
                    .foregroundStyle(FCTheme.accentLight)
                Text(Loc.t(.mbfcTitle))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(FCTheme.textPrimary)
                Spacer()
                if let domain = result.domain {
                    Text(domain)
                        .font(.caption2)
                        .foregroundStyle(FCTheme.textMuted)
                        .lineLimit(1)
                }
            }
            HStack(spacing: 10) {
                rating(Loc.t(.mbfcBias), result.biasLabel)
                rating(Loc.t(.mbfcFactual), result.factualLabel)
                rating(Loc.t(.mbfcCredibility), result.credibilityLabel)
            }
            if result.isQuestionable == true {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.caption2)
                    Text(Loc.t(.mbfcQuestionable)).font(.caption2.weight(.semibold))
                }
                .foregroundStyle(FCTheme.red)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((result.isQuestionable == true ? FCTheme.red : FCTheme.accent).opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                .stroke((result.isQuestionable == true ? FCTheme.red : FCTheme.border).opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    private func rating(_ label: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(FCTheme.textMuted)
            Text(value ?? "—")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FCTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Source assessment

struct FCSourceAssessmentCard: View {
    let assessment: SourceAssessment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let transparency = assessment.transparency, !transparency.isEmpty {
                Text(transparency.fcDisplay)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FCTheme.textPrimary)
            }
            if let strengths = assessment.strengths, !strengths.isEmpty {
                row(icon: "plus.circle.fill", color: FCTheme.green, text: strengths)
            }
            if let weaknesses = assessment.weaknesses, !weaknesses.isEmpty {
                row(icon: "minus.circle.fill", color: FCTheme.red, text: weaknesses)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.bgSecondary.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    private func row(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundStyle(color).padding(.top, 1)
            Text(text.fcDisplay).font(.system(size: 13)).foregroundStyle(FCTheme.textSecondary)
        }
    }
}
