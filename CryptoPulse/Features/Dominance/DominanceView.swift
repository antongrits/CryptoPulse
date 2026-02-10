import SwiftUI

struct DominanceView: View {
    @StateObject var viewModel: DominanceViewModel
    @State private var selectedSliceId: String?

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    if viewModel.showOfflineBanner {
                        BannerView(title: NSLocalizedString("Offline mode. Showing cached data.", comment: ""), systemImage: "wifi.slash")
                    } else if let error = viewModel.error, viewModel.global != nil {
                        BannerView(title: error.errorDescription ?? NSLocalizedString("Try again.", comment: ""), systemImage: "exclamationmark.triangle")
                    }

                    if viewModel.isLoading && viewModel.global == nil {
                        ProgressView()
                            .padding(.vertical, AppSpacing.lg)
                    } else if let error = viewModel.error, viewModel.global == nil {
                        EmptyStateView(
                            title: NSLocalizedString("Something went wrong", comment: ""),
                            message: error.errorDescription ?? NSLocalizedString("Try again.", comment: ""),
                            assetName: "EmptyMarket",
                            systemImageFallback: "chart.pie",
                            actionTitle: NSLocalizedString("Retry", comment: ""),
                            action: { Task { await viewModel.refresh() } }
                        )
                    } else if let slices = dominanceSlices, !slices.isEmpty {
                        CardView {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                Text(NSLocalizedString("Market Dominance", comment: ""))
                                    .font(AppTypography.headline)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)

                                DonutChartView(
                                    slices: slices,
                                    selectedSliceId: selectedSliceId,
                                    lineWidth: 22
                                )
                                .frame(maxWidth: .infinity, minHeight: 230, maxHeight: 250)

                                if let selected = selectedSlice(from: slices) {
                                    HStack {
                                        Text(selected.name)
                                            .font(AppTypography.headline)
                                        Spacer()
                                        Text(PercentFormatter.shortPercent(selected.percent))
                                            .font(AppTypography.headline)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(slices) { slice in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedSliceId = slice.id
                                            }
                                        } label: {
                                            HStack(spacing: 8) {
                                                Circle().fill(slice.color).frame(width: 10, height: 10)
                                                Text(slice.name)
                                                    .font(AppTypography.caption)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                                Text(PercentFormatter.shortPercent(slice.percent))
                                                    .font(AppTypography.caption)
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        if let global = viewModel.global {
                            CardView {
                                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                    Text(NSLocalizedString("Global Market", comment: ""))
                                        .font(AppTypography.headline)
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(NSLocalizedString("Total Market Cap", comment: ""))
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                            Text(PriceFormatter.short(global.totalMarketCapUSD))
                                                .font(AppTypography.headline)
                                        }
                                        Spacer()
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(NSLocalizedString("Total Volume", comment: ""))
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                            Text(PriceFormatter.short(global.totalVolumeUSD))
                                                .font(AppTypography.headline)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        EmptyStateView(
                            title: NSLocalizedString("No results", comment: ""),
                            message: NSLocalizedString("Try again.", comment: ""),
                            assetName: "EmptyMarket",
                            systemImageFallback: "chart.pie"
                        )
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle(NSLocalizedString("Dominance", comment: ""))
            .refreshable { await viewModel.refresh(force: true) }
            .task { await viewModel.loadIfNeeded() }
            .onAppear {
                if selectedSliceId == nil {
                    selectedSliceId = dominanceSlices?.first?.id
                }
            }
        }
    }

    private var dominanceSlices: [AllocationSlice]? {
        guard let global = viewModel.global else { return nil }
        let btc = global.btcDominance ?? 0
        let eth = global.ethDominance ?? 0
        let other = max(0, 100 - btc - eth)
        let colors = AppColors.chartPalette
        return [
            AllocationSlice(id: "btc", name: "BTC", value: btc, color: colors[0], percent: btc),
            AllocationSlice(id: "eth", name: "ETH", value: eth, color: colors[1], percent: eth),
            AllocationSlice(id: "other", name: NSLocalizedString("Other", comment: ""), value: other, color: colors[2], percent: other)
        ]
    }

    private func selectedSlice(from slices: [AllocationSlice]) -> AllocationSlice? {
        if let selectedSliceId, let selected = slices.first(where: { $0.id == selectedSliceId }) {
            return selected
        }
        return slices.first
    }
}

#Preview {
    DominanceView(viewModel: DominanceViewModel(marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview"))))
}
