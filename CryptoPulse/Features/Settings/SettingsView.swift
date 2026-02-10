import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appEnv: AppEnvironment
    @Environment(\.dismiss) private var dismiss

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
                    HStack {
                        Text(NSLocalizedString("Version", comment: ""))
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                    Text(NSLocalizedString("Data Source: CoinGecko", comment: ""))
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
