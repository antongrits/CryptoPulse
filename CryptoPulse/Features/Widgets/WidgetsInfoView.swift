import SwiftUI

struct WidgetsInfoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                header
                previewCard
                howToAdd
                tips
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle(NSLocalizedString("Widgets", comment: ""))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(NSLocalizedString("Home Screen Widgets", comment: ""))
                .font(AppTypography.title)
            Text(NSLocalizedString("Get quick market snapshots without opening the app.", comment: ""))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("BTC")
                    .font(AppTypography.headline)
                Spacer()
                Text("$43,812")
                    .font(AppTypography.headline)
            }
            Text("+2.4% 24h")
                .font(AppTypography.caption)
                .foregroundColor(.green)
            Divider()
            HStack {
                Text("ETH")
                    .font(AppTypography.caption)
                Spacer()
                Text("$2,982")
                    .font(AppTypography.caption)
            }
            HStack {
                Text("SOL")
                    .font(AppTypography.caption)
                Spacer()
                Text("$118")
                    .font(AppTypography.caption)
            }
        }
        .padding(AppSpacing.md)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.58, blue: 0.78).opacity(0.45),
                    Color(red: 0.08, green: 0.20, blue: 0.32).opacity(0.65)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .foregroundColor(.white)
    }

    private var howToAdd: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(NSLocalizedString("How to add a widget", comment: ""))
                .font(AppTypography.headline)
            VStack(alignment: .leading, spacing: 6) {
                Text("1. \(NSLocalizedString("Long‑press the Home Screen", comment: ""))")
                Text("2. \(NSLocalizedString("Tap the + button", comment: ""))")
                Text("3. \(NSLocalizedString("Search for CryptoPulse", comment: ""))")
                Text("4. \(NSLocalizedString("Choose size and tap Add Widget", comment: ""))")
            }
            .font(AppTypography.body)
            .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var tips: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(NSLocalizedString("Tips", comment: ""))
                .font(AppTypography.headline)
            Text(NSLocalizedString("Widgets refresh automatically. Pull‑to‑refresh in Market to nudge a faster update.", comment: ""))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    WidgetsInfoView()
}
