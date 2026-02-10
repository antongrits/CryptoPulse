import SwiftUI

struct CardView<Content: View>: View {
    let content: () -> Content
    let padding: CGFloat

    init(padding: CGFloat = AppSpacing.md, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.padding = padding
    }

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.35)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColors.textSecondary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: AppColors.shadow, radius: 12, x: 0, y: 6)
    }
}

#Preview {
    CardView {
        VStack(alignment: .leading) {
            Text("Card Title")
                .font(AppTypography.headline)
            Text("Card content preview")
                .font(AppTypography.caption)
        }
    }
    .padding()
}
