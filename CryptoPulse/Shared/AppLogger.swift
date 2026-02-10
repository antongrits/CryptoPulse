import Foundation
import os

enum AppLogger {
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CryptoPulse", category: "Network")
    static let realm = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CryptoPulse", category: "Realm")
    static let alerts = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CryptoPulse", category: "Alerts")
}
