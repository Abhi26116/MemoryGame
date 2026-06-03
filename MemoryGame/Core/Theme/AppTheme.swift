//
//  AppTheme.swift
//  Memory Match Kids
//

import SwiftUI

enum AppTheme {
    static let appName = "Memory Match Kids"

    static let cornerRadius: CGFloat = 20
    static let cardCornerRadius: CGFloat = 16
    static let minTouchTarget: CGFloat = 56

    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "FF6B9D"), Color(hex: "C44DFF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let skyGradient = LinearGradient(
        colors: [Color(hex: "87CEEB"), Color(hex: "B8E6FF"), Color(hex: "FFE5B4")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardBackGradient = LinearGradient(
        colors: [Color(hex: "5B8DEF"), Color(hex: "7B5BEF"), Color(hex: "9B4DEF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let playButtonGradient = LinearGradient(
        colors: [Color(hex: "FF9500"), Color(hex: "FF5E3A")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let successGreen = Color(hex: "34C759")
    static let warningOrange = Color(hex: "FF9500")
    static let toddlerPink = Color(hex: "FF6B9D")
    static let preschoolPurple = Color(hex: "AF52DE")
    static let learnerBlue = Color(hex: "5AC8FA")

    /// Dark text for labels on light cards and the sky background
    static let textPrimary = Color(hex: "1E3A5F")
    static let textSecondary = Color(hex: "5A6B7D")
    static let sectionTitle = Color(hex: "153A5C")
    static let linkBlue = Color(hex: "2F6BFF")

    static let cardSurface = Color.white
    static let chipUnselected = Color(hex: "EEF3FA")
    static let progressTrack = Color(hex: "D4DEE8")

    static let titleFont = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let headlineFont = Font.system(.title2, design: .rounded, weight: .semibold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded, weight: .medium)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}

struct KidFriendlyBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.skyGradient.ignoresSafeArea())
    }
}

extension View {
    func kidBackground() -> some View {
        modifier(KidFriendlyBackground())
    }

    /// Keeps light surfaces readable (avoids white `.primary` text on white cards in Dark Mode).
    func kidColorScheme() -> some View {
        preferredColorScheme(.light)
    }
}
