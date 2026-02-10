import Foundation
import RealmSwift

final class RMPriceAlert: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var coinId: String
    @Persisted var symbol: String
    @Persisted var name: String
    @Persisted var targetPrice: Double
    @Persisted var metricRaw: String
    @Persisted var directionRaw: String
    @Persisted var repeatModeRaw: String
    @Persisted var cooldownMinutes: Int
    @Persisted var isEnabled: Bool
    @Persisted var isArmed: Bool
    @Persisted var createdAt: Date
    @Persisted var lastTriggeredAt: Date?
}
