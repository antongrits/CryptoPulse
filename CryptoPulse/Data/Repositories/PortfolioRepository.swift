import Foundation
import RealmSwift
import os

final class PortfolioRepository: PortfolioRepositoryProtocol {
    private let realmProvider: RealmProvider

    init(realmProvider: RealmProvider) {
        self.realmProvider = realmProvider
    }

    func holdings() -> [Holding] {
        do {
            let realm = try realmProvider.realm()
            return realm.objects(RMHolding.self).sorted(byKeyPath: "updatedAt", ascending: false).map { $0.toDomain() }
        } catch {
            return []
        }
    }

    func upsertHolding(_ holding: Holding) {
        do {
            let realm = try realmProvider.realm()
            try realm.write {
                var values: [String: Any] = [
                    "id": holding.id,
                    "coinId": holding.coinId,
                    "symbol": holding.symbol,
                    "name": holding.name,
                    "amount": holding.amount,
                    "createdAt": holding.createdAt,
                    "updatedAt": holding.updatedAt
                ]
                if let avg = holding.avgBuyPrice {
                    values["avgBuyPrice"] = avg
                }
                realm.create(RMHolding.self, value: values, update: .modified)
            }
        } catch {
            AppLogger.realm.error("Failed to upsert holding: \(error.localizedDescription)")
        }
    }

    func deleteHolding(id: String) {
        do {
            let realm = try realmProvider.realm()
            if let obj = realm.object(ofType: RMHolding.self, forPrimaryKey: id) {
                try realm.write { realm.delete(obj) }
            }
        } catch {
            AppLogger.realm.error("Failed to delete holding: \(error.localizedDescription)")
        }
    }
}
