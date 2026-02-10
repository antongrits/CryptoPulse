import SwiftUI

struct AllocationSlice: Identifiable {
    let id: String
    let name: String
    let value: Double
    let color: Color
    let percent: Double
}

struct PortfolioAllocationView: View {
    let slices: [AllocationSlice]
    @State private var selectedSliceId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(NSLocalizedString("Allocation", comment: ""))
                .font(AppTypography.headline)

            DonutChartView(
                slices: slices,
                selectedSliceId: selectedSliceId,
                lineWidth: 22
            )
            .frame(maxWidth: .infinity, minHeight: 190, maxHeight: 210)

            if let selected = selectedSlice {
                HStack {
                        Text(selected.name)
                            .font(AppTypography.headline)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    Text(PriceFormatter.short(selected.value))
                        .font(AppTypography.headline)
                    Text(PercentFormatter.shortPercent(selected.percent))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 2)
            }

            legend
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if selectedSliceId == nil {
                selectedSliceId = slices.first?.id
            }
        }
    }

    private var selectedSlice: AllocationSlice? {
        if let selectedSliceId, let found = slices.first(where: { $0.id == selectedSliceId }) {
            return found
        }
        return slices.first
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(slices.prefix(8)) { slice in
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
                .padding(.vertical, 2)
                .overlay(alignment: .leading) {
                    if selectedSliceId == slice.id {
                        Rectangle()
                            .fill(AppColors.accent.opacity(0.5))
                            .frame(width: 2, height: 16)
                            .offset(x: -6)
                    }
                }
            }
        }
    }
}

struct DonutChartView: View {
    let slices: [AllocationSlice]
    let selectedSliceId: String?
    let lineWidth: CGFloat

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .stroke(AppColors.cardBackground, lineWidth: lineWidth)
                    .frame(width: size, height: size)

                ForEach(Array(slices.enumerated()), id: \.1.id) { index, slice in
                    Circle()
                        .trim(from: startAngle(for: index), to: endAngle(for: index))
                        .stroke(
                            slice.color,
                            style: StrokeStyle(
                                lineWidth: selectedSliceId == slice.id ? lineWidth + 4 : lineWidth,
                                lineCap: .butt
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: size, height: size)
                        .opacity(selectedSliceId == nil || selectedSliceId == slice.id ? 1.0 : 0.5)
                        .animation(.easeInOut(duration: 0.2), value: selectedSliceId)
                }

                VStack(spacing: 4) {
                    if let selected = selectedSlice {
                        Text(selected.name)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Text(PercentFormatter.shortPercent(selected.percent))
                            .font(AppTypography.headline)
                    }
                }
                .frame(maxWidth: size * 0.62)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var selectedSlice: AllocationSlice? {
        if let selectedSliceId, let found = slices.first(where: { $0.id == selectedSliceId }) {
            return found
        }
        return slices.first
    }

    private func startAngle(for index: Int) -> CGFloat {
        let total = slices.map(\.value).reduce(0, +)
        guard total > 0 else { return 0 }
        let sum = slices.prefix(index).map(\.value).reduce(0, +)
        return CGFloat(sum / total)
    }

    private func endAngle(for index: Int) -> CGFloat {
        let total = slices.map(\.value).reduce(0, +)
        guard total > 0 else { return 0 }
        let sum = slices.prefix(index + 1).map(\.value).reduce(0, +)
        return CGFloat(sum / total)
    }
}

#Preview {
    PortfolioAllocationView(slices: [
        AllocationSlice(id: "btc", name: "BTC", value: 5000, color: .blue, percent: 55),
        AllocationSlice(id: "eth", name: "ETH", value: 2500, color: .green, percent: 28),
        AllocationSlice(id: "sol", name: "SOL", value: 1500, color: .orange, percent: 17)
    ])
    .padding()
}
