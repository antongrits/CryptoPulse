import SwiftUI

struct BannerView: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: systemImage)
            Text(title)
                .font(AppTypography.caption)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.sm)
        .background(AppColors.bannerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    BannerView(title: "Offline mode. Showing cached data.", systemImage: "wifi.slash")
        .padding()
}
