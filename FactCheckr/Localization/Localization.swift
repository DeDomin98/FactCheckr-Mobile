import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case pl
    case en

    var id: String { rawValue }

    /// Shown in the language picker (native names).
    var displayName: String {
        switch self {
        case .system: return Loc.t(.languageSystem)
        case .pl: return "Polski"
        case .en: return "English"
        }
    }
}

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private let storageKey = "fc_app_language"
    private let appGroupCodeKey = "fc_app_lang_code"

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: storageKey)
            Loc.currentCode = code
            syncToAppGroup()
            NotificationService.refreshAuthorization()
        }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: storageKey)
        language = AppLanguage(rawValue: raw ?? "") ?? .system
        Loc.currentCode = code
        syncToAppGroup()
        NotificationService.refreshAuthorization()
    }

    /// Resolved two-letter code ("pl" / "en").
    var code: String {
        Loc.resolveCode(for: language)
    }

    private func syncToAppGroup() {
        UserDefaults(suiteName: AppGroupConfig.identifier)?.set(code, forKey: appGroupCodeKey)
    }
}

/// Lightweight, synchronous string lookup used across the app. The root view forces
/// a re-render when the language changes via `.id(...)`, so reading a cached code is
/// enough and keeps call sites simple and main-actor-agnostic.
enum Loc {
    static var currentCode: String = {
        let raw = UserDefaults.standard.string(forKey: "fc_app_language") ?? ""
        return resolveCode(for: AppLanguage(rawValue: raw) ?? .system)
    }()

    static func resolveCode(for language: AppLanguage) -> String {
        switch language {
        case .pl: return "pl"
        case .en: return "en"
        case .system:
            let preferred = Locale.preferredLanguages.first ?? "en"
            return preferred.lowercased().hasPrefix("pl") ? "pl" : "en"
        }
    }

    static var code: String { currentCode }

    static func t(_ key: LocKey) -> String {
        currentCode == "pl" ? key.values.pl : key.values.en
    }
}
