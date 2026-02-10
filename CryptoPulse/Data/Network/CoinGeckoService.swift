import Foundation

protocol CoinGeckoServiceProtocol {
    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort) async throws -> [MarketDTO]
    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort, category: String?) async throws -> [MarketDTO]
    func fetchDetails(coinId: String) async throws -> CoinDetailsDTO
    func fetchChart(coinId: String, range: ChartRange) async throws -> MarketChartDTO
    func fetchTrending() async throws -> TrendingResponseDTO
    func fetchGlobal() async throws -> GlobalDTO
    func fetchCategories() async throws -> [MarketCategoryDTO]
    func fetchCategoryStats() async throws -> [MarketCategoryStatsDTO]
    func fetchExchanges(page: Int, perPage: Int) async throws -> [ExchangeDTO]
}

extension CoinGeckoServiceProtocol {
    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort, category: String?) async throws -> [MarketDTO] {
        try await fetchMarkets(page: page, perPage: perPage, sort: sort)
    }

    func fetchCategories() async throws -> [MarketCategoryDTO] {
        []
    }

    func fetchCategoryStats() async throws -> [MarketCategoryStatsDTO] {
        []
    }

    func fetchExchanges(page: Int, perPage: Int) async throws -> [ExchangeDTO] {
        []
    }
}

final class CoinGeckoService: CoinGeckoServiceProtocol {
    private let client: NetworkClientProtocol
    private let fallbackClient: NetworkClientProtocol?

    init(client: NetworkClientProtocol, fallbackClient: NetworkClientProtocol? = nil) {
        self.client = client
        self.fallbackClient = fallbackClient
    }

    private func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        do {
            return try await client.request(endpoint)
        } catch let error as NetworkError {
            if shouldFallback(error), let fallbackClient {
                return try await fallbackClient.request(endpoint)
            }
            throw error
        }
    }

    private func shouldFallback(_ error: NetworkError) -> Bool {
        switch error {
        case .rateLimited:
            return true
        case .server(let statusCode):
            return [401, 403, 429].contains(statusCode)
        default:
            return false
        }
    }

    private func withAuth(_ items: [URLQueryItem]) -> [URLQueryItem] {
        var items = items
        if let auth = AppConfig.coinGeckoAuthQueryItem {
            items.append(auth)
        }
        return items
    }

    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort) async throws -> [MarketDTO] {
        try await fetchMarkets(page: page, perPage: perPage, sort: sort, category: nil)
    }

    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort, category: String?) async throws -> [MarketDTO] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "vs_currency", value: "usd"),
            URLQueryItem(name: "order", value: sort.apiOrder),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "price_change_percentage", value: "24h"),
            URLQueryItem(name: "sparkline", value: "false")
        ]
        if let category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        let endpoint = Endpoint(
            path: "/api/v3/coins/markets",
            queryItems: withAuth(queryItems),
            method: "GET",
            headers: AppConfig.coinGeckoHeaders
        )
        return try await request(endpoint)
    }

    func fetchDetails(coinId: String) async throws -> CoinDetailsDTO {
        let endpoint = Endpoint(
            path: "/api/v3/coins/\(coinId)",
            queryItems: withAuth([
                URLQueryItem(name: "localization", value: "false"),
                URLQueryItem(name: "tickers", value: "false"),
                URLQueryItem(name: "market_data", value: "true"),
                URLQueryItem(name: "community_data", value: "false"),
                URLQueryItem(name: "developer_data", value: "false"),
                URLQueryItem(name: "sparkline", value: "false")
            ]),
            method: "GET",
            headers: AppConfig.coinGeckoHeaders
        )
        return try await request(endpoint)
    }

    func fetchChart(coinId: String, range: ChartRange) async throws -> MarketChartDTO {
        let endpoint = Endpoint(
            path: "/api/v3/coins/\(coinId)/market_chart",
            queryItems: withAuth([
                URLQueryItem(name: "vs_currency", value: "usd"),
                URLQueryItem(name: "days", value: range.daysQueryValue)
            ]),
            method: "GET",
            headers: AppConfig.coinGeckoHeaders
        )
        return try await request(endpoint)
    }

    func fetchTrending() async throws -> TrendingResponseDTO {
        let endpoint = Endpoint(
            path: "/api/v3/search/trending",
            queryItems: withAuth([]),
            method: "GET",
            headers: AppConfig.coinGeckoHeaders
        )
        return try await request(endpoint)
    }

    func fetchGlobal() async throws -> GlobalDTO {
        let endpoint = Endpoint(
            path: "/api/v3/global",
            queryItems: withAuth([]),
            method: "GET",
            headers: AppConfig.coinGeckoHeaders
        )
        return try await request(endpoint)
    }

    func fetchCategories() async throws -> [MarketCategoryDTO] {
        let endpoint = Endpoint(
            path: "/api/v3/coins/categories/list",
            queryItems: withAuth([]),
            method: "GET",
            headers: AppConfig.coinGeckoHeaders
        )
        return try await request(endpoint)
    }

    func fetchCategoryStats() async throws -> [MarketCategoryStatsDTO] {
        let endpoint = Endpoint(
            path: "/api/v3/coins/categories",
            queryItems: withAuth([]),
            method: "GET",
            headers: AppConfig.coinGeckoHeaders
        )
        return try await request(endpoint)
    }

    func fetchExchanges(page: Int, perPage: Int) async throws -> [ExchangeDTO] {
        let endpoint = Endpoint(
            path: "/api/v3/exchanges",
            queryItems: withAuth([
                URLQueryItem(name: "per_page", value: String(perPage)),
                URLQueryItem(name: "page", value: String(page))
            ]),
            method: "GET",
            headers: AppConfig.coinGeckoHeaders
        )
        return try await request(endpoint)
    }
}
