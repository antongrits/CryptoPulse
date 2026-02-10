import Foundation

struct ConversionRecord: Identifiable, Hashable {
    let id: String
    let coinId: String
    let symbol: String
    let name: String
    let usdAmount: Double
    let coinAmount: Double
    let createdAt: Date
}
