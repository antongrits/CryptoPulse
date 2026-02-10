import Foundation
import RealmSwift

final class RMConversionRecord: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var coinId: String
    @Persisted var symbol: String
    @Persisted var name: String
    @Persisted var usdAmount: Double
    @Persisted var coinAmount: Double
    @Persisted var createdAt: Date
}
