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

    var displayName: String {
        switch self {
        case .transcribing: return "Transkrypcja"
        case .extracting: return "Ekstrakcja"
        case .researching: return "Research"
        case .judging: return "Werdykt"
        case .scraping: return "Pobieranie strony"
        case .analyzing: return "Analiza"
        }
    }

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
    let claims: [Claim]?
    let indicators: [Indicator]?
    let manipulationSignals: [ManipulationSignal]?
    let sourceAssessment: SourceAssessment?
    let missingContext: [String]?
    let correctedInfo: String?
    let categories: [String]?
    let detectedLanguage: String?
    let contentType: String?
    let scoreReasoning: String?
    let evidenceSummary: EvidenceSummary?
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
    let confirming: Int?
    let contradicting: Int?
    let neutral: Int?
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
