import Foundation
import RealmSwift

final class RMPricePoint: EmbeddedObject {
    @Persisted var timestamp: Double
    @Persisted var price: Double
    @Persisted var marketCap: Double?
    @Persisted var volume: Double?
}

final class RMCachedChart: Object {
    @Persisted(primaryKey: true) var key: String
    @Persisted var coinId: String
    @Persisted var rangeRaw: String
    @Persisted var points: List<RMPricePoint>
    @Persisted var updatedAt: Date
}
