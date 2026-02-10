import SwiftUI

struct ExchangesView: View {
    @StateObject var viewModel: ExchangesViewModel

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    MarketSearchBar(text: $viewModel.searchText, placeholder: NSLocalizedString("Search exchanges", comment: ""))

                    if viewModel.showOfflineBanner {
                        BannerView(title: NSLocalizedString("Offline mode. Showing cached data.", comment: ""), systemImage: "wifi.slash")
                    } else if let error = viewModel.error, !viewModel.exchanges.isEmpty {
                        BannerView(title: error.errorDescription ?? NSLocalizedString("Try again.", comment: ""), systemImage: "exclamationmark.triangle")
                    }

                    if viewModel.isLoading && viewModel.exchanges.isEmpty {
                        ProgressView()
                            .padding(.vertical, AppSpacing.lg)
                    } else if let error = viewModel.error, viewModel.exchanges.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("Something went wrong", comment: ""),
                            message: error.errorDescription ?? NSLocalizedString("Try again.", comment: ""),
                            assetName: "EmptyMarket",
                            systemImageFallback: "building.2",
                            actionTitle: NSLocalizedString("Retry", comment: ""),
                            action: { Task { await viewModel.refresh() } }
                        )
                    } else if viewModel.displayedExchanges.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("No results", comment: ""),
                            message: NSLocalizedString("Try another search query.", comment: ""),
                            assetName: "EmptyMarket",
                            systemImageFallback: "magnifyingglass"
                        )
                    } else {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(viewModel.displayedExchanges) { exchange in
                                ExchangeRowView(exchange: exchange)
                                    .onAppear {
                                        Task { await viewModel.loadNextPageIfNeeded(current: exchange) }
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
            .navigationTitle(NSLocalizedString("Exchanges", comment: ""))
            .refreshable { await viewModel.refresh(force: true) }
            .task { await viewModel.loadIfNeeded() }
        }
    }
}

struct ExchangeRowView: View {
    let exchange: Exchange

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    if let url = exchange.imageURL {
                        CachedAsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Image(systemName: "building.2")
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        Image(systemName: "building.2")
                            .frame(width: 36, height: 36)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(exchange.name)
                            .font(AppTypography.headline)
                        if let country = exchange.country, !country.isEmpty {
                            Text(country)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    Spacer()
                    if let rank = exchange.trustScoreRank {
                        Text("#\(rank)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Volume 24h", comment: ""))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        if let volume = exchange.tradeVolume24hBtc {
                            Text(NumberParsing.string(from: volume, maximumFractionDigits: 2))
                                .font(AppTypography.headline)
                        } else {
                            Text("—")
                                .font(AppTypography.headline)
                        }
                    }
                    Spacer()
                    if let year = exchange.yearEstablished {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Established", comment: ""))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            Text(String(year))
                                .font(AppTypography.headline)
                        }
                    }
                }

                if let url = exchange.url {
                    Link(NSLocalizedString("Open Website", comment: ""), destination: url)
                        .font(AppTypography.caption)
                }
            }
        }
    }
}

#Preview {
    ExchangesView(viewModel: ExchangesViewModel(marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview"))))
}
