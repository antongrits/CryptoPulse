import Foundation
import Combine
import SwiftUI

@MainActor
final class HeatmapViewModel: ObservableObject {
    @Published var coins: [CoinMarket] = []
    @Published var isLoading: Bool = false
    @Published var error: NetworkError?
    @Published var filter: HeatmapFilter = .top60
    @Published var tileScale: Double = 1.0
    @Published var pinnedCoinId: String?
    @Published var categories: [MarketCategory] = []
    @Published var selectedCategoryId: String = ""

    private let marketRepository: MarketRepositoryProtocol
    private let scaleKey = "heatmap_tile_scale"
    private let pinKey = "heatmap_pinned_coin_id"
    private let categoryKey = "heatmap_category_id"
    private var hasLoaded = false

    init(marketRepository: MarketRepositoryProtocol) {
        self.marketRepository = marketRepository
        let stored = UserDefaults.standard.double(forKey: scaleKey)
        tileScale = stored == 0 ? 1.0 : stored
        pinnedCoinId = UserDefaults.standard.string(forKey: pinKey)
        selectedCategoryId = UserDefaults.standard.string(forKey: categoryKey) ?? ""
        load()
        loadCachedCategories()
        if !selectedCategoryId.isEmpty, !categories.contains(where: { $0.id == selectedCategoryId }) {
            selectedCategoryId = ""
            UserDefaults.standard.removeObject(forKey: categoryKey)
        }
    }

    func loadIfNeeded(force: Bool = false) async {
        if hasLoaded && !force { return }
        hasLoaded = true
        await loadCategories(force: force)
        await refresh()
    }

    func load() {
        guard selectedCategoryId.isEmpty else { return }
        coins = marketRepository.cachedMarkets(sortedBy: .marketCapDesc)
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        do {
            let category = selectedCategoryId.isEmpty ? nil : selectedCategoryId
            let fresh = try await NetworkRetry.run {
                try await marketRepository.fetchMarkets(page: 1, perPage: 100, sort: .marketCapDesc, category: category)
            }
            coins = fresh
        } catch let networkError as NetworkError {
            self.error = networkError
        } catch {
            self.error = .unknown
        }
    }

    var heatmapCoins: [CoinMarket] {
        coins.sorted { ($0.marketCap ?? 0) > ($1.marketCap ?? 0) }
            .prefix(filter.limit)
            .map { $0 }
    }

    var pinnedCoin: CoinMarket? {
        guard let pinnedCoinId else { return nil }
        return coins.first(where: { $0.id == pinnedCoinId })
    }

    func sizeScale(for coin: CoinMarket) -> CGFloat {
        let caps = heatmapCoins.compactMap { $0.marketCap }
        guard let min = caps.min(), let max = caps.max(), max > min else { return 1 }
        let cap = coin.marketCap ?? min
        let normalized = (cap - min) / (max - min)
        let base = 0.8 + CGFloat(normalized) * 0.8
        return base * CGFloat(tileScale)
    }

    func updateTileScale(_ value: Double) {
        let clamped = min(1.2, max(0.85, value))
        tileScale = clamped
        UserDefaults.standard.set(clamped, forKey: scaleKey)
    }

    func togglePin(for coin: CoinMarket) {
        if pinnedCoinId == coin.id {
            pinnedCoinId = nil
            UserDefaults.standard.removeObject(forKey: pinKey)
        } else {
            pinnedCoinId = coin.id
            UserDefaults.standard.set(coin.id, forKey: pinKey)
        }
    }

    func loadCategories(force: Bool = false) async {
        do {
            if !force, marketRepository.isCategoriesCacheValid(), !categories.isEmpty {
                return
            }
            let categories = try await NetworkRetry.run {
                try await marketRepository.fetchCategories()
            }
            let sorted = categories.sorted { $0.name < $1.name }
            self.categories = sorted
            if !selectedCategoryId.isEmpty, !sorted.contains(where: { $0.id == selectedCategoryId }) {
                selectedCategoryId = ""
                UserDefaults.standard.removeObject(forKey: categoryKey)
            }
        } catch {
            self.categories = []
        }
    }

    private func loadCachedCategories() {
        let cached = marketRepository.cachedCategories()
        if !cached.isEmpty {
            categories = cached.sorted { $0.name < $1.name }
            if !selectedCategoryId.isEmpty, !categories.contains(where: { $0.id == selectedCategoryId }) {
                selectedCategoryId = ""
                UserDefaults.standard.removeObject(forKey: categoryKey)
            }
        }
    }

    func selectCategory(_ id: String) {
        selectedCategoryId = id
        if id.isEmpty {
            UserDefaults.standard.removeObject(forKey: categoryKey)
        } else {
            UserDefaults.standard.set(id, forKey: categoryKey)
        }
        Task { await refresh() }
    }

    func color(for change: Double) -> (Color, Color) {
        let intensity = min(1, max(0.2, abs(change) / 15))
        if change >= 0 {
            return (AppColors.positive.opacity(0.35 + intensity * 0.4),
                    AppColors.positive.opacity(0.15))
        } else {
            return (AppColors.negative.opacity(0.35 + intensity * 0.4),
                    AppColors.negative.opacity(0.15))
        }
    }
}

enum HeatmapFilter: String, CaseIterable, Identifiable {
    case top20
    case top40
    case top60
    case top100

    var id: String { rawValue }

    var title: String {
        switch self {
        case .top20: return NSLocalizedString("Top 20", comment: "")
        case .top40: return NSLocalizedString("Top 40", comment: "")
        case .top60: return NSLocalizedString("Top 60", comment: "")
        case .top100: return NSLocalizedString("Top 100", comment: "")
        }
    }

    var limit: Int {
        switch self {
        case .top20: return 20
        case .top40: return 40
        case .top60: return 60
        case .top100: return 100
        }
    }
}
