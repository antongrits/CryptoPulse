import Foundation
import Combine

@MainActor
final class DominanceViewModel: ObservableObject {
    @Published var global: GlobalMarket?
    @Published var isLoading: Bool = false
    @Published var error: NetworkError?
    @Published var showOfflineBanner: Bool = false

    private let marketRepository: MarketRepositoryProtocol
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

    func refresh(force: Bool = false) async {
        if !force, marketRepository.isGlobalCacheValid(), global != nil {
            return
        }
        isLoading = true
        defer { isLoading = false }
        error = nil
        showOfflineBanner = false
        do {
            let global = try await NetworkRetry.run {
                try await marketRepository.fetchGlobalMarket()
            }
            self.global = global
        } catch let networkError as NetworkError {
            if global == nil {
                loadCached()
            }
            if global != nil, shouldShowNonBlockingBanner(for: networkError) {
                showOfflineBanner = true
            } else {
                self.error = networkError
            }
        } catch {
            self.error = .unknown
        }
    }

    func loadCached() {
        if let cached = marketRepository.cachedGlobalMarket() {
            global = cached
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
