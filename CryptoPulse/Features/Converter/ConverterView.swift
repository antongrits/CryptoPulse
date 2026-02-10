import SwiftUI
import UIKit

struct ConverterView: View {
    @StateObject var viewModel: ConverterViewModel
    @FocusState private var focusedField: Field?
    @State private var swapRotation: Double = 0
    @State private var showCopied = false

    enum Field {
        case usd
        case coin
    }

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    if viewModel.coins.isEmpty && !viewModel.isLoading {
                        EmptyStateView(
                            title: NSLocalizedString("No market data", comment: ""),
                            message: NSLocalizedString("Refresh Market to load prices.", comment: ""),
                            assetName: "EmptySearch",
                            systemImageFallback: "arrow.left.arrow.right",
                            actionTitle: NSLocalizedString("Refresh", comment: ""),
                            action: { Task { await viewModel.refresh() } }
                        )
                    } else {
                        if viewModel.isLoading {
                            ProgressView()
                        }

                        if let error = viewModel.error, viewModel.coins.isEmpty {
                            BannerView(title: error.errorDescription ?? NSLocalizedString("Try again.", comment: ""), systemImage: "exclamationmark.triangle")
                        } else if viewModel.showOfflineBanner {
                            BannerView(title: NSLocalizedString("Offline mode. Showing cached data.", comment: ""), systemImage: "wifi.slash")
                        }

                        headerCard

                        coinPickerCard

                        inputCard

                        quickChips

                        resultCard

                        rateCard

                        historySection
                    }
                }
                .padding(AppSpacing.md)
            }
            .refreshable { await viewModel.refresh() }
            .navigationTitle(NSLocalizedString("Converter", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(NSLocalizedString("Done", comment: "")) {
                        focusedField = nil
                        viewModel.commitConversion()
                    }
                }
            }
        }
        .onAppear { viewModel.loadCached() }
        .task { await viewModel.loadIfNeeded() }
        .overlay(alignment: .top) {
            if showCopied {
                BannerView(title: NSLocalizedString("Copied", comment: ""), systemImage: "checkmark.circle.fill")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCopied)
    }

    private var headerCard: some View {
        Group {
            if let selected = viewModel.selectedCoin {
                CardView {
                    HStack(spacing: AppSpacing.md) {
                        if let url = selected.imageURL {
                            CachedAsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Image(systemName: "bitcoinsign.circle")
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        } else {
                            Image(systemName: "bitcoinsign.circle")
                                .frame(width: 44, height: 44)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selected.name)
                                .font(AppTypography.headline)
                            Text(selected.symbol.uppercased())
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(PriceFormatter.short(selected.currentPrice))
                                .font(AppTypography.title)
                            Text(PercentFormatter.string(selected.priceChangePercentage24h))
                                .font(AppTypography.caption)
                                .foregroundColor(selected.priceChangePercentage24h.isPositive ? AppColors.positive : AppColors.negative)
                        }
                    }

                    if let updated = viewModel.lastUpdated {
                        let updatedLabel = NSLocalizedString("Updated", comment: "")
                        Text(updatedLabel + " " + DateFormatter.shortDate.string(from: updated))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.top, AppSpacing.xs)
                    }
                }
            }
        }
    }

    private var coinPickerCard: some View {
        Group {
            if !viewModel.coins.isEmpty {
                CardView(padding: AppSpacing.sm) {
                    Menu {
                        ForEach(viewModel.coins) { coin in
                            Button {
                                viewModel.selectCoin(coin)
                            } label: {
                                Text("\(coin.name) (\(coin.symbol.uppercased()))")
                            }
                        }
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Text(NSLocalizedString("Coin", comment: ""))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text(viewModel.selectedCoin?.name ?? NSLocalizedString("Select", comment: ""))
                                .font(AppTypography.headline)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                    }
                }
            }
        }
    }

    private var inputCard: some View {
        CardView {
            VStack(spacing: AppSpacing.md) {
                ConverterFieldRow(
                    title: NSLocalizedString("You Pay", comment: ""),
                    suffix: "USD",
                    text: Binding(
                        get: { viewModel.usdText },
                        set: { value in viewModel.updateUSD(value) }
                    ),
                    focusedField: $focusedField,
                    field: .usd
                )

                Divider()

                ConverterFieldRow(
                    title: NSLocalizedString("You Receive", comment: ""),
                    suffix: viewModel.selectedCoin?.symbol.uppercased() ?? "—",
                    text: Binding(
                        get: { viewModel.coinText },
                        set: { value in viewModel.updateCoin(value) }
                    ),
                    focusedField: $focusedField,
                    field: .coin
                )
            }
            .overlay(alignment: .center) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        swapRotation += 180
                    }
                    viewModel.swapInputs()
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.title2)
                        .rotationEffect(.degrees(swapRotation))
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityIdentifier("converter_swap")
            }
        }
    }

    private var resultCard: some View {
        Group {
            if let summary = viewModel.resultSummary {
                CardView {
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Result", comment: ""))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            Text(summary)
                                .font(AppTypography.headline)
                        }
                        Spacer()
                        Button {
                            UIPasteboard.general.string = summary
                            showCopied = true
                            viewModel.commitConversion()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showCopied = false
                            }
                        } label: {
                            Label(NSLocalizedString("Copy", comment: ""), systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("converter_copy")
                    }
                }
            }
        }
    }

    private var rateCard: some View {
        Group {
            if let selected = viewModel.selectedCoin, selected.currentPrice > 0 {
                CardView {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(NSLocalizedString("Rate", comment: ""))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text("1 \(selected.symbol.uppercased()) = \(PriceFormatter.string(selected.currentPrice))")
                            .font(AppTypography.headline)
                        Text("1 USD = \(NumberParsing.string(from: 1 / selected.currentPrice, maximumFractionDigits: 8)) \(selected.symbol.uppercased())")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
    }

    private var historySection: some View {
        Group {
            if !viewModel.history.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text(NSLocalizedString("History", comment: ""))
                            .font(AppTypography.headline)
                        Spacer()
                        Button(NSLocalizedString("Clear", comment: "")) {
                            viewModel.clearHistory()
                        }
                        .font(AppTypography.caption)
                    }

                    ForEach(viewModel.history) { record in
                        CardView {
                            HStack(spacing: AppSpacing.md) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(PriceFormatter.short(record.usdAmount)) → \(NumberParsing.string(from: record.coinAmount, maximumFractionDigits: 8)) \(record.symbol.uppercased())")
                                        .font(AppTypography.headline)
                                    Text(DateFormatter.shortDate.string(from: record.createdAt))
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Button {
                                    let text = "\(PriceFormatter.string(record.usdAmount)) = \(NumberParsing.string(from: record.coinAmount, maximumFractionDigits: 8)) \(record.symbol.uppercased())"
                                    UIPasteboard.general.string = text
                                    showCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        showCopied = false
                                    }
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(.borderless)
                                .accessibilityIdentifier("converter_copy_history_\(record.id)")
                            }
                        }
                    }
                }
            }
        }
    }

    private var quickChips: some View {
        let chips: [String]
        let isUSD = focusedField != .coin
        if isUSD {
            chips = ["100", "500", "1000", "5000"]
        } else {
            chips = ["0.1", "0.5", "1", "5"]
        }
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(NSLocalizedString("Quick amounts", comment: ""))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(chips, id: \.self) { value in
                        let title = isUSD ? "$\(value)" : value
                        ChipView(title: title, isSelected: isChipSelected(value: value, isUSD: isUSD))
                            .onTapGesture {
                                if isUSD {
                                    viewModel.updateUSD(value)
                                    focusedField = .usd
                                } else {
                                    viewModel.updateCoin(value)
                                    focusedField = .coin
                                }
                            }
                    }
                }
            }
        }
    }

    private func isChipSelected(value: String, isUSD: Bool) -> Bool {
        let currentText = isUSD ? viewModel.usdText : viewModel.coinText
        guard let currentValue = NumberParsing.double(from: currentText),
              let chipValue = Double(value) else { return false }
        return abs(currentValue - chipValue) < 0.000_001
    }
}

private struct ConverterFieldRow: View {
    let title: String
    let suffix: String
    @Binding var text: String
    let focusedField: FocusState<ConverterView.Field?>.Binding
    let field: ConverterView.Field

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            HStack {
                TextField(title, text: $text)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: field)
                    .font(AppTypography.largeTitle)
                Spacer()
                Text(suffix)
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

#Preview {
    ConverterView(viewModel: ConverterViewModel(
        marketRepository: MarketRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        historyRepository: ConversionHistoryRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    ))
}
