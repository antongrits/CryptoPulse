import Foundation
import RealmSwift
import os

final class FavoritesRepository: FavoritesRepositoryProtocol {
    private let realmProvider: RealmProvider

    init(realmProvider: RealmProvider) {
        self.realmProvider = realmProvider
    }

    func favorites() -> [CoinMarket] {
        do {
            let realm = try realmProvider.realm()
            return realm.objects(RMFavorite.self).sorted(byKeyPath: "createdAt", ascending: false).map { $0.toDomain() }
        } catch {
            return []
        }
    }

    func isFavorite(coinId: String) -> Bool {
        do {
            let realm = try realmProvider.realm()
            return realm.object(ofType: RMFavorite.self, forPrimaryKey: coinId) != nil
        } catch {
            return false
        }
    }

    func addFavorite(_ coin: CoinMarket) {
        do {
            let realm = try realmProvider.realm()
            try realm.write {
                let fav = RMFavorite()
                fav.coinId = coin.id
                fav.name = coin.name
                fav.symbol = coin.symbol
                fav.imageURL = coin.imageURL?.absoluteString
                fav.createdAt = Date()
                realm.add(fav, update: .modified)
            }
        } catch {
            AppLogger.realm.error("Failed to add favorite: \(error.localizedDescription)")
        }
    }

    func removeFavorite(coinId: String) {
        do {
            let realm = try realmProvider.realm()
            if let obj = realm.object(ofType: RMFavorite.self, forPrimaryKey: coinId) {
                try realm.write { realm.delete(obj) }
            }
        } catch {
            AppLogger.realm.error("Failed to remove favorite: \(error.localizedDescription)")
        }
    }
}
