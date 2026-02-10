import SwiftUI

struct PrimaryButton: View {
    private let title: Text
    var systemImage: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    init(_ title: LocalizedStringKey, systemImage: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = Text(title)
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.action = action
    }

    init(title: String, systemImage: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = Text(verbatim: title)
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                title
                    .font(AppTypography.headline)
            }
            .foregroundColor(.white)
            .padding(.vertical, AppSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(AppColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

#Preview {
    PrimaryButton("Continue", systemImage: "arrow.right") {}
        .padding()
}
