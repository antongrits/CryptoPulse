import Foundation
import os

enum AppConfig {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CryptoPulse", category: "AppConfig")

    static var coinGeckoApiKey: String {
        let key = Bundle.main.object(forInfoDictionaryKey: "COINGECKO_API_KEY") as? String ?? ""
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            logger.error("Missing COINGECKO_API_KEY in Info.plist (set via build setting COINGECKO_API_KEY).")
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

    static var isConfigurationValid: Bool {
        !coinGeckoApiKey.isEmpty
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
