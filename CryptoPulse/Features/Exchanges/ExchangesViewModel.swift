import Foundation
import Combine

@MainActor
final class ExchangesViewModel: ObservableObject {
    @Published var exchanges: [Exchange] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var error: NetworkError?
    @Published var showOfflineBanner: Bool = false

    private let marketRepository: MarketRepositoryProtocol
    private var page: Int = 1
    private let perPage = 50
    private var hasMore = true
    private var hasLoaded = false

    init(marketRepository: MarketRepositoryProtocol) {
        self.marketRepository = marketRepository
        loadCached()
    }

    func loadIfNeeded(force: Bool = false) async {
        if hasLoaded && !force { return }
        hasLoaded = true
        await refresh(force: force)
    }

    var displayedExchanges: [Exchange] {
        let filtered = searchText.isEmpty ? exchanges : exchanges.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        return filtered
    }

    func refresh(force: Bool = false) async {
        if !force, marketRepository.isExchangesCacheValid(page: 1, perPage: perPage), !exchanges.isEmpty {
            return
        }
        page = 1
        hasMore = true
        error = nil
        isLoading = true
        showOfflineBanner = false
        defer { isLoading = false }
        do {
            let items = try await NetworkRetry.run {
                try await marketRepository.fetchExchanges(page: page, perPage: perPage)
            }
            exchanges = items
        } catch let networkError as NetworkError {
            if exchanges.isEmpty { loadCached() }
            if !exchanges.isEmpty, shouldShowNonBlockingBanner(for: networkError) {
                showOfflineBanner = true
                return
            }
            self.error = networkError
        } catch {
            self.error = .unknown
        }
    }

    func loadNextPageIfNeeded(current exchange: Exchange) async {
        guard let last = displayedExchanges.last, last.id == exchange.id else { return }
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        page += 1
        do {
            let items = try await NetworkRetry.run {
                try await marketRepository.fetchExchanges(page: page, perPage: perPage)
            }
            if items.isEmpty { hasMore = false }
            exchanges = merge(existing: exchanges, new: items)
        } catch let networkError as NetworkError {
            self.error = networkError
        } catch {
            self.error = .unknown
        }
    }

    func loadCached() {
        let cached = marketRepository.cachedExchanges(page: 1, perPage: perPage)
        if !cached.isEmpty {
            exchanges = cached
        }
    }

    private func merge(existing: [Exchange], new: [Exchange]) -> [Exchange] {
        var map = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        new.forEach { map[$0.id] = $0 }
        return Array(map.values).sorted { lhs, rhs in
            let left = lhs.trustScoreRank ?? Int.max
            let right = rhs.trustScoreRank ?? Int.max
            if left == right { return lhs.name < rhs.name }
            return left < right
        }
    }

    private func shouldShowNonBlockingBanner(for error: NetworkError) -> Bool {
        switch error {
        case .offline, .rateLimited:
            return true
        case .server(let statusCode):
            return statusCode == 400
        case .decoding, .unknown:
            return false
        }
    }
}
