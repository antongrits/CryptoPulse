import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let assetName: String
    let systemImageFallback: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(assetOrSystemName: assetName, fallbackSystemName: systemImageFallback)
                .resizable()
                .scaledToFit()
                .frame(height: 180)
                .foregroundColor(AppColors.textSecondary)

            Text(title)
                .font(AppTypography.title)
                .multilineTextAlignment(.center)
            Text(message)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, systemImage: "arrow.right", action: action)
                    .padding(.top, AppSpacing.sm)
            }
        }
        .padding(AppSpacing.lg)
    }
}

#Preview {
    EmptyStateView(
        title: "No Results",
        message: "Try another search query.",
        assetName: "EmptySearch",
        systemImageFallback: "magnifyingglass",
        actionTitle: "Retry",
        action: {}
    )
    .padding()
}
