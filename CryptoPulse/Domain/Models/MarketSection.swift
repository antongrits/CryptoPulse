import Foundation

enum MarketSection: String, CaseIterable, Identifiable {
    case all
    case gainers
    case losers
    case trending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return NSLocalizedString("All", comment: "")
        case .gainers: return NSLocalizedString("Gainers", comment: "")
        case .losers: return NSLocalizedString("Losers", comment: "")
        case .trending: return NSLocalizedString("Trending", comment: "")
        }
    }
}
