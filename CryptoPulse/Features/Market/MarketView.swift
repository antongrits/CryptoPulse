import SwiftUI
import Combine

struct MarketView: View {
    @StateObject var viewModel: MarketViewModel
    let coinRepository: CoinRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol
    let portfolioRepository: PortfolioRepositoryProtocol
    let alertsRepository: AlertsRepositoryProtocol
    let notesRepository: NotesRepositoryProtocol

    @State private var showSettings = false
    @State private var section: MarketSection = .all
    @State private var autoRefresh = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    @AppStorage("market_layout") private var layoutRaw: String = MarketLayout.cards.rawValue
    @State private var isActive = false

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    MarketSearchBar(text: $viewModel.searchText)
                        .padding(.top, AppSpacing.sm)

                    HStack {
                        Text(NSLocalizedString("Sort", comment: ""))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Picker(NSLocalizedString("Sort", comment: ""), selection: Binding(
                            get: { viewModel.sort },
                            set: { viewModel.updateSort($0) }
                        )) {
                            ForEach(MarketSort.allCases) { sort in
                                Text(sort.title).tag(sort)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    SegmentedControl(options: MarketSection.allCases, selection: $section) { option in
                        option.title
                    }

                    if viewModel.showOfflineBanner {
                        BannerView(title: NSLocalizedString("Offline mode. Showing cached data.", comment: ""), systemImage: "wifi.slash")
                    }

                    sectionContent
                        .animation(.easeInOut(duration: 0.25), value: currentLayout)
                }
                .padding(.horizontal, AppSpacing.md)
            }
            .refreshable {
                await viewModel.refresh(force: true)
                await viewModel.loadTrendingIfNeeded(force: true)
            }
            .onReceive(autoRefresh) { _ in
                guard isActive else { return }
                viewModel.autoRefreshIfNeeded()
            }
            .task { await viewModel.loadIfNeeded() }
            .onAppear { isActive = true }
            .onDisappear { isActive = false }
            .navigationTitle(NSLocalizedString("Market", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(MarketLayout.allCases) { layout in
                            Button {
                                layoutRaw = layout.rawValue
                            } label: {
                                Label(layout.title, systemImage: layout.systemImage)
                            }
                        }
                    } label: {
                        Image(systemName: currentLayout.systemImage)
                    }
                    .accessibilityIdentifier("market_layout_toggle")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityIdentifier("settings_button")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var currentLayout: MarketLayout {
        MarketLayout(rawValue: layoutRaw) ?? .cards
    }

    private var listSpacing: CGFloat {
        currentLayout == .cards ? AppSpacing.md : (AppSpacing.md + 8)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.coins.isEmpty {
            MarketSkeletonView()
        } else if let error = viewModel.error, viewModel.coins.isEmpty {
            EmptyStateView(
                title: NSLocalizedString("Something went wrong", comment: ""),
                message: error.errorDescription ?? NSLocalizedString("Try again.", comment: ""),
                assetName: "EmptySearch",
                systemImageFallback: "exclamationmark.triangle",
                actionTitle: NSLocalizedString("Retry", comment: ""),
                action: { viewModel.retry() }
            )
        } else if viewModel.displayedCoins.isEmpty {
            EmptyStateView(
                title: NSLocalizedString("No results", comment: ""),
                message: NSLocalizedString("Try another search query.", comment: ""),
                assetName: "EmptySearch",
                systemImageFallback: "magnifyingglass"
            )
        } else {
            LazyVStack(spacing: listSpacing) {
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
                        rowContent(for: coin)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("market_row_\(coin.id)")
                    .onAppear {
                        if section == .all {
                            Task { await viewModel.loadNextPageIfNeeded(current: coin) }
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, AppSpacing.md)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.displayedCoins)
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .all:
            if !viewModel.trending.isEmpty {
                TrendingSection(
                    coins: viewModel.trending,
                    marketCoins: viewModel.coins,
                    coinRepository: coinRepository,
                    favoritesRepository: favoritesRepository,
                    portfolioRepository: portfolioRepository,
                    alertsRepository: alertsRepository,
                    notesRepository: notesRepository
                )
            }

            if !viewModel.topGainers.isEmpty {
                TopMoversSection(title: NSLocalizedString("Top Gainers", comment: ""), coins: viewModel.topGainers)
            }

            if !viewModel.topLosers.isEmpty {
                TopMoversSection(title: NSLocalizedString("Top Losers", comment: ""), coins: viewModel.topLosers)
            }

            content
        case .gainers:
            marketList(title: NSLocalizedString("Top Gainers", comment: ""), coins: filtered(viewModel.gainers))
        case .losers:
            marketList(title: NSLocalizedString("Top Losers", comment: ""), coins: filtered(viewModel.losers))
        case .trending:
            trendingList
        }
    }

    private func filtered(_ coins: [CoinMarket]) -> [CoinMarket] {
        guard !viewModel.searchText.isEmpty else { return coins }
        return coins.filter { coin in
            coin.name.localizedCaseInsensitiveContains(viewModel.searchText) ||
            coin.symbol.localizedCaseInsensitiveContains(viewModel.searchText)
        }
    }

    @ViewBuilder
    private func marketList(title: String, coins: [CoinMarket]) -> some View {
        if coins.isEmpty {
            EmptyStateView(
                title: NSLocalizedString("No results", comment: ""),
                message: NSLocalizedString("Try another search query.", comment: ""),
                assetName: "EmptyMarket",
                systemImageFallback: "chart.line.uptrend.xyaxis"
            )
        } else {
            LazyVStack(spacing: listSpacing) {
                ForEach(coins) { coin in
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
                        rowContent(for: coin)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var trendingList: some View {
        let display = viewModel.trending.compactMap { trending in
            viewModel.coins.first(where: { $0.id == trending.id })
        }
        if display.isEmpty {
            EmptyStateView(
                title: NSLocalizedString("No results", comment: ""),
                message: NSLocalizedString("Try again.", comment: ""),
                assetName: "EmptyMarket",
                systemImageFallback: "chart.line.uptrend.xyaxis"
            )
        } else {
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(display) { marketCoin in
                    NavigationLink {
                        CoinDetailsView(viewModel: CoinDetailsViewModel(
                            coinId: marketCoin.id,
                            coinRepository: coinRepository,
                            favoritesRepository: favoritesRepository,
                            portfolioRepository: portfolioRepository,
                            alertsRepository: alertsRepository,
                            notesRepository: notesRepository
                        ))
                    } label: {
                        CardView { MarketRowView(coin: marketCoin) }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func rowContent(for coin: CoinMarket) -> some View {
        switch currentLayout {
        case .cards:
            CardView { MarketRowView(coin: coin) }
        case .compact:
            CardView(padding: AppSpacing.sm) {
                MarketCompactRowView(coin: coin)
            }
        }
    }
}

struct TopMoversSection: View {
    let title: String
    let coins: [CoinMarket]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(coins) { coin in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(coin.symbol)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            Text(PriceFormatter.short(coin.currentPrice))
                                .font(AppTypography.headline)
                            Text(PercentFormatter.string(coin.priceChangePercentage24h))
                                .font(AppTypography.caption)
                                .foregroundColor(coin.priceChangePercentage24h.isPositive ? AppColors.positive : AppColors.negative)
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }
}

struct TrendingSection: View {
    let coins: [TrendingCoin]
    let marketCoins: [CoinMarket]
    let coinRepository: CoinRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol
    let portfolioRepository: PortfolioRepositoryProtocol
    let alertsRepository: AlertsRepositoryProtocol
    let notesRepository: NotesRepositoryProtocol
    private var marketMap: [String: CoinMarket] {
        Dictionary(uniqueKeysWithValues: marketCoins.map { ($0.id, $0) })
    }

    var body: some View {
        let display = coins.compactMap { marketMap[$0.id] }
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(NSLocalizedString("Trending", comment: ""))
                .font(AppTypography.headline)
            if !display.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(display) { coin in
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
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        if let url = coin.imageURL {
                                            CachedAsyncImage(url: url) { image in
                                                image.resizable().scaledToFit()
                                            } placeholder: {
                                                Image(systemName: "bitcoinsign.circle")
                                            }
                                            .frame(width: 28, height: 28)
                                        } else {
                                            Image(systemName: "bitcoinsign.circle")
                                        }
                                        Spacer()
                                    }
                                    Text(coin.name)
                                        .font(AppTypography.headline)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(coin.symbol)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                    Text(PriceFormatter.short(coin.currentPrice))
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(PercentFormatter.string(coin.priceChangePercentage24h))
                                        .font(AppTypography.caption)
                                        .foregroundColor(coin.priceChangePercentage24h >= 0 ? AppColors.positive : AppColors.negative)
                                }
                                .padding(AppSpacing.sm)
                                .background(AppColors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct TrendingRowView: View {
    let coin: TrendingCoin

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            if let url = coin.imageURL {
                CachedAsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Image(systemName: "bitcoinsign.circle")
                }
                .frame(width: 36, height: 36)
            } else {
                Image(systemName: "bitcoinsign.circle")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundColor(AppColors.textSecondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(coin.name)
                    .font(AppTypography.headline)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(coin.symbol)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let rank = coin.marketCapRank {
                    Text(String(format: NSLocalizedString("Rank #%@", comment: ""), String(rank)))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}

#Preview {
    MarketView(
        viewModel: MarketViewModel(repository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview"))),
        coinRepository: CoinRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        favoritesRepository: FavoritesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        portfolioRepository: PortfolioRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        alertsRepository: AlertsRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        notesRepository: NotesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    )
    .environmentObject(AppEnvironment())
}
