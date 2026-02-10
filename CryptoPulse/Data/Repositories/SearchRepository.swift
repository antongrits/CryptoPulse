import Foundation
import RealmSwift
import os

final class SearchRepository: SearchRepositoryProtocol {
    private let realmProvider: RealmProvider
    private let maxItems = 10

    init(realmProvider: RealmProvider) {
        self.realmProvider = realmProvider
    }

    func recentSearches() -> [RecentSearch] {
        do {
            let realm = try realmProvider.realm()
            return realm.objects(RMRecentSearch.self)
                .sorted(byKeyPath: "createdAt", ascending: false)
                .map { $0.toDomain() }
        } catch {
            return []
        }
    }

    func addSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let realm = try realmProvider.realm()
            try realm.write {
                if let existing = realm.objects(RMRecentSearch.self).filter("query == %@", trimmed).first {
                    realm.delete(existing)
                }
                let obj = RMRecentSearch()
                obj.id = UUID().uuidString
                obj.query = trimmed
                obj.createdAt = Date()
                realm.add(obj, update: .modified)

                let all = realm.objects(RMRecentSearch.self).sorted(byKeyPath: "createdAt", ascending: false)
                if all.count > maxItems, let last = all.last {
                    realm.delete(last)
                }
            }
        } catch {
            AppLogger.realm.error("Failed to add search: \(error.localizedDescription)")
        }
    }

    func clearSearches() {
        do {
            let realm = try realmProvider.realm()
            try realm.write {
                realm.delete(realm.objects(RMRecentSearch.self))
            }
        } catch {
            AppLogger.realm.error("Failed to clear searches: \(error.localizedDescription)")
        }
    }
}
