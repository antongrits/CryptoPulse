import Foundation

struct Holding: Identifiable, Hashable {
    let id: String
    let coinId: String
    let symbol: String
    let name: String
    let amount: Double
    let avgBuyPrice: Double?
    let createdAt: Date
    let updatedAt: Date
}
