import Foundation

enum PriceAlertDirection: String, CaseIterable, Identifiable {
    case above
    case below

    var id: String { rawValue }

    var title: String {
        switch self {
        case .above: return NSLocalizedString("Above", comment: "")
        case .below: return NSLocalizedString("Below", comment: "")
        }
    }
}

enum PriceAlertMetric: String, CaseIterable, Identifiable {
    case price
    case percentChange24h

    var id: String { rawValue }

    var title: String {
        switch self {
        case .price: return NSLocalizedString("Price", comment: "")
        case .percentChange24h: return NSLocalizedString("24h Change", comment: "")
        }
    }

    var targetTitle: String {
        switch self {
        case .price: return NSLocalizedString("Target Price", comment: "")
        case .percentChange24h: return NSLocalizedString("Target % Change", comment: "")
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .price: return PriceFormatter.string(value)
        case .percentChange24h: return PercentFormatter.string(value)
        }
    }
}

enum PriceAlertRepeatMode: String, CaseIterable, Identifiable {
    case onceUntilReset
    case repeatWithCooldown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .onceUntilReset: return NSLocalizedString("Limit repeat", comment: "")
        case .repeatWithCooldown: return NSLocalizedString("Repeat with cooldown", comment: "")
        }
    }
}

struct PriceAlert: Identifiable, Hashable {
    let id: String
    let coinId: String
    let symbol: String
    let name: String
    let targetValue: Double
    let metric: PriceAlertMetric
    let direction: PriceAlertDirection
    let repeatMode: PriceAlertRepeatMode
    let cooldownMinutes: Int
    let isEnabled: Bool
    let isArmed: Bool
    let createdAt: Date
    let lastTriggeredAt: Date?

    var formattedTarget: String {
        metric.format(targetValue)
    }
}

struct PriceAlertTrigger: Hashable {
    let alert: PriceAlert
    let currentValue: Double
}
