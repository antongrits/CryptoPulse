import Foundation

struct CoinDetailsDTO: Decodable {
    let id: String
    let name: String
    let symbol: String
    let description: DescriptionDTO
    let image: ImageDTO
    let marketData: MarketDataDTO
    let lastUpdated: String?

    struct DescriptionDTO: Decodable {
        let en: String?
    }

    struct ImageDTO: Decodable {
        let large: String?
    }

    struct MarketDataDTO: Decodable {
        let currentPrice: CurrencyDTO
        let priceChangePercentage24h: Double?
        let marketCap: CurrencyDTO
        let totalVolume: CurrencyDTO
        let high24h: CurrencyDTO
        let low24h: CurrencyDTO
        let circulatingSupply: Double?

        enum CodingKeys: String, CodingKey {
            case currentPrice = "current_price"
            case priceChangePercentage24h = "price_change_percentage_24h"
            case marketCap = "market_cap"
            case totalVolume = "total_volume"
            case high24h = "high_24h"
            case low24h = "low_24h"
            case circulatingSupply = "circulating_supply"
        }
    }

    struct CurrencyDTO: Decodable {
        let usd: Double?
    }

    enum CodingKeys: String, CodingKey {
        case id, name, symbol, description, image
        case marketData = "market_data"
        case lastUpdated = "last_updated"
    }
}
