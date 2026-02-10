import Foundation
import Combine

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [CoinMarket] = []
    @Published var sort: MarketSort = .marketCapDesc

    private let favoritesRepository: FavoritesRepositoryProtocol
    private let marketRepository: MarketRepositoryProtocol

    init(favoritesRepository: FavoritesRepositoryProtocol, marketRepository: MarketRepositoryProtocol) {
        self.favoritesRepository = favoritesRepository
        self.marketRepository = marketRepository
        load()
    }

    func load() {
        let stored = favoritesRepository.favorites()
        let prices = marketRepository.cachedMarkets(sortedBy: .marketCapDesc)
        let priceMap = Dictionary(uniqueKeysWithValues: prices.map { ($0.id, $0) })
        favorites = stored.map { fav in
            if let market = priceMap[fav.id] {
                return market
            }
            return fav
        }
        favorites = MarketRepository.sort(favorites, by: sort)
    }

    func remove(coinId: String) {
        favoritesRepository.removeFavorite(coinId: coinId)
        load()
    }

    func updateSort(_ sort: MarketSort) {
        self.sort = sort
        favorites = MarketRepository.sort(favorites, by: sort)
    }

    func refresh() async {
        if !marketRepository.isMarketsCacheValid() {
            do {
                _ = try await marketRepository.fetchMarkets(page: 1, perPage: 100, sort: .marketCapDesc)
            } catch {
                // Silent refresh; UI keeps cached data.
            }
        }
        load()
    }
}
