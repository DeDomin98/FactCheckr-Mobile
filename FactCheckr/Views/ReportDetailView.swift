import SwiftUI

struct ReportDetailView: View {
    let response: AnalysisResponse
    var sourceUrl: String?

    private var analysis: AnalysisResult? { response.analysis }
    private var score: Int? { analysis?.credibilityScore }
    private var isVideo: Bool {
        guard let url = sourceUrl ?? response.url else { return false }
        let endpoint = pickEndpoint(url)
        return endpoint == .youtube || endpoint == .tiktok
    }

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

            FCAnalysisBadgesRow(response: response)
            FCAnalysisDetailSections(
                response: response,
                includeTranscript: isVideo,
                scoreReasoningInHero: false
            )
        }
    }
}
