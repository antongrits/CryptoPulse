import SwiftUI
#if canImport(Charts)
import Charts
#endif

struct PriceChartView: View {
    let points: [PricePoint]
    let range: ChartRange
    @Binding var selectedPoint: PricePoint?
    var fixedYDomain: ClosedRange<Double>? = nil
    var height: CGFloat = 240
    var showsTooltip: Bool = true
    var showsPriceAxisLabel: Bool = true
    var hapticsEnabled: Bool = true
    var allowsInternalSelection: Bool = true
    var tooltipYOffset: CGFloat = 22
    private let tooltipWidth: CGFloat = 210
    private let tooltipMargin: CGFloat = 10
    @State private var bubbleSize: CGSize = .zero

    var body: some View {
        let sorted = points.sorted { $0.date < $1.date }
        if sorted.count < 2 {
            VStack {
                Text(NSLocalizedString("Not enough data", comment: ""))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: height)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    chartContent(points: sorted)
                        .frame(width: geo.size.width, height: geo.size.height)
                    if showsTooltip, let selected = selectedPoint {
                        let bubbleWidth = min(tooltipWidth, geo.size.width - tooltipMargin * 2)
                        let bubbleHeight = bubbleSize.height > 0 ? bubbleSize.height : 120
                        let maxY = max(tooltipMargin, geo.size.height - bubbleHeight - tooltipMargin)
                        let clampedY = min(max(tooltipYOffset, tooltipMargin), maxY)
                        ChartTooltipBubble(point: selected, previousPoint: previousPoint(for: selected, in: sorted))
                            .frame(width: bubbleWidth, alignment: .leading)
                            .background(GeometryReader { proxy in
                                Color.clear.preference(key: ChartTooltipSizeKey.self, value: proxy.size)
                            })
                            .offset(x: tooltipOffsetX(for: selected, width: geo.size.width, bubbleWidth: bubbleWidth, points: sorted),
                                    y: clampedY)
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }
                }
                .onPreferenceChange(ChartTooltipSizeKey.self) { size in
                    if size != .zero {
                        bubbleSize = size
                    }
                }
            }
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColors.textSecondary.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .clipped()
        }
    }

    @ViewBuilder
    private func chartContent(points: [PricePoint]) -> some View {
        if #available(iOS 16.0, *) {
            PriceChartIOS16(
                points: points,
                range: range,
                selectedPoint: $selectedPoint,
                yDomainOverride: fixedYDomain,
                showsPriceAxisLabel: showsPriceAxisLabel,
                hapticsEnabled: hapticsEnabled,
                allowsInternalSelection: allowsInternalSelection
            )
        } else {
            CustomLineChartView(
                points: points,
                range: range,
                selectedPoint: $selectedPoint,
                yDomainOverride: fixedYDomain,
                showsPriceAxisLabel: showsPriceAxisLabel,
                hapticsEnabled: hapticsEnabled,
                allowsInternalSelection: allowsInternalSelection
            )
        }
    }

    private func previousPoint(for selected: PricePoint, in points: [PricePoint]) -> PricePoint? {
        guard let index = points.firstIndex(of: selected), index > 0 else { return nil }
        return points[index - 1]
    }

    private func tooltipOffsetX(for selected: PricePoint, width: CGFloat, bubbleWidth: CGFloat, points: [PricePoint]) -> CGFloat {
        guard points.count > 1, let index = points.firstIndex(of: selected) else { return width / 2 }
        let rawX = width * CGFloat(index) / CGFloat(points.count - 1)
        let proposed = rawX - bubbleWidth / 2
        let minX = tooltipMargin
        let maxX = width - bubbleWidth - tooltipMargin
        return min(max(proposed, minX), maxX)
    }
}

@available(iOS 16.0, *)
struct PriceChartIOS16: View {
    let points: [PricePoint]
    let range: ChartRange
    @Binding var selectedPoint: PricePoint?
    let yDomainOverride: ClosedRange<Double>?
    let showsPriceAxisLabel: Bool
    let hapticsEnabled: Bool
    let allowsInternalSelection: Bool
    @State private var lastHapticDate: Date?

