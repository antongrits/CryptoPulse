import Foundation
import RealmSwift
import os

final class CoinRepository: CoinRepositoryProtocol {
    private let service: CoinGeckoServiceProtocol
    private let realmProvider: RealmProvider
    private let detailsDeduper = RequestDeduper<CoinDetails>()
    private let chartDeduper = RequestDeduper<[PricePoint]>()

    init(service: CoinGeckoServiceProtocol, realmProvider: RealmProvider) {
        self.service = service
        self.realmProvider = realmProvider
    }

    func cachedDetails(for coinId: String) -> CoinDetails? {
        do {
            let realm = try realmProvider.realm()
            return realm.object(ofType: RMCachedCoinDetails.self, forPrimaryKey: coinId)?.toDomain()
        } catch {
            return nil
        }
    }

    func cachedChart(for coinId: String, range: ChartRange) -> [PricePoint] {
        do {
            let realm = try realmProvider.realm()
            return realm.object(ofType: RMCachedChart.self, forPrimaryKey: chartKey(coinId: coinId, range: range))?.toDomain() ?? []
        } catch {
            return []
        }
    }

    func isDetailsCacheValid(for coinId: String) -> Bool {
        do {
            let realm = try realmProvider.realm()
            let obj = realm.object(ofType: RMCachedCoinDetails.self, forPrimaryKey: coinId)
            return CachePolicy.isFresh(obj?.updatedAt, ttl: CachePolicy.detailsTTL)
        } catch {
            return false
        }
    }

    func isChartCacheValid(for coinId: String, range: ChartRange) -> Bool {
        do {
            let realm = try realmProvider.realm()
            let obj = realm.object(ofType: RMCachedChart.self, forPrimaryKey: chartKey(coinId: coinId, range: range))
            return CachePolicy.isFresh(obj?.updatedAt, ttl: CachePolicy.chartTTL)
        } catch {
            return false
        }
    }

    func fetchDetails(for coinId: String) async throws -> CoinDetails {
        try await detailsDeduper.run(key: "details_\(coinId)") {
            let dto = try await self.service.fetchDetails(coinId: coinId)
            let domain = dto.toDomain()
            await self.storeDetails(domain)
            return domain
        }
    }

    func fetchChart(for coinId: String, range: ChartRange) async throws -> [PricePoint] {
        try await chartDeduper.run(key: "chart_\(coinId)_\(range.rawValue)") {
            let dto = try await self.service.fetchChart(coinId: coinId, range: range)
            let points = dto.toDomain()
            await self.storeChart(coinId: coinId, range: range, points: points)
            return points
        }
    }

    private func storeDetails(_ details: CoinDetails) async {
        do {
            let realm = try realmProvider.realm()
            try realm.write {
                let obj = realm.object(ofType: RMCachedCoinDetails.self, forPrimaryKey: details.id) ?? RMCachedCoinDetails()
                if obj.realm == nil {
                    obj.coinId = details.id
                }
                obj.update(from: details, updatedAt: Date())
                realm.add(obj, update: .modified)
            }
        } catch {
            AppLogger.realm.error("Failed to store details: \(error.localizedDescription)")
        }
    }

    private func storeChart(coinId: String, range: ChartRange, points: [PricePoint]) async {
        do {
            let realm = try realmProvider.realm()
            try realm.write {
                let key = chartKey(coinId: coinId, range: range)
                let obj = realm.object(ofType: RMCachedChart.self, forPrimaryKey: key) ?? RMCachedChart()
                if obj.realm == nil {
                    obj.key = key
                    obj.coinId = coinId
                    obj.rangeRaw = range.rawValue
                }
                obj.update(points: points, updatedAt: Date())
                realm.add(obj, update: .modified)
            }
        } catch {
            AppLogger.realm.error("Failed to store chart: \(error.localizedDescription)")
        }
    }

    private func chartKey(coinId: String, range: ChartRange) -> String {
        "\(coinId)_\(range.rawValue)"
    }
}
