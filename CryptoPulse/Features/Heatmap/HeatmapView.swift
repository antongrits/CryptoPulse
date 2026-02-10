import SwiftUI

struct HeatmapView: View {
    @StateObject var viewModel: HeatmapViewModel
    let coinRepository: CoinRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol
    let portfolioRepository: PortfolioRepositoryProtocol
    let alertsRepository: AlertsRepositoryProtocol
    let notesRepository: NotesRepositoryProtocol
    @EnvironmentObject private var appEnv: AppEnvironment

    private var columns: [GridItem] {
        let base = CGFloat(86 * viewModel.tileScale)
        let minSize = max(78, min(base, 140))
        return [GridItem(.adaptive(minimum: minSize), spacing: AppSpacing.sm)]
    }

    @State private var selected: CoinMarket?

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    filterBar
                    categoryBar
                    scaleBar
                    legend

                    if let pinned = viewModel.pinnedCoin {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(NSLocalizedString("Pinned", comment: ""))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            NavigationLink {
                                CoinDetailsView(viewModel: CoinDetailsViewModel(
                                    coinId: pinned.id,
                                    coinRepository: coinRepository,
                                    favoritesRepository: favoritesRepository,
                                    portfolioRepository: portfolioRepository,
                                    alertsRepository: alertsRepository,
                                    notesRepository: notesRepository
                                ))
                            } label: {
                                HeatmapPinnedCard(coin: pinned)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let selected {
                        HeatmapSelectionCard(
                            coin: selected,
                            isPinned: viewModel.pinnedCoinId == selected.id,
                            onPinToggle: { viewModel.togglePin(for: selected) }
                        )
                    }

                    if viewModel.isLoading && viewModel.coins.isEmpty {
                        ProgressView()
                    }

                    if let error = viewModel.error, viewModel.coins.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("Something went wrong", comment: ""),
                            message: error.errorDescription ?? NSLocalizedString("Try again.", comment: ""),
                            assetName: "EmptyHeatmap",
                            systemImageFallback: "square.grid.3x3.fill",
                            actionTitle: NSLocalizedString("Retry", comment: ""),
                            action: { Task { await viewModel.refresh() } }
                        )
                    } else if viewModel.heatmapCoins.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("No results", comment: ""),
                            message: NSLocalizedString("Try again.", comment: ""),
                            assetName: "EmptyHeatmap",
                            systemImageFallback: "square.grid.3x3.fill"
                        )
                    } else {
                        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                            ForEach(viewModel.heatmapCoins) { coin in
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
                                    HeatmapTileView(
                                        coin: coin,
                                        scale: viewModel.sizeScale(for: coin),
                                        gradient: viewModel.color(for: coin.priceChangePercentage24h),
                                        isPinned: viewModel.pinnedCoinId == coin.id
                                    )
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(
                                    LongPressGesture(minimumDuration: 0.25)
                                        .onEnded { _ in
                                            selected = coin
                                            HapticsManager.shared.impact(.light, enabled: appEnv.hapticsEnabled)
                                        }
                                )
                            }
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle(NSLocalizedString("Market Heatmap", comment: ""))
            .refreshable { await viewModel.refresh() }
            .task { await viewModel.loadIfNeeded() }
            .simultaneousGesture(
                TapGesture().onEnded {
                    selected = nil
                }
            )
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(HeatmapFilter.allCases) { filter in
                    ChipView(title: filter.title, isSelected: filter == viewModel.filter)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.filter = filter
                            }
                        }
                }
            }
        }
    }

    private var scaleBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(NSLocalizedString("Scale", comment: ""))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            Slider(value: Binding(
                get: { viewModel.tileScale },
                set: { viewModel.updateTileScale($0) }
            ), in: 0.85...1.2, step: 0.05)
        }
    }

    private var categoryBar: some View {
        HStack {
            Text(NSLocalizedString("Category", comment: ""))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Picker(NSLocalizedString("Category", comment: ""), selection: Binding(
                get: { viewModel.selectedCategoryId },
                set: { viewModel.selectCategory($0) }
            )) {
                Text(NSLocalizedString("All", comment: "")).tag("")
                ForEach(viewModel.categories) { category in
                    Text(category.name).tag(category.id)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }

    private var legend: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(NSLocalizedString("Down", comment: ""))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            LinearGradient(
                colors: [AppColors.negative, AppColors.positive],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 6)
            .clipShape(Capsule())
            Text(NSLocalizedString("Up", comment: ""))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

struct HeatmapTileView: View {
    let coin: CoinMarket
    let scale: CGFloat
    let gradient: (Color, Color)
    let isPinned: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(coin.symbol)
                .font(AppTypography.caption)
                .foregroundColor(.white.opacity(0.9))
            Text(PriceFormatter.short(coin.currentPrice))
                .font(AppTypography.headline)
                .foregroundColor(.white)
            Text(PercentFormatter.string(coin.priceChangePercentage24h))
                .font(AppTypography.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity, minHeight: 88 * scale)
        .background(
            LinearGradient(
                colors: [gradient.0, gradient.1],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isPinned ? AppColors.accent.opacity(0.9) : Color.white.opacity(0.08), lineWidth: isPinned ? 2 : 1)
        )
        .overlay(alignment: .topTrailing) {
            if isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: scale)
        .accessibilityIdentifier("heatmap_tile_\(coin.id)")
    }
}

struct HeatmapSelectionCard: View {
    let coin: CoinMarket
    let isPinned: Bool
    let onPinToggle: () -> Void

    var body: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(coin.name)
                        .font(AppTypography.headline)
                    Text(coin.symbol)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(PriceFormatter.short(coin.currentPrice))
                        .font(AppTypography.headline)
                    Text(PercentFormatter.string(coin.priceChangePercentage24h))
                        .font(AppTypography.caption)
                        .foregroundColor(coin.priceChangePercentage24h >= 0 ? AppColors.positive : AppColors.negative)
                }
                Button(action: onPinToggle) {
                    Image(systemName: isPinned ? "pin.slash" : "pin.fill")
                        .foregroundColor(AppColors.accent)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("heatmap_pin")
            }
        }
    }
}

struct HeatmapPinnedCard: View {
    let coin: CoinMarket

    var body: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(coin.name)
                        .font(AppTypography.headline)
                    Text(coin.symbol)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(PriceFormatter.short(coin.currentPrice))
                        .font(AppTypography.headline)
                    Text(PercentFormatter.string(coin.priceChangePercentage24h))
                        .font(AppTypography.caption)
                        .foregroundColor(coin.priceChangePercentage24h >= 0 ? AppColors.positive : AppColors.negative)
                }
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

#Preview {
    HeatmapView(
        viewModel: HeatmapViewModel(
            marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
        ),
        coinRepository: CoinRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        favoritesRepository: FavoritesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        portfolioRepository: PortfolioRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        alertsRepository: AlertsRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        notesRepository: NotesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    )
    .environmentObject(AppEnvironment())
}
