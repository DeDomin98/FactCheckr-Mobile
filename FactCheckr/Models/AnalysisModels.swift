import Foundation

struct PowSolution: Encodable {
    let challenge: String
    let signature: String
    let nonce: Int
}

enum AnalysisStage: String, CaseIterable {
    case transcribing
    case extracting
    case researching
    case judging
    case scraping
    case analyzing

    var localizedDisplayName: String {
        switch self {
        case .transcribing: return Loc.t(.stageTranscribing)
        case .extracting: return Loc.t(.stageExtracting)
        case .researching: return Loc.t(.stageResearching)
        case .judging: return Loc.t(.stageJudging)
        case .scraping: return Loc.t(.stageScraping)
        case .analyzing: return Loc.t(.stageAnalyzing)
        }
    }

    var displayName: String { localizedDisplayName }

    var order: Int {
        switch self {
        case .transcribing: return 0
        case .extracting: return 1
        case .researching: return 2
        case .judging: return 3
        case .scraping: return 1
        case .analyzing: return 2
        }
    }
}

struct APIError: LocalizedError {
    let message: String
    let status: Int?

    var errorDescription: String? { message }
}

struct AnalysisResponse: Codable {
    let success: Bool?
    let url: String?
    let pageTitle: String?
    let transcript: String?
    let transcriptLanguage: String?
    let audioDuration: Double?
    let analysisTimeMs: Int?
    let cached: Bool?
    let modelUsed: String?
    let analysis: AnalysisResult?
}

struct AnalysisResult: Codable {
    let credibilityScore: Int?
    let manipulationScore: Int?
    let confidenceScore: Int?
    let verdict: String?
    let summary: String?
    let overallAssessment: String?
    var justification: String? = nil
    let claims: [Claim]?
    let indicators: [Indicator]?
    let manipulationSignals: [ManipulationSignal]?
    var manipulationTechniques: [ManipulationTechnique]? = nil
    let sourceAssessment: SourceAssessment?
    let missingContext: [String]?
    let correctedInfo: String?
    let categories: [String]?
    let detectedLanguage: String?
    let contentType: String?
    var modelUsed: String? = nil
    let scoreReasoning: String?
    let evidenceSummary: EvidenceSummary?
    var pipelineMetadata: PipelineMetadata? = nil
    var mbfcResult: MbfcResult? = nil
    var allGroundingSources: [GroundingSource]? = nil

    /// The dashboard shows `overallAssessment` and falls back to `justification`.
    var assessmentText: String? {
        let text = overallAssessment ?? justification
        guard let text, !text.isEmpty else { return nil }
        return text
    }
}

struct PipelineMetadata: Codable {
    let totalAgentCalls: Int?
    let groundedSearch: Bool?
    let flowVersion: String?
    let sourcesUsed: [String]?
}

struct MbfcResult: Codable {
    let domain: String?
    let biasLabel: String?
    let factualLabel: String?
    let credibilityLabel: String?
    let isQuestionable: Bool?
}

struct ManipulationTechnique: Codable, Identifiable {
    var id: String { technique }
    let technique: String
    let severity: String?
    let evidence: String?
}

struct Claim: Codable, Identifiable {
    var id: String { claim }
    let claim: String
    let type: String?
    let verifiability: String?
    let supportLevel: String?
    let status: String?
    let reason: String?
    let verdict: String?
    let researchSummary: String?
    let keyFindings: [String]?
    let sourceBreakdown: SourceBreakdown?
    let groundingSources: [GroundingSource]?
}

struct SourceBreakdown: Codable {
    let confirming: Int?
    let contradicting: Int?
    let neutral: Int?

    var confirmingCount: Int { confirming ?? 0 }
    var contradictingCount: Int { contradicting ?? 0 }
    var neutralCount: Int { neutral ?? 0 }
    var total: Int { confirmingCount + contradictingCount + neutralCount }
}

struct GroundingSource: Codable, Identifiable {
    var id: String { url ?? title ?? UUID().uuidString }
    let title: String?
    let url: String?
}

struct EvidenceSummary: Codable {
    let totalClaims: Int?
    let totalSources: Int?
    let confirming: Int?
    let contradicting: Int?
    let neutral: Int?

    var confirmingCount: Int { confirming ?? 0 }
    var contradictingCount: Int { contradicting ?? 0 }
    var neutralCount: Int { neutral ?? 0 }
    var total: Int { confirmingCount + contradictingCount + neutralCount }
}

struct Indicator: Codable, Identifiable {
    var id: String { label }
    let label: String
    let status: String?
    let detail: String?
}

struct ManipulationSignal: Codable, Identifiable {
    var id: String { label }
    let label: String
    let severity: String?
    let detail: String?
}

struct SourceAssessment: Codable {
    let transparency: String?
    let strengths: String?
    let weaknesses: String?
}
