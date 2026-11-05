//
//  L10n.swift
//  Memory Match Kids
//
//  In-app translations. The tables live in localization/l10n/<lang>.json at
//  the repo root and are shared verbatim with the Android app, so both
//  platforms always show the same words. Each table is keyed by the English
//  text; placeholders are written {0}, {1}… and filled positionally.
//

import Foundation

enum L10n {
    /// Language codes with a table in localization/l10n. English is the key
    /// language, so it only needs a table for disambiguated keys.
    static let supported = ["en", "hi", "es", "pt", "id", "de", "fr"]

    /// Resolved once per launch. iOS restarts the app when the user changes
    /// its language, so there is nothing to invalidate.
    static let language: String = {
        // preferredLocalizations honours the per-app language picker in
        // Settings; it only lists languages the bundle has an .lproj for.
        let preferred = Bundle.main.preferredLocalizations.first ?? "en"
        let code = String(preferred.prefix { $0 != "-" && $0 != "_" })
        return supported.contains(code) ? code : "en"
    }()

    /// Each language's name in itself, for the Settings row.
    static let nativeNames = [
        "en": "English", "hi": "हिन्दी", "es": "Español", "pt": "Português",
        "id": "Bahasa Indonesia", "de": "Deutsch", "fr": "Français"
    ]

    private static let table: [String: String] = {
        guard let url = Bundle.main.url(forResource: language, withExtension: "json", subdirectory: "l10n"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return dict
    }()

    static func string(_ key: String, _ args: [Any]) -> String {
        var out = table[key] ?? key
        for (index, arg) in args.enumerated() {
            out = out.replacingOccurrences(of: "{\(index)}", with: "\(arg)")
        }
        return out
    }
}

/// Translates `key` (the English text) into the app language.
func tr(_ key: String, _ args: Any...) -> String {
    L10n.string(key, args)
}
