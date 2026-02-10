import Foundation
import RealmSwift

enum RealmMigration {
    static let schemaVersion: UInt64 = 6

    static func configuration(inMemory: Bool = false, identifier: String = "CryptoPulse") -> Realm.Configuration {
        var config = Realm.Configuration()
        config.schemaVersion = schemaVersion
        config.migrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 2 {
                migration.deleteData(forType: "RMCachedChart")
            }
            if oldSchemaVersion < 3 {
                migration.deleteData(forType: "RMCachedChart")
            }
            if oldSchemaVersion < 4 {
                migration.enumerateObjects(ofType: "RMPriceAlert") { _, newObject in
                    newObject?["isArmed"] = true
                }
            }
            if oldSchemaVersion < 5 {
                migration.enumerateObjects(ofType: "RMPriceAlert") { _, newObject in
                    newObject?["repeatModeRaw"] = PriceAlertRepeatMode.onceUntilReset.rawValue
                    newObject?["cooldownMinutes"] = 30
                }
            }
            if oldSchemaVersion < 6 {
                migration.enumerateObjects(ofType: "RMPriceAlert") { _, newObject in
                    newObject?["metricRaw"] = PriceAlertMetric.price.rawValue
                }
            }
        }
        if inMemory {
            config.inMemoryIdentifier = identifier
        }
        return config
    }
}
