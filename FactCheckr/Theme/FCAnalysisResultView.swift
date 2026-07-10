import SwiftUI

struct FCAnalysisResultView: View {
    let entry: AnalysisHistoryEntry
    var onCheckAnother: (() -> Void)?

    @State private var showFullReport = false

    private var response: AnalysisResponse { entry.response }
    private var analysis: AnalysisResult? { response.analysis }
    private var endpoint: AnalyzeEndpoint { pickEndpoint(entry.sourceUrl) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            FCMediaPreviewHeader(sourceUrl: entry.sourceUrl, entry: entry)

            if endpoint == .article {
                FCArticleResultContent(response: response, sourceUrl: entry.sourceUrl, compact: !showFullReport)
            } else {
                FCVideoResultContent(response: response, sourceUrl: entry.sourceUrl, endpoint: endpoint, compact: !showFullReport)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.28)) {
                    showFullReport.toggle()
                }
                Haptics.selection()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showFullReport ? "chevron.up" : "chevron.down")
                    Text(showFullReport ? Loc.t(.hideFullReport) : Loc.t(.showFullReport))
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundStyle(FCTheme.accentLight)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(FCTheme.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
            }
            .buttonStyle(.plain)

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
    var compact: Bool = false

    private var analysis: AnalysisResult? { response.analysis }
    private var score: Int { analysis?.credibilityScore ?? 0 }
    private var level: ScoreLevel { .from(score: score) }

    @State private var pop = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            scoreRow
            if !compact {
                FCAnalysisBadgesRow(response: response)
                FCAnalysisDetailSections(response: response, includeTranscript: false, scoreReasoningInHero: false)
            } else if let summary = analysis?.summary, !summary.isEmpty {
                Text(summary.fcDisplay)
                    .font(.system(size: 15))
                    .foregroundStyle(FCTheme.textSecondary)
                    .lineSpacing(4)
                    .lineLimit(4)
            }
        }
    }

    private var scoreRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(level.background)
                        .overlay(Circle().stroke(level.border, lineWidth: 2))
                    Text("\(score)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(level.color)
                }
                .frame(width: 64, height: 64)
                .scaleEffect(pop ? 1 : 0.55)
                .opacity(pop ? 1 : 0)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1)) {
                        pop = true
                    }
                }

                if let verdict = analysis?.verdict {
                    Text(verdict.fcDisplay)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FCTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(scoreHint)
                .font(.subheadline)
                .foregroundStyle(FCTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    FCMetricTile(
                        icon: "theatermasks.fill",
                        label: Loc.t(.manipulation),
                        value: analysis?.manipulationScore ?? 0,
                        inverted: true,
                        tint: FCTheme.orange
                    )
                    FCMetricTile(
                        icon: "shield.fill",
                        label: Loc.t(.confidence),
                        value: analysis?.confidenceScore ?? 0,
                        inverted: false,
                        tint: FCTheme.green
                    )
                }
            }
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

    private var scoreHint: String {
        if score >= 70 { return Loc.t(.scoreHintHigh) }
        if score >= 40 { return Loc.t(.scoreHintMid) }
        return Loc.t(.scoreHintLow)
    }
}

// MARK: - Video result (SVG-style ring)

struct FCVideoResultContent: View {
    let response: AnalysisResponse
    let sourceUrl: String
    let endpoint: AnalyzeEndpoint
    var compact: Bool = false

    private var analysis: AnalysisResult? { response.analysis }
    private var score: Int { analysis?.credibilityScore ?? 0 }
    private var level: ScoreLevel { .videoFrom(score: score) }

