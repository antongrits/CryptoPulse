import Foundation
import Combine

enum CategorySort: String, CaseIterable, Identifiable {
    case marketCapDesc
    case changeDesc
    case volumeDesc
    case alphabetical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .marketCapDesc: return NSLocalizedString("Market Cap", comment: "")
        case .changeDesc: return NSLocalizedString("24h Change", comment: "")
        case .volumeDesc: return NSLocalizedString("Volume 24h", comment: "")
        case .alphabetical: return NSLocalizedString("A–Z", comment: "")
        }
    }
}

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var categories: [MarketCategoryStats] = []
    @Published var isLoading: Bool = false
    @Published var error: NetworkError?
    @Published var searchText: String = "" {
        didSet { resetPagination() }
    }
    @Published var sort: CategorySort = .marketCapDesc {
        didSet { resetPagination() }
    }
    @Published var showOfflineBanner: Bool = false
    @Published private(set) var visibleCount: Int = 30

    private let marketRepository: MarketRepositoryProtocol
    private var hasLoaded = false
    private let pageSize = 30

    init(marketRepository: MarketRepositoryProtocol) {
        self.marketRepository = marketRepository
        loadCached()
    }

    func loadIfNeeded(force: Bool = false) async {
        if hasLoaded && !force { return }
        hasLoaded = true
        await refresh(force: force)
    }

    var displayedCategories: [MarketCategoryStats] {
        let filtered = searchText.isEmpty ? categories : categories.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        return sortCategories(filtered)
    }

    var pagedCategories: [MarketCategoryStats] {
        Array(displayedCategories.prefix(visibleCount))
    }

    var canLoadMore: Bool {
        displayedCategories.count > visibleCount
    }

    func refresh(force: Bool = false) async {
        if !force, marketRepository.isCategoryStatsCacheValid(), !categories.isEmpty {
            return
        }
        isLoading = true
        defer { isLoading = false }
        error = nil
        showOfflineBanner = false
        do {
            let items = try await NetworkRetry.run {
                try await marketRepository.fetchCategoryStats()
            }
            categories = sanitize(items)
            resetPagination()
        } catch let networkError as NetworkError {
            if categories.isEmpty {
                loadCached()
            }
            if !categories.isEmpty, shouldShowNonBlockingBanner(for: networkError) {
                showOfflineBanner = true
            } else {
                self.error = networkError
            }
        } catch {
            self.error = .unknown
        }
    }

    func loadCached() {
        let cached = sanitize(marketRepository.cachedCategoryStats())
        if !cached.isEmpty {
            categories = cached
            resetPagination()
        }
    }

    func loadMoreIfNeeded(current category: MarketCategoryStats) {
        guard canLoadMore else { return }
        guard let last = pagedCategories.last, last.id == category.id else { return }
        visibleCount += pageSize
    }

    private func resetPagination() {
        visibleCount = pageSize
    }

    private func sortCategories(_ items: [MarketCategoryStats]) -> [MarketCategoryStats] {
        switch sort {
        case .marketCapDesc:
            return items.sorted { ($0.marketCap ?? 0) > ($1.marketCap ?? 0) }
        case .changeDesc:
            return items.sorted { ($0.marketCapChange24h ?? 0) > ($1.marketCapChange24h ?? 0) }
        case .volumeDesc:
            return items.sorted { ($0.volume24h ?? 0) > ($1.volume24h ?? 0) }
        case .alphabetical:
            return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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

    private func sanitize(_ items: [MarketCategoryStats]) -> [MarketCategoryStats] {
        let nonZero = items.filter {
            ($0.marketCap ?? 0) > 0 || ($0.volume24h ?? 0) > 0
        }
        return nonZero.isEmpty ? items : nonZero
    }
}
