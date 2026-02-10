import Foundation
import Combine

@MainActor
final class CompareViewModel: ObservableObject {
    @Published var coins: [CoinMarket] = []
    @Published var left: CoinMarket?
    @Published var right: CoinMarket?

    private let marketRepository: MarketRepositoryProtocol

    init(marketRepository: MarketRepositoryProtocol) {
        self.marketRepository = marketRepository
        load()
    }

    func load() {
        coins = marketRepository.cachedMarkets(sortedBy: .marketCapDesc)
        if left == nil { left = coins.first }
        if right == nil { right = coins.dropFirst().first ?? coins.first }
    }

    func selectLeft(_ coin: CoinMarket) { left = coin }
    func selectRight(_ coin: CoinMarket) { right = coin }

    var ratioText: String {
        guard let left, let right, right.currentPrice > 0 else { return "—" }
        let ratio = left.currentPrice / right.currentPrice
        return NumberParsing.string(from: ratio, maximumFractionDigits: 6)
    }

    var differencePercent: Double? {
        guard let left, let right, right.currentPrice > 0 else { return nil }
        return (left.currentPrice - right.currentPrice) / right.currentPrice * 100
    }
}
