import Foundation

protocol CoinRepositoryProtocol {
    func cachedDetails(for coinId: String) -> CoinDetails?
    func cachedChart(for coinId: String, range: ChartRange) -> [PricePoint]
    func isDetailsCacheValid(for coinId: String) -> Bool
    func isChartCacheValid(for coinId: String, range: ChartRange) -> Bool
    func fetchDetails(for coinId: String) async throws -> CoinDetails
    func fetchChart(for coinId: String, range: ChartRange) async throws -> [PricePoint]
}
