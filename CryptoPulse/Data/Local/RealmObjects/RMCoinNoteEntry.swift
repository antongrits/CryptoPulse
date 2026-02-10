import Foundation
import RealmSwift

final class RMCoinNoteEntry: Object {
    @Persisted(primaryKey: true) var noteId: String
    @Persisted(indexed: true) var coinId: String
    @Persisted var coinName: String
    @Persisted var coinSymbol: String
    @Persisted var text: String
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
}