    @State private var ringProgress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            scoreHero
            miniStats
            if !compact {
                FCAnalysisBadgesRow(response: response)
                FCAnalysisDetailSections(response: response, includeTranscript: true, scoreReasoningInHero: true)
            } else if let summary = analysis?.summary ?? analysis?.scoreReasoning, !summary.isEmpty {
                Text(summary.fcDisplay)
                    .font(.system(size: 15))
                    .foregroundStyle(FCTheme.textSecondary)
                    .lineSpacing(4)
                    .lineLimit(4)
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
                        .fixedSize(horizontal: false, vertical: true)
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
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                videoMiniStat(
                    value: "\(analysis?.manipulationScore ?? 0)%",
                    label: Loc.t(.manipulation),
                    icon: "theatermasks.fill",
                    color: FCTheme.scoreColor(for: 100 - (analysis?.manipulationScore ?? 0))
                )
                videoMiniStat(
                    value: "\(analysis?.confidenceScore ?? 0)%",
                    label: Loc.t(.confidenceAI),
                    icon: "shield.fill",
                    color: FCTheme.accentLight
                )
                videoMiniStat(
                    value: "\(analysis?.claims?.count ?? 0)",
                    label: Loc.t(.claimsCount),
                    icon: "list.bullet.rectangle.fill",
                    color: FCTheme.textPrimary
                )
            }
        }
        .padding(.vertical, 12)
        .background(FCTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    private func videoMiniStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color.opacity(0.85))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(FCTheme.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
}

// MARK: - Shared report sections (article + video)

struct FCAnalysisBadgesRow: View {
    let response: AnalysisResponse

    private var analysis: AnalysisResult? { response.analysis }

    var body: some View {
        let model = analysis?.modelUsed ?? response.modelUsed
        let grounded = analysis?.pipelineMetadata?.groundedSearch == true
        let contentType = analysis?.contentType
        let language = analysis?.detectedLanguage
        let categories = analysis?.categories ?? []
        let sourcesUsed = analysis?.pipelineMetadata?.sourcesUsed ?? []
        let hasBadges = model != nil || grounded || contentType != nil || language != nil
            || !categories.isEmpty || !sourcesUsed.isEmpty
            || (analysis?.pipelineMetadata?.totalAgentCalls ?? 0) > 0

        if hasBadges {
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
                ForEach(categories, id: \.self) { category in
                    FCResultBadge(icon: "folder.fill", text: category.fcDisplay, tint: FCTheme.orange)
                }
                ForEach(sourcesUsed.prefix(6), id: \.self) { source in
                    FCResultBadge(icon: "link", text: source.fcDisplay, tint: FCTheme.accentLight)
                }
            }
        }
    }
}

struct FCAnalysisDetailSections: View {
    let response: AnalysisResponse
    var includeTranscript: Bool = true
    var scoreReasoningInHero: Bool = false

    private var analysis: AnalysisResult? { response.analysis }

