import Foundation

struct TrendingCoin: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let symbol: String
    let imageURL: URL?
    let marketCapRank: Int?
    let priceBTC: Double?
}
