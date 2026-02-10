import SwiftUI
import UIKit

extension Double {
    var isPositive: Bool { self >= 0 }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: AppColors.shadow, radius: 12, x: 0, y: 6)
    }
}

extension Image {
    init(assetOrSystemName name: String, fallbackSystemName: String) {
        if UIImage(named: name) != nil {
            self.init(name)
        } else {
            self.init(systemName: fallbackSystemName)
        }
    }
}

extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
