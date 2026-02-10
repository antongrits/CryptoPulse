import Foundation

enum PriceFormatter {
    static let usd: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    static let usdShort: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f
    }()

    static func string(_ value: Double?) -> String {
        guard let value else { return "—" }
        return usd.string(from: NSNumber(value: value)) ?? "—"
    }

    static func short(_ value: Double?) -> String {
        guard let value else { return "—" }
        return usdShort.string(from: NSNumber(value: value)) ?? "—"
    }

    static func compact(_ value: Double?, includeCurrencySymbol: Bool = true) -> String {
        guard let value else { return "—" }
        let absValue = abs(value)
        if absValue < 1_000 {
            return includeCurrencySymbol ? short(value) : NumberParsing.string(from: value, maximumFractionDigits: 2)
        }
        let (divisor, suffix): (Double, String) = {
            switch absValue {
            case 1_000_000_000_000...:
                return (1_000_000_000_000, "T")
            case 1_000_000_000...:
                return (1_000_000_000, "B")
            case 1_000_000...:
                return (1_000_000, "M")
            default:
                return (1_000, "K")
            }
        }()
        let formatted = NumberParsing.string(from: absValue / divisor, maximumFractionDigits: 2)
        // App prices are always in USD, keep symbol stable across selected locale.
        let symbol = includeCurrencySymbol ? "$" : ""
        let sign = value < 0 ? "-" : ""
        return "\(sign)\(symbol)\(formatted)\(suffix)"
    }
}

enum PercentFormatter {
    static let percent: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        f.multiplier = 1
        return f
    }()

    static func string(_ value: Double?) -> String {
        guard let value else { return "—" }
        let formatted = percent.string(from: NSNumber(value: value)) ?? "—"
        return value > 0 ? "+\(formatted)" : formatted
    }

    static func shortPercent(_ value: Double?, tinyThreshold: Double = 0.05) -> String {
        guard let value else { return "—" }
        let absolute = abs(value)
        if absolute > 0, absolute < tinyThreshold {
            return value < 0 ? "-<0.1%" : "<0.1%"
        }
        return String(format: "%.1f%%", value)
    }
}

enum NumberParsing {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = .current
        f.maximumFractionDigits = 12
        return f
    }()

    static func double(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let separator = formatter.decimalSeparator ?? "."
        var normalized = trimmed
        if separator != "." {
            normalized = normalized.replacingOccurrences(of: ".", with: separator)
        }
        if separator != "," {
            normalized = normalized.replacingOccurrences(of: ",", with: separator)
        }
        if normalized.hasPrefix(separator) {
            normalized = "0" + normalized
        } else if normalized.hasPrefix("-" + separator) {
            normalized = normalized.replacingOccurrences(of: "-" + separator, with: "-0" + separator)
        }
        if let number = formatter.number(from: normalized) {
            return number.doubleValue
        }
        let fallback = normalized.replacingOccurrences(of: separator, with: ".")
        return Double(fallback)
    }

    static func string(from value: Double, maximumFractionDigits: Int = 6) -> String {
        let f = formatter.copy() as? NumberFormatter ?? formatter
        f.maximumFractionDigits = maximumFractionDigits
        return f.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func sanitizeDecimalInput(_ text: String, allowsNegative: Bool = false) -> String {
        let separator = formatter.decimalSeparator ?? "."
        let separatorChar = separator.first ?? "."
        var result = ""
        var hasSeparator = false
        var hasSign = false
        for ch in text {
            if ch.isNumber {
                result.append(ch)
                continue
            }
            if allowsNegative, ch == "-", !hasSign, result.isEmpty {
                result.append(ch)
                hasSign = true
                continue
            }
            if ch == "." || ch == "," || ch == separatorChar {
                if !hasSeparator {
                    result.append(separatorChar)
                    hasSeparator = true
                }
            }
        }
        if result == String(separatorChar) {
            result = "0" + result
        } else if result == "-" + String(separatorChar) {
            result = "-0" + String(separatorChar)
        }
        return result
    }
}
