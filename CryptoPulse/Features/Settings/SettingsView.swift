import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appEnv: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let privacyPolicyURL = URL(string: "https://example.com/privacy-policy")!

    var body: some View {
        NavigationView {
            Form {
                Section(NSLocalizedString("Appearance", comment: "")) {
                    Picker(NSLocalizedString("Theme", comment: ""), selection: $appEnv.theme) {
                        ForEach(AppEnvironment.Theme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(NSLocalizedString("Language", comment: "")) {
                    Picker(NSLocalizedString("Language", comment: ""), selection: $appEnv.language) {
                        ForEach(AppEnvironment.Language.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section(NSLocalizedString("Feedback", comment: "")) {
                    Toggle(NSLocalizedString("Haptics", comment: ""), isOn: $appEnv.hapticsEnabled)
                }

                Section(NSLocalizedString("About", comment: "")) {
                    CardView(padding: AppSpacing.md) {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            HStack {
                                Text(NSLocalizedString("Version", comment: ""))
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Text(appVersion)
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text(NSLocalizedString("Data Source: CoinGecko", comment: ""))
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textPrimary)
                                Text(NSLocalizedString("Powered by CoinGecko", comment: ""))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(NSLocalizedString("Data by Coinparika.com", comment: ""))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(NSLocalizedString("All names and logos are trademarks of their respective owners. This app is not affiliated with them.", comment: ""))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Button {
                                openURL(privacyPolicyURL)
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    Text(NSLocalizedString("Privacy Policy", comment: ""))
                                        .font(AppTypography.body.weight(.semibold))
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm + 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(AppColors.accent.opacity(0.14))
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("privacy_policy_button")
                        }
                    }
                    .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(NSLocalizedString("Settings", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "")) { dismiss() }
                }
            }
        }
        .preferredColorScheme(appEnv.colorSchemeOverride)
        .id("settings_theme_\(appEnv.theme.rawValue)")
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppEnvironment())
}
