import SwiftUI

struct CoinDetailsView: View {
    @StateObject var viewModel: CoinDetailsViewModel
    @EnvironmentObject private var appEnv: AppEnvironment
    @State private var showAddHolding = false
    @State private var showCreateAlert = false
    @State private var showFullScreenChart = false
    @State private var selectedPoint: PricePoint?
    @State private var preselectedAlertPrice: Double?
    @FocusState private var notesFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                header

                chartSection

                statsSection

                notesSection

                actionButtons
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle(NSLocalizedString("Details", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.spring()) {
                        viewModel.toggleFavorite()
                    }
                    HapticsManager.shared.impact(.light, enabled: appEnv.hapticsEnabled)
                } label: {
                    Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                        .foregroundColor(viewModel.isFavorite ? .yellow : AppColors.textPrimary)
                        .scaleEffect(viewModel.isFavorite ? 1.1 : 1.0)
                }
                .accessibilityIdentifier("favorite_button")
            }
        }
        .sheet(isPresented: $showAddHolding) {
            let coin = viewModel.details.map {
                CoinMarket(
                    id: $0.id,
                    name: $0.name,
                    symbol: $0.symbol,
                    imageURL: $0.imageURL,
                    currentPrice: $0.currentPrice,
                    priceChangePercentage24h: $0.priceChangePercentage24h,
                    marketCap: $0.marketCap,
                    totalVolume: $0.totalVolume,
                    high24h: $0.high24h,
                    low24h: $0.low24h,
                    lastUpdated: $0.lastUpdated
                )
            }
            HoldingFormView(
                title: NSLocalizedString("Add Holding", comment: ""),
                preselectedCoin: coin,
                marketRepository: nil,
                initialAmount: nil,
                initialAvgPrice: nil
            ) { _, amount, avg in
                viewModel.addHolding(amount: amount, avgBuyPrice: avg)
            }
        }
        .sheet(isPresented: $showCreateAlert) {
            let coin = viewModel.details.map {
                CoinMarket(
                    id: $0.id,
                    name: $0.name,
                    symbol: $0.symbol,
                    imageURL: $0.imageURL,
                    currentPrice: $0.currentPrice,
                    priceChangePercentage24h: $0.priceChangePercentage24h,
                    marketCap: $0.marketCap,
                    totalVolume: $0.totalVolume,
                    high24h: $0.high24h,
                    low24h: $0.low24h,
                    lastUpdated: $0.lastUpdated
                )
            }
            AlertFormView(preselectedCoin: coin, marketRepository: nil, preselectedPrice: preselectedAlertPrice) { _, value, metric, direction, repeatMode, cooldown in
                viewModel.createAlert(targetPrice: value, metric: metric, direction: direction, repeatMode: repeatMode, cooldownMinutes: cooldown)
            }
        }
        .onChange(of: viewModel.chart) { _ in
            selectedPoint = nil
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(NSLocalizedString("Done", comment: "")) { notesFocused = false }
            }
        }
        .fullScreenCover(isPresented: $showFullScreenChart) {
            FullScreenChartView(
                title: viewModel.details?.name ?? NSLocalizedString("Price Chart", comment: ""),
                points: viewModel.chart,
                range: $viewModel.selectedRange,
                selectedPoint: $selectedPoint,
                ranges: viewModel.availableRanges,
                hapticsEnabled: appEnv.hapticsEnabled,
                onSelectRange: { range in
                    selectedPoint = nil
                    Task { await viewModel.selectRange(range) }
                },
                onCreateAlert: { price in
                    preselectedAlertPrice = price
                    showCreateAlert = true
                },
                onClose: { showFullScreenChart = false }
            )
        }
        .onDisappear {
            if notesFocused {
                viewModel.saveNote()
            }
        }
    }

    private var header: some View {
        VStack(spacing: AppSpacing.md) {
            if let details = viewModel.details {
                HStack(spacing: AppSpacing.md) {
                    Group {
                        if let url = details.imageURL {
                            CachedAsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Image(systemName: "bitcoinsign.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        } else {
                            Image(systemName: "bitcoinsign.circle")
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(details.name)
                            .font(AppTypography.title)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(details.symbol)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(PriceFormatter.string(details.currentPrice))
                        .font(AppTypography.largeTitle)
                    Text(PercentFormatter.string(details.priceChangePercentage24h))
                        .font(AppTypography.headline)
                        .foregroundColor(details.priceChangePercentage24h.isPositive ? AppColors.positive : AppColors.negative)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if viewModel.isLoadingDetails {
                ProgressView()
            } else if let error = viewModel.detailsError {
                VStack(spacing: AppSpacing.sm) {
                    Text(error.errorDescription ?? "Error")
                        .foregroundColor(AppColors.negative)
                    PrimaryButton(title: NSLocalizedString("Retry", comment: ""), systemImage: "arrow.clockwise") {
                        Task { await viewModel.loadDetails(force: true) }
                    }
                }
            }
        }
        .cardStyle()
    }

    private var chartSection: some View {
        VStack(spacing: AppSpacing.sm) {
            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text(NSLocalizedString("Price Chart", comment: ""))
                            .font(AppTypography.headline)
                        Spacer()
                        Button {
                            showFullScreenChart = true
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                        }
                    }

                    ChartRangePicker(selectedRange: $viewModel.selectedRange, ranges: viewModel.availableRanges) { range in
                        selectedPoint = nil
                        Task { await viewModel.selectRange(range) }
                    }

                    if selectedPoint == nil, let stats = viewModel.chartStats {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(PriceFormatter.short(stats.end))
                                    .font(AppTypography.title)
                                Text(PercentFormatter.string(stats.changePercent))
                                    .font(AppTypography.caption)
                                    .foregroundColor(stats.changePercent >= 0 ? AppColors.positive : AppColors.negative)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(format: NSLocalizedString("High %@", comment: ""), PriceFormatter.short(stats.high)))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(String(format: NSLocalizedString("Low %@", comment: ""), PriceFormatter.short(stats.low)))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if viewModel.isLoadingChart {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 220)
                    } else if let error = viewModel.chartError {
                        VStack(spacing: AppSpacing.sm) {
                            Text(error.errorDescription ?? NSLocalizedString("Chart error", comment: ""))
                                .foregroundColor(AppColors.negative)
                            PrimaryButton(title: NSLocalizedString("Retry", comment: ""), systemImage: "arrow.clockwise") {
                                Task { await viewModel.loadChart(force: true) }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                    } else {
                        PriceChartView(
                            points: viewModel.chart,
                            range: viewModel.selectedRange,
                            selectedPoint: $selectedPoint,
                            height: 250,
                            showsTooltip: true,
                            hapticsEnabled: appEnv.hapticsEnabled
                        )
                    }
                }
            }
            if let selected = selectedPoint {
                let title = String(format: NSLocalizedString("Create Notification at %@", comment: ""), PriceFormatter.short(selected.price))
                PrimaryButton(title: title, systemImage: "bell") {
                    preselectedAlertPrice = selected.price
                    showCreateAlert = true
                }
            }
        }
    }

    private var statsSection: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                statItem(title: NSLocalizedString("Market Cap", comment: ""), value: PriceFormatter.short(viewModel.details?.marketCap))
                statItem(title: NSLocalizedString("Volume 24h", comment: ""), value: PriceFormatter.short(viewModel.details?.totalVolume))
            }
            HStack {
                statItem(title: NSLocalizedString("High 24h", comment: ""), value: PriceFormatter.short(viewModel.details?.high24h))
                statItem(title: NSLocalizedString("Low 24h", comment: ""), value: PriceFormatter.short(viewModel.details?.low24h))
            }
            HStack {
                statItem(title: NSLocalizedString("Supply", comment: ""), value: viewModel.details?.circulatingSupply.map { "\(Int($0))" } ?? "—")
                statItem(
                    title: NSLocalizedString("Updated", comment: ""),
                    value: {
                        let date = viewModel.details?.lastUpdated ?? viewModel.detailsLoadedAt ?? viewModel.chart.last?.date
                        return date.map { DateFormatter.shortDateTime.string(from: $0) } ?? "—"
                    }()
                )
            }
        }
        .cardStyle()
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(AppTypography.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            PrimaryButton(title: NSLocalizedString("Add to Portfolio", comment: ""), systemImage: "plus.circle") {
                showAddHolding = true
            }
            PrimaryButton(title: NSLocalizedString("Create Notification", comment: ""), systemImage: "bell") {
                preselectedAlertPrice = viewModel.details?.currentPrice
                showCreateAlert = true
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(NSLocalizedString("Notes", comment: ""))
                    .font(AppTypography.headline)
                Spacer()
                if let updated = viewModel.noteLastUpdated {
                    Text(DateFormatter.shortDateTime.string(from: updated))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.noteText)
                    .focused($notesFocused)
                    .frame(minHeight: 110)
                    .padding(8)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onTapGesture {
                        notesFocused = true
                    }
                if viewModel.noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(NSLocalizedString("Add a note…", comment: ""))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, 14)
                        .padding(.leading, 14)
                        .allowsHitTesting(false)
                }
            }

            HStack(spacing: AppSpacing.sm) {
                PrimaryButton(title: NSLocalizedString("Save", comment: ""), systemImage: "square.and.arrow.down") {
                    viewModel.saveNote()
                    notesFocused = false
                }
                .disabled(viewModel.noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if !viewModel.notes.isEmpty {
                    Button(role: .destructive) {
                        viewModel.clearAllNotes()
                    } label: {
                        Text(NSLocalizedString("Clear", comment: ""))
                    }
                    .buttonStyle(.bordered)
                }
            }

            if viewModel.notes.isEmpty {
                Text(NSLocalizedString("No notes yet", comment: ""))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.notes) { note in
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(note.text)
                                    .font(AppTypography.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(DateFormatter.shortDateTime.string(from: note.updatedAt))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Button(role: .destructive) {
                                viewModel.deleteNote(id: note.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .cardStyle()
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let shortDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}

#Preview {
    CoinDetailsView(viewModel: CoinDetailsViewModel(
        coinId: "bitcoin",
        coinRepository: CoinRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        favoritesRepository: FavoritesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        portfolioRepository: PortfolioRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        alertsRepository: AlertsRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        notesRepository: NotesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    ))
    .environmentObject(AppEnvironment())
}
