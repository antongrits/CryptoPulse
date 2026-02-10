import Foundation
import Combine

@MainActor
final class CoinDetailsViewModel: ObservableObject {
    @Published var details: CoinDetails?
    @Published var chart: [PricePoint] = []
    @Published var selectedRange: ChartRange = .sevenDays
    @Published var availableRanges: [ChartRange] = ChartRange.allCases
    @Published var isLoadingDetails = false
    @Published var isLoadingChart = false
    @Published var detailsError: NetworkError?
    @Published var chartError: NetworkError?
    @Published var isFavorite: Bool = false
    @Published var noteText: String = ""
    @Published var noteLastUpdated: Date?
    @Published var notes: [CoinNote] = []
    @Published var detailsLoadedAt: Date?

    let coinId: String
    private let coinRepository: CoinRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let portfolioRepository: PortfolioRepositoryProtocol
    private let alertsRepository: AlertsRepositoryProtocol
    private let notesRepository: NotesRepositoryProtocol
    private var unsupportedRanges: Set<String> = []

    init(coinId: String,
         coinRepository: CoinRepositoryProtocol,
         favoritesRepository: FavoritesRepositoryProtocol,
         portfolioRepository: PortfolioRepositoryProtocol,
         alertsRepository: AlertsRepositoryProtocol,
         notesRepository: NotesRepositoryProtocol) {
        self.coinId = coinId
        self.coinRepository = coinRepository
        self.favoritesRepository = favoritesRepository
        self.portfolioRepository = portfolioRepository
        self.alertsRepository = alertsRepository
        self.notesRepository = notesRepository

        unsupportedRanges = loadUnsupportedRanges()
        let baseRanges = ChartRange.allCases.filter { range in
            if range == .all {
                return AppConfig.supportsExtendedChartHistory
            }
            return true
        }
        availableRanges = baseRanges.filter { !unsupportedRanges.contains($0.rawValue) }
        if availableRanges.isEmpty {
            availableRanges = [.sevenDays]
        }
        if !availableRanges.contains(selectedRange) {
            selectedRange = availableRanges.first ?? .sevenDays
        }

        loadCached()
        Task { await refresh() }
    }

    func loadCached() {
        isFavorite = favoritesRepository.isFavorite(coinId: coinId)
        if let cached = coinRepository.cachedDetails(for: coinId) {
            details = cached
            detailsLoadedAt = Date()
        }
        let cachedChart = coinRepository.cachedChart(for: coinId, range: selectedRange)
        if !cachedChart.isEmpty { chart = cachedChart }
        notes = notesRepository.notes(for: coinId)
        noteLastUpdated = notes.first?.updatedAt
    }

    func refresh() async {
        await loadDetails()
        let success = await loadChart()
        if !success, let fallback = availableRanges.first, fallback != selectedRange {
            selectedRange = fallback
            _ = await loadChart(force: true)
        }
    }

    func loadDetails(force: Bool = false) async {
        detailsError = nil
        if !force, coinRepository.isDetailsCacheValid(for: coinId),
           let cached = coinRepository.cachedDetails(for: coinId) {
            details = cached
            detailsLoadedAt = Date()
            return
        }
        isLoadingDetails = true
        defer { isLoadingDetails = false }
        do {
            let details = try await coinRepository.fetchDetails(for: coinId)
            self.details = details
            detailsLoadedAt = Date()
        } catch let error as NetworkError {
            detailsError = error
        } catch {
            detailsError = .unknown
        }
    }

    @discardableResult
    func loadChart(force: Bool = false) async -> Bool {
        chartError = nil
        if !force, coinRepository.isChartCacheValid(for: coinId, range: selectedRange) {
            let cached = coinRepository.cachedChart(for: coinId, range: selectedRange)
            if !cached.isEmpty {
                chart = cached
                return true
            }
        }
        isLoadingChart = true
        defer { isLoadingChart = false }
        do {
            let chart = try await coinRepository.fetchChart(for: coinId, range: selectedRange)
            if chart.count < 2 {
                chartError = .decoding
                markRangeUnsupported(selectedRange)
                if availableRanges.isEmpty {
                    availableRanges = [.sevenDays]
                }
                return false
            } else {
                self.chart = chart
                if !availableRanges.contains(selectedRange) {
                    availableRanges.append(selectedRange)
                }
                unmarkRangeUnsupported(selectedRange)
                return true
            }
        } catch let error as NetworkError {
            if handleRangeErrorIfNeeded(error) {
                return false
            }
            chartError = error
            return false
        } catch {
            chartError = .unknown
            return false
        }
    }

    func selectRange(_ range: ChartRange) async {
        guard range != selectedRange else { return }
        selectedRange = range
        let success = await loadChart(force: true)
        if !success, let fallback = availableRanges.first, fallback != selectedRange {
            selectedRange = fallback
            _ = await loadChart(force: true)
        }
    }

    @discardableResult
    private func handleRangeErrorIfNeeded(_ error: NetworkError) -> Bool {
        guard case let .server(statusCode) = error, [400, 404].contains(statusCode) else { return false }
        markRangeUnsupported(selectedRange)
        if availableRanges.isEmpty {
            availableRanges = [.sevenDays]
        }
        return true
    }

