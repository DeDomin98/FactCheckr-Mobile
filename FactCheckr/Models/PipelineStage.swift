import Foundation
import SwiftUI

enum PipelineStageId: String, CaseIterable, Hashable {
    case pow
    case scraping
    case transcribing
    case extracting
    case researching
    case judging
    case analyzing

    func label(endpoint: AnalyzeEndpoint, isVideoSecurityLabel: Bool = false) -> String {
        switch self {
        case .pow:
            return isVideoSecurityLabel ? Loc.t(.pipePowVideo) : Loc.t(.pipePow)
        case .scraping:
            return Loc.t(.pipeScraping)
        case .transcribing:
            return endpoint == .youtube ? Loc.t(.pipeTranscribingYT) : Loc.t(.pipeTranscribingAudio)
        case .extracting:
            return endpoint == .article ? Loc.t(.pipeExtractArticle) : Loc.t(.pipeExtractVideo)
        case .researching:
            return endpoint == .article ? Loc.t(.pipeResearchArticle) : Loc.t(.pipeResearchVideo)
        case .judging:
            return endpoint == .article ? Loc.t(.pipeJudgeArticle) : Loc.t(.pipeJudgeVideo)
        case .analyzing:
            return Loc.t(.pipeAnalyzing)
        }
    }

    var icon: String {
        switch self {
        case .pow: return "shield.fill"
        case .scraping: return "doc.text.fill"
        case .transcribing: return "mic.fill"
        case .extracting: return "text.magnifyingglass"
        case .researching: return "globe"
        case .judging: return "hammer.fill"
        case .analyzing: return "brain.head.profile"
        }
    }

    static func defaultPipeline(for endpoint: AnalyzeEndpoint) -> [PipelineStageId] {
        switch endpoint {
        case .article:
            return [.pow, .scraping, .extracting, .researching, .judging]
        case .youtube, .tiktok:
            return [.pow, .transcribing, .extracting, .researching, .judging]
        }
    }
}

enum PipelineStageStatus: Equatable {
    case pending
    case active
    case done
    case error
}

struct PipelineStageItem: Identifiable, Equatable {
    let id: PipelineStageId
    var status: PipelineStageStatus
    var startedAt: Date?
    var finishedAt: Date?
}

enum ScoreLevel {
    case credible
    case suspicious
    case fake

    static func from(score: Int) -> ScoreLevel {
        if score >= 70 { return .credible }
        if score >= 40 { return .suspicious }
        return .fake
    }

    static func videoFrom(score: Int) -> ScoreLevel {
        if score >= 75 { return .credible }
        if score >= 50 { return .suspicious }
        return .fake
    }

    var color: Color {
        switch self {
        case .credible: return FCTheme.green
        case .suspicious: return FCTheme.orange
        case .fake: return FCTheme.red
        }
    }

    var background: Color {
        switch self {
        case .credible: return FCTheme.green.opacity(0.15)
        case .suspicious: return FCTheme.orange.opacity(0.15)
        case .fake: return FCTheme.red.opacity(0.15)
        }
    }

    var border: Color {
        switch self {
        case .credible: return FCTheme.green.opacity(0.3)
        case .suspicious: return FCTheme.orange.opacity(0.3)
        case .fake: return FCTheme.red.opacity(0.3)
        }
    }

    var localizedVideoLabel: String {
        switch self {
        case .credible: return Loc.t(.scoreCredible)
        case .suspicious: return Loc.t(.scorePartiallyCredible)
        case .fake: return Loc.t(.scoreDoubtful)
        }
    }

    var videoLabel: String { localizedVideoLabel }
}

extension PipelineStageTracker {
    static func markStages(
        _ stages: inout [PipelineStageItem],
        active id: PipelineStageId
    ) {
        let now = Date()
        for index in stages.indices {
            if stages[index].id == id {
                if stages[index].status != .done {
                    stages[index].status = .active
                    if stages[index].startedAt == nil { stages[index].startedAt = now }
                }
            } else if stages[index].status == .active {
                stages[index].status = .done
                stages[index].finishedAt = now
            }
        }
    }

    static func completeBefore(
        _ stages: inout [PipelineStageItem],
        id: PipelineStageId
    ) {
        let now = Date()
        for index in stages.indices {
            if stages[index].id == id { break }
            if stages[index].status != .done && stages[index].status != .error {
                stages[index].status = .done
                stages[index].finishedAt = stages[index].finishedAt ?? now
            }
        }
    }
}

enum PipelineStageTracker {
    static func applyProgress(
        stage: AnalysisStage,
        endpoint: AnalyzeEndpoint,
        stages: inout [PipelineStageItem]
    ) {
        switch endpoint {
        case .article:
            switch stage {
            case .scraping:
                markStages(&stages, active: .scraping)
            case .extracting:
                completeBefore(&stages, id: .extracting)
                markStages(&stages, active: .extracting)
            case .researching:
                completeBefore(&stages, id: .researching)
                markStages(&stages, active: .researching)
            case .judging:
                completeBefore(&stages, id: .judging)
                markStages(&stages, active: .judging)
            case .analyzing:
                completeBefore(&stages, id: .analyzing)
                markStages(&stages, active: .analyzing)
            default:
                break
            }
        default:
            switch stage {
            case .transcribing:
                markStages(&stages, active: .transcribing)
            case .extracting:
                completeBefore(&stages, id: .extracting)
                markStages(&stages, active: .extracting)
            case .researching:
                completeBefore(&stages, id: .researching)
                markStages(&stages, active: .researching)
            case .judging:
                completeBefore(&stages, id: .judging)
                markStages(&stages, active: .judging)
            case .analyzing:
                completeBefore(&stages, id: .extracting)
                markStages(&stages, active: .extracting)
            default:
                break
            }
        }
    }
}
