package com.memogame.app.core

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import com.memogame.app.model.AppearanceMode

@Composable
fun MemoryMatchTheme(
    appearanceMode: AppearanceMode = AppearanceMode.SYSTEM,
    content: @Composable () -> Unit
) {
    val isDark = when (appearanceMode) {
        AppearanceMode.SYSTEM -> isSystemInDarkTheme()
        AppearanceMode.LIGHT -> false
        AppearanceMode.DARK -> true
    }
    val ds = DSColors(isDark = isDark)

    val colorScheme = if (isDark) {
        darkColorScheme(
            primary = ds.brand,
            secondary = ds.accent,
            background = ds.screen,
            surface = ds.surface,
            onPrimary = androidx.compose.ui.graphics.Color.White,
            onBackground = ds.textPrimary,
            onSurface = ds.textPrimary
        )
    } else {
        lightColorScheme(
            primary = ds.brand,
            secondary = ds.accent,
            background = ds.screen,
            surface = ds.surface,
            onPrimary = androidx.compose.ui.graphics.Color.White,
            onBackground = ds.textPrimary,
            onSurface = ds.textPrimary
        )
    }

    CompositionLocalProvider(LocalDSColors provides ds) {
        MaterialTheme(colorScheme = colorScheme, content = content)
    }
}