    var chartStats: ChartStats? {
        guard let first = chart.first, let last = chart.last else { return nil }
        let prices = chart.map { $0.price }
        let high = prices.max() ?? last.price
        let low = prices.min() ?? last.price
        let change = last.price - first.price
        let changePercent = first.price == 0 ? 0 : (change / first.price) * 100
        return ChartStats(start: first.price, end: last.price, high: high, low: low, change: change, changePercent: changePercent)
    }

    func toggleFavorite() {
        guard let details else { return }
        if isFavorite {
            favoritesRepository.removeFavorite(coinId: details.id)
            isFavorite = false
        } else {
            let market = CoinMarket(
                id: details.id,
                name: details.name,
                symbol: details.symbol,
                imageURL: details.imageURL,
                currentPrice: details.currentPrice,
                priceChangePercentage24h: details.priceChangePercentage24h,
                marketCap: details.marketCap,
                totalVolume: details.totalVolume,
                high24h: details.high24h,
                low24h: details.low24h,
                lastUpdated: details.lastUpdated
            )
            favoritesRepository.addFavorite(market)
            isFavorite = true
        }
    }

    func addHolding(amount: Double, avgBuyPrice: Double?) {
        guard let details else { return }
        let existing = portfolioRepository.holdings().first { $0.coinId == details.id }
        let merged = mergeHolding(existing: existing, coinId: details.id, symbol: details.symbol, name: details.name, amount: amount, avgBuyPrice: avgBuyPrice)
        portfolioRepository.upsertHolding(merged)
    }

    func createAlert(targetPrice: Double, metric: PriceAlertMetric, direction: PriceAlertDirection, repeatMode: PriceAlertRepeatMode, cooldownMinutes: Int) {
        guard let details else { return }
        let alert = PriceAlert(
            id: UUID().uuidString,
            coinId: details.id,
            symbol: details.symbol,
            name: details.name,
            targetValue: targetPrice,
            metric: metric,
            direction: direction,
            repeatMode: repeatMode,
            cooldownMinutes: cooldownMinutes,
            isEnabled: true,
            isArmed: true,
            createdAt: Date(),
            lastTriggeredAt: nil
        )
        alertsRepository.upsertAlert(alert)
    }

    func saveNote() {
        let text = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let coinName = details?.name ?? coinId
        let coinSymbol = details?.symbol ?? coinId
        let note = notesRepository.addNote(
            coinId: coinId,
            coinName: coinName,
            coinSymbol: coinSymbol,
            text: text
        )
        noteText = ""
        notes.insert(note, at: 0)
        noteLastUpdated = note.updatedAt
    }

    func deleteNote(id: String) {
        notesRepository.deleteNote(id: id)
        notes.removeAll { $0.id == id }
        noteLastUpdated = notes.first?.updatedAt
    }

    func clearAllNotes() {
        notesRepository.deleteNotes(coinId: coinId)
        notes.removeAll()
        noteLastUpdated = nil
    }

    private func mergeHolding(existing: Holding?, coinId: String, symbol: String, name: String, amount: Double, avgBuyPrice: Double?) -> Holding {
        guard let existing else {
            return Holding(
                id: UUID().uuidString,
                coinId: coinId,
                symbol: symbol,
                name: name,
                amount: amount,
                avgBuyPrice: avgBuyPrice,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        let newAmount = existing.amount + amount
        let newAvg: Double?
        switch (existing.avgBuyPrice, avgBuyPrice) {
        case let (lhs?, rhs?):
            newAvg = (lhs * existing.amount + rhs * amount) / max(newAmount, 0.0001)
        case let (lhs?, nil):
            newAvg = lhs
        case let (nil, rhs?):
            newAvg = rhs
        default:
            newAvg = nil
        }
        return Holding(
            id: existing.id,
            coinId: existing.coinId,
            symbol: existing.symbol,
            name: existing.name,
            amount: newAmount,
            avgBuyPrice: newAvg,
            createdAt: existing.createdAt,
            updatedAt: Date()
        )
    }

    private func unsupportedRangesKey() -> String {
        "unsupported_chart_ranges_\(coinId)"
    }

    private func loadUnsupportedRanges() -> Set<String> {
        let raw = UserDefaults.standard.array(forKey: unsupportedRangesKey()) as? [String] ?? []
        return Set(raw)
    }

    private func saveUnsupportedRanges() {
        UserDefaults.standard.set(Array(unsupportedRanges), forKey: unsupportedRangesKey())
    }

    private func markRangeUnsupported(_ range: ChartRange) {
        unsupportedRanges.insert(range.rawValue)
        availableRanges.removeAll { $0 == range }
        saveUnsupportedRanges()
    }

    private func unmarkRangeUnsupported(_ range: ChartRange) {
        if unsupportedRanges.remove(range.rawValue) != nil {
            saveUnsupportedRanges()
        }
    }
}

struct ChartStats {
    let start: Double
    let end: Double
    let high: Double
    let low: Double
    let change: Double
    let changePercent: Double
}
