import SwiftUI

struct SearchView: View {
    @StateObject var viewModel: SearchViewModel
    let coinRepository: CoinRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol
    let portfolioRepository: PortfolioRepositoryProtocol
    let alertsRepository: AlertsRepositoryProtocol
    let notesRepository: NotesRepositoryProtocol

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    MarketSearchBar(text: $viewModel.query)
                        .onChange(of: viewModel.query) { _ in
                            viewModel.search()
                        }
                        .onSubmit {
                            viewModel.commitSearch()
                        }

                    if viewModel.query.isEmpty {
                        recentSection
                    } else if viewModel.results.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("No results", comment: ""),
                            message: NSLocalizedString("Try another query.", comment: ""),
                            assetName: "EmptySearch",
                            systemImageFallback: "magnifyingglass"
                        )
                    } else {
                        resultsSection
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle(NSLocalizedString("Search", comment: ""))
            .onAppear { viewModel.loadRecents() }
        }
    }

    private var resultsSection: some View {
        LazyVStack(spacing: AppSpacing.md) {
            ForEach(viewModel.results) { coin in
                NavigationLink {
                    CoinDetailsView(viewModel: CoinDetailsViewModel(
                        coinId: coin.id,
                        coinRepository: coinRepository,
                        favoritesRepository: favoritesRepository,
                        portfolioRepository: portfolioRepository,
                        alertsRepository: alertsRepository,
                        notesRepository: notesRepository
                    ))
                } label: {
                    CardView { MarketRowView(coin: coin) }
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.commitSearch()
                })
            }
        }
    }

    private var recentSection: some View {
        VStack(spacing: AppSpacing.md) {
            if viewModel.recent.isEmpty {
                EmptyStateView(
                    title: NSLocalizedString("Recent searches", comment: ""),
                    message: NSLocalizedString("Your recent queries will appear here.", comment: ""),
                    assetName: "EmptySearch",
                    systemImageFallback: "clock"
                )
            } else {
                HStack {
                    Text(NSLocalizedString("Recent", comment: ""))
                        .font(AppTypography.headline)
                    Spacer()
                    Button(NSLocalizedString("Clear", comment: "")) {
                        viewModel.clearHistory()
                    }
                }

                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.recent) { item in
                        Button {
                            viewModel.query = item.query
                            viewModel.search()
                        } label: {
                            HStack {
                                Image(systemName: "clock")
                                Text(item.query)
                                Spacer()
                            }
                            .padding(.vertical, AppSpacing.sm)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    SearchView(
        viewModel: SearchViewModel(
            marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
            searchRepository: SearchRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
        ),
        coinRepository: CoinRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        favoritesRepository: FavoritesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        portfolioRepository: PortfolioRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        alertsRepository: AlertsRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        notesRepository: NotesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    )
    .environmentObject(AppEnvironment())
}
