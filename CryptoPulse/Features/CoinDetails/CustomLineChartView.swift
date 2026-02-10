import SwiftUI

struct CustomLineChartView: View {
    let points: [PricePoint]
    let range: ChartRange
    @Binding var selectedPoint: PricePoint?
    let yDomainOverride: ClosedRange<Double>?
    let showsPriceAxisLabel: Bool
    let hapticsEnabled: Bool
    let allowsInternalSelection: Bool
    @State private var animate = false
    @State private var lastHapticDate: Date?

    private let insets = ChartInsets(left: 72, right: 56, top: 24, bottom: 42)
    private let gridRows = 4
    private let gridCols = 4

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let plotRect = CGRect(
                x: insets.left,
                y: insets.top,
                width: max(CGFloat(1), size.width - insets.left - insets.right),
                height: max(CGFloat(1), size.height - insets.top - insets.bottom)
            )

            let prices = points.map(\.price)
            let bounds = yBounds(for: prices)
            let minPrice = bounds.min
            let maxPrice = bounds.max
            let priceRange = max(maxPrice - minPrice, 0.0001)

            let chartPoints = points.enumerated().map { index, point -> CGPoint in
                let ratio = CGFloat(index) / CGFloat(max(points.count - 1, 1))
                let x = plotRect.minX + plotRect.width * ratio
                let yPosition = (point.price - minPrice) / priceRange
                let y = plotRect.maxY - (plotRect.height * CGFloat(yPosition))
                return CGPoint(x: x, y: y)
            }

            let linePath = smoothPath(points: chartPoints)

