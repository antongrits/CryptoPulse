import SwiftUI

struct MarketRowView: View {
    let coin: CoinMarket

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Group {
                if let url = coin.imageURL {
                    CachedAsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Image(systemName: "bitcoinsign.circle")
                            .resizable().scaledToFit()
                            .foregroundColor(AppColors.textSecondary)
                    }
                } else {
                    Image(systemName: "bitcoinsign.circle")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(coin.name)
                    .font(AppTypography.headline)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(coin.symbol)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if #available(iOS 16.0, *) {
                    Text(PriceFormatter.string(coin.currentPrice))
                        .font(AppTypography.headline)
                        .contentTransition(.numericText())
                } else {
                    Text(PriceFormatter.string(coin.currentPrice))
                        .font(AppTypography.headline)
                }
                HStack(spacing: 4) {
                    Image(systemName: coin.priceChangePercentage24h.isPositive ? "arrow.up" : "arrow.down")
                    Text(PercentFormatter.string(coin.priceChangePercentage24h))
                }
                .font(AppTypography.caption)
                .foregroundColor(coin.priceChangePercentage24h.isPositive ? AppColors.positive : AppColors.negative)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let priceLabel = NSLocalizedString("Price", comment: "")
        let changeLabel = NSLocalizedString("24h Change", comment: "")
        return "\(coin.name) \(priceLabel) \(PriceFormatter.string(coin.currentPrice)), \(changeLabel) \(PercentFormatter.string(coin.priceChangePercentage24h))"
    }
}

struct MarketCompactRowView: View {
    let coin: CoinMarket

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Group {
                if let url = coin.imageURL {
                    CachedAsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Image(systemName: "bitcoinsign.circle")
                            .resizable().scaledToFit()
                            .foregroundColor(AppColors.textSecondary)
                    }
                } else {
                    Image(systemName: "bitcoinsign.circle")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(coin.name)
                    .font(AppTypography.body)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(coin.symbol)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if #available(iOS 16.0, *) {
                    Text(PriceFormatter.short(coin.currentPrice))
                        .font(AppTypography.body)
                        .contentTransition(.numericText())
                } else {
                    Text(PriceFormatter.short(coin.currentPrice))
                        .font(AppTypography.body)
                }
                Text(PercentFormatter.string(coin.priceChangePercentage24h))
                    .font(AppTypography.caption)
                    .foregroundColor(coin.priceChangePercentage24h.isPositive ? AppColors.positive : AppColors.negative)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let priceLabel = NSLocalizedString("Price", comment: "")
        let changeLabel = NSLocalizedString("24h Change", comment: "")
        return "\(coin.name) \(priceLabel) \(PriceFormatter.string(coin.currentPrice)), \(changeLabel) \(PercentFormatter.string(coin.priceChangePercentage24h))"
    }
}
