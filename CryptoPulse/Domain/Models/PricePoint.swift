import Foundation

struct PricePoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let price: Double
    let marketCap: Double?
    let volume: Double?
}
