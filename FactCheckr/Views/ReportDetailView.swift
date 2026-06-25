import SwiftUI

struct ReportDetailView: View {
    let response: AnalysisResponse
    var sourceUrl: String?

    private var analysis: AnalysisResult? { response.analysis }
    private var score: Int? { analysis?.credibilityScore }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let url = sourceUrl ?? response.url, let link = URL(string: url) {
                Link(destination: link) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text(url)
                            .font(.caption)
                            .lineLimit(2)
                    }
                    .foregroundStyle(FCTheme.accentLight)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let score {
                        FCReportChip(label: Loc.t(.shareCredibility), value: "\(score)/100")
                    }
                    if let m = analysis?.manipulationScore {
                        FCReportChip(label: Loc.t(.manipulation), value: "\(m)/100")
                    }
                    if let c = analysis?.confidenceScore {
                        FCReportChip(label: Loc.t(.confidence), value: "\(c)/100")
                    }
                }
            }

            if let verdict = analysis?.verdict {
                HStack(spacing: 8) {
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(FCTheme.scoreColor(for: score))
                    Text(String(format: Loc.t(.verdictFmt), verdict))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FCTheme.textPrimary)
                }
            }

            if let summary = analysis?.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(FCTheme.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FCTheme.bgSecondary.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous))
            }

            if let assessment = analysis?.assessmentText {
                VStack(alignment: .leading, spacing: 8) {
                    FCSectionTitle(icon: "chart.bar.doc.horizontal", title: Loc.t(.secAnalysis))
                    Text(assessment)
                        .font(.caption)
                        .foregroundStyle(FCTheme.textSecondary)
                }
            }

            if let claims = analysis?.claims, !claims.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    FCSectionTitle(icon: "list.bullet.rectangle", title: Loc.t(.keyClaims))
                    ForEach(claims.prefix(5)) { claim in
                        claimRow(claim)
                    }
                }
            }

            if let indicators = analysis?.indicators, !indicators.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    FCSectionTitle(icon: "waveform.path.ecg", title: Loc.t(.secIndicators))
                    ForEach(indicators) { ind in
                        indicatorRow(ind)
                    }
                }
            }

            if let signals = analysis?.manipulationSignals, !signals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    FCSectionTitle(icon: "theatermasks.fill", title: Loc.t(.manipulationSignals))
                    ForEach(signals) { sig in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(sig.severity == "high" ? FCTheme.red : FCTheme.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sig.label)
                                    .font(.caption.weight(.semibold))
                                if let d = sig.detail {
                                    Text(d).font(.caption2).foregroundStyle(FCTheme.textMuted)
                                }
                            }
                        }
                    }
                }
            }

            if let transcript = response.transcript, !transcript.isEmpty {
                DisclosureGroup(Loc.t(.transcript)) {
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

    private func claimRow(_ claim: Claim) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                claimIcon(claim.status)
                Text(claim.claim)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(FCTheme.textPrimary)
            }
            if let reason = claim.reason {
                Text(reason)
                    .font(.caption2)
                    .foregroundStyle(FCTheme.textMuted)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.bgSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous))
    }

    private func claimIcon(_ status: String?) -> some View {
        let (icon, color) = claimIconMeta(status)
        return Image(systemName: icon)
            .font(.caption)
            .foregroundStyle(color)
            .padding(.top, 2)
    }

    private func claimIconMeta(_ status: String?) -> (String, Color) {
        switch status?.lowercased() {
        case "likely credible": return ("checkmark.circle.fill", FCTheme.green)
        case "likely false", "likely misleading": return ("xmark.circle.fill", FCTheme.red)
        default: return ("questionmark.circle.fill", FCTheme.orange)
        }
    }

    private func indicatorRow(_ ind: Indicator) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(indicatorColor(ind.status))
                .frame(width: 6, height: 6)
                .padding(.top, 5)
            Text("\(ind.label): \(ind.detail ?? "")")
                .font(.caption)
                .foregroundStyle(FCTheme.textSecondary)
        }
    }

    private func indicatorColor(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "positive": return FCTheme.green
        case "negative": return FCTheme.red
        default: return FCTheme.orange
        }
    }
}
