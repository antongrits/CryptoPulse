import SwiftUI

struct CategoriesView: View {
    @StateObject var viewModel: CategoriesViewModel
    let marketRepository: MarketRepositoryProtocol
    let coinRepository: CoinRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol
    let portfolioRepository: PortfolioRepositoryProtocol
    let alertsRepository: AlertsRepositoryProtocol
    let notesRepository: NotesRepositoryProtocol

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    MarketSearchBar(text: $viewModel.searchText, placeholder: NSLocalizedString("Search categories", comment: ""))

                    HStack {
                        Text(NSLocalizedString("Sort", comment: ""))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Picker(NSLocalizedString("Sort", comment: ""), selection: $viewModel.sort) {
                            ForEach(CategorySort.allCases) { sort in
                                Text(sort.title).tag(sort)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    if viewModel.showOfflineBanner {
                        BannerView(title: NSLocalizedString("Offline mode. Showing cached data.", comment: ""), systemImage: "wifi.slash")
                    } else if let error = viewModel.error, !viewModel.categories.isEmpty {
                        BannerView(title: error.errorDescription ?? NSLocalizedString("Try again.", comment: ""), systemImage: "exclamationmark.triangle")
                    }

                    if viewModel.isLoading && viewModel.categories.isEmpty {
                        ProgressView()
                            .padding(.vertical, AppSpacing.lg)
                    } else if let error = viewModel.error, viewModel.categories.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("Something went wrong", comment: ""),
                            message: error.errorDescription ?? NSLocalizedString("Try again.", comment: ""),
                            assetName: "EmptyMarket",
                            systemImageFallback: "square.grid.2x2",
                            actionTitle: NSLocalizedString("Retry", comment: ""),
                            action: { Task { await viewModel.refresh() } }
                        )
                    } else if viewModel.displayedCategories.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("No results", comment: ""),
                            message: NSLocalizedString("Try another search query.", comment: ""),
                            assetName: "EmptyMarket",
                            systemImageFallback: "magnifyingglass"
                        )
                    } else {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(viewModel.pagedCategories) { category in
                                NavigationLink {
                                    CategoryMarketsView(
                                        viewModel: CategoryMarketsViewModel(
                                            marketRepository: marketRepository,
                                            categoryId: category.id,
                                            categoryName: category.name
                                        ),
                                        coinRepository: coinRepository,
                                        favoritesRepository: favoritesRepository,
                                        portfolioRepository: portfolioRepository,
                                        alertsRepository: alertsRepository,
                                        notesRepository: notesRepository
                                    )
                                } label: {
                                    CategoryRowView(category: category)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    viewModel.loadMoreIfNeeded(current: category)
                                }
                            }
                            if viewModel.canLoadMore {
                                ProgressView()
                                    .padding(.vertical, AppSpacing.sm)
                            }
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle(NSLocalizedString("Categories", comment: ""))
            .refreshable { await viewModel.refresh(force: true) }
            .task { await viewModel.loadIfNeeded() }
        }
    }
}

struct CategoryRowView: View {
    let category: MarketCategoryStats

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text(category.name)
                        .font(AppTypography.headline)
                        .lineLimit(2)
                    Spacer()
                    if let change = category.marketCapChange24h {
                        Text(PercentFormatter.string(change))
                            .font(AppTypography.caption)
                            .foregroundColor(change >= 0 ? AppColors.positive : AppColors.negative)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Market Cap", comment: ""))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(PriceFormatter.short(category.marketCap))
                            .font(AppTypography.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Volume 24h", comment: ""))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(PriceFormatter.short(category.volume24h))
                            .font(AppTypography.headline)
                    }
                }

                if !category.top3CoinImageURLs.isEmpty {
                    HStack(spacing: 6) {
                        Text(NSLocalizedString("Top Coins", comment: ""))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        ForEach(Array(category.top3CoinImageURLs.prefix(3).enumerated()), id: \.offset) { _, url in
                            CachedAsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Image(systemName: "bitcoinsign.circle")
                            }
                            .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CategoriesView(
        viewModel: CategoriesViewModel(marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview"))),
        marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        coinRepository: CoinRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        favoritesRepository: FavoritesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        portfolioRepository: PortfolioRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        alertsRepository: AlertsRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        notesRepository: NotesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    )
}
