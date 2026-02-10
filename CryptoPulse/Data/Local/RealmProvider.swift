import Foundation
import RealmSwift

struct RealmProvider {
    let configuration: Realm.Configuration

    init(inMemory: Bool = false, identifier: String = "CryptoPulse") {
        configuration = RealmMigration.configuration(inMemory: inMemory, identifier: identifier)
    }

    func realm() throws -> Realm {
        try Realm(configuration: configuration)
    }
}
