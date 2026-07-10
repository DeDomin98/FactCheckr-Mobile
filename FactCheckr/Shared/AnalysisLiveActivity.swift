import Foundation
import ActivityKit

@MainActor
enum AnalysisLiveActivityController {
    static func start(url: String, endpoint: AnalyzeEndpoint, title: String? = nil) {
        guard #available(iOS 16.2, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        endMatching(url: url)

        let attributes = AnalysisActivityAttributes(
            sourceUrl: url,
            endpointRaw: endpoint.metaValue,
            displayTitle: title ?? shortened(url)
        )
        let state = AnalysisActivityAttributes.ContentState(
            stageLabel: Loc.t(.liveActivityStarting),
            progress: 0.05,
            isFailed: false,
            isComplete: false
        )

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: Date().addingTimeInterval(15 * 60)),
                pushType: nil
            )
        } catch {
            #if DEBUG
            print("[LiveActivity] start failed: \(error.localizedDescription)")
            #endif
        }
    }

    static func update(url: String, stageLabel: String, progress: Double) {
        guard #available(iOS 16.2, *) else { return }
        let state = AnalysisActivityAttributes.ContentState(
            stageLabel: stageLabel,
            progress: min(max(progress, 0), 1),
            isFailed: false,
            isComplete: false
        )
        Task {
            for activity in Activity<AnalysisActivityAttributes>.activities
            where urlsRoughlyMatch(activity.attributes.sourceUrl, url) {
                await activity.update(.init(state: state, staleDate: Date().addingTimeInterval(10 * 60)))
            }
        }
    }

    static func complete(url: String, success: Bool, message: String) {
        guard #available(iOS 16.2, *) else { return }
        let state = AnalysisActivityAttributes.ContentState(
            stageLabel: message,
            progress: success ? 1 : 0,
            isFailed: !success,
            isComplete: true
        )
        Task {
            for activity in Activity<AnalysisActivityAttributes>.activities
            where urlsRoughlyMatch(activity.attributes.sourceUrl, url) {
                await activity.update(.init(state: state, staleDate: nil))
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await activity.end(nil, dismissalPolicy: .after(.now.addingTimeInterval(4)))
            }
        }
    }

    /// Ensures a Live Activity exists for a background/share analysis when the app is open.
    static func ensureForInflight(url: String, endpoint: AnalyzeEndpoint = .article) {
        guard #available(iOS 16.2, *) else { return }
        let exists = Activity<AnalysisActivityAttributes>.activities.contains {
            urlsRoughlyMatch($0.attributes.sourceUrl, url) && !$0.content.state.isComplete
        }
        if !exists {
            start(url: url, endpoint: endpoint, title: nil)
            update(url: url, stageLabel: Loc.t(.liveActivityBackground), progress: 0.35)
        }
    }

    static func endMatching(url: String) {
        guard #available(iOS 16.2, *) else { return }
        for activity in Activity<AnalysisActivityAttributes>.activities
        where urlsRoughlyMatch(activity.attributes.sourceUrl, url) {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    static func endAll() {
        guard #available(iOS 16.2, *) else { return }
        for activity in Activity<AnalysisActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    private static func shortened(_ url: String) -> String {
        guard let host = URL(string: url)?.host else { return String(url.prefix(40)) }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}
