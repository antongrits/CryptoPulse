import Foundation

struct MarketDTO: Decodable {
    let id: String
    let name: String
    let symbol: String
    let image: String?
    let currentPrice: Double
    let priceChangePercentage24h: Double?
    let marketCap: Double?
    let totalVolume: Double?
    let high24h: Double?
    let low24h: Double?
    let lastUpdated: String?

    enum CodingKeys: String, CodingKey {
        case id, name, symbol, image
        case currentPrice = "current_price"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case marketCap = "market_cap"
        case totalVolume = "total_volume"
        case high24h = "high_24h"
        case low24h = "low_24h"
        case lastUpdated = "last_updated"
    }
}
