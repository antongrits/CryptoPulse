import XCTest
@testable import CryptoPulse

@MainActor
final class PortfolioCalculationsTests: XCTestCase {
    func testTotalValueAndPL() {
        let realmProvider = RealmProvider(inMemory: true, identifier: "portfolio_test")
        let portfolioRepo = PortfolioRepository(realmProvider: realmProvider)

        let holding = Holding(
            id: "1",
            coinId: "btc",
            symbol: "BTC",
            name: "Bitcoin",
            amount: 2,
            avgBuyPrice: 100,
            createdAt: Date(),
            updatedAt: Date()
        )
        portfolioRepo.upsertHolding(holding)

        let marketRepo = StubMarketRepo(cached: [
            CoinMarket(id: "btc", name: "Bitcoin", symbol: "BTC", imageURL: nil, currentPrice: 150, priceChangePercentage24h: 0, marketCap: nil, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil)
        ])

        let vm = PortfolioViewModel(portfolioRepository: portfolioRepo, marketRepository: marketRepo)
        XCTAssertEqual(vm.totalValue, 300)
        XCTAssertEqual(vm.totalProfitLoss, 100)
    }
}

private struct StubMarketRepo: MarketRepositoryProtocol {
    let cached: [CoinMarket]
    func cachedMarkets(sortedBy sort: MarketSort) -> [CoinMarket] { cached }
    func isMarketsCacheValid() -> Bool { true }
    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort) async throws -> [CoinMarket] { cached }
    func fetchTrending() async throws -> [TrendingCoin] { [] }
    func fetchGlobalMarket() async throws -> GlobalMarket {
        GlobalMarket(
            totalMarketCapUSD: nil,
            totalVolumeUSD: nil,
            marketCapChangePercentage24h: nil,
            btcDominance: nil,
            ethDominance: nil,
            activeCryptocurrencies: nil,
            markets: nil,
            updatedAt: nil
        )
    }
}