    private var manipulationRows: [ManipulationSignal] {
        if let signals = analysis?.manipulationSignals, !signals.isEmpty { return signals }
        return (analysis?.manipulationTechniques ?? []).map {
            ManipulationSignal(label: $0.technique, severity: $0.severity, detail: $0.evidence)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let summary = analysis?.summary, !summary.isEmpty {
                Text(summary.fcDisplay)
                    .font(.system(size: 15))
                    .foregroundStyle(FCTheme.textSecondary)
                    .lineSpacing(4)
                    .padding(.vertical, 8)
                    .overlay(Rectangle().frame(height: 1).foregroundStyle(FCTheme.border), alignment: .bottom)
            }

            if !scoreReasoningInHero, let reasoning = analysis?.scoreReasoning, !reasoning.isEmpty {
                FCSectionCard(title: Loc.t(.scoreReasoningLabel), icon: "chart.bar.fill", tint: FCTheme.accentLight) {
                    Text(reasoning.fcDisplay)
                        .font(.system(size: 14))
                        .foregroundStyle(FCTheme.textSecondary)
                        .lineSpacing(4)
                }
            }

            if let es = analysis?.evidenceSummary, (es.totalSources ?? 0) > 0 {
                FCEvidenceSummaryCard(summary: es)
            }

            if let mbfc = analysis?.mbfcResult, mbfc.domain != nil {
                FCMbfcCard(result: mbfc)
            }

            if let assessment = analysis?.assessmentText {
                FCAnalysisSectionLabel(title: Loc.t(.secAnalysis))
                Text(assessment.fcDisplay)
                    .font(.system(size: 15))
                    .foregroundStyle(FCTheme.textSecondary)
                    .lineSpacing(5)
            }

            if let claims = analysis?.claims, !claims.isEmpty {
                FCAnalysisSectionLabel(title: Loc.t(.secClaimsEvidence), count: claims.count)
                VStack(spacing: 10) {
                    ForEach(claims) { claim in
                        FCWebClaimCard(claim: claim)
                    }
                }
            }

            if let sources = analysis?.allGroundingSources, !sources.isEmpty {
                FCAnalysisSectionLabel(title: Loc.t(.secAllSources), count: sources.count)
                FCAllGroundingSourcesCard(sources: sources)
            }

            if let indicators = analysis?.indicators, !indicators.isEmpty {
                FCAnalysisSectionLabel(title: Loc.t(.secIndicators))
                VStack(spacing: 8) {
                    ForEach(indicators) { indicator in
                        FCIndicatorRow(indicator: indicator)
                    }
                }
            }

            if !manipulationRows.isEmpty {
                FCAnalysisSectionLabel(title: Loc.t(.secManipulation))
                VStack(spacing: 8) {
                    ForEach(manipulationRows) { signal in
                        FCManipulationRow(signal: signal)
                    }
                }
            }

            if let source = analysis?.sourceAssessment,
               source.transparency != nil || source.strengths != nil || source.weaknesses != nil {
                FCAnalysisSectionLabel(title: Loc.t(.secSourceAssessment))
                FCSourceAssessmentCard(assessment: source)
            }

            if let missing = analysis?.missingContext, !missing.isEmpty {
                FCAnalysisSectionLabel(title: Loc.t(.secMissingContext))
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
                FCAnalysisSectionLabel(title: Loc.t(.secCorrection))
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

            if includeTranscript, let transcript = response.transcript, !transcript.isEmpty {
                DisclosureGroup(Loc.t(.transcript)) {
                    Text(transcript.fcDisplay)
                        .font(.caption)
                        .foregroundStyle(FCTheme.textSecondary)
                        .padding(.top, 6)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FCTheme.textPrimary)
            }

            if let lang = response.transcriptLanguage, !lang.isEmpty {
                Text("\(Loc.t(.transcript)) · \(lang.uppercased())")
                    .font(.caption2)
                    .foregroundStyle(FCTheme.textMuted)
            }

            resultMeta
        }
    }

    @ViewBuilder
    private var resultMeta: some View {
        HStack(spacing: 12) {
            if let ms = response.analysisTimeMs {
                Label(String(format: "%.1fs", Double(ms) / 1000), systemImage: "stopwatch")
            }
            if response.cached == true {
                Label("cached", systemImage: "bolt.fill")
            }
            if let duration = response.audioDuration {
                Label(String(format: "%.0fs", duration), systemImage: "waveform")
            }
            if let model = response.modelUsed ?? analysis?.modelUsed {
                Label(model, systemImage: "cpu")
            }
        }
        .font(.caption)
        .foregroundStyle(FCTheme.textMuted)
        .padding(.top, 12)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(FCTheme.border), alignment: .top)
    }
}

struct FCAnalysisSectionLabel: View {
    let title: String
    var count: Int? = nil

    var body: some View {
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
}

struct FCSectionCard<Content: View>: View {
    let title: String
    let icon: String
    var tint: Color = FCTheme.accentLight
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(FCTheme.textPrimary)
            }
            content
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
}

