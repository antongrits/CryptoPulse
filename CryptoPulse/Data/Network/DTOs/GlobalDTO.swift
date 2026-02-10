import Foundation

struct GlobalDTO: Decodable {
    let data: GlobalDataDTO
}

struct GlobalDataDTO: Decodable {
    let activeCryptocurrencies: Int?
    let markets: Int?
    let totalMarketCap: [String: Double]?
    let totalVolume: [String: Double]?
    let marketCapPercentage: [String: Double]?
    let marketCapChangePercentage24hUsd: Double?
    let updatedAt: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case activeCryptocurrencies = "active_cryptocurrencies"
        case markets
        case totalMarketCap = "total_market_cap"
        case totalVolume = "total_volume"
        case marketCapPercentage = "market_cap_percentage"
        case marketCapChangePercentage24hUsd = "market_cap_change_percentage_24h_usd"
        case updatedAt = "updated_at"
    }
}
