import SwiftUI

struct ChipView: View {
    let title: String
    var isSelected: Bool = false

    var body: some View {
        Text(title)
            .font(AppTypography.caption)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(isSelected ? AppColors.accent.opacity(0.2) : AppColors.cardBackground)
            .foregroundColor(isSelected ? AppColors.accent : AppColors.textSecondary)
            .clipShape(Capsule())
    }
}
