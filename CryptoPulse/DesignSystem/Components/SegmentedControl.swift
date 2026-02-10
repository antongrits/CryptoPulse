import SwiftUI

struct SegmentedControl<Option: Identifiable & Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options) { option in
                let isSelected = option.id == selection.id
                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .font(AppTypography.caption)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? AppColors.accent.opacity(0.2) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.textSecondary.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    SegmentedControl(options: MarketSection.allCases, selection: .constant(.all)) { $0.title }
        .padding()
        .environmentObject(AppEnvironment())
}
