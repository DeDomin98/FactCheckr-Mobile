import Foundation
import ActivityKit

/// Shared between the main app and the Widget Extension.
struct AnalysisActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var stageLabel: String
        var progress: Double
        var isFailed: Bool
        var isComplete: Bool
    }

    var sourceUrl: String
    var endpointRaw: String
    var displayTitle: String
}
