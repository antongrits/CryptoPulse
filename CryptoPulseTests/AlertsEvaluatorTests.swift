import XCTest
@testable import CryptoPulse

@MainActor
final class AlertsEvaluatorTests: XCTestCase {
    func testAboveTrigger() {
        let alert = PriceAlert(
            id: "1",
            coinId: "btc",
            symbol: "BTC",
            name: "Bitcoin",
            targetValue: 100,
            metric: .price,
            direction: .above,
            repeatMode: .onceUntilReset,
            cooldownMinutes: 30,
            isEnabled: true,
            isArmed: true,
            createdAt: Date(),
            lastTriggeredAt: nil
        )
        let evaluator = AlertsEvaluator(cooldownMinutes: 30)
        let result = evaluator.evaluate(alerts: [alert], snapshots: ["btc": AlertMarketSnapshot(price: 120, percentChange24h: 3)])
        XCTAssertEqual(result.triggers.count, 1)
    }

    func testBelowTrigger() {
        let alert = PriceAlert(
            id: "1",
            coinId: "btc",
            symbol: "BTC",
            name: "Bitcoin",
            targetValue: 100,
            metric: .price,
            direction: .below,
            repeatMode: .onceUntilReset,
            cooldownMinutes: 30,
            isEnabled: true,
            isArmed: true,
            createdAt: Date(),
            lastTriggeredAt: nil
        )
        let evaluator = AlertsEvaluator(cooldownMinutes: 30)
        let result = evaluator.evaluate(alerts: [alert], snapshots: ["btc": AlertMarketSnapshot(price: 80, percentChange24h: -2)])
        XCTAssertEqual(result.triggers.count, 1)
    }

    func testCooldownPreventsSpam() {
        let last = Date().addingTimeInterval(-60 * 10)
        let alert = PriceAlert(
            id: "1",
            coinId: "btc",
            symbol: "BTC",
            name: "Bitcoin",
            targetValue: 100,
            metric: .price,
            direction: .above,
            repeatMode: .repeatWithCooldown,
            cooldownMinutes: 30,
            isEnabled: true,
            isArmed: true,
            createdAt: Date(),
            lastTriggeredAt: last
        )
        let evaluator = AlertsEvaluator(cooldownMinutes: 30)
        let result = evaluator.evaluate(alerts: [alert], snapshots: ["btc": AlertMarketSnapshot(price: 120, percentChange24h: 4)])
        XCTAssertEqual(result.triggers.count, 0)
    }

    func testPercentChangeTrigger() {
        let alert = PriceAlert(
            id: "1",
            coinId: "btc",
            symbol: "BTC",
            name: "Bitcoin",
            targetValue: 5,
            metric: .percentChange24h,
            direction: .above,
            repeatMode: .onceUntilReset,
            cooldownMinutes: 30,
            isEnabled: true,
            isArmed: true,
            createdAt: Date(),
            lastTriggeredAt: nil
        )
        let evaluator = AlertsEvaluator(cooldownMinutes: 30)
        let result = evaluator.evaluate(alerts: [alert], snapshots: ["btc": AlertMarketSnapshot(price: 100, percentChange24h: 6)])
        XCTAssertEqual(result.triggers.count, 1)
    }
}
