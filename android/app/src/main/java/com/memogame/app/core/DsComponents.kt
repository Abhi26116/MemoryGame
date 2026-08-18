package com.memogame.app.core

import android.graphics.BlurMaskFilter
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.asAndroidPath
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.Canvas as FoundationCanvas

// MARK: - Press feedback

/**
 * Spring scale-down on press — port of the iOS `PressableButtonStyle`.
 * Pass [onClick] here so the whole element is one tap target.
 */
fun Modifier.pressableClickable(
    enabled: Boolean = true,
    scale: Float = 0.96f,
    onClick: () -> Unit
): Modifier = composed {
    val interactionSource = remember { MutableInteractionSource() }
    val pressed by interactionSource.collectIsPressedAsState()
    val pressScale by animateFloatAsState(
        targetValue = if (pressed) scale else 1f,
        animationSpec = DS.Motion.snappy(),
        label = "pressScale"
    )
    this
        .graphicsLayer {
            scaleX = pressScale
            scaleY = pressScale
        }
        .clickable(
            interactionSource = interactionSource,
            indication = null,
            enabled = enabled,
            onClick = onClick
        )
}

// MARK: - Buttons

/** Full-width filled call-to-action. Gradient background, white label. */
@Composable
fun PrimaryButton(
    title: String,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    gradient: Brush? = null,
    enabled: Boolean = true,
    onClick: () -> Unit
) {
    val ds = LocalDSColors.current
    val brush = gradient ?: ds.brandGradient
    Row(
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = DS.Layout.minTouchTarget)
            .pressableClickable(enabled = enabled, onClick = onClick)
            .softShadow(shape = RoundedCornerShape(DS.Radius.lg), blurRadius = 8.dp, offsetY = 3.dp)
            .background(brush, RoundedCornerShape(DS.Radius.lg))
            .graphicsLayer { alpha = if (enabled) 1f else 0.6f }
            .padding(vertical = DS.Spacing.xs),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            Icon(icon, contentDescription = null, tint = Color.White)
            Spacer(Modifier.width(DS.Spacing.sm))
        }
        Text(title, style = DSText.button, color = Color.White)
    }
}

/** Circular icon control for toolbars and floating actions (gear, pause, back). */
@Composable
fun RoundIconButton(
    icon: ImageVector,
    contentDescription: String,
    modifier: Modifier = Modifier,
    tint: Color? = null,
    size: Dp = 44.dp,
    onClick: () -> Unit
) {
    val ds = LocalDSColors.current
    Box(
        modifier = modifier
            .size(size)
            .pressableClickable(onClick = onClick)
            .softShadow(shape = CircleShape, blurRadius = 6.dp, offsetY = 2.dp)
            .background(ds.surface, CircleShape),
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, contentDescription = contentDescription, tint = tint ?: ds.link)
    }
}

// MARK: - Soft shadow

/**
 * A soft drop shadow drawn with Skia's Gaussian [BlurMaskFilter] instead of
 * Android's RenderNode elevation shadow (`Modifier.shadow`). The native
 * elevation shadow is generated as a small number of discrete alpha steps, so
 * on rounded shapes it renders as visible banded rings right at the corner —
 * most noticeable on cards like [DSCard]. Drawing the shape's own outline
 * with a blur mask instead gives a smooth, even falloff with no rings.
 */
fun Modifier.softShadow(
    shape: Shape,
    color: Color = Color.Black.copy(alpha = 0.16f),
    blurRadius: Dp = 8.dp,
    offsetY: Dp = 2.dp,
    offsetX: Dp = 0.dp
): Modifier = drawBehind {
    val outline = shape.createOutline(size, layoutDirection, this)
    val path = when (outline) {
        is Outline.Rectangle -> Path().apply { addRect(outline.rect) }
        is Outline.Rounded -> Path().apply { addRoundRect(outline.roundRect) }
        is Outline.Generic -> outline.path
    }.asAndroidPath()

    val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
        this.color = color.toArgb()
        val blurPx = blurRadius.toPx()
        if (blurPx > 0f) maskFilter = BlurMaskFilter(blurPx, BlurMaskFilter.Blur.NORMAL)
    }

    drawIntoCanvas { canvas ->
        val native = canvas.nativeCanvas
        native.save()
        native.translate(offsetX.toPx(), offsetY.toPx())
        native.drawPath(path, paint)
        native.restore()
    }
}

// MARK: - Card surface

/** The standard rounded surface used for every content block. */
@Composable
fun DSCard(
    modifier: Modifier = Modifier,
    padding: Dp = DS.Spacing.lg,
    radius: Dp = DS.Radius.lg,
    content: @Composable androidx.compose.foundation.layout.ColumnScope.() -> Unit
) {
    val ds = LocalDSColors.current
    val shape = RoundedCornerShape(radius)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .softShadow(
                shape = shape,
                color = Color.Black.copy(alpha = if (ds.isDark) 0.32f else 0.10f),
                blurRadius = if (ds.isDark) 12.dp else 8.dp,
                offsetY = 3.dp
            )
            .background(ds.surface, shape)
            .border(0.75.dp, ds.border, shape)
            .padding(padding),
        verticalArrangement = Arrangement.spacedBy(DS.Spacing.md),
        content = content
    )
}

// MARK: - Inline nav title (iOS large-title collapse)

/**
 * iOS-style pinned inline title: sits centered in a 44dp bar and fades in as
 * the screen's large title scrolls away underneath — the Compose equivalent of
 * `.navigationTitle` collapsing from large to inline.
 */
@Composable
fun InlineTitleBar(title: String, alpha: Float) {
    val ds = LocalDSColors.current
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(44.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            title,
            style = DSText.body.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
            color = ds.textPrimary,
            modifier = Modifier.graphicsLayer { this.alpha = alpha }
        )
    }
}

