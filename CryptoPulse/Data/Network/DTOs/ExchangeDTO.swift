import Foundation

struct ExchangeDTO: Decodable {
    let id: String
    let name: String
    let image: String?
    let country: String?
    let yearEstablished: Int?
    let trustScoreRank: Int?
    let tradeVolume24hBtc: Double?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case image
        case country
        case yearEstablished = "year_established"
        case trustScoreRank = "trust_score_rank"
        case tradeVolume24hBtc = "trade_volume_24h_btc"
        case url
    }
}
