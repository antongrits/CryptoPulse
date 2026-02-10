import SwiftUI

struct HoldingFormView: View {
    let title: String
    let preselectedCoin: CoinMarket?
    let marketRepository: MarketRepositoryProtocol?
    let initialAmount: Double?
    let initialAvgPrice: Double?
    let onSave: (CoinMarket, Double, Double?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var amountText: String = ""
    @State private var avgPriceText: String = ""

    @State private var selectedCoin: CoinMarket?
    @FocusState private var focusedField: Field?

    enum Field {
        case amount
        case avgPrice
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

                Section(NSLocalizedString("Amount", comment: "")) {
                    TextField(NSLocalizedString("Amount", comment: ""), text: Binding(
                        get: { amountText },
                        set: { amountText = NumberParsing.sanitizeDecimalInput($0) }
                    ))
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                    TextField(NSLocalizedString("Average Buy Price (optional)", comment: ""), text: Binding(
                        get: { avgPriceText },
                        set: { avgPriceText = NumberParsing.sanitizeDecimalInput($0) }
                    ))
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .avgPrice)
                }
            }
            .navigationTitle(title)
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
            if let initialAmount { amountText = NumberParsing.string(from: initialAmount, maximumFractionDigits: 8) }
            if let initialAvgPrice { avgPriceText = NumberParsing.string(from: initialAvgPrice, maximumFractionDigits: 8) }
        }
    }

    private var filteredCoins: [CoinMarket] {
        let coins = marketRepository?.cachedMarkets(sortedBy: .marketCapDesc) ?? []
        if searchText.isEmpty { return coins.prefix(30).map { $0 } }
        return coins.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.symbol.localizedCaseInsensitiveContains(searchText) }
    }

    private var canSave: Bool {
        guard selectedCoin != nil || preselectedCoin != nil else { return false }
        return NumberParsing.double(from: amountText) != nil
    }

    private func save() {
        guard let amount = NumberParsing.double(from: amountText) else { return }
        let avg = NumberParsing.double(from: avgPriceText)
        let coin = preselectedCoin ?? selectedCoin
        guard let coin else { return }
        onSave(coin, amount, avg)
        dismiss()
    }
}
