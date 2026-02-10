import Foundation

struct Exchange: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let imageURL: URL?
    let country: String?
    let yearEstablished: Int?
    let trustScoreRank: Int?
    let tradeVolume24hBtc: Double?
    let url: URL?
}
