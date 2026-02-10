import Foundation

struct GlobalMarket: Hashable, Codable {
    let totalMarketCapUSD: Double?
    let totalVolumeUSD: Double?
    let marketCapChangePercentage24h: Double?
    let btcDominance: Double?
    let ethDominance: Double?
    let activeCryptocurrencies: Int?
    let markets: Int?
    let updatedAt: Date?
}
