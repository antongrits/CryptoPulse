import Foundation
import os

enum AppConfig {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CryptoPulse", category: "AppConfig")
    private static let hardcodedCoinGeckoKey = "CG-KDgcsu7uLDg2W472kx28Hcen"

    static var coinGeckoApiKey: String {
        let trimmed = hardcodedCoinGeckoKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            logger.error("Empty hardcoded CoinGecko API key.")
        }
        return trimmed
    }

    static var coinGeckoBaseURL: URL {
        if let override = Bundle.main.object(forInfoDictionaryKey: "COINGECKO_API_BASE_URL") as? String,
           let url = URL(string: override) {
            return url
        }
        return URL(string: "https://api.coingecko.com")!
    }

    static var coinGeckoFallbackBaseURL: URL? {
        if let override = Bundle.main.object(forInfoDictionaryKey: "COINGECKO_FALLBACK_BASE_URL") as? String,
           let url = URL(string: override) {
            return url
        }
        return nil
    }

    static var coinGeckoHeaders: [String: String] {
        let key = coinGeckoApiKey
        guard !key.isEmpty else { return [:] }
        return ["x-cg-demo-api-key": key]
    }

    static var coinGeckoAuthQueryItem: URLQueryItem? {
        let key = coinGeckoApiKey
        guard !key.isEmpty else { return nil }
        return URLQueryItem(name: "x_cg_demo_api_key", value: key)
    }

    // CoinGecko demo keys have historical range limits for some chart queries.
    // Keep this configurable in case plan/limits change.
    static var supportsExtendedChartHistory: Bool {
        if let value = Bundle.main.object(forInfoDictionaryKey: "COINGECKO_SUPPORTS_EXTENDED_HISTORY") as? Bool {
            return value
        }
        return false
    }
}
