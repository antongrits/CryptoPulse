import SwiftUI
import Combine

@MainActor
final class AppEnvironment: ObservableObject {
    enum Theme: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }

        var title: String {
            switch self {
            case .system: return NSLocalizedString("System", comment: "")
            case .light: return NSLocalizedString("Light", comment: "")
            case .dark: return NSLocalizedString("Dark", comment: "")
            }
        }
    }

    enum Language: String, CaseIterable, Identifiable {
        case system
        case english
        case russian
        case belarusian

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: return NSLocalizedString("System", comment: "")
            case .english: return NSLocalizedString("English", comment: "")
            case .russian: return NSLocalizedString("Russian", comment: "")
            case .belarusian: return NSLocalizedString("Belarusian", comment: "")
            }
        }

        var code: String? {
            switch self {
            case .system: return nil
            case .english: return "en"
            case .russian: return "ru"
            case .belarusian: return "be"
            }
        }

        var locale: Locale? {
            switch self {
            case .system: return nil
            case .english: return Locale(identifier: "en")
            case .russian: return Locale(identifier: "ru")
            case .belarusian: return Locale(identifier: "be")
            }
        }
    }

    @AppStorage("app_theme") private var storedTheme: String = Theme.system.rawValue
    @AppStorage("app_language") private var storedLanguage: String = Language.system.rawValue
    @AppStorage("haptics_enabled") var hapticsEnabled: Bool = true

    @Published var theme: Theme = .system {
        didSet { storedTheme = theme.rawValue }
    }
    @Published var language: Language = .system {
        didSet {
            storedLanguage = language.rawValue
            Localization.apply(languageCode: language.code)
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "app_theme") ?? Theme.system.rawValue
        theme = Theme(rawValue: raw) ?? .system
        let langRaw = UserDefaults.standard.string(forKey: "app_language") ?? Language.system.rawValue
        language = Language(rawValue: langRaw) ?? .system
        Localization.apply(languageCode: language.code)
    }

    var colorSchemeOverride: ColorScheme? { theme.colorScheme }
    var localeOverride: Locale? { language.locale }
}
