import Foundation
import Combine

@MainActor
final class ConverterViewModel: ObservableObject {
    @Published var coins: [CoinMarket] = [] {
        didSet {
            if !coins.isEmpty {
                error = nil
            }
        }
    }
    @Published var selectedCoin: CoinMarket?
    @Published var usdText: String = ""
    @Published var coinText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: NetworkError?
    @Published var lastUpdated: Date?
    @Published var history: [ConversionRecord] = []
    @Published var showOfflineBanner: Bool = false

    private let marketRepository: MarketRepositoryProtocol
    private let historyRepository: ConversionHistoryRepositoryProtocol
    private var hasLoaded = false
    private let perPage = 50

    init(marketRepository: MarketRepositoryProtocol, historyRepository: ConversionHistoryRepositoryProtocol) {
        self.marketRepository = marketRepository
        self.historyRepository = historyRepository
        loadCached()
        loadHistory()
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    func loadCached() {
        let cached = marketRepository.cachedMarkets(sortedBy: .marketCapDesc)
        coins = cached
        if selectedCoin == nil || !coins.contains(where: { $0.id == selectedCoin?.id }) {
            selectedCoin = cached.first
        }
    }

    func loadHistory() {
        history = historyRepository.recent(limit: 20)
    }

    func updateUSD(_ text: String) {
        let sanitized = NumberParsing.sanitizeDecimalInput(text)
        usdText = sanitized
        guard let usd = NumberParsing.double(from: sanitized), let price = selectedCoin?.currentPrice, price > 0 else {
            coinText = ""
            return
        }
        coinText = NumberParsing.string(from: usd / price, maximumFractionDigits: 8)
    }

    func updateCoin(_ text: String) {
        let sanitized = NumberParsing.sanitizeDecimalInput(text)
        coinText = sanitized
        guard let coin = NumberParsing.double(from: sanitized), let price = selectedCoin?.currentPrice, price > 0 else {
            usdText = ""
            return
        }
        usdText = NumberParsing.string(from: coin * price, maximumFractionDigits: 2)
    }

    func selectCoin(_ coin: CoinMarket) {
        selectedCoin = coin
        if let usd = NumberParsing.double(from: usdText) {
            updateUSD(NumberParsing.string(from: usd, maximumFractionDigits: 8))
        } else if let coinValue = NumberParsing.double(from: coinText) {
            updateCoin(NumberParsing.string(from: coinValue, maximumFractionDigits: 8))
        }
    }

    func commitConversion() {
        guard let coin = selectedCoin else { return }
        guard let usd = NumberParsing.double(from: usdText),
              let amount = NumberParsing.double(from: coinText) else { return }
        let record = ConversionRecord(
            id: UUID().uuidString,
            coinId: coin.id,
            symbol: coin.symbol,
            name: coin.name,
            usdAmount: usd,
            coinAmount: amount,
            createdAt: Date()
        )
        historyRepository.addRecord(record)
        loadHistory()
    }

    func clearHistory() {
        historyRepository.clear()
        loadHistory()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        showOfflineBanner = false
        do {
            let markets = try await NetworkRetry.run {
                try await marketRepository.fetchMarkets(page: 1, perPage: perPage, sort: .marketCapDesc)
            }
            coins = markets
            lastUpdated = Date()
            if selectedCoin == nil || !markets.contains(where: { $0.id == selectedCoin?.id }) {
                selectedCoin = markets.first
            }
            if let usd = NumberParsing.double(from: usdText) {
                updateUSD(NumberParsing.string(from: usd, maximumFractionDigits: 8))
            } else if let coinValue = NumberParsing.double(from: coinText) {
                updateCoin(NumberParsing.string(from: coinValue, maximumFractionDigits: 8))
            }
        } catch let networkError as NetworkError {
            let cached = marketRepository.cachedMarkets(sortedBy: .marketCapDesc)
            if !cached.isEmpty {
                coins = cached
                if selectedCoin == nil || !cached.contains(where: { $0.id == selectedCoin?.id }) {
                    selectedCoin = cached.first
                }
                if shouldShowNonBlockingBanner(for: networkError) {
                    showOfflineBanner = true
                } else {
                    self.error = networkError
                }
                return
            }
            self.error = networkError
        } catch is CancellationError {
            return
        } catch {
            let cached = marketRepository.cachedMarkets(sortedBy: .marketCapDesc)
            if !cached.isEmpty {
                coins = cached
                if selectedCoin == nil || !cached.contains(where: { $0.id == selectedCoin?.id }) {
                    selectedCoin = cached.first
                }
                showOfflineBanner = true
            } else {
                self.error = .unknown
            }
        }
    }

    func swapInputs() {
        let tmp = usdText
        usdText = coinText
        coinText = tmp
    }

    var resultSummary: String? {
        guard let coin = selectedCoin else { return nil }
        guard let usd = NumberParsing.double(from: usdText),
              let amount = NumberParsing.double(from: coinText) else { return nil }
        let usdString = PriceFormatter.string(usd)
        let coinString = NumberParsing.string(from: amount, maximumFractionDigits: 8)
        return "\(usdString) = \(coinString) \(coin.symbol.uppercased())"
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
