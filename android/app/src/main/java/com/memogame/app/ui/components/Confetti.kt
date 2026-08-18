package com.memogame.app.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.rotate
import com.memogame.app.core.colorFromHex
import kotlin.math.sin
import kotlin.random.Random

private data class ConfettiParticle(
    val startXFraction: Float,
    val startY: Float,
    val vx: Float,
    val vy0: Float,
    val gravity: Float,
    val size: Float,
    val color: Color,
    val spin0: Float,
    val spinSpeed: Float,
    val wobbleSpeed: Float,
    val wobbleAmp: Float,
    val phase: Float,
    val isCircle: Boolean,
    val lifetime: Float,
    val birth: Float
)

/**
 * Celebratory confetti burst — particles fan out across the full screen width,
 * tumble with spin + wobble under gravity. Port of the iOS Canvas confetti.
 */
@Composable
fun ConfettiOverlay(isActive: Boolean, modifier: Modifier = Modifier) {
    var particles by remember { mutableStateOf<List<ConfettiParticle>>(emptyList()) }
    var frameTimeNanos by remember { mutableLongStateOf(0L) }
    var startNanos by remember { mutableLongStateOf(0L) }

    LaunchedEffect(isActive) {
        if (!isActive) return@LaunchedEffect
        particles = spawnParticles()
        startNanos = withFrameNanos { it }
        val maxLifetime = 5.5f
        while (true) {
            val now = withFrameNanos { it }
            frameTimeNanos = now
            if ((now - startNanos) / 1_000_000_000f > maxLifetime) break
        }
        particles = emptyList()
    }

    if (particles.isEmpty()) return

    Canvas(modifier = modifier.fillMaxSize()) {
        val elapsed = (frameTimeNanos - startNanos) / 1_000_000_000f
        val density = density
        for (p in particles) {
            val age = elapsed - p.birth
            if (age < 0f || age >= p.lifetime) continue

            val progress = age / p.lifetime
            val x = p.startXFraction * size.width +
                (p.vx * age + sin((age * p.wobbleSpeed + p.phase).toDouble()).toFloat() * p.wobbleAmp) * density
            val y = (p.startY + p.vy0 * age + 0.5f * p.gravity * age * age) * density
            if (y > size.height + 60 * density) continue

            // Fade out over the last 20% of life.
            val alpha = if (progress < 0.8f) 1f else ((1f - (progress - 0.8f) / 0.2f).coerceAtLeast(0f))
            val color = p.color.copy(alpha = alpha)
            val sizePx = p.size * density
            val rotationDegrees = Math.toDegrees((p.spin0 + p.spinSpeed * age).toDouble()).toFloat()

            rotate(rotationDegrees, pivot = Offset(x, y)) {
                if (p.isCircle) {
                    drawCircle(color, radius = sizePx / 2, center = Offset(x, y))
                } else {
                    val w = sizePx * 0.62f
                    drawRoundRect(
                        color,
                        topLeft = Offset(x - w / 2, y - sizePx / 2),
                        size = Size(w, sizePx),
                        cornerRadius = CornerRadius(1.5f * density)
                    )
                }
            }
        }
    }
}

private fun spawnParticles(): List<ConfettiParticle> {
    val colors = listOf(
        colorFromHex("FF6B9D"), colorFromHex("FFD60A"), colorFromHex("FF9500"),
        colorFromHex("34C759"), colorFromHex("5B8DEF"), colorFromHex("C44DFF"),
        colorFromHex("63E6BE"), colorFromHex("22B8CF"), Color.White
    )
    return List(150) {
        ConfettiParticle(
            startXFraction = Random.nextFloat() * 1.1f - 0.05f,
            startY = Random.nextFloat() * -70f - 10f,
            vx = Random.nextFloat() * 140f - 70f,
            vy0 = Random.nextFloat() * 60f + 20f,
            gravity = Random.nextFloat() * 70f + 90f,
            size = Random.nextFloat() * 8f + 7f,
            color = colors.random(),
            spin0 = Random.nextFloat() * (2f * Math.PI.toFloat()),
            spinSpeed = Random.nextFloat() * 14f - 7f,
            wobbleSpeed = Random.nextFloat() * 3f + 2f,
            wobbleAmp = Random.nextFloat() * 20f + 8f,
            phase = Random.nextFloat() * (2f * Math.PI.toFloat()),
            isCircle = Random.nextBoolean(),
            lifetime = Random.nextFloat() * 1.8f + 3f,
            birth = Random.nextFloat() * 0.55f
        )
    }
}
