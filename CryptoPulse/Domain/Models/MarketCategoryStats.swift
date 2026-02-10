import Foundation

struct MarketCategoryStats: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let marketCap: Double?
    let marketCapChange24h: Double?
    let volume24h: Double?
    let top3CoinImageURLs: [URL]
    let updatedAt: Date?
}