            let areaPath = Path { path in
                path.addPath(linePath)
                path.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))
                path.addLine(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
                path.closeSubpath()
            }

            ZStack {
                ChartGridView(plotRect: plotRect, rows: gridRows, cols: gridCols)
                    .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 1)

                areaPath
                    .trim(from: 0, to: animate ? 1 : 0)
                    .fill(LinearGradient(colors: [AppColors.accent.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))

                linePath
                    .trim(from: 0, to: animate ? 1 : 0)
                    .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

                if let selected = selectedPoint, let index = points.firstIndex(of: selected) {
                    let ratio = CGFloat(index) / CGFloat(max(points.count - 1, 1))
                    let x = plotRect.minX + plotRect.width * ratio
                    let yPosition = (selected.price - minPrice) / priceRange
                    let y = plotRect.maxY - (plotRect.height * CGFloat(yPosition))

                    Path { path in
                        path.move(to: CGPoint(x: x, y: plotRect.minY))
                        path.addLine(to: CGPoint(x: x, y: plotRect.maxY))
                    }
                    .stroke(AppColors.textSecondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    Path { path in
                        path.move(to: CGPoint(x: plotRect.minX, y: y))
                        path.addLine(to: CGPoint(x: plotRect.maxX, y: y))
                    }
                    .stroke(AppColors.textSecondary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    Circle()
                        .fill(AppColors.accent)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 2))
                        .position(x: x, y: y)

                    if showsPriceAxisLabel {
                        PriceAxisFloatingLabel(text: PriceFormatter.short(selected.price))
                            .position(x: plotRect.maxX + 30, y: min(max(plotRect.minY + 12, y), plotRect.maxY - 12))
                    }
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let clampedX = min(max(value.location.x, plotRect.minX), plotRect.maxX)
                        let index = indexForLocation(clampedX, plotRect: plotRect, count: points.count)
                        let nearest = points[index]
                        selectedPoint = nearest
                        if nearest.date != lastHapticDate {
                            lastHapticDate = nearest.date
                            HapticsManager.shared.selectionChanged(enabled: hapticsEnabled)
                        }
                    },
                including: allowsInternalSelection ? .all : .none
            )
            .gesture(
                TapGesture().onEnded { selectedPoint = nil },
                including: allowsInternalSelection ? .all : .none
            )
            .overlay {
                GeometryReader { _ in
                    ZStack(alignment: .topLeading) {
                        yAxisLabels(minValue: minPrice, maxValue: maxPrice, plotRect: plotRect)
                        xAxisLabels(plotRect: plotRect)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.1)) {
                    animate = true
                }
            }
        }
    }

    private func indexForLocation(_ x: CGFloat, plotRect: CGRect, count: Int) -> Int {
        guard count > 1 else { return 0 }
        let ratio = max(CGFloat(0), min(CGFloat(1), (x - plotRect.minX) / max(plotRect.width, CGFloat(1))))
        return min(count - 1, max(0, Int(round(ratio * CGFloat(count - 1)))))
    }

    private func yAxisLabels(minValue: Double, maxValue: Double, plotRect: CGRect) -> some View {
        let steps = 3
        let stepValue = (maxValue - minValue) / Double(steps)
        let items = (0...steps).map { index in
            AxisLabelItem(
                id: index,
                value: maxValue - stepValue * Double(index),
                position: plotRect.minY + plotRect.height * CGFloat(index) / CGFloat(steps)
            )
        }
        return ZStack {
            ForEach(items) { item in
                Text(PriceFormatter.compact(item.value))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: max(CGFloat(1), plotRect.minX - 16), alignment: .trailing)
                    .position(x: (max(CGFloat(1), plotRect.minX - 16) / 2) + 8, y: item.position)
            }
        }
    }

    private func xAxisLabels(plotRect: CGRect) -> some View {
        let indices: [Int] = [
            0,
            max(points.count / 3, 0),
            max((points.count * 2) / 3, 0),
            max(points.count - 1, 0)
        ]
        return ZStack {
            ForEach(indices, id: \.self) { index in
                if points.indices.contains(index) {
                    let ratio = CGFloat(index) / CGFloat(max(points.count - 1, 1))
                    let x = plotRect.minX + plotRect.width * ratio
                    let dateText = range.axisDateStyle.string(from: points[index].date)
                    Text(dateText)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 84)
                        .position(x: x, y: plotRect.maxY + 18)
                }
            }
        }
    }

    private func yBounds(for prices: [Double]) -> (min: Double, max: Double) {
        if let override = yDomainOverride {
            return (override.lowerBound, override.upperBound)
        }
        let minRaw = prices.min() ?? 0
        let maxRaw = prices.max() ?? 1
        if abs(maxRaw - minRaw) < 0.000_000_000_001 {
            let pad = max(abs(maxRaw) * 0.03, 0.000_000_000_001)
            return (minRaw - pad, maxRaw + pad)
        }
        let pad = max((maxRaw - minRaw) * 0.12, 0.000_000_000_001)
        return (minRaw - pad, maxRaw + pad)
    }

    private func smoothPath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 1 else {
            if let first = points.first { path.move(to: first) }
            return path
        }
        path.move(to: points[0])
        for index in 1..<points.count {
            let prev = points[index - 1]
            let current = points[index]
            let mid = CGPoint(x: (prev.x + current.x) / 2, y: (prev.y + current.y) / 2)
            path.addQuadCurve(to: mid, control: prev)
        }
        if let last = points.last {
            path.addLine(to: last)
        }
        return path
    }
}

struct ChartInsets {
    let left: CGFloat
    let right: CGFloat
    let top: CGFloat
    let bottom: CGFloat
}

struct ChartGridView: Shape {
    let plotRect: CGRect
    let rows: Int
    let cols: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rows = max(1, rows)
        let cols = max(1, cols)
        for i in 0...rows {
            let y = plotRect.minY + plotRect.height * CGFloat(i) / CGFloat(rows)
            path.move(to: CGPoint(x: plotRect.minX, y: y))
            path.addLine(to: CGPoint(x: plotRect.maxX, y: y))
        }
        for i in 0...cols {
            let x = plotRect.minX + plotRect.width * CGFloat(i) / CGFloat(cols)
            path.move(to: CGPoint(x: x, y: plotRect.minY))
            path.addLine(to: CGPoint(x: x, y: plotRect.maxY))
        }
        return path
    }
}

private struct AxisLabelItem: Identifiable {
    let id: Int
    let value: Double
    let position: CGFloat
}
