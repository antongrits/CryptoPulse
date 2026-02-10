import Foundation

private struct PaprikaGlobalDTO: Decodable {
    let marketCapUsd: Double?
    let volume24hUsd: Double?
    let bitcoinDominancePercentage: Double?
    let ethereumDominancePercentage: Double?
    let cryptocurrenciesNumber: Int?
    let marketsNumber: Int?
    let marketCapChange24h: Double?
    let lastUpdated: String?

    enum CodingKeys: String, CodingKey {
        case marketCapUsd = "market_cap_usd"
        case volume24hUsd = "volume_24h_usd"
        case bitcoinDominancePercentage = "bitcoin_dominance_percentage"
        case ethereumDominancePercentage = "ethereum_dominance_percentage"
        case cryptocurrenciesNumber = "cryptocurrencies_number"
        case marketsNumber = "markets_number"
        case marketCapChange24h = "market_cap_change_24h"
        case lastUpdated = "last_updated"
    }
}

private struct PaprikaTagDTO: Decodable {
    let id: String
    let name: String
}

private struct PaprikaExchangeDTO: Decodable {
    let id: String
    let name: String
    let links: PaprikaLinksDTO?
    let adjustedRank: Int?
    let reportedRank: Int?
    let quotes: PaprikaExchangeQuotesDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case links
        case adjustedRank = "adjusted_rank"
        case reportedRank = "reported_rank"
        case quotes
    }
}

private struct PaprikaLinksDTO: Decodable {
    let website: [String]?
}

private struct PaprikaExchangeQuotesDTO: Decodable {
    let usd: PaprikaQuoteDTO?

    enum CodingKeys: String, CodingKey {
        case usd = "USD"
    }
}

private struct PaprikaQuoteDTO: Decodable {
    let reportedVolume24h: Double?

    enum CodingKeys: String, CodingKey {
        case reportedVolume24h = "reported_volume_24h"
    }
}

private actor PaprikaCache {
    static let shared = PaprikaCache()

    private var exchanges: (items: [PaprikaExchangeDTO], updatedAt: Date)?
    private var tags: (items: [PaprikaTagDTO], updatedAt: Date)?

    func cachedExchanges(ttl: TimeInterval) -> [PaprikaExchangeDTO]? {
        guard let cached = exchanges else { return nil }
        guard Date().timeIntervalSince(cached.updatedAt) < ttl else { return nil }
        return cached.items
    }

    func storeExchanges(_ items: [PaprikaExchangeDTO]) {
        exchanges = (items, Date())
    }

    func cachedTags(ttl: TimeInterval) -> [PaprikaTagDTO]? {
        guard let cached = tags else { return nil }
        guard Date().timeIntervalSince(cached.updatedAt) < ttl else { return nil }
        return cached.items
    }

    func storeTags(_ items: [PaprikaTagDTO]) {
        tags = (items, Date())
    }
}

final class CoinPaprikaService: CoinGeckoServiceProtocol {
    private let client: NetworkClientProtocol
    private let cache = PaprikaCache.shared
    private let dateFormatter = ISO8601DateFormatter()
    private let tagsTTL: TimeInterval = 60 * 30
    private let exchangesTTL: TimeInterval = 60 * 15

    init(client: NetworkClientProtocol) {
        self.client = client
    }

    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort) async throws -> [MarketDTO] {
        throw NetworkError.server(statusCode: 501)
    }

    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort, category: String?) async throws -> [MarketDTO] {
        throw NetworkError.server(statusCode: 501)
    }

    func fetchDetails(coinId: String) async throws -> CoinDetailsDTO {
        throw NetworkError.server(statusCode: 501)
    }

    func fetchChart(coinId: String, range: ChartRange) async throws -> MarketChartDTO {
        throw NetworkError.server(statusCode: 501)
    }

    func fetchTrending() async throws -> TrendingResponseDTO {
        throw NetworkError.server(statusCode: 501)
    }

    func fetchGlobal() async throws -> GlobalDTO {
        let endpoint = Endpoint(path: "/v1/global", queryItems: [], method: "GET", headers: [:])
        let dto: PaprikaGlobalDTO = try await client.request(endpoint)
        let updatedAt = dto.lastUpdated.flatMap { dateFormatter.date(from: $0)?.timeIntervalSince1970 }
        var dominance: [String: Double] = [:]
        if let btc = dto.bitcoinDominancePercentage { dominance["btc"] = btc }
        if let eth = dto.ethereumDominancePercentage { dominance["eth"] = eth }
        let data = GlobalDataDTO(
            activeCryptocurrencies: dto.cryptocurrenciesNumber,
            markets: dto.marketsNumber,
            totalMarketCap: dto.marketCapUsd.map { ["usd": $0] },
            totalVolume: dto.volume24hUsd.map { ["usd": $0] },
            marketCapPercentage: dominance.isEmpty ? nil : dominance,
            marketCapChangePercentage24hUsd: dto.marketCapChange24h,
            updatedAt: updatedAt
        )
        return GlobalDTO(data: data)
    }

    func fetchCategories() async throws -> [MarketCategoryDTO] {
        let tags = try await fetchTags()
        return tags.map { MarketCategoryDTO(categoryId: "paprika:\($0.id)", name: $0.name) }
    }

    func fetchCategoryStats() async throws -> [MarketCategoryStatsDTO] {
        let tags = try await fetchTags()
        return tags.map {
            MarketCategoryStatsDTO(
                id: "paprika:\($0.id)",
                name: $0.name,
                marketCap: nil,
                marketCapChange24h: nil,
                volume24h: nil,
                top3Coins: nil,
                updatedAt: nil
            )
        }
    }

    func fetchExchanges(page: Int, perPage: Int) async throws -> [ExchangeDTO] {
        let all = try await fetchExchangesList()
        let start = max(0, (page - 1) * perPage)
        guard start < all.count else { return [] }
        let slice = all[start..<min(all.count, start + perPage)]
        return slice.map { exchange in
            ExchangeDTO(
                id: exchange.id,
                name: exchange.name,
                image: nil,
                country: nil,
                yearEstablished: nil,
                trustScoreRank: exchange.adjustedRank ?? exchange.reportedRank,
                tradeVolume24hBtc: exchange.quotes?.usd?.reportedVolume24h,
                url: exchange.links?.website?.first
            )
        }
    }

    private func fetchTags() async throws -> [PaprikaTagDTO] {
        if let cached = await cache.cachedTags(ttl: tagsTTL) {
            return cached
        }
        let endpoint = Endpoint(path: "/v1/tags", queryItems: [], method: "GET", headers: [:])
        let tags: [PaprikaTagDTO] = try await client.request(endpoint)
        await cache.storeTags(tags)
        return tags
    }

    private func fetchExchangesList() async throws -> [PaprikaExchangeDTO] {
        if let cached = await cache.cachedExchanges(ttl: exchangesTTL) {
            return cached
        }
        let endpoint = Endpoint(path: "/v1/exchanges", queryItems: [], method: "GET", headers: [:])
        let exchanges: [PaprikaExchangeDTO] = try await client.request(endpoint)
        await cache.storeExchanges(exchanges)
        return exchanges
    }
}
