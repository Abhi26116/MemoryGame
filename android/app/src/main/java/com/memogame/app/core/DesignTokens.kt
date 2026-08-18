package com.memogame.app.core

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/** Parses "5B8DEF"-style hex strings (same format the iOS app uses). */
fun colorFromHex(hex: String): Color {
    val clean = hex.filter { it.isLetterOrDigit() }
    if (clean.length != 6) return Color.White
    val value = clean.toLong(16)
    return Color(
        red = ((value shr 16) and 0xFF) / 255f,
        green = ((value shr 8) and 0xFF) / 255f,
        blue = (value and 0xFF) / 255f
    )
}

/**
 * Design-system palette resolved for the current light/dark appearance.
 * Port of the iOS `DS.Color` tokens ("refined hybrid" direction).
 */
@Immutable
data class DSColors(
    val isDark: Boolean,
    // Brand signatures
    val brand: Color = colorFromHex("5B8DEF"),
    val brandDeep: Color = colorFromHex("3E6FD6"),
    val accent: Color = colorFromHex("FF6B9D"),
    val accentDeep: Color = colorFromHex("E5557F"),
    // Semantic status
    val success: Color = colorFromHex("34C759"),
    val warning: Color = colorFromHex("FF9500"),
    val danger: Color = colorFromHex("FF3B30"),
    val star: Color = colorFromHex("FFD60A"),
    // Surfaces
    val screen: Color = if (isDark) colorFromHex("0F1622") else colorFromHex("F4F7FB"),
    val surface: Color = if (isDark) colorFromHex("1A2433") else Color.White,
    val surfaceElevated: Color = if (isDark) colorFromHex("232F42") else Color.White,
    val fill: Color = if (isDark) colorFromHex("2A3850") else colorFromHex("EEF3FA"),
    // Text
    val textPrimary: Color = if (isDark) colorFromHex("E8F0FA") else colorFromHex("1E3A5F"),
    val textSecondary: Color = if (isDark) colorFromHex("9AB0C8") else colorFromHex("5A6B7D"),
    val textTertiary: Color = if (isDark) colorFromHex("6E8099") else colorFromHex("8A98A8"),
    val sectionTitle: Color = if (isDark) colorFromHex("B8D4FF") else colorFromHex("153A5C"),
    val link: Color = if (isDark) colorFromHex("6BA3FF") else colorFromHex("2F6BFF"),
    // Lines & tracks
    val border: Color = if (isDark) colorFromHex("2E3C54") else colorFromHex("E2E8F0"),
    val track: Color = if (isDark) colorFromHex("3A5070") else colorFromHex("D4DEE8"),
    val overlay: Color = Color.Black.copy(alpha = 0.4f),
    val cardSurface: Color = if (isDark) colorFromHex("1E2F45") else Color.White
) {
    // Gradients
    val brandGradient: Brush
        get() = Brush.linearGradient(listOf(brand, brandDeep))
    val accentGradient: Brush
        get() = Brush.linearGradient(listOf(accent, brand))
    val ctaGradient: Brush
        get() = Brush.linearGradient(listOf(colorFromHex("FF9500"), colorFromHex("FF5E3A")))
    val primaryGradient: Brush
        get() = Brush.linearGradient(listOf(colorFromHex("FF6B9D"), colorFromHex("C44DFF")))

    val skyGradient: Brush
        get() = if (isDark) {
            Brush.verticalGradient(
                listOf(colorFromHex("0F1B2E"), colorFromHex("1A2F4F"), colorFromHex("2A1F3D"))
            )
        } else {
            Brush.verticalGradient(
                listOf(colorFromHex("87CEEB"), colorFromHex("B8E6FF"), colorFromHex("FFE5B4"))
            )
        }
}

val LocalDSColors = staticCompositionLocalOf { DSColors(isDark = false) }

object DS {
    // Spacing (4-dp grid)
    object Spacing {
        val xxs = 2.dp
        val xs = 4.dp
        val sm = 8.dp
        val md = 12.dp
        val lg = 16.dp
        val xl = 20.dp
        val xxl = 24.dp
        val xxxl = 32.dp
    }

    // Corner radius
    object Radius {
        val sm = 12.dp
        val md = 16.dp
        val lg = 20.dp
        val xl = 28.dp
    }

    object Layout {
        val minTouchTarget = 56.dp
        val screenPadding = 20.dp
        /** Caps content width on tablets so cards read as a column. */
        val contentMaxWidth = 760.dp
        val cardCornerRadius = 16.dp
    }

    // Motion — spring specs matching the iOS DS.Motion feel.
    // stiffness ≈ (2π / response)²  →  response 0.45 ≈ 195, 0.3 ≈ 440, 0.4 ≈ 250.
    object Motion {
        /** iOS `spring(response: 0.45, dampingFraction: 0.82)` — settle without overshoot. */
        fun <T> springDefault() = spring<T>(dampingRatio = 0.82f, stiffness = 195f)

        /** iOS `snappy` (response 0.3, damping 0.72) — quick, tight taps/toggles. */
        fun <T> snappy() = spring<T>(dampingRatio = 0.72f, stiffness = 440f)

        /** iOS `bouncy` (response 0.4, damping 0.6) — playful overshoot for rewards. */
        fun <T> bouncy() = spring<T>(dampingRatio = 0.6f, stiffness = 250f)
    }
}

/** Gradient for a card-back style. */
fun cardBackBrush(colors: List<String>): Brush =
    Brush.linearGradient(colors.map { colorFromHex(it) }, start = Offset.Zero, end = Offset.Infinite)

const val APP_NAME = "Memory Match"
