import Foundation
import WidgetKit
import SwiftUI

struct MarketWidgetEntry: TimelineEntry {
    let date: Date
    let coins: [WidgetCoin]
    let errorMessage: String?
}

struct WidgetCoin: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let price: Double
    let change24h: Double?
}

struct MarketProvider: TimelineProvider {
    func placeholder(in context: Context) -> MarketWidgetEntry {
        MarketWidgetEntry(
            date: Date(),
            coins: [
                WidgetCoin(id: "bitcoin", name: "Bitcoin", symbol: "BTC", price: 43812, change24h: 2.4),
                WidgetCoin(id: "ethereum", name: "Ethereum", symbol: "ETH", price: 2982, change24h: -1.1),
                WidgetCoin(id: "solana", name: "Solana", symbol: "SOL", price: 118, change24h: 3.9)
            ],
            errorMessage: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MarketWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MarketWidgetEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let refresh = Calendar.current.date(byAdding: .minute, value: 45, to: Date()) ?? Date().addingTimeInterval(2700)
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }

    private func fetchEntry() async -> MarketWidgetEntry {
        guard let apiKey = WidgetConfig.coinGeckoApiKey, !apiKey.isEmpty else {
            return MarketWidgetEntry(date: Date(), coins: [], errorMessage: "Missing API key")
        }

        var components = URLComponents(url: WidgetConfig.coinGeckoBaseURL.appendingPathComponent("/api/v3/coins/markets"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "vs_currency", value: "usd"),
            URLQueryItem(name: "order", value: "market_cap_desc"),
            URLQueryItem(name: "per_page", value: "6"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "price_change_percentage", value: "24h"),
            URLQueryItem(name: "sparkline", value: "false")
        ]
        if let auth = WidgetConfig.authQueryItem {
            components?.queryItems?.append(auth)
        }
        guard let url = components?.url else {
            return MarketWidgetEntry(date: Date(), coins: [], errorMessage: "Invalid URL")
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        WidgetConfig.headers(for: apiKey).forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let dtos = try JSONDecoder().decode([MarketCoinDTO].self, from: data)
            let coins = dtos.map {
                WidgetCoin(
                    id: $0.id,
                    name: $0.name,
                    symbol: $0.symbol.uppercased(),
                    price: $0.currentPrice,
                    change24h: $0.priceChangePercentage24h
                )
            }
            return MarketWidgetEntry(date: Date(), coins: coins, errorMessage: nil)
        } catch {
            return MarketWidgetEntry(date: Date(), coins: [], errorMessage: "Network error")
        }
    }
}

struct CryptoPulseMarketWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CryptoPulseMarketWidget", provider: MarketProvider()) { entry in
            MarketWidgetContainerView(entry: entry)
        }
        .configurationDisplayName("CryptoPulse Market")
        .description("Top coins snapshot.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct MarketWidgetContainerView: View {
    let entry: MarketWidgetEntry

    var body: some View {
        if #available(iOS 17.0, *) {
            MarketWidgetView(entry: entry)
                .padding(14)
                .containerBackground(for: .widget) {
                    MarketWidgetBackground()
                }
        } else {
            MarketWidgetView(entry: entry)
                .padding(14)
                .background(MarketWidgetBackground())
        }
    }
}

struct MarketWidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.58, blue: 0.78).opacity(0.45),
                Color(red: 0.08, green: 0.20, blue: 0.32).opacity(0.70)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct MarketWidgetView: View {
    let entry: MarketWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        if let error = entry.errorMessage {
            VStack(alignment: .leading, spacing: 6) {
                Text("CryptoPulse")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        } else if entry.coins.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("CryptoPulse")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        } else {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .systemLarge:
                largeView
            default:
                mediumView
            }
        }
    }

    private var smallView: some View {
        let coin = entry.coins.first
        return VStack(alignment: .leading, spacing: 6) {
            Text(coin?.symbol ?? "—")
                .font(.headline)
                .foregroundColor(.white)
            Text(PriceFormatterWidget.price(coin?.price))
                .font(.title3.bold())
                .foregroundColor(.white)
            Text(PriceFormatterWidget.change(coin?.change24h))
                .font(.caption)
                .foregroundColor(PriceFormatterWidget.changeColor(coin?.change24h))
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            ForEach(entry.coins.prefix(3)) { coin in
                HStack {
                    Text(coin.symbol)
                        .font(.caption)
                        .foregroundColor(.white)
                    Spacer()
                    Text(PriceFormatterWidget.price(coin.price))
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            ForEach(entry.coins.prefix(5)) { coin in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(coin.name)
                            .font(.caption)
                            .foregroundColor(.white)
                        Text(coin.symbol)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(PriceFormatterWidget.price(coin.price))
                            .font(.caption)
                            .foregroundColor(.white)
                        Text(PriceFormatterWidget.change(coin.change24h))
                            .font(.caption2)
                            .foregroundColor(PriceFormatterWidget.changeColor(coin.change24h))
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("CryptoPulse")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Text("Top")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

enum WidgetConfig {
    static var coinGeckoApiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "COINGECKO_API_KEY") as? String
    }

    static var coinGeckoBaseURL: URL {
        if let override = Bundle.main.object(forInfoDictionaryKey: "COINGECKO_API_BASE_URL") as? String,
           let url = URL(string: override) {
            return url
        }
        return URL(string: "https://api.coingecko.com")!
    }

    static func headers(for key: String) -> [String: String] {
        return ["x-cg-demo-api-key": key]
    }

    static var authQueryItem: URLQueryItem? {
        guard let key = coinGeckoApiKey, !key.isEmpty else { return nil }
        return URLQueryItem(name: "x_cg_demo_api_key", value: key)
    }
}

enum PriceFormatterWidget {
    static func price(_ value: Double?) -> String {
        guard let value else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = value < 1 ? 4 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    static func change(_ value: Double?) -> String {
        guard let value else { return "—" }
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", value))%"
    }

    static func changeColor(_ value: Double?) -> Color {
        guard let value else { return .white.opacity(0.7) }
        return value >= 0 ? Color.green : Color.red
    }
}

struct MarketCoinDTO: Decodable {
    let id: String
    let name: String
    let symbol: String
    let currentPrice: Double
    let priceChangePercentage24h: Double?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case symbol
        case currentPrice = "current_price"
        case priceChangePercentage24h = "price_change_percentage_24h"
    }
}
