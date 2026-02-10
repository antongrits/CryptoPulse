import Foundation

struct MarketCategoryStatsDTO: Decodable {
    let id: String
    let name: String
    let marketCap: Double?
    let marketCapChange24h: Double?
    let volume24h: Double?
    let top3Coins: [String]?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case marketCap = "market_cap"
        case marketCapChange24h = "market_cap_change_24h"
        case volume24h = "volume_24h"
        case top3Coins = "top_3_coins"
        case updatedAt = "updated_at"
    }
}
