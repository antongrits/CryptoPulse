import SwiftUI

struct MoreView: View {
    let marketRepository: MarketRepositoryProtocol
    let coinRepository: CoinRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol
    let portfolioRepository: PortfolioRepositoryProtocol
    let alertsRepository: AlertsRepositoryProtocol
    let notesRepository: NotesRepositoryProtocol
    let searchRepository: SearchRepositoryProtocol
    let conversionHistoryRepository: ConversionHistoryRepositoryProtocol
    @EnvironmentObject private var appEnv: AppEnvironment

    var body: some View {
        AppNavigationContainer {
            List {
                NavigationLink {
                    ConverterView(viewModel: ConverterViewModel(
                        marketRepository: marketRepository,
                        historyRepository: conversionHistoryRepository
                    ))
                } label: {
                    Label(NSLocalizedString("Converter", comment: ""), systemImage: "arrow.left.arrow.right")
                }
                NavigationLink {
                    SearchView(
                        viewModel: SearchViewModel(
                            marketRepository: marketRepository,
                            searchRepository: searchRepository
                        ),
                        coinRepository: coinRepository,
                        favoritesRepository: favoritesRepository,
                        portfolioRepository: portfolioRepository,
                        alertsRepository: alertsRepository,
                        notesRepository: notesRepository
                    )
                } label: {
                    Label(NSLocalizedString("Search", comment: ""), systemImage: "magnifyingglass")
                }
                NavigationLink {
                    InsightsView(viewModel: InsightsViewModel(
                        marketRepository: marketRepository,
                        portfolioRepository: portfolioRepository,
                        favoritesRepository: favoritesRepository
                    ))
                } label: {
                    Label(NSLocalizedString("Insights", comment: ""), systemImage: "waveform.path.ecg")
                }
                NavigationLink {
                    CompareView(viewModel: CompareViewModel(marketRepository: marketRepository))
                } label: {
                    Label(NSLocalizedString("Compare", comment: ""), systemImage: "arrow.left.arrow.right")
                }
                NavigationLink {
                    ProfitCalculatorView(viewModel: ProfitCalculatorViewModel(marketRepository: marketRepository))
                } label: {
                    Label(NSLocalizedString("Profit Calculator", comment: ""), systemImage: "function")
                }
                NavigationLink {
                    NotesLibraryView(
                        viewModel: NotesLibraryViewModel(notesRepository: notesRepository),
                        coinRepository: coinRepository,
                        favoritesRepository: favoritesRepository,
                        portfolioRepository: portfolioRepository,
                        alertsRepository: alertsRepository,
                        notesRepository: notesRepository
                    )
                } label: {
                    Label(NSLocalizedString("Notes", comment: ""), systemImage: "note.text")
                }
                NavigationLink {
                    CategoriesView(
                        viewModel: CategoriesViewModel(marketRepository: marketRepository),
                        marketRepository: marketRepository,
                        coinRepository: coinRepository,
                        favoritesRepository: favoritesRepository,
                        portfolioRepository: portfolioRepository,
                        alertsRepository: alertsRepository,
                        notesRepository: notesRepository
                    )
                } label: {
                    Label(NSLocalizedString("Categories", comment: ""), systemImage: "square.grid.2x2")
                }
                NavigationLink {
                    ExchangesView(viewModel: ExchangesViewModel(marketRepository: marketRepository))
                } label: {
                    Label(NSLocalizedString("Exchanges", comment: ""), systemImage: "building.2")
                }
                NavigationLink {
                    DominanceView(viewModel: DominanceViewModel(marketRepository: marketRepository))
                } label: {
                    Label(NSLocalizedString("Dominance", comment: ""), systemImage: "chart.pie")
                }
                NavigationLink {
                    HeatmapView(
                        viewModel: HeatmapViewModel(marketRepository: marketRepository),
                        coinRepository: coinRepository,
                        favoritesRepository: favoritesRepository,
                        portfolioRepository: portfolioRepository,
                        alertsRepository: alertsRepository,
                        notesRepository: notesRepository
                    )
                } label: {
                    Label(NSLocalizedString("Heatmap", comment: ""), systemImage: "square.grid.3x3.fill")
                }
                NavigationLink {
                    SettingsView()
                        .environmentObject(appEnv)
                } label: {
                    Label(NSLocalizedString("Settings", comment: ""), systemImage: "gearshape")
                }
                NavigationLink {
                    WidgetsInfoView()
                } label: {
                    Label(NSLocalizedString("Home Screen Widgets", comment: ""), systemImage: "rectangle.grid.1x2")
                }
            }
            .navigationTitle(NSLocalizedString("More", comment: ""))
        }
    }
}

#Preview {
    MoreView(
        marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        coinRepository: CoinRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        favoritesRepository: FavoritesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        portfolioRepository: PortfolioRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        alertsRepository: AlertsRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        notesRepository: NotesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        searchRepository: SearchRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        conversionHistoryRepository: ConversionHistoryRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    )
        .environmentObject(AppEnvironment())
}
