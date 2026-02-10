import XCTest
@testable import CryptoPulse

@MainActor
final class FavoritesRepositoryTests: XCTestCase {
    func testAddRemoveFavorite() {
        let repo = FavoritesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "fav_test"))
        let coin = CoinMarket(id: "btc", name: "Bitcoin", symbol: "BTC", imageURL: nil, currentPrice: 1, priceChangePercentage24h: 0, marketCap: nil, totalVolume: nil, high24h: nil, low24h: nil, lastUpdated: nil)

        repo.addFavorite(coin)
        XCTAssertTrue(repo.isFavorite(coinId: "btc"))
        XCTAssertEqual(repo.favorites().count, 1)

        repo.removeFavorite(coinId: "btc")
        XCTAssertFalse(repo.isFavorite(coinId: "btc"))
    }
}
