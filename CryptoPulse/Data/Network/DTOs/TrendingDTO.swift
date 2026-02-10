import Foundation

struct TrendingResponseDTO: Decodable {
    let coins: [TrendingItemDTO]
}

struct TrendingItemDTO: Decodable {
    let item: TrendingCoinDTO
}

struct TrendingCoinDTO: Decodable {
    let id: String
    let name: String
    let symbol: String
    let small: String?
    let marketCapRank: Int?
    let priceBTC: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, symbol, small
        case marketCapRank = "market_cap_rank"
        case priceBTC = "price_btc"
    }
}
