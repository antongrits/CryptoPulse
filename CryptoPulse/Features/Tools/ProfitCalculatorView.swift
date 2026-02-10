import SwiftUI

struct ProfitCalculatorView: View {
    @StateObject var viewModel: ProfitCalculatorViewModel
    @FocusState private var focusedField: Field?

    enum Field { case amount, buy }

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    if viewModel.coins.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("No market data", comment: ""),
                            message: NSLocalizedString("Refresh Market to load prices.", comment: ""),
                            assetName: "EmptySearch",
                            systemImageFallback: "chart.line.uptrend.xyaxis"
                        )
                    } else {
                        CardView {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Picker(NSLocalizedString("Coin", comment: ""), selection: Binding(
                                    get: {
                                        if let current = viewModel.selectedCoin?.id, viewModel.coins.contains(where: { $0.id == current }) {
                                            return current
                                        }
                                        return ""
                                    },
                                    set: { id in
                                        if let coin = viewModel.coins.first(where: { $0.id == id }) {
                                            viewModel.selectedCoin = coin
                                        }
                                    }
                                )) {
                                    Text(NSLocalizedString("Select", comment: "")).tag("")
                                    ForEach(viewModel.coins) { coin in
                                        Text("\(coin.name) (\(coin.symbol))").tag(coin.id)
                                    }
                                }
                                .pickerStyle(.menu)

                                Text(PriceFormatter.short(viewModel.selectedCoin?.currentPrice))
                                    .font(AppTypography.title)
                            }
                        }

                        CardView {
                            VStack(spacing: AppSpacing.sm) {
                                TextField(NSLocalizedString("Amount", comment: ""), text: Binding(
                                    get: { viewModel.amountText },
                                    set: { viewModel.amountText = NumberParsing.sanitizeDecimalInput($0) }
                                ))
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .amount)
                                Divider()
                                TextField(NSLocalizedString("Average Buy Price (optional)", comment: ""), text: Binding(
                                    get: { viewModel.buyPriceText },
                                    set: { viewModel.buyPriceText = NumberParsing.sanitizeDecimalInput($0) }
                                ))
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .buy)
                            }
                        }

                        if let pl = viewModel.profitLoss {
                            CardView {
                                HStack {
                                    Text(NSLocalizedString("P/L", comment: ""))
                                    Spacer()
                                    Text(PriceFormatter.short(pl))
                                        .foregroundColor(pl >= 0 ? AppColors.positive : AppColors.negative)
                                }
                                if let percent = viewModel.profitLossPercent {
                                    HStack {
                                        Text("%")
                                        Spacer()
                                        Text(PercentFormatter.string(percent))
                                            .foregroundColor(percent >= 0 ? AppColors.positive : AppColors.negative)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle(NSLocalizedString("Profit Calculator", comment: ""))
            .onAppear { viewModel.load() }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(NSLocalizedString("Done", comment: "")) { focusedField = nil }
                }
            }
        }
    }
}

#Preview {
    ProfitCalculatorView(viewModel: ProfitCalculatorViewModel(
        marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    ))
}
