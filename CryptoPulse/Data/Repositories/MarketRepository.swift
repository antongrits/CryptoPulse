import Foundation
import RealmSwift
import os

final class MarketRepository: MarketRepositoryProtocol {
    private let service: CoinGeckoServiceProtocol
    private let realmProvider: RealmProvider
    private let diskCache = DiskCache.shared
    private let marketDeduper = RequestDeduper<[CoinMarket]>()

    init(service: CoinGeckoServiceProtocol, realmProvider: RealmProvider) {
        self.service = service
        self.realmProvider = realmProvider
    }

    func cachedMarkets(sortedBy sort: MarketSort) -> [CoinMarket] {
        do {
            let realm = try realmProvider.realm()
            let cached = realm.objects(RMCachedMarket.self)
            let markets = Array(cached.map { $0.toDomain() })
            return Self.sort(markets, by: sort)
        } catch {
            AppLogger.realm.error("Failed to read cached markets: \(error.localizedDescription)")
            return []
        }
    }

    func isMarketsCacheValid() -> Bool {
        do {
            let realm = try realmProvider.realm()
            let meta = realm.object(ofType: RMCacheMeta.self, forPrimaryKey: "markets")
            return CachePolicy.isFresh(meta?.updatedAt, ttl: CachePolicy.marketsTTL)
        } catch {
            return false
        }
    }

    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort) async throws -> [CoinMarket] {
        try await fetchMarkets(page: page, perPage: perPage, sort: sort, category: nil)
    }

    func fetchMarkets(page: Int, perPage: Int, sort: MarketSort, category: String?) async throws -> [CoinMarket] {
        let key = "markets_\(page)_\(perPage)_\(sort.rawValue)_\(category ?? "all")"
        return try await marketDeduper.run(key: key) {
            let dtos = try await self.service.fetchMarkets(page: page, perPage: perPage, sort: sort, category: category)
            let markets = dtos.map { $0.toDomain() }
            if category == nil || category?.isEmpty == true {
                await self.storeMarkets(markets, isFirstPage: page == 1)
            }
            return Self.sort(markets, by: sort)
        }
    }

    func fetchTrending() async throws -> [TrendingCoin] {
        if let cached: CacheResult<[TrendingCoin]> = diskCache.load(key: "trending", ttl: CachePolicy.trendingTTL),
           cached.isFresh {
            return cached.value
        }
        let dto = try await service.fetchTrending()
        let domain = dto.toDomain()
        diskCache.store(domain, key: "trending")
        return domain
    }

    func fetchGlobalMarket() async throws -> GlobalMarket {
        let dto = try await service.fetchGlobal()
        let domain = dto.toDomain()
        diskCache.store(domain, key: "global_market")
        return domain
    }

    func fetchCategories() async throws -> [MarketCategory] {
        let dtos = try await service.fetchCategories()
        let domain = dtos.map { $0.toDomain() }
        diskCache.store(domain, key: "categories_list")
        return domain
    }

    func fetchCategoryStats() async throws -> [MarketCategoryStats] {
        let dtos = try await service.fetchCategoryStats()
        let domain = dtos.map { $0.toDomain() }
        diskCache.store(domain, key: "categories_stats")
        return domain
    }

    func fetchExchanges(page: Int, perPage: Int) async throws -> [Exchange] {
        let dtos = try await service.fetchExchanges(page: page, perPage: perPage)
        let domain = dtos.map { $0.toDomain() }
        let key = "exchanges_\(page)_\(perPage)"
        diskCache.store(domain, key: key)
        return domain
    }

    func cachedGlobalMarket() -> GlobalMarket? {
        diskCache.load(key: "global_market", ttl: CachePolicy.globalTTL)?.value
    }

    func cachedCategories() -> [MarketCategory] {
        diskCache.load(key: "categories_list", ttl: CachePolicy.categoriesTTL)?.value ?? []
    }

    func cachedCategoryStats() -> [MarketCategoryStats] {
        diskCache.load(key: "categories_stats", ttl: CachePolicy.categoryStatsTTL)?.value ?? []
    }

    func cachedExchanges(page: Int, perPage: Int) -> [Exchange] {
        let key = "exchanges_\(page)_\(perPage)"
        return diskCache.load(key: key, ttl: CachePolicy.exchangesTTL)?.value ?? []
    }

    func isCategoriesCacheValid() -> Bool {
        let cached: CacheResult<[MarketCategory]>? = diskCache.load(key: "categories_list", ttl: CachePolicy.categoriesTTL)
        return cached?.isFresh ?? false
    }

    func isCategoryStatsCacheValid() -> Bool {
        let cached: CacheResult<[MarketCategoryStats]>? = diskCache.load(key: "categories_stats", ttl: CachePolicy.categoryStatsTTL)
        return cached?.isFresh ?? false
    }

    func isExchangesCacheValid(page: Int, perPage: Int) -> Bool {
        let key = "exchanges_\(page)_\(perPage)"
        let cached: CacheResult<[Exchange]>? = diskCache.load(key: key, ttl: CachePolicy.exchangesTTL)
        return cached?.isFresh ?? false
    }

    func isGlobalCacheValid() -> Bool {
        let cached: CacheResult<GlobalMarket>? = diskCache.load(key: "global_market", ttl: CachePolicy.globalTTL)
        return cached?.isFresh ?? false
    }

    static func sort(_ markets: [CoinMarket], by sort: MarketSort) -> [CoinMarket] {
        switch sort {
        case .marketCapDesc:
            return markets.sorted { ($0.marketCap ?? 0) > ($1.marketCap ?? 0) }
        case .priceDesc:
            return markets.sorted { $0.currentPrice > $1.currentPrice }
        case .changeDesc:
            return markets.sorted { $0.priceChangePercentage24h > $1.priceChangePercentage24h }
        case .alphabetical:
            return markets.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    func merge(existing: [CoinMarket], new: [CoinMarket]) -> [CoinMarket] {
        var map = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        new.forEach { map[$0.id] = $0 }
        return Array(map.values)
    }

    private func storeMarkets(_ markets: [CoinMarket], isFirstPage: Bool) async {
        do {
            let realm = try realmProvider.realm()
            try realm.write {
                if isFirstPage {
                    realm.delete(realm.objects(RMCachedMarket.self))
                }
                let now = Date()
                for market in markets {
                    let obj = realm.object(ofType: RMCachedMarket.self, forPrimaryKey: market.id) ?? RMCachedMarket()
                    if obj.realm == nil {
                        obj.coinId = market.id
                    }
                    obj.update(from: market, updatedAt: now)
                    realm.add(obj, update: .modified)
                }
                let meta = realm.object(ofType: RMCacheMeta.self, forPrimaryKey: "markets") ?? RMCacheMeta()
                if meta.realm == nil {
                    meta.key = "markets"
                }
                meta.updatedAt = now
                realm.add(meta, update: .modified)
            }
        } catch {
            AppLogger.realm.error("Failed to store markets: \(error.localizedDescription)")
        }
    }
}
