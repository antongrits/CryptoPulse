import Foundation

protocol MarketRepositoryProtocol {
    func cachedMarkets(sortedBy sort: MarketSort) -> [CoinMarket]
    func isMarketsCacheValid() -> Bool
    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort) async throws -> [CoinMarket]
    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort, category: String?) async throws -> [CoinMarket]
    func fetchTrending() async throws -> [TrendingCoin]
    func fetchGlobalMarket() async throws -> GlobalMarket
    func fetchCategories() async throws -> [MarketCategory]
    func fetchCategoryStats() async throws -> [MarketCategoryStats]
    func fetchExchanges(page: Int, perPage: Int) async throws -> [Exchange]

    func cachedGlobalMarket() -> GlobalMarket?
    func cachedCategories() -> [MarketCategory]
    func cachedCategoryStats() -> [MarketCategoryStats]
    func cachedExchanges(page: Int, perPage: Int) -> [Exchange]

    func isGlobalCacheValid() -> Bool
    func isCategoriesCacheValid() -> Bool
    func isCategoryStatsCacheValid() -> Bool
    func isExchangesCacheValid(page: Int, perPage: Int) -> Bool
}

extension MarketRepositoryProtocol {
    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort, category: String?) async throws -> [CoinMarket] {
        try await fetchMarkets(page: page, perPage: perPage, sort: sort)
    }

    func fetchCategories() async throws -> [MarketCategory] {
        []
    }

    func fetchCategoryStats() async throws -> [MarketCategoryStats] {
        []
    }

    func fetchExchanges(page: Int, perPage: Int) async throws -> [Exchange] {
        []
    }

    func cachedGlobalMarket() -> GlobalMarket? { nil }
    func cachedCategories() -> [MarketCategory] { [] }
    func cachedCategoryStats() -> [MarketCategoryStats] { [] }
    func cachedExchanges(page: Int, perPage: Int) -> [Exchange] { [] }

    func isGlobalCacheValid() -> Bool { false }
    func isCategoriesCacheValid() -> Bool { false }
    func isCategoryStatsCacheValid() -> Bool { false }
    func isExchangesCacheValid(page: Int, perPage: Int) -> Bool { false }
}
