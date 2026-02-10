import Foundation

final class AppDIContainer {
    let realmProvider: RealmProvider
    let marketRepository: MarketRepository
    let coinRepository: CoinRepository
    let favoritesRepository: FavoritesRepository
    let portfolioRepository: PortfolioRepository
    let alertsRepository: AlertsRepository
    let searchRepository: SearchRepository
    let notesRepository: NotesRepository
    let conversionHistoryRepository: ConversionHistoryRepository
    let alertsChecker: AlertsChecker

    init(useMockData: Bool = ProcessInfo.processInfo.arguments.contains("-use-mock-data"),
         inMemoryRealm: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing")) {
        let realmProvider = RealmProvider(inMemory: inMemoryRealm, identifier: "CryptoPulse")
        let service: CoinGeckoServiceProtocol
        if useMockData {
            service = MockCoinGeckoService()
        } else {
            let client = NetworkClient(baseURL: AppConfig.coinGeckoBaseURL)
            let fallbackClient: NetworkClientProtocol?
            if let fallback = AppConfig.coinGeckoFallbackBaseURL, fallback != AppConfig.coinGeckoBaseURL {
                fallbackClient = NetworkClient(baseURL: fallback)
            } else {
                fallbackClient = nil
            }
            let primary = CoinGeckoService(client: client, fallbackClient: fallbackClient)
            let paprikaClient = NetworkClient(baseURL: URL(string: "https://api.coinpaprika.com") ?? AppConfig.coinGeckoBaseURL)
            let paprikaService = CoinPaprikaService(client: paprikaClient)
            service = FallbackMarketService(primary: primary, secondary: paprikaService)
        }

        self.realmProvider = realmProvider
        self.marketRepository = MarketRepository(service: service, realmProvider: realmProvider)
        self.coinRepository = CoinRepository(service: service, realmProvider: realmProvider)
        self.favoritesRepository = FavoritesRepository(realmProvider: realmProvider)
        self.portfolioRepository = PortfolioRepository(realmProvider: realmProvider)
        self.alertsRepository = AlertsRepository(realmProvider: realmProvider)
        self.searchRepository = SearchRepository(realmProvider: realmProvider)
        self.notesRepository = NotesRepository(realmProvider: realmProvider)
        self.conversionHistoryRepository = ConversionHistoryRepository(realmProvider: realmProvider)
        self.alertsChecker = AlertsChecker(alertsRepository: alertsRepository, marketRepository: marketRepository)
    }
}
