import Foundation

enum MarketLayout: String, CaseIterable, Identifiable {
    case cards
    case compact

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cards: return NSLocalizedString("Cards", comment: "")
        case .compact: return NSLocalizedString("Compact", comment: "")
        }
    }

    var systemImage: String {
        switch self {
        case .cards: return "rectangle.grid.2x2"
        case .compact: return "list.bullet"
        }
    }
}
