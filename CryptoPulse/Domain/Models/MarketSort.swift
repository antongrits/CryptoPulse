import Foundation
import Combine

enum MarketSort: String, CaseIterable, Identifiable {
    case marketCapDesc
    case priceDesc
    case changeDesc
    case alphabetical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .marketCapDesc: return NSLocalizedString("Market Cap", comment: "")
        case .priceDesc: return NSLocalizedString("Price", comment: "")
        case .changeDesc: return NSLocalizedString("24h Change", comment: "")
        case .alphabetical: return NSLocalizedString("A–Z", comment: "")
        }
    }

    var apiOrder: String {
        // CoinGecko order supports market cap reliably; other sorts are applied client-side.
        return "market_cap_desc"
    }
}
