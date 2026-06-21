import Foundation

enum AppTab: String, CaseIterable {
    case home
    case history

    var title: String {
        switch self {
        case .home: return "Start"
        case .history: return "Historia"
        }
    }

    var icon: String {
        switch self {
        case .home: return "magnifyingglass"
        case .history: return "clock.arrow.circlepath"
        }
    }
}
