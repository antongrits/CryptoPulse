import Foundation
import Combine

@MainActor
final class ProfitCalculatorViewModel: ObservableObject {
    @Published var coins: [CoinMarket] = []
    @Published var selectedCoin: CoinMarket?
    @Published var amountText: String = ""
    @Published var buyPriceText: String = ""

    private let marketRepository: MarketRepositoryProtocol

    init(marketRepository: MarketRepositoryProtocol) {
        self.marketRepository = marketRepository
        load()
    }

    func load() {
        coins = marketRepository.cachedMarkets(sortedBy: .marketCapDesc)
        if selectedCoin == nil { selectedCoin = coins.first }
    }

    var profitLoss: Double? {
        guard let coin = selectedCoin,
              let amount = NumberParsing.double(from: amountText),
              let buy = NumberParsing.double(from: buyPriceText) else { return nil }
        return (coin.currentPrice - buy) * amount
    }

    var profitLossPercent: Double? {
        guard let coin = selectedCoin,
              let buy = NumberParsing.double(from: buyPriceText),
              buy > 0 else { return nil }
        return (coin.currentPrice - buy) / buy * 100
    }
}
