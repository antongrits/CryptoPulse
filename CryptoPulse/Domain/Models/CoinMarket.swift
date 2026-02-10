import Foundation

struct CoinMarket: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let imageURL: URL?
    let currentPrice: Double
    let priceChangePercentage24h: Double
    let marketCap: Double?
    let totalVolume: Double?
    let high24h: Double?
    let low24h: Double?
    let lastUpdated: Date?
}
