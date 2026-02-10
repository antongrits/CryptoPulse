import SwiftUI

struct InsightsView: View {
    @StateObject var viewModel: InsightsViewModel

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    if viewModel.isLoading {
                        ProgressView()
                    }

                    if viewModel.showOfflineBanner {
                        BannerView(title: NSLocalizedString("Offline mode. Showing cached data.", comment: ""), systemImage: "wifi.slash")
                    } else if let error = viewModel.error, viewModel.markets.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("Could not load insights", comment: ""),
                            message: error.errorDescription ?? NSLocalizedString("Try again.", comment: ""),
                            assetName: "EmptySearch",
                            systemImageFallback: "exclamationmark.triangle",
                            actionTitle: NSLocalizedString("Retry", comment: ""),
                            action: { Task { await viewModel.refresh() } }
                        )
                    } else {
                        marketPulseCard
                        if let global = viewModel.globalMarket {
                            globalMarketCard(global)
                        }
                        portfolioCard

                        if !viewModel.topGainers.isEmpty {
                            TopMoversSection(title: NSLocalizedString("Top Gainers", comment: ""), coins: viewModel.topGainers)
                        }

                        if !viewModel.topLosers.isEmpty {
                            TopMoversSection(title: NSLocalizedString("Top Losers", comment: ""), coins: viewModel.topLosers)
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle(NSLocalizedString("Insights", comment: ""))
            .refreshable { await viewModel.refresh() }
            .onAppear { viewModel.load() }
            .task { await viewModel.loadIfNeeded() }
        }
    }

    private var marketPulseCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(NSLocalizedString("Market Pulse", comment: ""))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                HStack {
                    Text("\(Int(viewModel.marketPulse))")
                        .font(AppTypography.largeTitle)
                    Spacer()
                    let breadth = viewModel.marketBreadth
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: NSLocalizedString("Gainers %@", comment: ""), "\(breadth.gainers)"))
                        Text(String(format: NSLocalizedString("Losers %@", comment: ""), "\(breadth.losers)"))
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                }
                ProgressView(value: viewModel.marketPulse, total: 100)
            }
        }
    }

    private var portfolioCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(NSLocalizedString("Portfolio Snapshot", comment: ""))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                HStack {
                    Text(PriceFormatter.string(viewModel.totalPortfolioValue))
                        .font(AppTypography.title)
                    Spacer()
                    Text(String(format: NSLocalizedString("Favorites %@", comment: ""), "\(viewModel.favoritesCount)"))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    private func globalMarketCard(_ global: GlobalMarket) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(NSLocalizedString("Global Market", comment: ""))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                    StatCell(title: NSLocalizedString("Total Market Cap", comment: ""), value: PriceFormatter.short(global.totalMarketCapUSD))
                    StatCell(title: NSLocalizedString("Total Volume", comment: ""), value: PriceFormatter.short(global.totalVolumeUSD))
                    StatCell(title: NSLocalizedString("BTC Dominance", comment: ""), value: PercentFormatter.string(global.btcDominance))
                    StatCell(title: NSLocalizedString("ETH Dominance", comment: ""), value: PercentFormatter.string(global.ethDominance))
                    StatCell(title: NSLocalizedString("Active Cryptocurrencies", comment: ""), value: global.activeCryptocurrencies.map { "\($0)" } ?? "—")
                    StatCell(title: NSLocalizedString("Markets", comment: ""), value: global.markets.map { "\($0)" } ?? "—")
                }

                if let change = global.marketCapChangePercentage24h {
                    Text(String(format: NSLocalizedString("24h Change %@", comment: ""), PercentFormatter.string(change)))
                        .font(AppTypography.caption)
                        .foregroundColor(change >= 0 ? AppColors.positive : AppColors.negative)
                }
            }
        }
    }
}

private struct StatCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(AppTypography.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    InsightsView(viewModel: InsightsViewModel(
        marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        portfolioRepository: PortfolioRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        favoritesRepository: FavoritesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    ))
}
