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

    static let titleFont = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let headlineFont = Font.system(.title2, design: .rounded, weight: .semibold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded, weight: .medium)

    // MARK: - Adaptive palette (light / dark)

    static func skyGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [Color(hex: "0F1B2E"), Color(hex: "1A2F4F"), Color(hex: "2A1F3D")],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [Color(hex: "87CEEB"), Color(hex: "B8E6FF"), Color(hex: "FFE5B4")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func cardSurface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1E2F45") : Color.white
    }

    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "E8F2FF") : Color(hex: "1E3A5F")
    }

    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "9AB0C8") : Color(hex: "5A6B7D")
    }

    static func sectionTitle(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "B8D4FF") : Color(hex: "153A5C")
    }

    static func linkBlue(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "6BA3FF") : Color(hex: "2F6BFF")
    }

    static func chipUnselected(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "2A3F5C") : Color(hex: "EEF3FA")
    }

    static func progressTrack(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "3A5070") : Color(hex: "D4DEE8")
    }

    static func cardShadowOpacity(for scheme: ColorScheme) -> Double {
        scheme == .dark ? 0.35 : 0.08
    }

    // Legacy aliases (light) — prefer adaptive helpers in views
    static let skyGradient = skyGradient(for: .light)
    static let textPrimary = textPrimary(for: .light)
    static let textSecondary = textSecondary(for: .light)
    static let sectionTitle = sectionTitle(for: .light)
    static let linkBlue = linkBlue(for: .light)
    static let cardSurface = cardSurface(for: .light)
    static let chipUnselected = chipUnselected(for: .light)
    static let progressTrack = progressTrack(for: .light)
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
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(AppTheme.skyGradient(for: colorScheme).ignoresSafeArea())
    }
}

struct AppAppearanceModifier: ViewModifier {
    let mode: AppearanceMode

    func body(content: Content) -> some View {
        content.preferredColorScheme(mode.preferredColorScheme)
    }
}

/// Replaces the plain system "< Back" chevron with a soft circular button that
/// matches the app's other round controls (gear / trophy / pause).
struct KidBackButtonModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppTheme.linkBlue(for: colorScheme))
                    }
                    .accessibilityLabel("Back")
                }
            }
    }
}

extension View {
    func kidBackground() -> some View {
        modifier(KidFriendlyBackground())
    }

    func appAppearance(_ mode: AppearanceMode) -> some View {
        modifier(AppAppearanceModifier(mode: mode))
    }

    func kidBackButton() -> some View {
        modifier(KidBackButtonModifier())
    }
}
