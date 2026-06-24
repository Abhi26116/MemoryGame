//
//  GameEnums.swift
//  Memory Match Kids
//

import Foundation
import SwiftUI

enum GridSize: String, CaseIterable, Identifiable {
    case twoByTwo = "2×2"
    case twoByThree = "2×3"
    case twoByFour = "2×4"
    case threeByFour = "3×4"
    case fourByFour = "4×4"
    case fourByFive = "4×5"
    case fiveBySix = "5×6"

    var id: String { rawValue }

    var gridRows: Int {
        switch self {
        case .twoByTwo: return 2
        case .twoByThree: return 2
        case .twoByFour: return 2
        case .threeByFour: return 3
        case .fourByFour: return 4
        case .fourByFive: return 4
        case .fiveBySix: return 5
        }
    }

    var gridColumns: Int {
        switch self {
        case .twoByTwo: return 2
        case .twoByThree: return 3
        case .twoByFour: return 4
        case .threeByFour: return 4
        case .fourByFour: return 4
        case .fourByFive: return 5
        case .fiveBySix: return 6
        }
    }

    var pairCount: Int { (gridRows * gridColumns) / 2 }
}

enum MatchMode: String, Codable {
    case identical
    case association
    case triple
    case sequence
    case maze
}

enum BadgeTier: String, CaseIterable, Codable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"

    var icon: String {
        switch self {
        case .bronze: return "medal.fill"
        case .silver: return "medal.fill"
        case .gold: return "crown.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .bronze: return "CD7F32"
        case .silver: return "C0C0C0"
        case .gold: return "FFD700"
        }
    }

    static func forStars(_ stars: Int) -> BadgeTier? {
        if stars >= 3 { return .gold }
        if stars >= 2 { return .silver }
        if stars >= 1 { return .bronze }
        return nil
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
