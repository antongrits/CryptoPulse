import Foundation
import RealmSwift

private let iso8601WithFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let iso8601Default: ISO8601DateFormatter = {
    ISO8601DateFormatter()
}()

private func parseISO8601Date(_ value: String?) -> Date? {
    guard let value, !value.isEmpty else { return nil }
    return iso8601WithFractional.date(from: value) ?? iso8601Default.date(from: value)
}

extension MarketDTO {
    func toDomain() -> CoinMarket {
        CoinMarket(
            id: id,
            name: name,
            symbol: symbol.uppercased(),
            imageURL: image.flatMap(URL.init(string:)),
            currentPrice: currentPrice,
            priceChangePercentage24h: priceChangePercentage24h ?? 0,
            marketCap: marketCap,
            totalVolume: totalVolume,
            high24h: high24h,
            low24h: low24h,
            lastUpdated: parseISO8601Date(lastUpdated)
        )
    }
}

extension CoinDetailsDTO {
    func toDomain() -> CoinDetails {
        CoinDetails(
            id: id,
            name: name,
            symbol: symbol.uppercased(),
            description: description.en ?? "",
            imageURL: image.large.flatMap(URL.init(string:)),
            currentPrice: marketData.currentPrice.usd ?? 0,
            priceChangePercentage24h: marketData.priceChangePercentage24h ?? 0,
            marketCap: marketData.marketCap.usd,
            totalVolume: marketData.totalVolume.usd,
            high24h: marketData.high24h.usd,
            low24h: marketData.low24h.usd,
            circulatingSupply: marketData.circulatingSupply,
            lastUpdated: parseISO8601Date(lastUpdated)
        )
    }
}

extension MarketChartDTO {
    func toDomain() -> [PricePoint] {
        let caps = marketCaps ?? []
        let volumes = totalVolumes ?? []
        return prices.enumerated().compactMap { index, pair in
            guard pair.count >= 2 else { return nil }
            let timestamp = pair[0] / 1000
            let price = pair[1]
            let cap = index < caps.count && caps[index].count >= 2 ? caps[index][1] : nil
            let volume = index < volumes.count && volumes[index].count >= 2 ? volumes[index][1] : nil
            return PricePoint(date: Date(timeIntervalSince1970: timestamp), price: price, marketCap: cap, volume: volume)
        }
    }
}

extension TrendingResponseDTO {
    func toDomain() -> [TrendingCoin] {
        coins.map { item in
            TrendingCoin(
                id: item.item.id,
                name: item.item.name,
                symbol: item.item.symbol.uppercased(),
                imageURL: item.item.small.flatMap(URL.init(string:)),
                marketCapRank: item.item.marketCapRank,
                priceBTC: item.item.priceBTC
            )
        }
    }
}

extension GlobalDTO {
    func toDomain() -> GlobalMarket {
        GlobalMarket(
            totalMarketCapUSD: data.totalMarketCap?["usd"],
            totalVolumeUSD: data.totalVolume?["usd"],
            marketCapChangePercentage24h: data.marketCapChangePercentage24hUsd,
            btcDominance: data.marketCapPercentage?["btc"],
            ethDominance: data.marketCapPercentage?["eth"],
            activeCryptocurrencies: data.activeCryptocurrencies,
            markets: data.markets,
            updatedAt: data.updatedAt.map { Date(timeIntervalSince1970: $0) }
        )
    }
}

extension MarketCategoryDTO {
    func toDomain() -> MarketCategory {
        MarketCategory(id: categoryId, name: name)
    }
}

extension MarketCategoryStatsDTO {
    func toDomain() -> MarketCategoryStats {
        MarketCategoryStats(
            id: id,
            name: name,
            marketCap: marketCap,
            marketCapChange24h: marketCapChange24h,
            volume24h: volume24h,
            top3CoinImageURLs: (top3Coins ?? []).compactMap(URL.init(string:)),
            updatedAt: parseISO8601Date(updatedAt)
        )
    }
}

extension ExchangeDTO {
    func toDomain() -> Exchange {
        Exchange(
            id: id,
            name: name,
            imageURL: image.flatMap(URL.init(string:)),
            country: country,
            yearEstablished: yearEstablished,
            trustScoreRank: trustScoreRank,
            tradeVolume24hBtc: tradeVolume24hBtc,
            url: url.flatMap(URL.init(string:))
        )
    }
}

extension RMCachedMarket {
    func toDomain() -> CoinMarket {
        CoinMarket(
            id: coinId,
            name: name,
            symbol: symbol,
            imageURL: imageURL.flatMap(URL.init(string:)),
            currentPrice: currentPrice,
            priceChangePercentage24h: priceChangePercentage24h,
            marketCap: marketCap,
            totalVolume: totalVolume,
            high24h: high24h,
            low24h: low24h,
            lastUpdated: lastUpdated
        )
    }