    var body: some View {
        let domain = yDomain
        Chart {
            ForEach(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Price", point.price)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(AppColors.accent)

                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Baseline", domain.lowerBound),
                    yEnd: .value("Price", point.price)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(colors: [AppColors.accent.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
            }

            if let selected = selectedPoint {
                RuleMark(x: .value("Selected", selected.date))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                RuleMark(y: .value("Selected", selected.price))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Price", selected.price)
                )
                .foregroundStyle(AppColors.accent)
                .symbolSize(40)
            }
        }
        .chartYScale(domain: yDomain)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                    .foregroundStyle(AppColors.textSecondary.opacity(0.2))
                AxisTick()
                    .foregroundStyle(AppColors.textSecondary.opacity(0.4))
                AxisValueLabel() {
                    if let price = value.as(Double.self) {
                        Text(PriceFormatter.compact(price))
                            .font(AppTypography.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                    .foregroundStyle(AppColors.textSecondary.opacity(0.15))
                AxisTick()
                    .foregroundStyle(AppColors.textSecondary.opacity(0.4))
                AxisValueLabel() {
                    if let date = value.as(Date.self) {
                        Text(range.axisDateStyle.string(from: date))
                            .font(AppTypography.caption)
                    }
                }
            }
        }
        .chartPlotStyle { plot in
            plot
                .padding(.leading, 10)
                .padding(.trailing, 6)
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                let plotFrame = geo[proxy.plotAreaFrame]
                ZStack(alignment: .topLeading) {
                    if allowsInternalSelection {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard plotFrame.contains(value.location) else { return }
                                        let x = value.location.x - plotFrame.origin.x
                                        if let date: Date = proxy.value(atX: x) {
                                            let nearest = nearestPoint(to: date)
                                            selectedPoint = nearest
                                            if let nearest, nearest.date != lastHapticDate {
                                                lastHapticDate = nearest.date
                                                HapticsManager.shared.selectionChanged(enabled: hapticsEnabled)
                                            }
                                        }
                                    }
                            )
                            .onTapGesture { selectedPoint = nil }
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .allowsHitTesting(false)
                    }

                    if showsPriceAxisLabel,
                       let selected = selectedPoint,
                       let y = proxy.position(forY: selected.price) {
                        PriceAxisFloatingLabel(text: PriceFormatter.short(selected.price))
                            .position(x: geo.size.width - 42, y: min(max(plotFrame.minY + 12, y), plotFrame.maxY - 12))
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .padding(.top, 6)
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.bottom, 4)
    }

    private func nearestPoint(to date: Date) -> PricePoint? {
        points.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    private var yDomain: ClosedRange<Double> {
        if let yDomainOverride {
            return yDomainOverride
        }
        let minPrice = points.map(\.price).min() ?? 0
        let maxPrice = points.map(\.price).max() ?? 1
        if abs(maxPrice - minPrice) < 0.000_000_000_001 {
            let padding = max(abs(maxPrice) * 0.03, 0.000_000_000_001)
            return (minPrice - padding)...(maxPrice + padding)
        }
        let padding = max((maxPrice - minPrice) * 0.12, 0.000_000_000_001)
        return (minPrice - padding)...(maxPrice + padding)
    }
}

struct PriceAxisFloatingLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTypography.caption)
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColors.cardBackground.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColors.textSecondary.opacity(0.18), lineWidth: 1)
            )
    }
}

struct ChartTooltipBubble: View {
    let point: PricePoint
    let previousPoint: PricePoint?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(PriceFormatter.short(point.price))
                    .font(AppTypography.title)
                Spacer()
                if let prev = previousPoint {
                    let change = point.price - prev.price
                    let percent = prev.price == 0 ? 0 : (change / prev.price) * 100
                    Text(PercentFormatter.string(percent))
                        .font(AppTypography.caption)
                        .foregroundColor(percent >= 0 ? AppColors.positive : AppColors.negative)
                }
            }

            Text(DateFormatter.chartTooltip.string(from: point.date))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            if point.volume != nil || point.marketCap != nil {
                Divider()
                    .background(AppColors.textSecondary.opacity(0.2))
                VStack(alignment: .leading, spacing: 4) {
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
                }
            }
        }
        .padding(10)
        .background(AppColors.cardBackground.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 1)
        )
    }
}

private struct ChartTooltipSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
