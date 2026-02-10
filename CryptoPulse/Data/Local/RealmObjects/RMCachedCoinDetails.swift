import Foundation
import RealmSwift

final class RMCachedCoinDetails: Object {
    @Persisted(primaryKey: true) var coinId: String
    @Persisted var name: String
    @Persisted var symbol: String
    @Persisted var descriptionText: String
    @Persisted var imageURL: String?
    @Persisted var currentPrice: Double
    @Persisted var priceChangePercentage24h: Double
    @Persisted var marketCap: Double?
    @Persisted var totalVolume: Double?
    @Persisted var high24h: Double?
    @Persisted var low24h: Double?
    @Persisted var circulatingSupply: Double?
    @Persisted var lastUpdated: Date?
    @Persisted var updatedAt: Date
}
