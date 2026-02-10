import SwiftUI

struct AlertsView: View {
    @StateObject var viewModel: AlertsViewModel
    let marketRepository: MarketRepositoryProtocol

    @State private var showAdd = false
    @State private var editingAlert: PriceAlert?

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    if viewModel.notificationStatus != .authorized {
                        BannerView(title: NSLocalizedString("Enable notifications to receive price alerts.", comment: ""), systemImage: "bell.badge")
                            .onTapGesture {
                                Task { await viewModel.requestPermission() }
                            }
                    }

                    if viewModel.alerts.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("No alerts", comment: ""),
                            message: NSLocalizedString("Create alerts to get notified on price moves.", comment: ""),
                            assetName: "EmptyAlerts",
                            systemImageFallback: "bell",
                            actionTitle: NSLocalizedString("Create Alert", comment: ""),
                            action: { showAdd = true }
                        )
                    } else {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(viewModel.alerts, id: \.id) { alert in
                                CardView {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(alert.name) • \(alert.symbol)")
                                                .font(AppTypography.headline)
                                            Text("\(alert.metric.title) • \(alert.direction.title) \(alert.formattedTarget)")
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                            Text(alert.repeatMode.title)
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                            Text(String(format: NSLocalizedString("Cooldown: %d min", comment: ""), alert.cooldownMinutes))
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        Spacer()
                                        Toggle("", isOn: Binding(
                                            get: { alert.isEnabled },
                                            set: { _ in viewModel.toggle(alert: alert) }
                                        ))
                                        .labelsHidden()
                                    }
                                }
                                .onTapGesture { editingAlert = alert }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.delete(id: alert.id)
                                    } label: {
                                        Label(NSLocalizedString("Delete", comment: ""), systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.delete(id: alert.id)
                                    } label: {
                                        Label(NSLocalizedString("Delete", comment: ""), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle(NSLocalizedString("Alerts", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .onAppear {
                viewModel.load()
                Task { await viewModel.refreshNotificationStatus() }
            }
            .sheet(isPresented: $showAdd) {
                AlertFormView(preselectedCoin: nil, marketRepository: marketRepository, preselectedPrice: nil) { coin, value, metric, direction, repeatMode, cooldown in
                    viewModel.createAlert(coin: coin, target: value, metric: metric, direction: direction, repeatMode: repeatMode, cooldownMinutes: cooldown)
                }
            }
            .sheet(item: $editingAlert) { alert in
                let market = marketRepository.cachedMarkets(sortedBy: .marketCapDesc).first { $0.id == alert.coinId }
                let coin = CoinMarket(
                    id: alert.coinId,
                    name: alert.name,
                    symbol: alert.symbol,
                    imageURL: market?.imageURL,
                    currentPrice: market?.currentPrice ?? 0,
                    priceChangePercentage24h: market?.priceChangePercentage24h ?? 0,
                    marketCap: market?.marketCap,
                    totalVolume: market?.totalVolume,
                    high24h: market?.high24h,
                    low24h: market?.low24h,
                    lastUpdated: market?.lastUpdated
                )
                AlertFormView(
                    preselectedCoin: coin,
                    marketRepository: nil,
                    preselectedPrice: alert.targetValue,
                    formTitle: NSLocalizedString("Edit Alert", comment: ""),
                    initialMetric: alert.metric,
                    initialDirection: alert.direction,
                    initialRepeatMode: alert.repeatMode,
                    initialCooldownMinutes: alert.cooldownMinutes
                ) { _, value, metric, direction, repeatMode, cooldown in
                    let updated = PriceAlert(
                        id: alert.id,
                        coinId: alert.coinId,
                        symbol: alert.symbol,
                        name: alert.name,
                        targetValue: value,
                        metric: metric,
                        direction: direction,
                        repeatMode: repeatMode,
                        cooldownMinutes: cooldown,
                        isEnabled: alert.isEnabled,
                        isArmed: alert.isArmed,
                        createdAt: alert.createdAt,
                        lastTriggeredAt: alert.lastTriggeredAt
                    )
                    viewModel.updateAlert(updated)
                }
            }
        }
    }
}

#Preview {
    AlertsView(
        viewModel: AlertsViewModel(
            alertsRepository: AlertsRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
            marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
        ),
        marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    )
}