    func update(from domain: CoinMarket, updatedAt: Date) {
        name = domain.name
        symbol = domain.symbol
        imageURL = domain.imageURL?.absoluteString
        currentPrice = domain.currentPrice
        priceChangePercentage24h = domain.priceChangePercentage24h
        marketCap = domain.marketCap
        totalVolume = domain.totalVolume
        high24h = domain.high24h
        low24h = domain.low24h
        lastUpdated = domain.lastUpdated
        self.updatedAt = updatedAt
    }
}

extension RMCachedCoinDetails {
    func toDomain() -> CoinDetails {
        CoinDetails(
            id: coinId,
            name: name,
            symbol: symbol,
            description: descriptionText,
            imageURL: imageURL.flatMap(URL.init(string:)),
            currentPrice: currentPrice,
            priceChangePercentage24h: priceChangePercentage24h,
            marketCap: marketCap,
            totalVolume: totalVolume,
            high24h: high24h,
            low24h: low24h,
            circulatingSupply: circulatingSupply,
            lastUpdated: lastUpdated
        )
    }

    func update(from domain: CoinDetails, updatedAt: Date) {
        name = domain.name
        symbol = domain.symbol
        descriptionText = domain.description
        imageURL = domain.imageURL?.absoluteString
        currentPrice = domain.currentPrice
        priceChangePercentage24h = domain.priceChangePercentage24h
        marketCap = domain.marketCap
        totalVolume = domain.totalVolume
        high24h = domain.high24h
        low24h = domain.low24h
        circulatingSupply = domain.circulatingSupply
        lastUpdated = domain.lastUpdated
        self.updatedAt = updatedAt
    }
}

extension RMCachedChart {
    func toDomain() -> [PricePoint] {
        points.map { point in
            PricePoint(
                date: Date(timeIntervalSince1970: point.timestamp),
                price: point.price,
                marketCap: point.marketCap,
                volume: point.volume
            )
        }
    }

    func update(points newPoints: [PricePoint], updatedAt: Date) {
        points.removeAll()
        let list = newPoints.map { point in
            let rm = RMPricePoint()
            rm.timestamp = point.date.timeIntervalSince1970
            rm.price = point.price
            rm.marketCap = point.marketCap
            rm.volume = point.volume
            return rm
        }
        points.append(objectsIn: list)
        self.updatedAt = updatedAt
    }
}

extension RMFavorite {
    func toDomain() -> CoinMarket {
        CoinMarket(
            id: coinId,
            name: name,
            symbol: symbol,
            imageURL: imageURL.flatMap(URL.init(string:)),
            currentPrice: 0,
            priceChangePercentage24h: 0,
            marketCap: nil,
            totalVolume: nil,
            high24h: nil,
            low24h: nil,
            lastUpdated: nil
        )
    }
}

extension RMHolding {
    func toDomain() -> Holding {
        Holding(
            id: id,
            coinId: coinId,
            symbol: symbol,
            name: name,
            amount: amount,
            avgBuyPrice: avgBuyPrice,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension RMPriceAlert {
    func toDomain() -> PriceAlert {
        PriceAlert(
            id: id,
            coinId: coinId,
            symbol: symbol,
            name: name,
            targetValue: targetPrice,
            metric: PriceAlertMetric(rawValue: metricRaw) ?? .price,
            direction: PriceAlertDirection(rawValue: directionRaw) ?? .above,
            repeatMode: PriceAlertRepeatMode(rawValue: repeatModeRaw) ?? .onceUntilReset,
            cooldownMinutes: cooldownMinutes,
            isEnabled: isEnabled,
            isArmed: isArmed,
            createdAt: createdAt,
            lastTriggeredAt: lastTriggeredAt
        )
    }
}

extension RMRecentSearch {
    func toDomain() -> RecentSearch {
        RecentSearch(id: id, query: query, createdAt: createdAt)
    }
}

extension RMCoinNote {
    func toDomain() -> CoinNote {
        CoinNote(
            id: coinId,
            coinId: coinId,
            coinName: coinId,
            coinSymbol: coinId.uppercased(),
            text: text,
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
    }
}

extension RMCoinNoteEntry {
    func toDomain() -> CoinNote {
        CoinNote(
            id: noteId,
            coinId: coinId,
            coinName: coinName,
            coinSymbol: coinSymbol,
            text: text,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension RMConversionRecord {
    func toDomain() -> ConversionRecord {
        ConversionRecord(
            id: id,
            coinId: coinId,
            symbol: symbol,
            name: name,
            usdAmount: usdAmount,
            coinAmount: coinAmount,
            createdAt: createdAt
        )
    }
}
