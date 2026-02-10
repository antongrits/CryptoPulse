import Foundation
import RealmSwift
import os

final class AlertsRepository: AlertsRepositoryProtocol {
    private let realmProvider: RealmProvider

    init(realmProvider: RealmProvider) {
        self.realmProvider = realmProvider
    }

    func alerts() -> [PriceAlert] {
        do {
            let realm = try realmProvider.realm()
            return realm.objects(RMPriceAlert.self).sorted(byKeyPath: "createdAt", ascending: false).map { $0.toDomain() }
        } catch {
            return []
        }
    }

    func upsertAlert(_ alert: PriceAlert) {
        do {
            let realm = try realmProvider.realm()
            try realm.write {
                var values: [String: Any] = [
                    "id": alert.id,
                    "coinId": alert.coinId,
                    "symbol": alert.symbol,
                    "name": alert.name,
                    "targetPrice": alert.targetValue,
                    "metricRaw": alert.metric.rawValue,
                    "directionRaw": alert.direction.rawValue,
                    "repeatModeRaw": alert.repeatMode.rawValue,
                    "cooldownMinutes": alert.cooldownMinutes,
                    "isEnabled": alert.isEnabled,
                    "isArmed": alert.isArmed,
                    "createdAt": alert.createdAt
                ]
                if let lastTriggered = alert.lastTriggeredAt {
                    values["lastTriggeredAt"] = lastTriggered
                }
                realm.create(RMPriceAlert.self, value: values, update: .modified)
            }
        } catch {
            AppLogger.realm.error("Failed to upsert alert: \(error.localizedDescription)")
        }
    }

    func deleteAlert(id: String) {
        do {
            let realm = try realmProvider.realm()
            if let obj = realm.object(ofType: RMPriceAlert.self, forPrimaryKey: id) {
                try realm.write { realm.delete(obj) }
            }
        } catch {
            AppLogger.realm.error("Failed to delete alert: \(error.localizedDescription)")
        }
    }

    func markTriggered(id: String, date: Date) {
        do {
            let realm = try realmProvider.realm()
            if let obj = realm.object(ofType: RMPriceAlert.self, forPrimaryKey: id) {
                try realm.write {
                    obj.lastTriggeredAt = date
                    obj.isArmed = false
                }
            }
        } catch {
            AppLogger.realm.error("Failed to mark alert triggered: \(error.localizedDescription)")
        }
    }

    func setArmed(id: String, isArmed: Bool) {
        do {
            let realm = try realmProvider.realm()
            if let obj = realm.object(ofType: RMPriceAlert.self, forPrimaryKey: id) {
                try realm.write { obj.isArmed = isArmed }
            }
        } catch {
            AppLogger.realm.error("Failed to update alert armed state: \(error.localizedDescription)")
        }
    }
}