struct FCAllGroundingSourcesCard: View {
    let sources: [GroundingSource]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(sources) { source in
                if let url = source.url, let link = URL(string: url) {
                    Link(destination: link) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "link.circle.fill")
                                .font(.body)
                                .foregroundStyle(FCTheme.accentLight)
                            VStack(alignment: .leading, spacing: 2) {
                                Text((source.title ?? url).fcDisplay)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(FCTheme.textPrimary)
                                    .multilineTextAlignment(.leading)
                                Text(url)
                                    .font(.caption2)
                                    .foregroundStyle(FCTheme.textMuted)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                                .foregroundStyle(FCTheme.textMuted)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.bgSecondary.opacity(0.35))
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
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
                    FCClaimTagsRow(claim: claim)

                    if let reason = claim.reason {
                        Text(reason.fcDisplay)
                            .font(.caption)
                            .foregroundStyle(FCTheme.textMuted)
                    }
                    if let summary = claim.researchSummary {
                        Text(summary.fcDisplay)
                            .font(.caption)
                            .foregroundStyle(FCTheme.textSecondary)
                            .lineSpacing(3)
                    }
                    if let findings = claim.keyFindings, !findings.isEmpty {
                        Text(Loc.t(.keyFindingsLabel))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(FCTheme.textMuted)
                            .textCase(.uppercase)
                        ForEach(Array(findings.enumerated()), id: \.offset) { _, finding in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .foregroundStyle(FCTheme.accentLight)
                                Text(finding.fcDisplay)
                                    .font(.caption)
                                    .foregroundStyle(FCTheme.textSecondary)
                            }
                        }
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

struct FCClaimTagsRow: View {
    let claim: Claim

    var body: some View {
        let tags = claimTags
        if !tags.isEmpty {
            FCFlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag.fcDisplay)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(FCTheme.accentLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(FCTheme.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var claimTags: [String] {
        var tags: [String] = []
        if let type = claim.type, !type.isEmpty { tags.append(type) }
        if let v = claim.verifiability, !v.isEmpty { tags.append(v) }
        if let s = claim.supportLevel, !s.isEmpty { tags.append(s) }
        if let verdict = claim.verdict ?? claim.status, !verdict.isEmpty { tags.append(verdict) }
        return tags
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
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(indicatorColor.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: indicatorIcon)
                    .font(.body)
                    .foregroundStyle(indicatorColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(indicator.label.fcDisplay)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FCTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let status = indicator.status, !status.isEmpty {
                        Text(status.fcDisplay.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(indicatorColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(indicatorColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                if let detail = indicator.detail, !detail.isEmpty {
                    Text(detail.fcDisplay)
                        .font(.caption)
                        .foregroundStyle(FCTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
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

    private var indicatorIcon: String {
        switch indicator.status?.lowercased() {
        case "positive": return "checkmark.circle.fill"
        case "negative": return "xmark.circle.fill"
        default: return "exclamationmark.circle.fill"
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

    private var techniqueIcon: String { FCTextFormat.manipulationIcon(signal.label) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(severityColor.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: techniqueIcon)
                    .font(.body)
                    .foregroundStyle(severityColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(signal.label.fcManipulationLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FCTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let severity = signal.severity, !severity.isEmpty {
                        Text(severityLabel(severity))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(severityColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(severityColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                if let detail = signal.detail, !detail.isEmpty {
                    Text(detail.fcDisplay)
                        .font(.caption)
                        .foregroundStyle(FCTheme.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                .stroke(severityColor.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    private var severityColor: Color {
        switch signal.severity?.lowercased() {
        case "high": return FCTheme.red
        case "medium": return FCTheme.orange
        default: return FCTheme.orange.opacity(0.85)
        }
    }

    private func severityLabel(_ severity: String) -> String {
        severity.uppercased()
    }
}

// MARK: - Metric tile (score hero)

struct FCMetricTile: View {
    let icon: String
    let label: String
    let value: Int
    var inverted: Bool = false
    var tint: Color = FCTheme.accentLight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(tint)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FCTheme.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Text("\(value)/100")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(FCTheme.textPrimary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.bgSecondary.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    private var barColor: Color {
        if inverted {
            if value > 60 { return FCTheme.red }
            if value > 30 { return FCTheme.orange }
            return FCTheme.green
        }
        if value >= 70 { return FCTheme.green }
        if value >= 40 { return FCTheme.orange }
        return FCTheme.red
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
            Text(value ?? "-")
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
