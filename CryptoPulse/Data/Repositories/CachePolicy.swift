import Foundation

enum CachePolicy {
    static let marketsTTL: TimeInterval = 2 * 60
    static let detailsTTL: TimeInterval = 5 * 60
    static let chartTTL: TimeInterval = 10 * 60
    static let categoriesTTL: TimeInterval = 30 * 60
    static let categoryStatsTTL: TimeInterval = 15 * 60
    static let exchangesTTL: TimeInterval = 15 * 60
    static let globalTTL: TimeInterval = 5 * 60
    static let trendingTTL: TimeInterval = 10 * 60

    static func isFresh(_ date: Date?, ttl: TimeInterval) -> Bool {
        guard let date else { return false }
        return Date().timeIntervalSince(date) < ttl
    }
}
