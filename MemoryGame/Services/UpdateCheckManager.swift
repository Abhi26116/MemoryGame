//
//  UpdateCheckManager.swift
//  Memory Match Kids
//
//  Optional, best-effort check against Apple's public (keyless) App Store
//  lookup API to see if a newer version is live. Not a backend of ours — just
//  a read-only call to `itunes.apple.com`. Fails silently on any error (no
//  internet, app not yet published, malformed response) so the app stays
//  fully usable offline; this is a courtesy nudge, never a blocker.
//

import Foundation

enum UpdateCheckManager {
    struct AvailableUpdate {
        let version: String
        let storeURL: URL
    }

    private static let lastCheckDateKey = "updateCheckLastDate"
    private static let minHoursBetweenChecks = 20

    /// Returns details of a newer App Store version, or nil if there isn't one,
    /// we checked too recently, or the lookup failed for any reason.
    static func checkForUpdate(bundleID: String) async -> AvailableUpdate? {
        guard shouldCheck() else { return nil }
        markChecked()
        guard !bundleID.isEmpty,
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let root = try? JSONDecoder().decode(LookupResponse.self, from: data),
              let result = root.results.first,
              let storeURL = URL(string: result.trackViewUrl) else {
            return nil
        }

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        guard isVersion(result.version, newerThan: currentVersion) else { return nil }

        return AvailableUpdate(version: result.version, storeURL: storeURL)
    }

    private static func shouldCheck() -> Bool {
        guard let last = UserDefaults.standard.object(forKey: lastCheckDateKey) as? Date else { return true }
        let hours = Calendar.current.dateComponents([.hour], from: last, to: Date()).hour ?? 0
        return hours >= minHoursBetweenChecks
    }

    private static func markChecked() {
        UserDefaults.standard.set(Date(), forKey: lastCheckDateKey)
    }

    /// Component-wise numeric comparison ("1.10" > "1.9"), not a string compare.
    private static func isVersion(_ a: String, newerThan b: String) -> Bool {
        let aParts = a.split(separator: ".").map { Int($0) ?? 0 }
        let bParts = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(aParts.count, bParts.count) {
            let x = i < aParts.count ? aParts[i] : 0
            let y = i < bParts.count ? bParts[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    private struct LookupResponse: Decodable {
        let results: [LookupResult]
    }

    private struct LookupResult: Decodable {
        let version: String
        let trackViewUrl: String
    }
}
