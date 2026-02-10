import Foundation
import Combine

@MainActor
final class CategoryMarketsViewModel: ObservableObject {
    @Published var coins: [CoinMarket] = []
    @Published var searchText: String = ""
    @Published var sort: MarketSort = .marketCapDesc
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var error: NetworkError?
    @Published var fallbackMessage: String?

    let categoryId: String
    let categoryName: String

    private let marketRepository: MarketRepositoryProtocol
    private var page: Int = 1
    private let perPage = 50
    private var hasMore = true

    init(marketRepository: MarketRepositoryProtocol, categoryId: String, categoryName: String) {
        self.marketRepository = marketRepository
        self.categoryId = categoryId
        self.categoryName = categoryName
        Task { await refresh() }
    }

    var displayedCoins: [CoinMarket] {
        let filtered = searchText.isEmpty ? coins : coins.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) || $0.symbol.localizedCaseInsensitiveContains(searchText)
        }
        return MarketRepository.sort(filtered, by: sort)
    }

    func refresh() async {
        if categoryId.hasPrefix("paprika:") {
            fallbackMessage = NSLocalizedString("Category details are unavailable for this data source.", comment: "")
            coins = []
            error = nil
            isLoading = false
            return
        }
        fallbackMessage = nil
        page = 1
        hasMore = true
        error = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let markets = try await marketRepository.fetchMarkets(page: page, perPage: perPage, sort: sort, category: categoryId)
            coins = markets
        } catch let networkError as NetworkError {
            self.error = networkError
        } catch {
            self.error = .unknown
        }
    }

    func loadNextPageIfNeeded(current coin: CoinMarket) async {
        if categoryId.hasPrefix("paprika:") { return }
        guard let last = displayedCoins.last, last.id == coin.id else { return }
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        page += 1
        do {
            let markets = try await marketRepository.fetchMarkets(page: page, perPage: perPage, sort: sort, category: categoryId)
            if markets.isEmpty { hasMore = false }
            coins = merge(existing: coins, new: markets)
        } catch let networkError as NetworkError {
            self.error = networkError
        } catch {
            self.error = .unknown
        }
    }

    private func merge(existing: [CoinMarket], new: [CoinMarket]) -> [CoinMarket] {
        var map = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        new.forEach { map[$0.id] = $0 }
        return MarketRepository.sort(Array(map.values), by: sort)
    }
}
