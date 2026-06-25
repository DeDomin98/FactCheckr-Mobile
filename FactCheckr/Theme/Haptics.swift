import UIKit

/// Lightweight wrapper around UIKit feedback generators for satisfying tactile cues.
enum Haptics {
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// Maps a verdict to a fitting success / warning / error feedback.
    static func forVerdict(_ category: VerdictCategory) {
        switch category {
        case .trueFact:
            notify(.success)
        case .falseFact:
            notify(.error)
        case .partial, .insufficient:
            notify(.warning)
        }
    }
}
