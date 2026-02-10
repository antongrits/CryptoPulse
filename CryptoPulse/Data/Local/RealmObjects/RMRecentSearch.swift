import Foundation
import RealmSwift

final class RMRecentSearch: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var query: String
    @Persisted var createdAt: Date
}
