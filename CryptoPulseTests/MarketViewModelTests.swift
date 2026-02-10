import XCTest
@testable import CryptoPulse

@MainActor
final class MarketViewModelTests: XCTestCase {
    func testInitialLoadSuccess() async {
        let coin = CoinMarket(id: "btc", name: "Bitcoin", symbol: "BTC", imageURL: nil, currentPrice: 1, priceChangePercentage24h: 0, marketCap: nil, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil)
        let repo = StubMarketRepository(cached: [], fetchResult: .success([coin]))
        let vm = MarketViewModel(repository: repo)

        await vm.refresh(force: true)
        XCTAssertEqual(vm.coins.count, 1)
        XCTAssertNil(vm.error)
    }

    func testOfflineWithCacheShowsBanner() async {
        let coin = CoinMarket(id: "btc", name: "Bitcoin", symbol: "BTC", imageURL: nil, currentPrice: 1, priceChangePercentage24h: 0, marketCap: nil, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil)
        let repo = StubMarketRepository(cached: [coin], fetchResult: .failure(NetworkError.offline))
        let vm = MarketViewModel(repository: repo)

        await vm.refresh(force: true)
        XCTAssertTrue(vm.showOfflineBanner)
        XCTAssertEqual(vm.coins.count, 1)
    }

    func testSearchFiltering() {
        let repo = StubMarketRepository(cached: [], fetchResult: .success([]))
        let vm = MarketViewModel(repository: repo)
        vm.coins = [
            CoinMarket(id: "btc", name: "Bitcoin", symbol: "BTC", imageURL: nil, currentPrice: 1, priceChangePercentage24h: 0, marketCap: nil, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil),
            CoinMarket(id: "eth", name: "Ethereum", symbol: "ETH", imageURL: nil, currentPrice: 1, priceChangePercentage24h: 0, marketCap: nil, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil)
        ]
        vm.searchText = "bit"
        XCTAssertEqual(vm.displayedCoins.count, 1)
        XCTAssertEqual(vm.displayedCoins.first?.id, "btc")
    }
}

private final class StubMarketRepository: MarketRepositoryProtocol {
    var cached: [CoinMarket]
    var fetchResult: Result<[CoinMarket], Error>

    init(cached: [CoinMarket], fetchResult: Result<[CoinMarket], Error>) {
        self.cached = cached
        self.fetchResult = fetchResult
    }

    func cachedMarkets(sortedBy sort: MarketSort) -> [CoinMarket] { cached }
    func isMarketsCacheValid() -> Bool { true }
    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort) async throws -> [CoinMarket] {
        switch fetchResult {
        case .success(let coins): return coins
        case .failure(let error): throw error
        }
    }

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
