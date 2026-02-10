import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [CoinMarket] = []
    @Published var recent: [RecentSearch] = []

    private let marketRepository: MarketRepositoryProtocol
    private let searchRepository: SearchRepositoryProtocol

    init(marketRepository: MarketRepositoryProtocol, searchRepository: SearchRepositoryProtocol) {
        self.marketRepository = marketRepository
        self.searchRepository = searchRepository
        loadRecents()
    }

    func loadRecents() {
        recent = searchRepository.recentSearches()
    }

    func search() {
        let markets = marketRepository.cachedMarkets(sortedBy: .marketCapDesc)
        if query.isEmpty {
            results = []
            return
        }
        results = markets.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.symbol.localizedCaseInsensitiveContains(query) }
    }

    func commitSearch() {
        searchRepository.addSearch(query: query)
        loadRecents()
    }

    func clearHistory() {
        searchRepository.clearSearches()
        loadRecents()
    }
}
