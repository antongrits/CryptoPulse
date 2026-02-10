import Foundation
import RealmSwift

final class RMCoinNote: Object {
    @Persisted(primaryKey: true) var coinId: String
    @Persisted var text: String
    @Persisted var updatedAt: Date
}
