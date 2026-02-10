import SwiftUI

enum ChartYScaleMode: String, CaseIterable, Identifiable {
    case auto
    case locked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto:
            return NSLocalizedString("Auto Y", comment: "")
        case .locked:
            return NSLocalizedString("Lock Y", comment: "")
        }
    }
}

struct FullScreenChartView: View {
    let title: String
    let points: [PricePoint]
    @Binding var range: ChartRange
    @Binding var selectedPoint: PricePoint?
    let ranges: [ChartRange]
    let hapticsEnabled: Bool
    let onSelectRange: (ChartRange) -> Void
    let onCreateAlert: (Double) -> Void
    let onClose: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var zoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0
    @State private var yScaleMode: ChartYScaleMode = .auto

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            let bottomInset = geo.safeAreaInsets.bottom
            let chartHeight = max(geo.size.height * 0.55, 360)
            let contentWidth = max(300, geo.size.width - (AppSpacing.md * 2))

            VStack(spacing: 0) {
                topBar
                    .padding(.top, topInset + 4)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: AppSpacing.md) {
                        ChartRangePicker(selectedRange: $range, ranges: ranges, onSelect: onSelectRange)
                        zoomControls
                        yScaleControls

                        ChartSelectionSummaryView(
                            point: selectedPoint,
                            previousPoint: previousPoint()
                        )

                        ZoomableChartContainer(
                            points: points,
                            range: range,
                            selectedPoint: $selectedPoint,
                            hapticsEnabled: hapticsEnabled,
                            zoom: $zoom,
                            lastZoom: $lastZoom,
                            yScaleMode: yScaleMode,
                            chartHeight: chartHeight,
                            baseWidth: contentWidth
                        )

                        if !analyticsItems.isEmpty {
                            CardView {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                                    ForEach(Array(analyticsItems.prefix(6))) { item in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                            Text(item.value)
                                                .font(AppTypography.headline)
                                                .lineLimit(2)
                                                .minimumScaleFactor(0.8)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                        }

                        if let selected = selectedPoint {
                            let actionTitle = String(format: NSLocalizedString("Create Notification at %@", comment: ""), PriceFormatter.short(selected.price))
                            PrimaryButton(title: actionTitle, systemImage: "bell") {
                                onCreateAlert(selected.price)
                            }
                            .accessibilityIdentifier("create_notification_fullscreen")
                        }

                        Spacer(minLength: bottomInset + 20)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                AppBackgroundView()
                    .overlay(
                        Color.black.opacity(colorScheme == .dark ? 0.14 : 0.04)
                            .ignoresSafeArea()
                    )
                    .ignoresSafeArea()
            )
        }
    }

