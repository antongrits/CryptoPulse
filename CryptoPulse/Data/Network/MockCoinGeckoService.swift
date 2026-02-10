import Foundation

final class MockCoinGeckoService: CoinGeckoServiceProtocol {
    private let decoder = JSONDecoder()

    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort) async throws -> [MarketDTO] {
        try load("mock_markets")
    }

    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort, category: String?) async throws -> [MarketDTO] {
        try load("mock_markets")
    }

    func fetchDetails(coinId: String) async throws -> CoinDetailsDTO {
        try load("mock_details")
    }

    func fetchChart(coinId: String, range: ChartRange) async throws -> MarketChartDTO {
        try load("mock_chart")
    }

    func fetchTrending() async throws -> TrendingResponseDTO {
        try load("mock_trending")
    }

    func fetchGlobal() async throws -> GlobalDTO {
        try load("mock_global")
    }

    func fetchCategories() async throws -> [MarketCategoryDTO] {
        [
            MarketCategoryDTO(categoryId: "layer-1", name: "Layer 1"),
            MarketCategoryDTO(categoryId: "defi", name: "DeFi"),
            MarketCategoryDTO(categoryId: "meme-token", name: "Meme")
        ]
    }

    func fetchCategoryStats() async throws -> [MarketCategoryStatsDTO] {
        [
            MarketCategoryStatsDTO(
                id: "layer-1",
                name: "Layer 1",
                marketCap: 850_000_000_000,
                marketCapChange24h: 1.4,
                volume24h: 25_000_000_000,
                top3Coins: [],
                updatedAt: "2024-01-01T00:00:00.000Z"
            ),
            MarketCategoryStatsDTO(
                id: "defi",
                name: "DeFi",
                marketCap: 120_000_000_000,
                marketCapChange24h: -0.8,
                volume24h: 8_000_000_000,
                top3Coins: [],
                updatedAt: "2024-01-01T00:00:00.000Z"
            )
        ]
    }

    func fetchExchanges(page: Int, perPage: Int) async throws -> [ExchangeDTO] {
        [
            ExchangeDTO(
                id: "binance",
                name: "Binance",
                image: nil,
                country: "Cayman Islands",
                yearEstablished: 2017,
                trustScoreRank: 1,
                tradeVolume24hBtc: 123456.0,
                url: "https://www.binance.com"
            ),
            ExchangeDTO(
                id: "coinbase",
                name: "Coinbase",
                image: nil,
                country: "United States",
                yearEstablished: 2012,
                trustScoreRank: 2,
                tradeVolume24hBtc: 45678.0,
                url: "https://www.coinbase.com"
            )
        ]
    }

    private func load<T: Decodable>(_ name: String) throws -> T {
        let data: Data
        if let url = Bundle.main.url(forResource: name, withExtension: "json") {
            data = try Data(contentsOf: url)
        } else {
            data = Self.inlineData(for: name)
        }
        return try decoder.decode(T.self, from: data)
    }

    private static func inlineData(for name: String) -> Data {
        switch name {
        case "mock_markets":
            return Data("""
            [
              {"id":"bitcoin","name":"Bitcoin","symbol":"btc","image":null,"current_price":45000,"price_change_percentage_24h":2.5,"market_cap":800000000000,"total_volume":25000000000,"high_24h":46000,"low_24h":44000,"last_updated":"2024-01-01T00:00:00.000Z"},
              {"id":"ethereum","name":"Ethereum","symbol":"eth","image":null,"current_price":3200,"price_change_percentage_24h":-1.4,"market_cap":380000000000,"total_volume":12000000000,"high_24h":3300,"low_24h":3100,"last_updated":"2024-01-01T00:00:00.000Z"}
            ]
            """.utf8)
        case "mock_details":
            return Data("""
            {"id":"bitcoin","name":"Bitcoin","symbol":"btc","description":{"en":"Bitcoin is a decentralized digital currency."},"image":{"large":null},"market_data":{"current_price":{"usd":45000},"price_change_percentage_24h":2.5,"market_cap":{"usd":800000000000},"total_volume":{"usd":25000000000},"high_24h":{"usd":46000},"low_24h":{"usd":44000},"circulating_supply":19500000},"last_updated":"2024-01-01T00:00:00.000Z"}
            """.utf8)
        case "mock_chart":
            return Data("""
            {"prices":[[1704067200000,43000],[1704153600000,44000],[1704240000000,44500],[1704326400000,45000],[1704412800000,44800],[1704499200000,45500],[1704585600000,46000]],
             "market_caps":[[1704067200000,800000000000],[1704153600000,810000000000],[1704240000000,815000000000],[1704326400000,820000000000],[1704412800000,818000000000],[1704499200000,825000000000],[1704585600000,830000000000]],
             "total_volumes":[[1704067200000,25000000000],[1704153600000,26000000000],[1704240000000,25500000000],[1704326400000,27000000000],[1704412800000,26500000000],[1704499200000,28000000000],[1704585600000,29000000000]]
            }
            """.utf8)
        case "mock_trending":
            return Data("""
            {"coins":[
                {"item":{"id":"bitcoin","name":"Bitcoin","symbol":"BTC","small":null,"market_cap_rank":1,"price_btc":1}},
                {"item":{"id":"ethereum","name":"Ethereum","symbol":"ETH","small":null,"market_cap_rank":2,"price_btc":0.05}},
                {"item":{"id":"solana","name":"Solana","symbol":"SOL","small":null,"market_cap_rank":5,"price_btc":0.002}}
            ]}
            """.utf8)
        case "mock_global":
            return Data("""
            {"data":{
                "active_cryptocurrencies": 12000,
                "markets": 950,
                "total_market_cap":{"usd": 1800000000000},
                "total_volume":{"usd": 85000000000},
                "market_cap_percentage":{"btc": 48.2, "eth": 17.4},
                "market_cap_change_percentage_24h_usd": 1.2,
                "updated_at": 1704585600
            }}
            """.utf8)
        default:
            return Data("{}".utf8)
        }
    }
}
