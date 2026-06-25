import Foundation

enum AppTab: String, CaseIterable {
    case home
    case history
    case account

    var title: String {
        switch self {
        case .home: return Loc.t(.tabHome)
        case .history: return Loc.t(.tabHistory)
        case .account: return Loc.t(.tabAccount)
        }
    }

    var icon: String {
        switch self {
        case .home: return "magnifyingglass"
        case .history: return "clock.arrow.circlepath"
        case .account: return "person.crop.circle"
        }
    }
}
