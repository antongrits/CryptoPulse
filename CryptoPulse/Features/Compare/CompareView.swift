import SwiftUI

struct CompareView: View {
    @StateObject var viewModel: CompareViewModel

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    if viewModel.coins.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("No market data", comment: ""),
                            message: NSLocalizedString("Refresh Market to load prices.", comment: ""),
                            assetName: "EmptySearch",
                            systemImageFallback: "arrow.left.arrow.right"
                        )
                    } else {
                        CardView {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Picker(NSLocalizedString("Coin", comment: ""), selection: Binding(
                                    get: {
                                        if let current = viewModel.left?.id, viewModel.coins.contains(where: { $0.id == current }) {
                                            return current
                                        }
                                        return ""
                                    },
                                    set: { id in
                                        if let coin = viewModel.coins.first(where: { $0.id == id }) {
                                            viewModel.selectLeft(coin)
                                        }
                                    }
                                )) {
                                    Text(NSLocalizedString("Select", comment: "")).tag("")
                                    ForEach(viewModel.coins) { coin in
                                        Text("\(coin.name) (\(coin.symbol))").tag(coin.id)
                                    }
                                }
                                .pickerStyle(.menu)

                                Text(PriceFormatter.short(viewModel.left?.currentPrice))
                                    .font(AppTypography.title)
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Picker(NSLocalizedString("Coin", comment: ""), selection: Binding(
                                    get: {
                                        if let current = viewModel.right?.id, viewModel.coins.contains(where: { $0.id == current }) {
                                            return current
                                        }
                                        return ""
                                    },
                                    set: { id in
                                        if let coin = viewModel.coins.first(where: { $0.id == id }) {
                                            viewModel.selectRight(coin)
                                        }
                                    }
                                )) {
                                    Text(NSLocalizedString("Select", comment: "")).tag("")
                                    ForEach(viewModel.coins) { coin in
                                        Text("\(coin.name) (\(coin.symbol))").tag(coin.id)
                                    }
                                }
                                .pickerStyle(.menu)

                                Text(PriceFormatter.short(viewModel.right?.currentPrice))
                                    .font(AppTypography.title)
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text(NSLocalizedString("Ratio", comment: ""))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text("1 \(viewModel.left?.symbol ?? "") = \(viewModel.ratioText) \(viewModel.right?.symbol ?? "")")
                                    .font(AppTypography.headline)

                                if let diff = viewModel.differencePercent {
                                    Text(PercentFormatter.string(diff))
                                        .font(AppTypography.caption)
                                        .foregroundColor(diff >= 0 ? AppColors.positive : AppColors.negative)
                                }
                            }
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle(NSLocalizedString("Compare", comment: ""))
            .onAppear { viewModel.load() }
        }
    }
}

#Preview {
    CompareView(viewModel: CompareViewModel(
        marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    ))
}
