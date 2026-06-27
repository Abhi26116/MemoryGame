//
//  DesignTokens.swift
//  Memory Match
//
//  Phase 1 of the UI/UX redesign — the single source of truth for color,
//  spacing, radius, shadow, motion and typography. Screens should consume
//  these `DS.*` tokens instead of hardcoding hex values, paddings or spring
//  constants. The palette follows the "refined hybrid" direction: the blue and
//  pink brand signatures are kept, everything else is calmed toward a premium,
//  layered-surface look in both light and dark mode.
//

import SwiftUI

// MARK: - Dynamic color helper

extension Color {
    /// Builds a single `Color` that resolves automatically for light / dark mode,
    /// so semantic tokens don't need `(for: colorScheme)` threading at call sites.
    init(light: Color, dark: Color) {
        self = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

/// Design-system namespace. Everything is `static` — `DS.Color.brand`,
/// `DS.Spacing.lg`, `DS.Motion.spring`, etc.
enum DS {

    // MARK: - Color

    enum Color {
        // Brand signatures (kept from the original identity)
        static let brand = SwiftUI.Color(hex: "5B8DEF")          // primary blue
        static let brandDeep = SwiftUI.Color(hex: "3E6FD6")
        static let accent = SwiftUI.Color(hex: "FF6B9D")         // secondary pink
        static let accentDeep = SwiftUI.Color(hex: "E5557F")

        // Semantic status
        static let success = SwiftUI.Color(hex: "34C759")
        static let warning = SwiftUI.Color(hex: "FF9500")
        static let danger = SwiftUI.Color(hex: "FF3B30")
        static let star = SwiftUI.Color(hex: "FFD60A")

        // Surfaces (layered, Apple-style — dark mode avoids pure black)
        static let screen = SwiftUI.Color(
            light: SwiftUI.Color(hex: "F4F7FB"),
            dark: SwiftUI.Color(hex: "0F1622")
        )
        static let surface = SwiftUI.Color(
            light: .white,
            dark: SwiftUI.Color(hex: "1A2433")
        )
        static let surfaceElevated = SwiftUI.Color(
            light: .white,
            dark: SwiftUI.Color(hex: "232F42")
        )
        /// Subtle filled chip / inset background.
        static let fill = SwiftUI.Color(
            light: SwiftUI.Color(hex: "EEF3FA"),
            dark: SwiftUI.Color(hex: "2A3850")
        )

        // Text
        static let textPrimary = SwiftUI.Color(
            light: SwiftUI.Color(hex: "1E3A5F"),
            dark: SwiftUI.Color(hex: "E8F0FA")
        )
        static let textSecondary = SwiftUI.Color(
            light: SwiftUI.Color(hex: "5A6B7D"),
            dark: SwiftUI.Color(hex: "9AB0C8")
        )
        static let textTertiary = SwiftUI.Color(
            light: SwiftUI.Color(hex: "8A98A8"),
            dark: SwiftUI.Color(hex: "6E8099")
        )
        static let sectionTitle = SwiftUI.Color(
            light: SwiftUI.Color(hex: "153A5C"),
            dark: SwiftUI.Color(hex: "B8D4FF")
        )
        static let link = SwiftUI.Color(
            light: SwiftUI.Color(hex: "2F6BFF"),
            dark: SwiftUI.Color(hex: "6BA3FF")
        )

        // Lines & tracks
        static let border = SwiftUI.Color(
            light: SwiftUI.Color(hex: "E2E8F0"),
            dark: SwiftUI.Color(hex: "2E3C54")
        )
        static let track = SwiftUI.Color(
            light: SwiftUI.Color(hex: "D4DEE8"),
            dark: SwiftUI.Color(hex: "3A5070")
        )
        static let overlay = SwiftUI.Color.black.opacity(0.4)
    }

    // MARK: - Gradients

    enum Gradient {
        /// Calm, premium brand signature (blue → deep blue).
        static let brand = LinearGradient(
            colors: [Color.brand, Color.brandDeep],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        /// Secondary accent (pink → blue) — used sparingly for highlights.
        static let accent = LinearGradient(
            colors: [Color.accent, Color.brand],
            startPoint: .leading, endPoint: .trailing
        )
        /// Warm call-to-action (Play).
        static let cta = LinearGradient(
            colors: [SwiftUI.Color(hex: "FF9500"), SwiftUI.Color(hex: "FF5E3A")],
            startPoint: .leading, endPoint: .trailing
        )
    }

    // MARK: - Spacing (4-pt grid)

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner radius

    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let pill: CGFloat = 999
    }

    // MARK: - Layout constants

    enum Layout {
        /// HIG-friendly minimum tappable size.
        static let minTouchTarget: CGFloat = 56
        static let screenPadding: CGFloat = 20
    }

    // MARK: - Shadow

    struct Shadow {
        let color: SwiftUI.Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        /// Soft resting shadow for cards. Lighter in light mode, deeper in dark.
        static let card = Shadow(
            color: SwiftUI.Color(light: .black.opacity(0.08), dark: .black.opacity(0.35)),
            radius: 10, x: 0, y: 4
        )
        /// More pronounced shadow for elevated / floating surfaces.
        static let elevated = Shadow(
            color: SwiftUI.Color(light: .black.opacity(0.12), dark: .black.opacity(0.45)),
            radius: 18, x: 0, y: 8
        )
    }

    // MARK: - Motion

    enum Motion {
        /// Default UI spring — settle without overshoot.
        static let spring = Animation.spring(response: 0.45, dampingFraction: 0.82)
        /// Quick, tight response for taps / toggles.
        static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.72)
        /// Playful overshoot for rewards / pops.
        static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
        /// Plain ease for cross-fades.
        static let smooth = Animation.easeInOut(duration: 0.3)

        /// Returns the animation unless Reduce Motion is on, in which case it
        /// collapses to a near-instant cross-fade.
        static func respecting(_ reduceMotion: Bool, _ animation: Animation) -> Animation {
            reduceMotion ? .linear(duration: 0.01) : animation
        }
    }
}

// MARK: - Shadow modifier

extension View {
    func dsShadow(_ shadow: DS.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Typography

extension Font {
    enum DSText {
        static let largeTitle = AppTheme.display(34, relativeTo: .largeTitle)
        static let title = AppTheme.display(28, relativeTo: .title)
        static let headline = Font.custom("Fredoka-SemiBold", size: 22, relativeTo: .title2)
        static let subheadline = Font.system(.subheadline, design: .rounded, weight: .semibold)
        static let body = Font.system(.body, design: .rounded)
        static let callout = Font.system(.callout, design: .rounded, weight: .medium)
        static let caption = Font.system(.caption, design: .rounded, weight: .medium)
        static let button = Font.system(.headline, design: .rounded, weight: .bold)
        /// Tabular display numbers for score / counters.
        static let score = Font.custom("Fredoka-Bold", size: 26, relativeTo: .title)
        static let timer = Font.system(size: 28, weight: .black, design: .rounded)
    }
}