// MARK: - Section header

@Composable
fun SectionHeader(title: String, icon: ImageVector? = null) {
    val ds = LocalDSColors.current
    Row(verticalAlignment = Alignment.CenterVertically) {
        if (icon != null) {
            Icon(icon, contentDescription = null, tint = ds.sectionTitle, modifier = Modifier.size(22.dp))
            Spacer(Modifier.width(DS.Spacing.sm))
        }
        Text(title, style = DSText.headline, color = ds.sectionTitle)
    }
}

// MARK: - Stat card

/** Compact metric tile: tinted icon, large value, caption label. */
@Composable
fun StatCard(
    value: String,
    label: String,
    icon: ImageVector,
    modifier: Modifier = Modifier,
    tint: Color? = null,
    horizontal: Boolean = false
) {
    val ds = LocalDSColors.current
    val tintColor = tint ?: ds.brand

    val iconBadge: @Composable () -> Unit = {
        Box(
            modifier = Modifier
                .size(40.dp)
                .background(tintColor.copy(alpha = 0.16f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, contentDescription = null, tint = tintColor, modifier = Modifier.size(20.dp))
        }
    }

    Box(
        modifier = modifier
            .background(ds.fill, RoundedCornerShape(DS.Radius.md))
            .padding(horizontal = DS.Spacing.md, vertical = DS.Spacing.md)
    ) {
        if (horizontal) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(DS.Spacing.md),
                modifier = Modifier.fillMaxWidth()
            ) {
                iconBadge()
                Column(verticalArrangement = Arrangement.spacedBy(DS.Spacing.xxs)) {
                    Text(label, style = DSText.caption, color = ds.textSecondary)
                    Text(value, style = DSText.score, color = ds.textPrimary)
                }
            }
        } else {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(DS.Spacing.sm),
                modifier = Modifier.fillMaxWidth()
            ) {
                iconBadge()
                Text(value, style = DSText.score, color = ds.textPrimary, maxLines = 1)
                Text(
                    label, style = DSText.caption, color = ds.textSecondary,
                    maxLines = 1, textAlign = TextAlign.Center
                )
            }
        }
    }
}

// MARK: - Progress ring

/** Circular progress indicator with a gradient stroke and free-form center content. */
@Composable
fun ProgressRing(
    progress: Float,
    modifier: Modifier = Modifier,
    lineWidth: Dp = 7.dp,
    colors: List<Color>? = null,
    center: @Composable () -> Unit = {}
) {
    val ds = LocalDSColors.current
    val ringColors = colors ?: listOf(ds.brand, ds.brandDeep)
    val animated by animateFloatAsState(
        targetValue = progress.coerceIn(0f, 1f),
        animationSpec = DS.Motion.springDefault(),
        label = "ringProgress"
    )

    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        FoundationCanvas(modifier = Modifier.fillMaxSize()) {
            val stroke = Stroke(width = lineWidth.toPx(), cap = StrokeCap.Round)
            val inset = lineWidth.toPx() / 2
            val arcSize = androidx.compose.ui.geometry.Size(
                size.width - inset * 2, size.height - inset * 2
            )
            drawArc(
                color = ds.track,
                startAngle = 0f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = Offset(inset, inset),
                size = arcSize,
                style = stroke
            )
            if (animated > 0f) {
                drawArc(
                    brush = Brush.sweepGradient(ringColors + ringColors.first()),
                    startAngle = -90f,
                    sweepAngle = 360f * animated,
                    useCenter = false,
                    topLeft = Offset(inset, inset),
                    size = arcSize,
                    style = stroke
                )
            }
        }
        center()
    }
}

// MARK: - Screen background

/** Calm, layered app background: flat screen color with soft brand/accent glows. */
@Composable
fun DSScreenBackground(glow: Boolean = true, content: @Composable () -> Unit) {
    val ds = LocalDSColors.current
    Box(modifier = Modifier.fillMaxSize().background(ds.screen)) {
        if (glow) {
            GlowCircle(color = ds.brand.copy(alpha = 0.16f), size = 300.dp, x = (-130).dp, y = (-140).dp)
            GlowCircle(color = ds.accent.copy(alpha = 0.14f), size = 260.dp, x = 140.dp, y = 300.dp)
            GlowCircle(color = ds.brand.copy(alpha = 0.10f), size = 220.dp, x = 60.dp, y = 580.dp)
        }
        content()
    }
}

@Composable
fun GlowCircle(color: Color, size: Dp, x: Dp, y: Dp) {
    // Radial fade instead of blur so it renders softly on every API level.
    Box(
        modifier = Modifier
            .offset(x = x, y = y)
            .size(size)
            .background(
                Brush.radialGradient(listOf(color, color.copy(alpha = 0f))),
                CircleShape
            )
    )
}

// MARK: - Dialog

/** Centered modal card over a dimmed background — port of the iOS `Dialog`. */
@Composable
fun DialogCard(content: @Composable androidx.compose.foundation.layout.ColumnScope.() -> Unit) {
    val ds = LocalDSColors.current
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(ds.overlay)
            // absorb taps behind the dialog
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null
            ) {},
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .padding(DS.Spacing.xxxl)
                .widthIn(max = 480.dp)
                .softShadow(
                    shape = RoundedCornerShape(DS.Radius.xl),
                    color = Color.Black.copy(alpha = 0.22f),
                    blurRadius = 20.dp,
                    offsetY = 6.dp
                )
                .background(ds.surfaceElevated, RoundedCornerShape(DS.Radius.xl))
                .padding(DS.Spacing.xxl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(DS.Spacing.lg),
            content = content
        )
    }
}
