package com.memogame.app.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AutoAwesome
import androidx.compose.material.icons.rounded.Psychology
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.memogame.app.core.APP_NAME
import com.memogame.app.core.DSText
import com.memogame.app.core.GlowCircle
import com.memogame.app.core.LocalDSColors
import com.memogame.app.core.colorFromHex
import com.memogame.app.core.softShadow
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

private data class Sparkle(
    val xFrac: Float,
    val yFrac: Float,
    val size: Float,
    val color: Color,
    val lifetime: Float,
    val birth: Float,
    val riseSpeed: Float,
    val wobble: Float
)

/**
 * Animated splash — full port of the iOS SplashView: drifting color blobs,
 * rising sparkles, a floating/breathing logo card with orbiting emoji cards,
 * shimmering gradient title, tag pill and a pulsing loading bar. All motion is
 * driven by one frame-time clock, like the iOS TimelineView.
 */
@Composable
fun SplashScreen() {
    val ds = LocalDSColors.current

    // Continuous time in seconds — the Android equivalent of TimelineView.
    val time by produceState(0f) {
        var start = 0L
        while (true) {
            withFrameNanos { now ->
                if (start == 0L) start = now
                value = (now - start) / 1_000_000_000f
            }
        }
    }

    // Entrance: scale 0.88 → 1 with a soft spring + fade, like the iOS onAppear.
    val appeared = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        appeared.animateTo(
            1f,
            androidx.compose.animation.core.spring(dampingRatio = 0.72f, stiffness = 90f)
        )
    }

    val floatY = sin(time * 1.4f) * 10f
    val breathe = 1f + 0.02f * sin(time * 1.2f)

    Box(modifier = Modifier.fillMaxSize().background(ds.skyGradient)) {
        // Drifting color blobs (iOS splashBackground)
        val blobAlpha = if (ds.isDark) 0.22f else 0.28f
        GlowCircle(
            colorFromHex("FF6B9D").copy(alpha = blobAlpha), 320.dp,
            (-90 + 24 * sin(time * 0.7f)).dp, (-40 + 18 * cos(time * 0.5f)).dp
        )
        GlowCircle(
            colorFromHex("5B8DEF").copy(alpha = blobAlpha), 300.dp,
            (110 + 20 * cos(time * 0.6f)).dp, (620 + 22 * sin(time * 0.55f)).dp
        )
        GlowCircle(
            colorFromHex("C44DFF").copy(alpha = blobAlpha - 0.04f), 200.dp,
            (140 + 40 * sin(time * 0.9f)).dp, (330 + 15 * cos(time * 0.8f)).dp
        )
        GlowCircle(
            colorFromHex("FFD60A").copy(alpha = blobAlpha - 0.06f), 160.dp,
            (-30 + 16 * cos(time * 1.1f)).dp, (400 + 14 * sin(time * 0.95f)).dp
        )

        SparkleLayer(time)

        Column(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    val scale = 0.88f + 0.12f * appeared.value
                    scaleX = scale
                    scaleY = scale
                    alpha = appeared.value
                },
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(48.dp))

            HeroScene(time = time, floatY = floatY, breathe = breathe)

            Spacer(Modifier.height(36.dp))

            TitleSection(time = time)

            Spacer(Modifier.weight(1f))

            LoadingBar(time = time)

            Spacer(Modifier.height(52.dp))
        }
    }
}

// MARK: - Hero

