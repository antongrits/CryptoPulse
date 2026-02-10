import Foundation
import Combine

@MainActor
final class PortfolioViewModel: ObservableObject {
    @Published var holdings: [Holding] = []

    private let portfolioRepository: PortfolioRepositoryProtocol
    private let marketRepository: MarketRepositoryProtocol

    init(portfolioRepository: PortfolioRepositoryProtocol, marketRepository: MarketRepositoryProtocol) {
        self.portfolioRepository = portfolioRepository
        self.marketRepository = marketRepository
        load()
    }

    func load() {
        let current = portfolioRepository.holdings()
        consolidateDuplicates(current)
        holdings = portfolioRepository.holdings()
    }

    func delete(id: String) {
        portfolioRepository.deleteHolding(id: id)
        load()
    }

    func upsert(holding: Holding) {
        portfolioRepository.upsertHolding(holding)
        load()
    }

    func addHolding(coin: CoinMarket, amount: Double, avgBuyPrice: Double?) {
        let existing = holdings.first { $0.coinId == coin.id }
        let merged = mergeHolding(existing: existing, coin: coin, amount: amount, avgBuyPrice: avgBuyPrice)
        portfolioRepository.upsertHolding(merged)
        load()
    }

    func refresh(force: Bool = false) async {
        if !force, marketRepository.isMarketsCacheValid() {
            load()
            return
        }
        do {
            _ = try await marketRepository.fetchMarkets(page: 1, perPage: 100, sort: .marketCapDesc)
        } catch {
            // Keep cached data on refresh failure.
        }
        load()
    }

    struct PortfolioRow: Identifiable {
        let id: String
        let holding: Holding
        let currentPrice: Double?
        let dayChange: Double?

        var currentValue: Double {
            (currentPrice ?? 0) * holding.amount
        }

        var profitLoss: Double? {
            guard let avg = holding.avgBuyPrice else { return nil }
            return (currentPrice ?? 0 - avg) * holding.amount
        }

        var profitLossPercent: Double? {
            guard let avg = holding.avgBuyPrice, avg > 0 else { return nil }
            return ((currentPrice ?? 0) - avg) / avg * 100
        }
    }

    var rows: [PortfolioRow] {
        let markets = marketRepository.cachedMarkets(sortedBy: .marketCapDesc)
        let map = Dictionary(uniqueKeysWithValues: markets.map { ($0.id, $0) })
        return holdings.map { holding in
            let market = map[holding.coinId]
            return PortfolioRow(
                id: holding.id,
                holding: holding,
                currentPrice: market?.currentPrice,
                dayChange: market?.priceChangePercentage24h
            )
        }
    }

    var totalValue: Double {
        rows.reduce(0) { $0 + $1.currentValue }
    }

    var totalProfitLoss: Double? {
        let values = rows.compactMap { $0.profitLoss }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +)
    }

    var totalProfitLossPercent: Double? {
        let cost = rows.reduce(0) { sum, row in
            if let avg = row.holding.avgBuyPrice {
                return sum + (avg * row.holding.amount)
            }
            return sum
        }
        guard cost > 0, let total = totalProfitLoss else { return nil }
        return total / cost * 100
    }

    private func mergeHolding(existing: Holding?, coin: CoinMarket, amount: Double, avgBuyPrice: Double?) -> Holding {
        guard let existing else {
            return Holding(
                id: UUID().uuidString,
                coinId: coin.id,
                symbol: coin.symbol,
                name: coin.name,
                amount: amount,
                avgBuyPrice: avgBuyPrice,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        let newAmount = existing.amount + amount
        let newAvg: Double?
        switch (existing.avgBuyPrice, avgBuyPrice) {
        case let (lhs?, rhs?):
            newAvg = (lhs * existing.amount + rhs * amount) / max(newAmount, 0.0001)
        case let (lhs?, nil):
            newAvg = lhs
        case let (nil, rhs?):
            newAvg = rhs
        default:
            newAvg = nil
        }
        return Holding(
            id: existing.id,
            coinId: existing.coinId,
            symbol: existing.symbol,
            name: existing.name,
            amount: newAmount,
            avgBuyPrice: newAvg,
            createdAt: existing.createdAt,
            updatedAt: Date()
        )
    }

    private func consolidateDuplicates(_ holdings: [Holding]) {
        let grouped = Dictionary(grouping: holdings, by: { $0.coinId })
        for (_, items) in grouped where items.count > 1 {
            let sorted = items.sorted { $0.updatedAt > $1.updatedAt }
            let keep = sorted.first!
            let totalAmount = items.reduce(0) { $0 + $1.amount }
            let weighted: Double? = {
                let pairs = items.compactMap { holding -> (amount: Double, avg: Double)? in
                    guard let avg = holding.avgBuyPrice else { return nil }
                    return (holding.amount, avg)
                }
                guard !pairs.isEmpty else { return nil }
                let total = pairs.reduce(0) { $0 + $1.amount }
                guard total > 0 else { return nil }
                let sum = pairs.reduce(0) { $0 + ($1.amount * $1.avg) }
                return sum / total
            }()
            let merged = Holding(
                id: keep.id,
                coinId: keep.coinId,
                symbol: keep.symbol,
                name: keep.name,
                amount: totalAmount,
                avgBuyPrice: weighted,
                createdAt: items.map(\.createdAt).min() ?? keep.createdAt,
                updatedAt: Date()
            )
            portfolioRepository.upsertHolding(merged)
            for extra in items where extra.id != keep.id {
                portfolioRepository.deleteHolding(id: extra.id)
            }
        }
    }
}