    private var topBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(NSLocalizedString("Close", comment: "")) { onClose() }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppColors.cardBackground.opacity(0.88))
                .clipShape(Capsule())
        }
    }

    private var zoomControls: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(NSLocalizedString("Scale", comment: ""))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            Slider(value: Binding(
                get: { zoom },
                set: { value in
                    zoom = min(6, max(1, value))
                    lastZoom = zoom
                }
            ), in: 1...6, step: 0.1)
            Text("\(Int(zoom * 100))%")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    zoom = 1
                    lastZoom = 1
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
            .accessibilityIdentifier("chart_zoom_reset")
        }
    }

    private var yScaleControls: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(NSLocalizedString("Y Scale", comment: ""))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            Picker("", selection: $yScaleMode) {
                ForEach(ChartYScaleMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func previousPoint() -> PricePoint? {
        guard let selected = selectedPoint,
              let index = points.firstIndex(of: selected),
              index > 0 else { return nil }
        return points[index - 1]
    }

    private var analyticsItems: [ChartAnalyticsItem] {
        guard points.count > 1 else { return [] }
        let prices = points.map(\.price)
        let high = prices.max() ?? 0
        let low = prices.min() ?? 0
        let start = points.first?.price ?? 0
        let end = points.last?.price ?? 0
        let changePercent = start == 0 ? 0 : (end - start) / start * 100
        var items: [ChartAnalyticsItem] = [
            .init(title: NSLocalizedString("High", comment: ""), value: PriceFormatter.short(high)),
            .init(title: NSLocalizedString("Low", comment: ""), value: PriceFormatter.short(low)),
            .init(title: NSLocalizedString("Change", comment: ""), value: PercentFormatter.string(changePercent)),
            .init(title: NSLocalizedString("Range", comment: ""), value: PriceFormatter.short(high - low))
        ]
        let volumes = points.compactMap(\.volume)
        if !volumes.isEmpty {
            let avg = volumes.reduce(0, +) / Double(volumes.count)
            let max = volumes.max() ?? 0
            items.append(.init(title: NSLocalizedString("Avg Volume", comment: ""), value: PriceFormatter.short(avg)))
            items.append(.init(title: NSLocalizedString("Max Volume", comment: ""), value: PriceFormatter.short(max)))
        }
        if let cap = points.compactMap(\.marketCap).last {
            items.append(.init(title: NSLocalizedString("Market Cap", comment: ""), value: PriceFormatter.short(cap)))
        }
        return items
    }
}

private struct ZoomableChartContainer: View {
    let points: [PricePoint]
    let range: ChartRange
    @Binding var selectedPoint: PricePoint?
    let hapticsEnabled: Bool
    @Binding var zoom: CGFloat
    @Binding var lastZoom: CGFloat
    let yScaleMode: ChartYScaleMode
    let chartHeight: CGFloat
    let baseWidth: CGFloat
    @State private var windowStart: Int = 0
    @State private var dragStartWindowStart: Int?
    @State private var dragIsHorizontal = false
    @State private var crosshairXRatio: CGFloat = 0.5
    @State private var lastHapticDate: Date?

    var body: some View {
        PriceChartView(
            points: visiblePoints,
            range: range,
            selectedPoint: $selectedPoint,
            fixedYDomain: yScaleMode == .locked ? fullYDomain : nil,
            height: chartHeight,
            showsTooltip: false,
            showsPriceAxisLabel: true,
            hapticsEnabled: hapticsEnabled,
            allowsInternalSelection: false,
            tooltipYOffset: 12
        )
        .frame(width: baseWidth, height: chartHeight)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    guard !points.isEmpty else { return }
                    if dragStartWindowStart == nil {
                        dragStartWindowStart = windowStart
                        dragIsHorizontal = false
                    }

                    if !dragIsHorizontal {
                        let dx = abs(value.translation.width)
                        let dy = abs(value.translation.height)
                        if dx > 6 || dy > 6 {
                            dragIsHorizontal = dx >= dy
                        }
                    }

                    if dragIsHorizontal {
                        let xRatio = clampedRatio(value.location.x / max(baseWidth, 1))
                        crosshairXRatio = xRatio
                        syncSelection(at: xRatio)

                        if let start = dragStartWindowStart {
                            let pointsSpan = max(maxWindowStart, 1)
                            let pointsPerPixel = CGFloat(pointsSpan) / max(baseWidth, 1)
                            let delta = Int(round(-value.translation.width * pointsPerPixel))
                            windowStart = clampedWindowStart(start + delta)
                            syncSelection(at: crosshairXRatio)
                        }
                    }
                }
                .onEnded { value in
                    if dragIsHorizontal {
                        applyInertia(for: value)
                    }
                    dragStartWindowStart = nil
                    dragIsHorizontal = false
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    zoom = min(6, max(1, lastZoom * value))
                    clampWindowStart()
                    syncSelection(at: crosshairXRatio)
                }
                .onEnded { _ in
                    lastZoom = zoom
                    clampWindowStart()
                    syncSelection(at: crosshairXRatio)
                }
        )
        .onChange(of: zoom) { _ in
            clampWindowStart()
            syncSelection(at: crosshairXRatio)
        }
        .onChange(of: yScaleMode) { _ in
            syncSelection(at: crosshairXRatio)
        }
        .onChange(of: points.count) { _ in
            clampWindowStart()
            syncSelection(at: crosshairXRatio)
        }
        .onAppear {
            clampWindowStart()
            syncSelection(at: crosshairXRatio)
        }
        .accessibilityIdentifier("fullscreen_chart")
    }

    private var visiblePoints: [PricePoint] {
        guard !points.isEmpty else { return [] }
        let start = min(max(0, windowStart), maxWindowStart)
        let end = min(points.count, start + visibleCount)
        return Array(points[start..<end])
    }

    private var visibleCount: Int {
        guard !points.isEmpty else { return 0 }
        let minCount = min(24, points.count)
        let baseCount = baselineVisibleCount
        let count = Int(round(Double(baseCount) / Double(zoom)))
        return min(points.count, max(minCount, count))
    }

    private var maxWindowStart: Int {
        max(points.count - visibleCount, 0)
    }

    private var baselineVisibleCount: Int {
        guard !points.isEmpty else { return 0 }
        if points.count <= 100 {
            return points.count
        }
        return min(points.count, 120)
    }

    private var fullYDomain: ClosedRange<Double> {
        let minPrice = points.map(\.price).min() ?? 0
        let maxPrice = points.map(\.price).max() ?? 1
        if abs(maxPrice - minPrice) < 0.000_001 {
            let pad = max(abs(maxPrice) * 0.03, 0.01)
            return (minPrice - pad)...(maxPrice + pad)
        }
        let pad = (maxPrice - minPrice) * 0.12
        return (minPrice - pad)...(maxPrice + pad)
    }

    private func clampWindowStart() {
        windowStart = clampedWindowStart(windowStart)
    }

    private func clampedWindowStart(_ value: Int) -> Int {
        min(max(0, value), maxWindowStart)
    }

    private func syncSelection(at xRatio: CGFloat) {
        guard !visiblePoints.isEmpty else {
            selectedPoint = nil
            return
        }
        let clamped = clampedRatio(xRatio)
        let localIndex = Int(round(clamped * CGFloat(max(visiblePoints.count - 1, 0))))
        let globalIndex = min(points.count - 1, max(0, windowStart + localIndex))
        let point = points[globalIndex]
        selectedPoint = point
        if point.date != lastHapticDate {
            lastHapticDate = point.date
            HapticsManager.shared.selectionChanged(enabled: hapticsEnabled)
        }
    }

    private func applyInertia(for value: DragGesture.Value) {
        guard maxWindowStart > 0 else { return }
        let pointsSpan = max(maxWindowStart, 1)
        let pointsPerPixel = CGFloat(pointsSpan) / max(baseWidth, 1)
        let predictedExtra = value.predictedEndTranslation.width - value.translation.width
        let velocityDelta = Int(round(-predictedExtra * pointsPerPixel * 0.75))
        let target = clampedWindowStart(windowStart + velocityDelta)
        withAnimation(.easeOut(duration: 0.18)) {
            windowStart = target
        }
        syncSelection(at: crosshairXRatio)
    }

    private func clampedRatio(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }
}

struct ChartAnalyticsItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct ChartSelectionSummaryView: View {
    let point: PricePoint?
    let previousPoint: PricePoint?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let point {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(PriceFormatter.short(point.price))
                        .font(AppTypography.title)
                    Text(DateFormatter.chartTooltip.string(from: point.date))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    if let volume = point.volume {
                        Text(String(format: NSLocalizedString("Volume %@", comment: ""), PriceFormatter.compact(volume)))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    if let cap = point.marketCap {
                        Text(String(format: NSLocalizedString("Market Cap %@", comment: ""), PriceFormatter.compact(cap)))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    if let prev = previousPoint {
                        let change = point.price - prev.price
                        let percent = prev.price == 0 ? 0 : (change / prev.price) * 100
                        Text(PercentFormatter.string(percent))
                            .font(AppTypography.caption)
                            .foregroundColor(percent >= 0 ? AppColors.positive : AppColors.negative)
                    }
                }
                Spacer()
            }
            .padding(AppSpacing.sm)
            .background(AppColors.cardBackground.opacity(colorScheme == .dark ? 0.9 : 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            EmptyView()
        }
    }
}

extension DateFormatter {
    static let chartTooltip: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
