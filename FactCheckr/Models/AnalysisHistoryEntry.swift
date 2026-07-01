import Foundation

enum ThreatLevel: String, Codable, CaseIterable {
    case none
    case medium
    case high

    var label: String {
        switch self {
        case .none: return "Wiarygodne"
        case .medium: return "Podejrzane"
        case .high: return "Wysokie ryzyko"
        }
    }

    var localizedLabel: String {
        switch self {
        case .none: return Loc.t(.threatCredible)
        case .medium: return Loc.t(.threatSuspicious)
        case .high: return Loc.t(.threatHighRisk)
        }
    }

    static func from(score: Int?) -> ThreatLevel {
        guard let score else { return .medium }
        if score >= 70 { return .none }
        if score >= 50 { return .medium }
        return .high
    }
}

struct AnalysisHistoryEntry: Identifiable, Codable {
    let id: String
    let sourceUrl: String
    let title: String
    let type: String
    let threatLevel: ThreatLevel
    let overallScore: Int
    let verdict: String?
    let createdAt: Date
    let response: AnalysisResponse

    init(sourceUrl: String, endpoint: AnalyzeEndpoint, response: AnalysisResponse) {
        id = UUID().uuidString
        self.sourceUrl = sourceUrl
        self.type = endpoint.label
        let score = response.analysis?.credibilityScore ?? 0
        overallScore = score
        threatLevel = ThreatLevel.from(score: score)
        verdict = response.analysis?.verdict
        title = MediaPreviewHelper.historyDisplayTitle(sourceUrl: sourceUrl, response: response)
        createdAt = Date()
        self.response = response
    }

    init(
        id: String,
        sourceUrl: String,
        title: String,
        type: String,
        threatLevel: ThreatLevel,
        overallScore: Int,
        verdict: String?,
        createdAt: Date,
        response: AnalysisResponse
    ) {
        self.id = id
        self.sourceUrl = sourceUrl
        self.title = title
        self.type = type
        self.threatLevel = threatLevel
        self.overallScore = overallScore
        self.verdict = verdict
        self.createdAt = createdAt
        self.response = response
    }
}

struct UserProfile: Codable {
    let uid: String
    let email: String?
    let displayName: String?
    let freeTokens: Int
    let totalAnalyses: Int
    let plan: String
    let testerStatus: String?
    let monthlyAnalysisLimit: Int?
    let monthlyAnalysisMonth: String?
    let monthlyAnalysesUsed: Int?

    var isTester: Bool {
        plan.lowercased() == "tester" || testerStatus == "approved"
    }

    static let guest = UserProfile(
        uid: "",
        email: nil,
        displayName: nil,
        freeTokens: 0,
        totalAnalyses: 0,
        plan: "guest",
        testerStatus: nil,
        monthlyAnalysisLimit: nil,
        monthlyAnalysisMonth: nil,
        monthlyAnalysesUsed: nil
    )
}
