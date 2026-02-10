import Foundation
import RealmSwift

final class RMFavorite: Object {
    @Persisted(primaryKey: true) var coinId: String
    @Persisted var name: String
    @Persisted var symbol: String
    @Persisted var imageURL: String?
    @Persisted var createdAt: Date
}
