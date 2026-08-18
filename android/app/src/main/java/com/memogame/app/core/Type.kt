package com.memogame.app.core

import androidx.compose.ui.text.ExperimentalTextApi
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.memogame.app.R

/**
 * Fredoka (rounded display font) for titles & headings — same variable font the
 * iOS app ships. Body copy uses the system font.
 */
@OptIn(ExperimentalTextApi::class)
val Fredoka = FontFamily(
    Font(
        R.font.fredoka,
        weight = FontWeight.Medium,
        variationSettings = FontVariation.Settings(FontVariation.weight(500))
    ),
    Font(
        R.font.fredoka,
        weight = FontWeight.SemiBold,
        variationSettings = FontVariation.Settings(FontVariation.weight(600))
    ),
    Font(
        R.font.fredoka,
        weight = FontWeight.Bold,
        variationSettings = FontVariation.Settings(FontVariation.weight(700))
    )
)

/** Text styles mirroring the iOS `Font.DSText` scale. */
object DSText {
    val largeTitle = TextStyle(fontFamily = Fredoka, fontWeight = FontWeight.Bold, fontSize = 34.sp)
    val title = TextStyle(fontFamily = Fredoka, fontWeight = FontWeight.Bold, fontSize = 28.sp)
    val headline = TextStyle(fontFamily = Fredoka, fontWeight = FontWeight.SemiBold, fontSize = 22.sp)
    val subheadline = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
    val body = TextStyle(fontSize = 17.sp)
    val callout = TextStyle(fontWeight = FontWeight.Medium, fontSize = 16.sp)
    val caption = TextStyle(fontWeight = FontWeight.Medium, fontSize = 12.sp)
    val caption2 = TextStyle(fontWeight = FontWeight.Medium, fontSize = 11.sp)
    val button = TextStyle(fontWeight = FontWeight.Bold, fontSize = 17.sp)
    val score = TextStyle(fontFamily = Fredoka, fontWeight = FontWeight.Bold, fontSize = 26.sp)
    val timer = TextStyle(fontWeight = FontWeight.Black, fontSize = 28.sp)
}
