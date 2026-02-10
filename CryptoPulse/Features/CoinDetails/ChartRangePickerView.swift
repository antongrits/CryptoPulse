import SwiftUI

struct ChartRangePicker: View {
    @Binding var selectedRange: ChartRange
    let ranges: [ChartRange]
    let onSelect: (ChartRange) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(ranges) { range in
                    Button {
                        onSelect(range)
                    } label: {
                        Text(range.title)
                            .font(AppTypography.caption)
                            .foregroundColor(range == selectedRange ? .white : AppColors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(range == selectedRange ? AppColors.accent : AppColors.cardBackground)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    ChartRangePicker(selectedRange: .constant(.sevenDays), ranges: ChartRange.allCases, onSelect: { _ in })
        .padding()
}
