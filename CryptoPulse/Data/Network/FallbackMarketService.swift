import Foundation

final class FallbackMarketService: CoinGeckoServiceProtocol {
    private let primary: CoinGeckoServiceProtocol
    private let secondary: CoinGeckoServiceProtocol?

    init(primary: CoinGeckoServiceProtocol, secondary: CoinGeckoServiceProtocol? = nil) {
        self.primary = primary
        self.secondary = secondary
    }

    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort) async throws -> [MarketDTO] {
        try await primary.fetchMarkets(page: page, perPage: perPage, sort: sort)
    }

    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort, category: String?) async throws -> [MarketDTO] {
        try await primary.fetchMarkets(page: page, perPage: perPage, sort: sort, category: category)
    }

    func fetchDetails(coinId: String) async throws -> CoinDetailsDTO {
        try await primary.fetchDetails(coinId: coinId)
    }

    func fetchChart(coinId: String, range: ChartRange) async throws -> MarketChartDTO {
        try await primary.fetchChart(coinId: coinId, range: range)
    }

    func fetchTrending() async throws -> TrendingResponseDTO {
        try await primary.fetchTrending()
    }

    func fetchGlobal() async throws -> GlobalDTO {
        do {
            return try await primary.fetchGlobal()
        } catch let error as NetworkError where shouldFallback(error, allowRateLimit: true) {
            guard let secondary else { throw error }
            return try await secondary.fetchGlobal()
        }
    }

    func fetchCategories() async throws -> [MarketCategoryDTO] {
        do {
            return try await primary.fetchCategories()
        } catch let error as NetworkError where shouldFallback(error, allowRateLimit: true) {
            guard let secondary else { throw error }
            return try await secondary.fetchCategories()
        }
    }

    func fetchCategoryStats() async throws -> [MarketCategoryStatsDTO] {
        do {
            return try await primary.fetchCategoryStats()
        } catch let error as NetworkError where shouldFallback(error, allowRateLimit: true) {
            guard let secondary else { throw error }
            return try await secondary.fetchCategoryStats()
        }
    }

    func fetchExchanges(page: Int, perPage: Int) async throws -> [ExchangeDTO] {
        do {
            return try await primary.fetchExchanges(page: page, perPage: perPage)
        } catch let error as NetworkError where shouldFallback(error, allowRateLimit: true) {
            guard let secondary else { throw error }
            return try await secondary.fetchExchanges(page: page, perPage: perPage)
        }
    }

    private func shouldFallback(_ error: NetworkError, allowRateLimit: Bool) -> Bool {
        switch error {
        case .rateLimited:
            return allowRateLimit
        case .server(let statusCode):
            return [400, 401, 403].contains(statusCode)
        default:
            return false
        }
    }
}
