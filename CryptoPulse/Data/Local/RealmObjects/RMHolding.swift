import Foundation
import RealmSwift

final class RMHolding: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var coinId: String
    @Persisted var symbol: String
    @Persisted var name: String
    @Persisted var amount: Double
    @Persisted var avgBuyPrice: Double?
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
}
