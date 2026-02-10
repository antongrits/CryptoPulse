import Foundation
import UserNotifications
import Combine

@MainActor
final class AlertsViewModel: ObservableObject {
    @Published var alerts: [PriceAlert] = []
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined

    private let alertsRepository: AlertsRepositoryProtocol
    private let marketRepository: MarketRepositoryProtocol
    private let checker: AlertsChecker

    init(alertsRepository: AlertsRepositoryProtocol, marketRepository: MarketRepositoryProtocol) {
        self.alertsRepository = alertsRepository
        self.marketRepository = marketRepository
        self.checker = AlertsChecker(alertsRepository: alertsRepository, marketRepository: marketRepository)
        load()
        Task { await refreshNotificationStatus() }
    }

    func load() {
        alerts = alertsRepository.alerts()
        checker.checkAndNotify()
    }

    func delete(id: String) {
        alertsRepository.deleteAlert(id: id)
        load()
    }

    func toggle(alert: PriceAlert) {
        let updated = PriceAlert(
            id: alert.id,
            coinId: alert.coinId,
            symbol: alert.symbol,
            name: alert.name,
            targetValue: alert.targetValue,
            metric: alert.metric,
            direction: alert.direction,
            repeatMode: alert.repeatMode,
            cooldownMinutes: alert.cooldownMinutes,
            isEnabled: !alert.isEnabled,
            isArmed: alert.isArmed,
            createdAt: alert.createdAt,
            lastTriggeredAt: alert.lastTriggeredAt
        )
        alertsRepository.upsertAlert(updated)
        load()
    }

    func createAlert(coin: CoinMarket, target: Double, metric: PriceAlertMetric, direction: PriceAlertDirection, repeatMode: PriceAlertRepeatMode, cooldownMinutes: Int) {
        let alert = PriceAlert(
            id: UUID().uuidString,
            coinId: coin.id,
            symbol: coin.symbol,
            name: coin.name,
            targetValue: target,
            metric: metric,
            direction: direction,
            repeatMode: repeatMode,
            cooldownMinutes: cooldownMinutes,
            isEnabled: true,
            isArmed: true,
            createdAt: Date(),
            lastTriggeredAt: nil
        )
        alertsRepository.upsertAlert(alert)
        load()
    }

    func updateAlert(_ alert: PriceAlert) {
        alertsRepository.upsertAlert(alert)
        load()
    }

    func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }

    func requestPermission() async {
        _ = await NotificationManager.shared.requestAuthorization()
        await refreshNotificationStatus()
    }
}
