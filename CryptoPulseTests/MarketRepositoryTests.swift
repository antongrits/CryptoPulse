import XCTest
@testable import CryptoPulse

@MainActor
final class MarketRepositoryTests: XCTestCase {
    func testSortPriceDesc() {
        let coins = [
            CoinMarket(id: "a", name: "A", symbol: "A", imageURL: nil, currentPrice: 2, priceChangePercentage24h: 0, marketCap: 10, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil),
            CoinMarket(id: "b", name: "B", symbol: "B", imageURL: nil, currentPrice: 10, priceChangePercentage24h: 0, marketCap: 5, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil),
            CoinMarket(id: "c", name: "C", symbol: "C", imageURL: nil, currentPrice: 5, priceChangePercentage24h: 0, marketCap: 1, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil)
        ]

        let sorted = MarketRepository.sort(coins, by: .priceDesc)
        XCTAssertEqual(sorted.first?.id, "b")
    }

    func testMergeDeduplicatesById() {
        let repo = MarketRepository(service: StubCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "test"))
        let first = [CoinMarket(id: "a", name: "A", symbol: "A", imageURL: nil, currentPrice: 1, priceChangePercentage24h: 0, marketCap: nil, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil)]
        let second = [CoinMarket(id: "a", name: "A2", symbol: "A", imageURL: nil, currentPrice: 2, priceChangePercentage24h: 0, marketCap: nil, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil)]

        let merged = repo.merge(existing: first, new: second)
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged.first?.currentPrice, 2)
    }

    func testPaginationMergeAddsNewItems() {
        let repo = MarketRepository(service: StubCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "test2"))
        let first = [CoinMarket(id: "a", name: "A", symbol: "A", imageURL: nil, currentPrice: 1, priceChangePercentage24h: 0, marketCap: nil, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil)]
        let second = [CoinMarket(id: "b", name: "B", symbol: "B", imageURL: nil, currentPrice: 2, priceChangePercentage24h: 0, marketCap: nil, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil)]

        let merged = repo.merge(existing: first, new: second)
        XCTAssertEqual(merged.count, 2)
    }
}

private final class StubCoinGeckoService: CoinGeckoServiceProtocol {
    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort) async throws -> [MarketDTO] { [] }
    func fetchDetails(coinId: String) async throws -> CoinDetailsDTO { throw NetworkError.unknown }
    func fetchChart(coinId: String, range: ChartRange) async throws -> MarketChartDTO { throw NetworkError.unknown }
    func fetchTrending() async throws -> TrendingResponseDTO { TrendingResponseDTO(coins: []) }
    func fetchGlobal() async throws -> GlobalDTO {
        GlobalDTO(data: GlobalDataDTO(
            activeCryptocurrencies: nil,
            markets: nil,
            totalMarketCap: nil,
            totalVolume: nil,
            marketCapPercentage: nil,
            marketCapChangePercentage24hUsd: nil,
            updatedAt: nil
        ))
    }
}
