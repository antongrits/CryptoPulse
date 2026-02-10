import Foundation

final class AlertsChecker {
    private let alertsRepository: AlertsRepositoryProtocol
    private let marketRepository: MarketRepositoryProtocol
    private let evaluator: AlertsEvaluator

    init(alertsRepository: AlertsRepositoryProtocol, marketRepository: MarketRepositoryProtocol, cooldownMinutes: Int = 30) {
        self.alertsRepository = alertsRepository
        self.marketRepository = marketRepository
        self.evaluator = AlertsEvaluator(cooldownMinutes: cooldownMinutes)
    }

    func checkAndNotify() {
        let alerts = alertsRepository.alerts()
        guard !alerts.isEmpty else { return }
        let markets = marketRepository.cachedMarkets(sortedBy: .marketCapDesc)
        let snapshots = Dictionary(uniqueKeysWithValues: markets.map { ($0.id, AlertMarketSnapshot(price: $0.currentPrice, percentChange24h: $0.priceChangePercentage24h)) })
        let result = evaluator.evaluate(alerts: alerts, snapshots: snapshots)
        for trigger in result.triggers {
            let directionText = trigger.alert.direction == .above
                ? NSLocalizedString("above", comment: "")
                : NSLocalizedString("below", comment: "")
            let metricTitle = trigger.alert.metric == .price
                ? NSLocalizedString("price alert", comment: "")
                : NSLocalizedString("change alert", comment: "")
            let title = String(format: NSLocalizedString("%@ %@", comment: ""), trigger.alert.name, metricTitle)
            let targetText = trigger.alert.metric.format(trigger.alert.targetValue)
            let currentText = trigger.alert.metric.format(trigger.currentValue)
            let body = String(format: NSLocalizedString("%@ is %@ %@. Current: %@", comment: ""),
                              trigger.alert.symbol,
                              directionText,
                              targetText,
                              currentText)
            NotificationManager.shared.sendPriceAlert(
                title: title,
                body: body
            )
            alertsRepository.markTriggered(id: trigger.alert.id, date: Date())
            if trigger.alert.repeatMode == .repeatWithCooldown {
                alertsRepository.setArmed(id: trigger.alert.id, isArmed: true)
            }
        }
        for id in result.rearmIds {
            alertsRepository.setArmed(id: id, isArmed: true)
        }
    }
}
