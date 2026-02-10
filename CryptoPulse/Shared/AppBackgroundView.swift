import SwiftUI
import UIKit

struct AppBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let imageName = preferredGradientName {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        } else {
            LinearGradient(
                colors: [AppColors.background, AppColors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var preferredGradientName: String? {
        let lightCandidates = ["Gradient1", "gradient1"]
        let darkCandidates = ["Gradient2", "gradient2"]
        let fallback = colorScheme == .dark ? lightCandidates : darkCandidates
        let primary = colorScheme == .dark ? darkCandidates : lightCandidates
        for name in primary where UIImage(named: name) != nil { return name }
        for name in fallback where UIImage(named: name) != nil { return name }
        return nil
    }
}
