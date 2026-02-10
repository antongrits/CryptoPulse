import Foundation
import RealmSwift

final class RMCacheMeta: Object {
    @Persisted(primaryKey: true) var key: String
    @Persisted var updatedAt: Date
}
