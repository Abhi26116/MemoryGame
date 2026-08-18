package com.memogame.app.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Psychology
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.memogame.app.core.DS
import com.memogame.app.core.LocalDSColors
import com.memogame.app.core.cardBackBrush
import com.memogame.app.core.colorFromHex
import com.memogame.app.core.pressableClickable
import com.memogame.app.model.CardBackStyle
import com.memogame.app.model.CardModel
import kotlin.math.PI
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * Memory card with a true 3-D Y-axis flip, matching the iOS MemoryCardView:
 * the back narrows to edge-on over the first 90°, then the front expands from
 * the edge — one continuous spring (iOS DS.Motion.spring). Matched cards pulse,
 * mismatches shake horizontally.
 */
@Composable
fun MemoryCard(
    card: CardModel,
    size: Dp,
    largeText: Boolean = false,
    highContrast: Boolean = false,
    colorBlindMode: Boolean = false,
    cardBackStyle: CardBackStyle = CardBackStyle.CLASSIC,
    /** Shared across every card in the grid — see [CardFront]'s doc. */
    labelFontSize: Float = if (largeText) 14f else 11f,
    onTap: () -> Unit
) {
    val ds = LocalDSColors.current
    val faceUp = card.isFaceUp || card.isMatched

    val flipDegrees by animateFloatAsState(
        targetValue = if (faceUp) 180f else 0f,
        animationSpec = DS.Motion.springDefault(),
        label = "flip"
    )

    // Pulse when matched (iOS: bouncy 1.12 then settle)
    val pulse = remember { Animatable(1f) }
    LaunchedEffect(card.isMatched) {
        if (card.isMatched) {
            pulse.animateTo(1.12f, DS.Motion.bouncy())
            pulse.animateTo(1f, DS.Motion.springDefault())
        }
    }

    // Horizontal shake on mismatch (iOS ShakeEffect: 3 oscillations × 6pt)
    val shake = remember { Animatable(0f) }
    LaunchedEffect(card.isShaking) {
        if (card.isShaking) {
            shake.snapTo(0f)
            shake.animateTo(3f, tween(durationMillis = 500))
            shake.snapTo(0f)
        }
    }

    Box(
        modifier = Modifier
            .width(size)
            .height(size * 1.15f)
            .graphicsLayer {
                translationX = (sin(shake.value * 2.0 * PI) * 6.dp.toPx()).toFloat()
                scaleX = pulse.value
                scaleY = pulse.value
            }
            .pressableClickable(enabled = !card.isMatched, onClick = onTap)
    ) {
        // Classic 3-D flip, confirmed frame-by-frame against the iOS screen
        // recording: the back rotates to edge-on (0→90°), then the front
        // rotates in (90→180°) — one continuous iOS-tuned spring, door-like
        // perspective from cameraDistance.
        Box(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    rotationY = flipDegrees
                    cameraDistance = 9f * density
                    alpha = if (flipDegrees <= 90f) 1f else 0f
                }
        ) {
            CardBack(size = size, cardBackStyle = cardBackStyle)
        }

        Box(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    rotationY = flipDegrees - 180f
                    cameraDistance = 9f * density
                    alpha = if (flipDegrees > 90f) 1f else 0f
                }
        ) {
            CardFront(
                card = card,
                size = size,
                largeText = largeText,
                highContrast = highContrast,
                colorBlindMode = colorBlindMode,
                cardSurface = if (highContrast) Color.White else ds.cardSurface,
                textColor = if (highContrast) Color.Black else ds.textPrimary,
                labelFontSize = labelFontSize
            )
        }
    }
}

@Composable
private fun CardBack(size: Dp, cardBackStyle: CardBackStyle) {
    val shape = RoundedCornerShape(DS.Layout.cardCornerRadius)
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(cardBackBrush(cardBackStyle.colorHexes), shape)
            .border(2.dp, Color.White.copy(alpha = 0.35f), shape),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                Icons.Rounded.Psychology,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier
                    .width(size * 0.3f)
                    .height(size * 0.3f)
            )
            Text(
                "MM",
                color = Color.White.copy(alpha = 0.9f),
                fontSize = (size.value * 0.14f).roundToInt().sp,
                fontWeight = FontWeight.Black,
                letterSpacing = 1.sp
            )
        }
    }
}

@Composable
private fun CardFront(
    card: CardModel,
    size: Dp,
    largeText: Boolean,
    highContrast: Boolean,
    colorBlindMode: Boolean,
    cardSurface: Color,
    textColor: Color,
    /**
     * Font size for the label under an emoji, computed ONCE by the caller
     * from the longest label among the currently-dealt cards — so every card
     * in the grid shares one size instead of each picking its own from just
     * its own word length (which made short words render bigger than long
     * ones sitting right next to them).
     */
    labelFontSize: Float
) {
    val shape = RoundedCornerShape(DS.Layout.cardCornerRadius)
    val accent = colorFromHex(if (colorBlindMode) "007AFF" else card.content.accentColorHex)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(cardSurface, shape)
            .border(if (highContrast) 4.dp else 2.dp, accent, shape)
            .padding(6.dp),
        contentAlignment = Alignment.Center
    ) {
        val emoji = card.content.emoji
        if (emoji != null) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    emoji,
                    fontSize = (size.value * if (largeText) 0.42f else 0.36f).roundToInt().sp,
                    textAlign = TextAlign.Center
                )
                if (card.content.label.isNotEmpty() && card.content.label != emoji) {
                    Text(
                        card.content.label,
                        fontSize = labelFontSize.sp,
                        fontWeight = FontWeight.Bold,
                        color = textColor,
                        textAlign = TextAlign.Center,
                        maxLines = 2
                    )
                }
            }
        } else {
            // Text card: letters, words, country names, math.
            val base = size.value * (if (largeText) 0.34f else 0.28f)
            // Rounded to a whole point — a fractional sp size renders visibly
            // soft on some densities.
            val textSize = when (card.content.label.length) {
                in 0..3 -> base.roundToInt().toFloat()           // "A", "12", "USA"
                in 4..6 -> (base * 0.72f).roundToInt().toFloat()   // "SHARK", "Japan"
                else -> (base * 0.55f).roundToInt().toFloat()      // "CROCODILE", "South Africa"
            }
            Text(
                card.content.label,
                fontSize = textSize.sp,
                fontWeight = FontWeight.ExtraBold,
                color = textColor,
                textAlign = TextAlign.Center,
                maxLines = 2,
                modifier = Modifier.padding(horizontal = 4.dp)
            )
        }
    }
}
