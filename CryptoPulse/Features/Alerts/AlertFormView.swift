import SwiftUI

struct AlertFormView: View {
    let preselectedCoin: CoinMarket?
    let marketRepository: MarketRepositoryProtocol?
    let preselectedPrice: Double?
    var formTitle: String = NSLocalizedString("Create Alert", comment: "")
    var initialMetric: PriceAlertMetric? = nil
    var initialDirection: PriceAlertDirection? = nil
    var initialRepeatMode: PriceAlertRepeatMode? = nil
    var initialCooldownMinutes: Int? = nil
    let onSave: (CoinMarket, Double, PriceAlertMetric, PriceAlertDirection, PriceAlertRepeatMode, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var targetPriceText = ""
    @State private var metric: PriceAlertMetric = .price
    @State private var direction: PriceAlertDirection = .above
    @State private var repeatMode: PriceAlertRepeatMode = .onceUntilReset
    @State private var cooldownMinutes: Int = 30
    @State private var selectedCoin: CoinMarket?
    @FocusState private var focusedField: Field?

    enum Field {
        case targetPrice
    }

    var body: some View {
        NavigationView {
            Form {
                Section(NSLocalizedString("Coin", comment: "")) {
                    if let preselectedCoin {
                        HStack {
                            Text(preselectedCoin.name)
                            Spacer()
                            Text(preselectedCoin.symbol)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        TextField(NSLocalizedString("Search coins", comment: ""), text: $searchText)
                        ForEach(filteredCoins) { coin in
                            Button {
                                selectedCoin = coin
                            } label: {
                                HStack {
                                    Text(coin.name)
                                    Spacer()
                                    Text(coin.symbol)
                                        .foregroundColor(.secondary)
                                    if selectedCoin?.id == coin.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }

                Section(NSLocalizedString("Alert", comment: "")) {
                    Picker(NSLocalizedString("Metric", comment: ""), selection: $metric) {
                        ForEach(PriceAlertMetric.allCases) { metric in
                            Text(metric.title).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField(metric.targetTitle, text: Binding(
                        get: { targetPriceText },
                        set: { targetPriceText = NumberParsing.sanitizeDecimalInput($0, allowsNegative: metric == .percentChange24h) }
                    ))
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .targetPrice)
                    Picker(NSLocalizedString("Direction", comment: ""), selection: $direction) {
                        ForEach(PriceAlertDirection.allCases) { direction in
                            Text(direction.title).tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker(NSLocalizedString("Repeat Mode", comment: ""), selection: $repeatMode) {
                        ForEach(PriceAlertRepeatMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)

                    Stepper(value: $cooldownMinutes, in: 5...180, step: 5) {
                        Text(String(format: NSLocalizedString("Cooldown: %d min", comment: ""), cooldownMinutes))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .navigationTitle(formTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "")) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Save", comment: "")) { save() }
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(NSLocalizedString("Done", comment: "")) { focusedField = nil }
                }
            }
        }
        .onAppear {
            selectedCoin = preselectedCoin
            if let preselectedPrice {
                targetPriceText = NumberParsing.string(from: preselectedPrice, maximumFractionDigits: 6)
            }
            if let initialMetric {
                metric = initialMetric
            }
            if let initialDirection {
                direction = initialDirection
            }
            if let initialRepeatMode {
                repeatMode = initialRepeatMode
            }
            if let initialCooldownMinutes {
                cooldownMinutes = initialCooldownMinutes
            }
        }
    }

    private var filteredCoins: [CoinMarket] {
        let coins = marketRepository?.cachedMarkets(sortedBy: .marketCapDesc) ?? []
        if searchText.isEmpty { return coins.prefix(30).map { $0 } }
        return coins.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.symbol.localizedCaseInsensitiveContains(searchText) }
    }

    private var canSave: Bool {
        guard selectedCoin != nil || preselectedCoin != nil else { return false }
        return NumberParsing.double(from: targetPriceText) != nil
    }

    private func save() {
        guard let price = NumberParsing.double(from: targetPriceText) else { return }
        let coin = preselectedCoin ?? selectedCoin
        guard let coin else { return }
        onSave(coin, price, metric, direction, repeatMode, cooldownMinutes)
        dismiss()
    }
}
