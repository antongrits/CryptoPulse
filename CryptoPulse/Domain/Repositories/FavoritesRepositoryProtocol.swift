import Foundation

protocol FavoritesRepositoryProtocol {
    func favorites() -> [CoinMarket]
    func isFavorite(coinId: String) -> Bool
    func addFavorite(_ coin: CoinMarket)
    func removeFavorite(coinId: String)
}
