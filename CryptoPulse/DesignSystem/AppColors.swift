import SwiftUI
import UIKit

enum AppColors {
    static let background = Color(UIColor.systemBackground)
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let accent = Color.accentColor
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let positive = Color.green
    static let negative = Color.red
    static let shadow = Color.black.opacity(0.08)
    static let bannerBackground = Color.orange.opacity(0.15)
    static let chartPalette: [Color] = [
        Color(hex: "3B82F6"),
        Color(hex: "22C55E"),
        Color(hex: "F97316"),
        Color(hex: "A855F7"),
        Color(hex: "F59E0B"),
        Color(hex: "14B8A6")
    ]
}

extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.count == 6 { hex.append("FF") }
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a = Double(int & 0xFF) / 255.0
        let r = Double((int >> 24) & 0xFF) / 255.0
        let g = Double((int >> 16) & 0xFF) / 255.0
        let b = Double((int >> 8) & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