@Composable
private fun HeroScene(time: Float, floatY: Float, breathe: Float) {
    val ds = LocalDSColors.current

    Box(modifier = Modifier.size(340.dp), contentAlignment = Alignment.Center) {
        // Soft halo behind everything
        Box(
            modifier = Modifier
                .size(340.dp)
                .graphicsLayer { scaleX = breathe; scaleY = breathe }
                .background(
                    Brush.radialGradient(
                        listOf(
                            colorFromHex("5B8DEF").copy(alpha = 0.35f),
                            colorFromHex("FF6B9D").copy(alpha = 0.08f),
                            Color.Transparent
                        )
                    ),
                    CircleShape
                )
        )

        // Orbiting emoji cards — continuous revolution + per-card wobble.
        val orbitEmojis = listOf("⭐️", "🍎", "🚗", "🐶", "🔵", "🎈")
        orbitEmojis.forEachIndexed { index, emoji ->
            val angle = (index.toFloat() / orbitEmojis.size) * 2f * PI.toFloat() + time * 0.45f
            val radius = 118f
            OrbitCard(
                emoji = emoji,
                index = index,
                wobbleDegrees = sin(time + index) * 6f,
                modifier = Modifier.offset(
                    x = (cos(angle) * radius).dp,
                    y = (sin(angle) * radius + floatY * 0.3f).dp
                )
            )
        }

        // Main logo card — floats and breathes. (No elevation shadow in dark
        // mode: it would paint through the translucent glass fill as a grey box.)
        Box(
            modifier = Modifier
                .offset(y = floatY.dp)
                .graphicsLayer { scaleX = breathe; scaleY = breathe }
                .size(width = 240.dp, height = 190.dp)
                .then(
                    if (ds.isDark) Modifier
                    else Modifier.softShadow(
                        shape = RoundedCornerShape(36.dp),
                        color = colorFromHex("5B8DEF").copy(alpha = 0.35f),
                        blurRadius = 28.dp,
                        offsetY = 8.dp
                    )
                )
                .background(
                    Brush.linearGradient(
                        if (ds.isDark) {
                            listOf(Color.White.copy(alpha = 0.18f), Color.White.copy(alpha = 0.12f))
                        } else {
                            listOf(Color.White.copy(alpha = 0.95f), colorFromHex("E8F4FF").copy(alpha = 0.85f))
                        }
                    ),
                    RoundedCornerShape(36.dp)
                )
                .border(
                    2.5.dp,
                    Brush.linearGradient(
                        listOf(
                            Color.White.copy(alpha = 0.9f),
                            colorFromHex("B8E6FF").copy(alpha = 0.5f),
                            colorFromHex("FF6B9D").copy(alpha = 0.25f)
                        )
                    ),
                    RoundedCornerShape(36.dp)
                ),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        "🧠",
                        fontSize = 64.sp,
                        modifier = Modifier.graphicsLayer { scaleX = breathe; scaleY = breathe }
                    )
                    // Accent sparkle + star, pulsing like the iOS overlay icons.
                    Icon(
                        Icons.Rounded.AutoAwesome,
                        contentDescription = null,
                        tint = colorFromHex("FFD60A"),
                        modifier = Modifier
                            .size(24.dp)
                            .offset(x = 46.dp, y = (-30).dp)
                            .graphicsLayer { alpha = 0.7f + 0.3f * sin(time * 2.2f) }
                    )
                    Icon(
                        Icons.Rounded.Star,
                        contentDescription = null,
                        tint = colorFromHex("FF6B9D"),
                        modifier = Modifier
                            .size(20.dp)
                            .offset(x = (-48).dp, y = (-28).dp)
                            .graphicsLayer { alpha = 0.6f + 0.4f * cos(time * 1.8f) }
                    )
                }
                Spacer(Modifier.height(10.dp))
                Text(
                    APP_NAME,
                    style = DSText.headline,
                    color = colorFromHex("5B8DEF"),
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

@Composable
private fun OrbitCard(
    emoji: String,
    index: Int,
    wobbleDegrees: Float,
    modifier: Modifier = Modifier
) {
    val gradients = listOf(
        listOf("5B8DEF", "7B5BEF"),
        listOf("FF6B9D", "C44DFF"),
        listOf("FF9500", "FF5E3A"),
        listOf("34C759", "5AC8FA"),
        listOf("AF52DE", "5B8DEF"),
        listOf("FFD60A", "FF9500")
    )
    val colors = gradients[index % gradients.size].map { colorFromHex(it) }
    val shape = RoundedCornerShape(14.dp)

    Box(
        modifier = modifier
            .size(width = 52.dp, height = 68.dp)
            .graphicsLayer { rotationZ = wobbleDegrees }
            .softShadow(
                shape = shape,
                color = colorFromHex("5B8DEF").copy(alpha = 0.3f),
                blurRadius = 10.dp,
                offsetY = 3.dp
            )
            .background(Brush.linearGradient(colors), shape)
            .border(1.5.dp, Color.White.copy(alpha = 0.45f), shape),
        contentAlignment = Alignment.Center
    ) {
        Text(emoji, fontSize = 26.sp)
    }
}

// MARK: - Title + shimmer

@Composable
private fun TitleSection(time: Float) {
    val ds = LocalDSColors.current
    val titleStyle = DSText.largeTitle.copy(fontSize = 36.sp)
    val titleGradient = Brush.linearGradient(
        listOf(colorFromHex("FF6B9D"), colorFromHex("C44DFF"), colorFromHex("5B8DEF"))
    )

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        BoxWithConstraints {
            val density = LocalDensity.current
            val widthPx = with(density) { maxWidth.toPx() }
            val bandPx = with(density) { 130.dp.toPx() }
            // Sweep the highlight band across the text every 1.8s (iOS shimmer).
            val sweep = (time % 1.8f) / 1.8f
            val x0 = -bandPx + sweep * (widthPx + 2f * bandPx)

            Box {
                Text(
                    APP_NAME,
                    style = titleStyle.copy(brush = titleGradient),
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
                // Shimmer overlay — same glyphs, moving white band as the brush,
                // so the highlight only paints inside the letters (like the iOS mask).
                Text(
                    APP_NAME,
                    style = titleStyle.copy(
                        brush = Brush.linearGradient(
                            colors = listOf(
                                Color.Transparent,
                                Color.White.copy(alpha = 0.55f),
                                Color.Transparent
                            ),
                            start = Offset(x0, 0f),
                            end = Offset(x0 + bandPx, bandPx * 0.4f)
                        )
                    ),
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }

        Spacer(Modifier.height(14.dp))

        Text(
            "Flip · Match · Remember!",
            fontSize = 17.sp,
            fontWeight = FontWeight.SemiBold,
            color = ds.textSecondary
        )

        Spacer(Modifier.height(14.dp))

        // Tag pill (iOS "Brain Boost")
        Row(
            modifier = Modifier
                .softShadow(shape = CircleShape, blurRadius = 6.dp, offsetY = 2.dp)
                .background(ds.cardSurface.copy(alpha = 0.85f), CircleShape)
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Icon(
                Icons.Rounded.Psychology,
                contentDescription = null,
                tint = colorFromHex("5B8DEF"),
                modifier = Modifier.size(16.dp)
            )
            Text(
                "Brain Boost",
                style = DSText.caption.copy(fontWeight = FontWeight.Bold),
                color = colorFromHex("5B8DEF")
            )
        }
    }
}

// MARK: - Sparkles

@Composable
private fun SparkleLayer(time: Float) {
    val sparkles = remember {
        val colors = listOf(
            colorFromHex("FFD60A"), colorFromHex("FF6B9D"), colorFromHex("5B8DEF"),
            Color.White, colorFromHex("C44DFF"), colorFromHex("FF9500")
        )
        List(52) {
            Sparkle(
                xFrac = Random.nextFloat(),
                yFrac = Random.nextFloat(),
                size = Random.nextFloat() * 6f + 3f,
                color = colors.random(),
                lifetime = Random.nextFloat() * 2.5f + 2.5f,
                birth = Random.nextFloat() * 2f,
                riseSpeed = Random.nextFloat() * 28f + 20f,
                wobble = Random.nextFloat() * 2f + 1.5f
            )
        }
    }

    Canvas(modifier = Modifier.fillMaxSize()) {
        for (s in sparkles) {
            val raw = time - s.birth
            if (raw < 0f) continue
            val age = raw % s.lifetime               // respawn so the splash stays alive
            val progress = age / s.lifetime
            val x = s.xFrac * size.width + sin(age * s.wobble) * 12f * density
            val y = s.yFrac * size.height - age * s.riseSpeed * density
            val alpha = (1f - progress) * 0.9f
            val starSize = s.size * (0.8f + 0.2f * sin(age * 4f)) * density
            drawCircle(s.color.copy(alpha = alpha), radius = starSize / 2f, center = Offset(x, y))
        }
    }
}

// MARK: - Loading bar

@Composable
private fun LoadingBar(time: Float) {
    val ds = LocalDSColors.current
    // 0.2 ↔ 0.72 every 1.8s with ease-in-out, like the iOS repeatForever bar.
    val phase = (time % 3.6f) / 1.8f
    val triangle = if (phase > 1f) 2f - phase else phase
    val eased = 0.5f - 0.5f * cos(PI.toFloat() * triangle)
    val fraction = 0.2f + (0.72f - 0.2f) * eased

    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 48.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .clip(CircleShape)
                .background(ds.track)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(fraction)
                    .height(8.dp)
                    .clip(CircleShape)
                    .background(ds.primaryGradient)
            )
        }
        Spacer(Modifier.height(10.dp))
        Text("Getting ready…", style = DSText.caption, color = ds.textSecondary)
    }
}
