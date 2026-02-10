import SwiftUI
import Combine

struct FavoritesView: View {
    @StateObject var viewModel: FavoritesViewModel
    @Binding var selection: AppTab
    let coinRepository: CoinRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol
    let portfolioRepository: PortfolioRepositoryProtocol
    let alertsRepository: AlertsRepositoryProtocol
    let notesRepository: NotesRepositoryProtocol

    @State private var section: FavoritesSection = .all
    @State private var autoRefresh = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    @State private var isActive = false

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
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

                    SegmentedControl(options: FavoritesSection.allCases, selection: $section) { option in
                        option.title
                    }

                    if viewModel.favorites.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("No favorites yet", comment: ""),
                            message: NSLocalizedString("Save coins to track them here.", comment: ""),
                            assetName: "EmptyFavorites",
                            systemImageFallback: "star",
                            actionTitle: NSLocalizedString("Go to Market", comment: ""),
                            action: { selection = .market }
                        )
                    } else if favoritesForSection.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("No results", comment: ""),
                            message: NSLocalizedString("Try another search query.", comment: ""),
                            assetName: "EmptyFavorites",
                            systemImageFallback: "star"
                        )
                    } else {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(favoritesForSection) { coin in
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
                                    CardView {
                                        MarketRowView(coin: coin)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("favorite_row_\(coin.id)")
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.remove(coinId: coin.id)
                                    } label: {
                                        Label(NSLocalizedString("Remove", comment: ""), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle(NSLocalizedString("Favorites", comment: ""))
            .refreshable { await viewModel.refresh() }
            .onReceive(autoRefresh) { _ in
                guard isActive else { return }
                Task { await viewModel.refresh() }
            }
            .onAppear {
                viewModel.load()
                isActive = true
            }
            .onDisappear { isActive = false }
        }
    }

    private var favoritesForSection: [CoinMarket] {
        switch section {
        case .all:
            return viewModel.favorites
        case .gainers:
            return viewModel.favorites.filter { $0.priceChangePercentage24h >= 0 }
                .sorted { $0.priceChangePercentage24h > $1.priceChangePercentage24h }
        case .losers:
            return viewModel.favorites.filter { $0.priceChangePercentage24h < 0 }
                .sorted { $0.priceChangePercentage24h < $1.priceChangePercentage24h }
        }
    }
}

enum FavoritesSection: String, CaseIterable, Identifiable {
    case all
    case gainers
    case losers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return NSLocalizedString("All", comment: "")
        case .gainers: return NSLocalizedString("Gainers", comment: "")
        case .losers: return NSLocalizedString("Losers", comment: "")
        }
    }
}

#Preview {
    FavoritesView(
        viewModel: FavoritesViewModel(
            favoritesRepository: FavoritesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
            marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
        ),
        selection: .constant(.favorites),
        coinRepository: CoinRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        favoritesRepository: FavoritesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        portfolioRepository: PortfolioRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        alertsRepository: AlertsRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        notesRepository: NotesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    )
    .environmentObject(AppEnvironment())
}
