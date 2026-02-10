import Foundation

struct CoinNote: Identifiable, Hashable {
    let id: String
    let coinId: String
    let coinName: String
    let coinSymbol: String
    let text: String
    let createdAt: Date
    let updatedAt: Date
}
