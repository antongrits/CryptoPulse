import SwiftUI
import Combine
import UIKit

struct PortfolioView: View {
    @StateObject var viewModel: PortfolioViewModel
    let marketRepository: MarketRepositoryProtocol

    @State private var showAdd = false
    @State private var editingHolding: Holding?
    @State private var showExport = false
    @State private var exportItems: [Any] = []
    @State private var autoRefresh = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    @State private var isActive = false

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    summaryCard
                    if !allocationSlices.isEmpty {
                        CardView {
                            PortfolioAllocationView(slices: allocationSlices)
                        }
                    }

                    if viewModel.holdings.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("No holdings", comment: ""),
                            message: NSLocalizedString("Track your investments here.", comment: ""),
                            assetName: "EmptyPortfolio",
                            systemImageFallback: "briefcase",
                            actionTitle: NSLocalizedString("Add Holding", comment: ""),
                            action: { showAdd = true }
                        )
                    } else {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(viewModel.rows) { row in
                                CardView {
                                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(row.holding.name)
                                                    .font(AppTypography.headline)
                                                Text(row.holding.symbol)
                                                    .font(AppTypography.caption)
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            Spacer()
                                            Text(PriceFormatter.short(row.currentValue))
                                                .font(AppTypography.headline)
                                        }

                                        HStack {
                                            Text(String(format: NSLocalizedString("Amount: %@", comment: ""), String(format: "%.4f", row.holding.amount)))
                                                .font(AppTypography.caption)
                                            Spacer()
                                            if let pl = row.profitLoss {
                                                Text(PriceFormatter.short(pl))
                                                    .font(AppTypography.caption)
                                                    .foregroundColor(pl >= 0 ? AppColors.positive : AppColors.negative)
                                            }
                                            if let day = row.dayChange {
                                                Text(PercentFormatter.string(day))
                                                    .font(AppTypography.caption)
                                                    .foregroundColor(day >= 0 ? AppColors.positive : AppColors.negative)
                                            }
                                        }
                                    }
                                }
                                .onTapGesture { editingHolding = row.holding }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.delete(id: row.holding.id)
                                    } label: {
                                        Label(NSLocalizedString("Delete", comment: ""), systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.delete(id: row.holding.id)
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
            .navigationTitle(NSLocalizedString("Portfolio", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if let image = Snapshotter.captureScreen() {
                            exportItems = [image]
                        } else {
                            exportItems = [portfolioCSV]
                        }
                        showExport = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(viewModel.rows.isEmpty)
                    .accessibilityIdentifier("portfolio_export")
                }
            }
            .refreshable { await viewModel.refresh(force: true) }
            .onReceive(autoRefresh) { _ in
                guard isActive else { return }
                Task { await viewModel.refresh() }
            }
            .onAppear {
                viewModel.load()
                isActive = true
            }
            .onDisappear { isActive = false }
            .sheet(isPresented: $showExport) {
                ShareSheet(items: exportItems)
            }
            .sheet(isPresented: $showAdd) {
                HoldingFormView(
                    title: NSLocalizedString("Add Holding", comment: ""),
                    preselectedCoin: nil,
                    marketRepository: marketRepository,
                    initialAmount: nil,
                    initialAvgPrice: nil
                ) { coin, amount, avg in
                    viewModel.addHolding(coin: coin, amount: amount, avgBuyPrice: avg)
                }
            }
            .sheet(item: $editingHolding) { holding in
                let coin = coinFromHolding(holding)
                HoldingFormView(
                    title: NSLocalizedString("Edit Holding", comment: ""),
                    preselectedCoin: coin,
                    marketRepository: nil,
                    initialAmount: holding.amount,
                    initialAvgPrice: holding.avgBuyPrice
                ) { _, amount, avg in
                    let updated = Holding(
                        id: holding.id,
                        coinId: holding.coinId,
                        symbol: holding.symbol,
                        name: holding.name,
                        amount: amount,
                        avgBuyPrice: avg,
                        createdAt: holding.createdAt,
                        updatedAt: Date()
                    )
                    viewModel.upsert(holding: updated)
                }
            }
        }
    }

    private var summaryCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(NSLocalizedString("Total Value", comment: ""))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(PriceFormatter.string(viewModel.totalValue))
                    .font(AppTypography.largeTitle)

                if let pl = viewModel.totalProfitLoss {
                    HStack {
                        Text(NSLocalizedString("P/L", comment: ""))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(PriceFormatter.short(pl))
                                .foregroundColor(pl >= 0 ? AppColors.positive : AppColors.negative)
                            if let percent = viewModel.totalProfitLossPercent {
                                Text(PercentFormatter.string(percent))
                                    .font(AppTypography.caption)
                                    .foregroundColor(pl >= 0 ? AppColors.positive : AppColors.negative)
                            }
                        }
                    }
                }
            }
        }
    }

    private var allocationSlices: [AllocationSlice] {
        let total = viewModel.totalValue
        guard total > 0 else { return [] }
        let grouped = Dictionary(grouping: viewModel.rows, by: { $0.holding.coinId })
        let palette = AppColors.chartPalette
        let slices = grouped.enumerated().map { index, item in
            let rows = item.value
            let symbol = rows.first?.holding.symbol ?? "—"
            let value = rows.reduce(0) { $0 + $1.currentValue }
            let percent = value / total * 100
            return AllocationSlice(
                id: item.key,
                name: symbol,
                value: value,
                color: palette[index % palette.count],
                percent: percent
            )
        }
        return slices.sorted(by: { $0.value > $1.value })
    }

    private func coinFromHolding(_ holding: Holding) -> CoinMarket {
        let market = marketRepository.cachedMarkets(sortedBy: .marketCapDesc).first { $0.id == holding.coinId }
        return CoinMarket(
            id: holding.coinId,
            name: holding.name,
            symbol: holding.symbol,
            imageURL: market?.imageURL,
            currentPrice: market?.currentPrice ?? 0,
            priceChangePercentage24h: market?.priceChangePercentage24h ?? 0,
            marketCap: market?.marketCap,
            totalVolume: market?.totalVolume,
            high24h: market?.high24h,
            low24h: market?.low24h,
            lastUpdated: market?.lastUpdated
        )
    }

    private var portfolioCSV: String {
        var lines: [String] = []
        lines.append("symbol,name,amount,avg_buy_price,current_price,current_value,profit_loss,updated_at")
        let formatter = ISO8601DateFormatter()
        for row in viewModel.rows {
            let avg = row.holding.avgBuyPrice ?? 0
            let profit = row.profitLoss ?? 0
            let updated = formatter.string(from: row.holding.updatedAt)
            let currentPrice = row.currentPrice ?? 0
            let line = "\(row.holding.symbol),\(row.holding.name),\(row.holding.amount),\(avg),\(currentPrice),\(row.currentValue),\(profit),\(updated)"
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
}

#Preview {
    PortfolioView(
        viewModel: PortfolioViewModel(
            portfolioRepository: PortfolioRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
            marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
        ),
        marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    )
}
