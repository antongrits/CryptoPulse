import Foundation
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var markets: [CoinMarket] = []
    @Published var holdings: [Holding] = []
    @Published var favoritesCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var error: NetworkError?
    @Published var globalMarket: GlobalMarket?
    @Published var showOfflineBanner: Bool = false

    private let marketRepository: MarketRepositoryProtocol
    private let portfolioRepository: PortfolioRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private var hasLoaded = false

    init(marketRepository: MarketRepositoryProtocol,
         portfolioRepository: PortfolioRepositoryProtocol,
         favoritesRepository: FavoritesRepositoryProtocol) {
        self.marketRepository = marketRepository
        self.portfolioRepository = portfolioRepository
        self.favoritesRepository = favoritesRepository
        load()
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    func load() {
        markets = marketRepository.cachedMarkets(sortedBy: .marketCapDesc)
        holdings = portfolioRepository.holdings()
        favoritesCount = favoritesRepository.favorites().count
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        showOfflineBanner = false
        do {
            async let marketsTask = NetworkRetry.run {
                try await marketRepository.fetchMarkets(page: 1, perPage: 100, sort: .marketCapDesc)
            }
            async let globalTask = fetchGlobalMarket()
            markets = try await marketsTask
            globalMarket = try await globalTask
        } catch let networkError as NetworkError {
            if !markets.isEmpty, shouldShowNonBlockingBanner(for: networkError) {
                showOfflineBanner = true
            } else {
                self.error = networkError
            }
        } catch {
            if markets.isEmpty {
                self.error = .unknown
            }
        }
        load()
    }

    private func fetchGlobalMarket() async throws -> GlobalMarket? {
        if marketRepository.isGlobalCacheValid(), let cached = marketRepository.cachedGlobalMarket() {
            return cached
        }
        return try await NetworkRetry.run {
            try await marketRepository.fetchGlobalMarket()
        }
    }

    var topGainers: [CoinMarket] {
        markets.sorted { $0.priceChangePercentage24h > $1.priceChangePercentage24h }.prefix(5).map { $0 }
    }

    var topLosers: [CoinMarket] {
        markets.sorted { $0.priceChangePercentage24h < $1.priceChangePercentage24h }.prefix(5).map { $0 }
    }

    var marketBreadth: (gainers: Int, losers: Int) {
        let gainers = markets.filter { $0.priceChangePercentage24h >= 0 }.count
        let losers = markets.filter { $0.priceChangePercentage24h < 0 }.count
        return (gainers, losers)
    }

    var marketPulse: Double {
        guard !markets.isEmpty else { return 0 }
        let avg = markets.map { abs($0.priceChangePercentage24h) }.reduce(0, +) / Double(markets.count)
        return min(100, avg * 2)
    }

    var totalPortfolioValue: Double {
        let priceMap = Dictionary(uniqueKeysWithValues: markets.map { ($0.id, $0.currentPrice) })
        return holdings.reduce(0) { total, holding in
            total + (priceMap[holding.coinId] ?? 0) * holding.amount
        }
    }

    private func shouldShowNonBlockingBanner(for error: NetworkError) -> Bool {
        switch error {
        case .offline, .rateLimited:
            return true
        case .server(let statusCode):
            return statusCode == 400
        case .decoding, .unknown:
            return false
        }
    }
}
