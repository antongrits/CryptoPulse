import Foundation

struct AlertMarketSnapshot {
    let price: Double
    let percentChange24h: Double
}

struct AlertsEvaluator {
    let cooldownMinutes: Int

    func evaluate(alerts: [PriceAlert], snapshots: [String: AlertMarketSnapshot], now: Date = Date()) -> (triggers: [PriceAlertTrigger], rearmIds: [String]) {
        var triggers: [PriceAlertTrigger] = []
        var rearm: [String] = []

        for alert in alerts {
            guard alert.isEnabled, let snapshot = snapshots[alert.coinId] else { continue }
            let cooldown = TimeInterval((alert.cooldownMinutes > 0 ? alert.cooldownMinutes : cooldownMinutes) * 60)
            let currentValue: Double
            switch alert.metric {
            case .price:
                currentValue = snapshot.price
            case .percentChange24h:
                currentValue = snapshot.percentChange24h
            }

            let isBeyond = alert.direction == .above ? currentValue >= alert.targetValue : currentValue <= alert.targetValue
            let canTrigger: Bool
            if let last = alert.lastTriggeredAt {
                canTrigger = now.timeIntervalSince(last) >= cooldown
            } else {
                canTrigger = true
            }

            if isBeyond {
                switch alert.repeatMode {
                case .onceUntilReset:
                    guard alert.isArmed, canTrigger else { continue }
                    triggers.append(PriceAlertTrigger(alert: alert, currentValue: currentValue))
                case .repeatWithCooldown:
                    guard canTrigger else { continue }
                    triggers.append(PriceAlertTrigger(alert: alert, currentValue: currentValue))
                }
            } else if !alert.isArmed {
                rearm.append(alert.id)
            }
        }

        return (triggers, rearm)
    }
}
