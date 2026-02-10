import SwiftUI

struct CategoryMarketsView: View {
    @StateObject var viewModel: CategoryMarketsViewModel
    let coinRepository: CoinRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol
    let portfolioRepository: PortfolioRepositoryProtocol
    let alertsRepository: AlertsRepositoryProtocol
    let notesRepository: NotesRepositoryProtocol

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    MarketSearchBar(text: $viewModel.searchText)

                    HStack {
                        Text(NSLocalizedString("Sort", comment: ""))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Picker(NSLocalizedString("Sort", comment: ""), selection: $viewModel.sort) {
                            ForEach(MarketSort.allCases) { sort in
                                Text(sort.title).tag(sort)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    if let message = viewModel.fallbackMessage {
                        EmptyStateView(
                            title: NSLocalizedString("Unavailable", comment: ""),
                            message: message,
                            assetName: "EmptyMarket",
                            systemImageFallback: "exclamationmark.triangle"
                        )
                    } else if viewModel.isLoading && viewModel.coins.isEmpty {
                        MarketSkeletonView()
                    } else if let error = viewModel.error, viewModel.coins.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("Something went wrong", comment: ""),
                            message: error.errorDescription ?? NSLocalizedString("Try again.", comment: ""),
                            assetName: "EmptyMarket",
                            systemImageFallback: "exclamationmark.triangle",
                            actionTitle: NSLocalizedString("Retry", comment: ""),
                            action: { Task { await viewModel.refresh() } }
                        )
                    } else if viewModel.displayedCoins.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("No results", comment: ""),
                            message: NSLocalizedString("Try another search query.", comment: ""),
                            assetName: "EmptyMarket",
                            systemImageFallback: "magnifyingglass"
                        )
                    } else {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(viewModel.displayedCoins) { coin in
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
                                .onAppear {
                                    Task { await viewModel.loadNextPageIfNeeded(current: coin) }
                                }
                            }
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .padding(.vertical, AppSpacing.md)
                            }
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle(viewModel.categoryName)
            .refreshable { await viewModel.refresh() }
        }
    }
}

#Preview {
    CategoryMarketsView(
        viewModel: CategoryMarketsViewModel(
            marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
            categoryId: "layer-1",
            categoryName: "Layer 1"
        ),
        coinRepository: CoinRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        favoritesRepository: FavoritesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        portfolioRepository: PortfolioRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        alertsRepository: AlertsRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        notesRepository: NotesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    )
}
