import Foundation
import RealmSwift
import os

final class ConversionHistoryRepository: ConversionHistoryRepositoryProtocol {
    private let realmProvider: RealmProvider
    private let maxItems: Int

    init(realmProvider: RealmProvider, maxItems: Int = 20) {
        self.realmProvider = realmProvider
        self.maxItems = maxItems
    }

    func recent(limit: Int = 20) -> [ConversionRecord] {
        do {
            let realm = try realmProvider.realm()
            return realm.objects(RMConversionRecord.self)
                .sorted(byKeyPath: "createdAt", ascending: false)
                .prefix(limit)
                .map { $0.toDomain() }
        } catch {
            return []
        }
    }

    func addRecord(_ record: ConversionRecord) {
        do {
            let realm = try realmProvider.realm()
            try realm.write {
                let values: [String: Any] = [
                    "id": record.id,
                    "coinId": record.coinId,
                    "symbol": record.symbol,
                    "name": record.name,
                    "usdAmount": record.usdAmount,
                    "coinAmount": record.coinAmount,
                    "createdAt": record.createdAt
                ]
                realm.create(RMConversionRecord.self, value: values, update: .modified)

                let all = realm.objects(RMConversionRecord.self)
                    .sorted(byKeyPath: "createdAt", ascending: false)
                if all.count > maxItems {
                    let extra = all.suffix(all.count - maxItems)
                    realm.delete(extra)
                }
            }
        } catch {
            AppLogger.realm.error("Failed to add conversion record: \(error.localizedDescription)")
        }
    }

    func clear() {
        do {
            let realm = try realmProvider.realm()
            try realm.write {
                realm.delete(realm.objects(RMConversionRecord.self))
            }
        } catch {
            AppLogger.realm.error("Failed to clear conversion history: \(error.localizedDescription)")
        }
    }
}
