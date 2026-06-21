import SwiftUI

struct FCAnalysisResultView: View {
    let entry: AnalysisHistoryEntry
    var onCheckAnother: (() -> Void)?

    private var response: AnalysisResponse { entry.response }
    private var analysis: AnalysisResult? { response.analysis }
    private var endpoint: AnalyzeEndpoint { pickEndpoint(entry.sourceUrl) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if endpoint == .article {
                FCArticleResultContent(response: response, sourceUrl: entry.sourceUrl)
            } else {
                FCVideoResultContent(response: response, sourceUrl: entry.sourceUrl, endpoint: endpoint)
            }

            if let onCheckAnother {
                FCPrimaryButton(title: "Sprawdź kolejny", icon: "plus.magnifyingglass", action: onCheckAnother)
            }
        }
        .fcFadeInUp()
    }
}

// MARK: - Article result (score circle + claims & evidence)

struct FCArticleResultContent: View {
    let response: AnalysisResponse
    let sourceUrl: String

    private var analysis: AnalysisResult? { response.analysis }
    private var score: Int { analysis?.credibilityScore ?? 0 }
    private var level: ScoreLevel { .from(score: score) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            scoreRow
            if let summary = analysis?.summary {
                Text(summary)
                    .font(.system(size: 15))
                    .foregroundStyle(FCTheme.textSecondary)
                    .lineSpacing(4)
                    .padding(.vertical, 8)
                    .overlay(Rectangle().frame(height: 1).foregroundStyle(FCTheme.border), alignment: .bottom)
            }
            if let assessment = analysis?.overallAssessment, !assessment.isEmpty {
                sectionLabel("Analiza")
                Text(assessment)
                    .font(.system(size: 15))
                    .foregroundStyle(FCTheme.textSecondary)
                    .lineSpacing(5)
            }
            if let claims = analysis?.claims, !claims.isEmpty {
                sectionLabel("Twierdzenia i dowody", count: claims.count)
                VStack(spacing: 10) {
                    ForEach(claims) { claim in
                        FCWebClaimCard(claim: claim)
                    }
                }
            }
            if let indicators = analysis?.indicators, !indicators.isEmpty {
                sectionLabel("Wskaźniki")
                VStack(spacing: 8) {
                    ForEach(indicators) { indicator in
                        FCIndicatorRow(indicator: indicator)
                    }
                }
            }
            if let signals = analysis?.manipulationSignals, !signals.isEmpty {
                sectionLabel("Techniki manipulacji")
                VStack(spacing: 8) {
                    ForEach(signals) { signal in
                        FCManipulationRow(signal: signal)
                    }
                }
            }
            resultMeta
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

                VStack(alignment: .leading, spacing: 6) {
                    if let verdict = analysis?.verdict {
                        Text(verdict)
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
                miniScore(label: "Manipulacja", icon: "theatermasks.fill", value: analysis?.manipulationScore ?? 0, inverted: true)
                miniScore(label: "Pewność", icon: "shield.fill", value: analysis?.confidenceScore ?? 0, inverted: false)
            }
            .frame(minWidth: 180)
        }
    }

    private var scoreHint: String {
        if score >= 70 {
            return "Wysoki wynik — większość twierdzeń potwierdzona przez niezależne źródła."
        }
        if score >= 40 {
            return "Średni wynik — mieszane dowody: część twierdzeń potwierdzona, inne podważone lub niezweryfikowane."
        }
        return "Niski wynik — wiele twierdzeń zaprzeczonych przez niezależne źródła."
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

    @State private var ringProgress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            scoreHero
            miniStats
            if let summary = analysis?.summary {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Podsumowanie")
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(FCTheme.textSecondary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FCTheme.bgSecondary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
                }
            }
            if let claims = analysis?.claims, !claims.isEmpty {
                sectionLabel("Twierdzenia", count: claims.count)
                VStack(spacing: 10) {
                    ForEach(claims) { claim in
                        FCVideoClaimCard(claim: claim)
                    }
                }
            }
            if let transcript = response.transcript, !transcript.isEmpty {
                DisclosureGroup("Transkrypcja") {
                    Text(transcript)
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
                    Text(verdict)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FCTheme.textPrimary)
                }
                if let reasoning = analysis?.scoreReasoning {
                    Text(reasoning)
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
                label: "Manipulacja",
                color: FCTheme.scoreColor(for: 100 - (analysis?.manipulationScore ?? 0))
            )
            videoMiniStat(
                value: "\(analysis?.confidenceScore ?? 0)%",
                label: "Pewność AI",
                color: FCTheme.accentLight
            )
            videoMiniStat(
                value: "\(analysis?.claims?.count ?? 0)",
                label: "Twierdzenia",
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
                    Text(claim.claim)
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
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(FCTheme.textMuted)
                    }
                    if let summary = claim.researchSummary {
                        Text(summary)
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
                                        Text(source.title ?? url)
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
                    evidenceCount("\(breakdown.confirmingCount) potwierdza", color: FCTheme.green, icon: "checkmark.circle.fill")
                }
                if breakdown.contradictingCount > 0 {
                    evidenceCount("\(breakdown.contradictingCount) zaprzecza", color: FCTheme.red, icon: "xmark.circle.fill")
                }
                if breakdown.neutralCount > 0 {
                    evidenceCount("\(breakdown.neutralCount) kontekst", color: FCTheme.textMuted, icon: "info.circle.fill")
                }
                if breakdown.total == 0 {
                    evidenceCount("Brak źródeł", color: FCTheme.textMuted, icon: "questionmark.circle")
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
                Text(claim.claim)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FCTheme.textPrimary)
            }
            if let reason = claim.reason {
                Text(reason)
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
                Text(indicator.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(FCTheme.textPrimary)
                Text(": \(indicator.detail ?? "")")
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
                Text(signal.label)
                    .font(.caption.weight(.semibold))
                if let detail = signal.detail {
                    Text(detail).font(.caption2).foregroundStyle(FCTheme.textMuted)
                }
            }
        }
    }
}
