import Foundation
import SwiftUI

enum VerdictCategory: String {
    case trueFact = "Prawda"
    case falseFact = "Fałsz"
    case partial = "Częściowo"
    case insufficient = "Brak danych"

    var localizedLabel: String {
        switch self {
        case .trueFact: return Loc.t(.verdictTrue)
        case .falseFact: return Loc.t(.verdictFalse)
        case .partial: return Loc.t(.verdictPartial)
        case .insufficient: return Loc.t(.verdictInsufficient)
        }
    }

    var color: Color {
        switch self {
        case .trueFact: return FCTheme.green
        case .falseFact: return FCTheme.red
        case .partial: return FCTheme.orange
        case .insufficient: return FCTheme.textMuted
        }
    }

    static func from(analysis: AnalysisResult?) -> VerdictCategory {
        guard let analysis else { return .insufficient }

        let verdict = analysis.verdict?.lowercased() ?? ""
        if verdict.contains("true") || verdict.contains("prawda") || verdict.contains("credible") {
            return .trueFact
        }
        if verdict.contains("false") || verdict.contains("fałsz") || verdict.contains("misleading") {
            return .falseFact
        }
        if verdict.contains("partial") || verdict.contains("części") || verdict.contains("mixed") {
            return .partial
        }

        guard let score = analysis.credibilityScore else { return .insufficient }
        if score >= 70 { return .trueFact }
        if score >= 45 { return .partial }
        return .falseFact
    }
}

extension AnalysisHistoryEntry: Hashable {
    static func == (lhs: AnalysisHistoryEntry, rhs: AnalysisHistoryEntry) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
