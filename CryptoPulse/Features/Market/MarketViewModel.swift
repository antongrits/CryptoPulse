import Foundation
import Combine
import SwiftUI

@MainActor
final class MarketViewModel: ObservableObject {
    @Published var coins: [CoinMarket] = []
    @Published var searchText: String = ""
    @Published var sort: MarketSort = .marketCapDesc
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var error: NetworkError?
    @Published var showOfflineBanner: Bool = false
    @Published var lastUpdated: Date?
    @Published var trending: [TrendingCoin] = []
    @Published var isLoadingTrending: Bool = false

    private let repository: MarketRepositoryProtocol
    private let alertsChecker: AlertsChecker?
    private var page: Int = 1
    private let perPage = 50
    private var hasMore = true
    private var lastTrendingUpdate: Date?
    private var hasLoaded = false

    init(repository: MarketRepositoryProtocol, alertsChecker: AlertsChecker? = nil) {
        self.repository = repository
        self.alertsChecker = alertsChecker
        loadCached()
    }

    func loadIfNeeded(force: Bool = false) async {
        if hasLoaded && !force { return }
        hasLoaded = true
        await refresh(force: force)
        await loadTrendingIfNeeded(force: force)
    }

    var displayedCoins: [CoinMarket] {
        let filtered = searchText.isEmpty ? coins : coins.filter { coin in
            coin.name.localizedCaseInsensitiveContains(searchText) || coin.symbol.localizedCaseInsensitiveContains(searchText)
        }
        return sortCoins(filtered, by: sort)
    }

    var topGainers: [CoinMarket] {
        coins.sorted { $0.priceChangePercentage24h > $1.priceChangePercentage24h }.prefix(5).map { $0 }
    }

    var topLosers: [CoinMarket] {
        coins.sorted { $0.priceChangePercentage24h < $1.priceChangePercentage24h }.prefix(5).map { $0 }
    }

    var gainers: [CoinMarket] {
        coins
            .filter { $0.priceChangePercentage24h >= 0 }
            .sorted { $0.priceChangePercentage24h > $1.priceChangePercentage24h }
    }

    var losers: [CoinMarket] {
        coins
            .filter { $0.priceChangePercentage24h < 0 }
            .sorted { $0.priceChangePercentage24h < $1.priceChangePercentage24h }
    }

    func loadCached() {
        let cached = repository.cachedMarkets(sortedBy: sort)
        if !cached.isEmpty {
            coins = cached
        }
    }

    func loadTrendingIfNeeded(force: Bool = false) async {
        if !force, let lastTrendingUpdate, Date().timeIntervalSince(lastTrendingUpdate) < 300 {
            return
        }
        isLoadingTrending = true
        defer { isLoadingTrending = false }
        do {
            let items = try await NetworkRetry.run {
                try await repository.fetchTrending()
            }
            trending = items
            lastTrendingUpdate = Date()
        } catch {
            trending = []
        }
    }

    func refresh(force: Bool) async {
        if !force, repository.isMarketsCacheValid() {
            showOfflineBanner = false
            return
        }
        page = 1
        hasMore = true
        error = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let markets = try await NetworkRetry.run {
                try await repository.fetchMarkets(page: page, perPage: perPage, sort: sort)
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                coins = markets
            }
            showOfflineBanner = false
            lastUpdated = Date()
            alertsChecker?.checkAndNotify()
        } catch let networkError as NetworkError {
            self.error = networkError
            handleOfflineIfNeeded(networkError)
        } catch {
            self.error = .unknown
        }
    }

    func loadNextPageIfNeeded(current coin: CoinMarket) async {
        guard searchText.isEmpty else { return }
        guard let last = displayedCoins.last, last.id == coin.id else { return }
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        page += 1

        do {
            let markets = try await NetworkRetry.run {
                try await repository.fetchMarkets(page: page, perPage: perPage, sort: sort)
            }
            if markets.isEmpty { hasMore = false }
            withAnimation(.easeInOut(duration: 0.25)) {
                coins = merge(existing: coins, new: markets)
            }
            showOfflineBanner = false
            lastUpdated = Date()
            alertsChecker?.checkAndNotify()
        } catch let networkError as NetworkError {
            self.error = networkError
            handleOfflineIfNeeded(networkError)
        } catch {
            self.error = .unknown
        }
    }

    func retry() {
        Task { await refresh(force: true) }
    }

    func updateSort(_ newSort: MarketSort) {
        sort = newSort
        coins = sortCoins(coins, by: sort)
    }

    func autoRefreshIfNeeded(interval: TimeInterval = 300) {
        guard searchText.isEmpty else { return }
        guard !isLoading && !isLoadingMore else { return }
        if let lastUpdated {
            if Date().timeIntervalSince(lastUpdated) >= interval {
                Task { await refresh(force: false) }
            }
        } else {
            Task { await refresh(force: false) }
        }
    }

    private func sortCoins(_ markets: [CoinMarket], by sort: MarketSort) -> [CoinMarket] {
        MarketRepository.sort(markets, by: sort)
    }

    private func merge(existing: [CoinMarket], new: [CoinMarket]) -> [CoinMarket] {
        var map = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        new.forEach { map[$0.id] = $0 }
        return sortCoins(Array(map.values), by: sort)
    }

    private func handleOfflineIfNeeded(_ error: NetworkError) {
        if case .offline = error, !coins.isEmpty {
            showOfflineBanner = true
        }
    }
}
