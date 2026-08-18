package com.memogame.app.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ArrowBack
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.PlayCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.memogame.app.core.DS
import com.memogame.app.core.DSCard
import com.memogame.app.core.DSScreenBackground
import com.memogame.app.core.DSText
import com.memogame.app.core.LocalDSColors
import com.memogame.app.core.RoundIconButton
import com.memogame.app.core.pressableClickable
import com.memogame.app.model.LevelModel
import com.memogame.app.services.ProgressStore
import com.memogame.app.ui.components.StarRating
import com.memogame.app.viewmodel.HomeViewModel

/** Full level browser, reached from Settings → All Levels. */
@Composable
fun LevelsScreen(
    store: ProgressStore,
    onPlayLevel: (LevelModel) -> Unit,
    onBack: () -> Unit
) {
    val ds = LocalDSColors.current
    val viewModel = remember(store) { HomeViewModel(store) }

    DSScreenBackground {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Top bar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = DS.Spacing.lg, vertical = DS.Spacing.sm),
                verticalAlignment = Alignment.CenterVertically
            ) {
                RoundIconButton(
                    icon = Icons.Rounded.ArrowBack,
                    contentDescription = "Back",
                    onClick = onBack
                )
                Text(
                    "Levels",
                    fontWeight = FontWeight.Bold,
                    fontSize = 17.sp,
                    color = ds.textPrimary,
                    modifier = Modifier.weight(1f),
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )
                Spacer(Modifier.width(44.dp)) // balance the back button
            }

            LazyColumn(
                modifier = Modifier
                    .widthIn(max = DS.Layout.contentMaxWidth)
                    .fillMaxHeight(),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    horizontal = DS.Layout.screenPadding, vertical = DS.Spacing.lg
                ),
                verticalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)
            ) {
                items(viewModel.visibleLevels, key = { it.id }) { level ->
                    val locked = !viewModel.isUnlocked(level)
                    LevelRow(
                        level = level,
                        locked = locked,
                        stars = viewModel.stars(level.id),
                        completed = viewModel.isCompleted(level.id),
                        unlockHint = viewModel.unlockHint(level),
                        onClick = { if (!locked) onPlayLevel(level) }
                    )
                }
            }
        }
    }
}

@Composable
private fun LevelRow(
    level: LevelModel,
    locked: Boolean,
    stars: Int,
    completed: Boolean,
    unlockHint: String?,
    onClick: () -> Unit
) {
    val ds = LocalDSColors.current

    // The dimming + press-scale used to live on a Box wrapping the whole
    // DSCard (shadow included). Any graphicsLayer{} — alpha here, and the
    // scale one inside pressableClickable — forces its subtree into an
    // offscreen layer bounded exactly to that Box's own layout size, so the
    // card's soft shadow (meant to bleed a few dp past the card edge) got
    // hard-clipped right at that boundary — most visible at the rounded
    // corners. Scoping both to just this Row (inside the card's padding)
    // keeps the dimming/press feedback without clipping the shadow.
    DSCard(padding = DS.Spacing.md) {
        Row(
            modifier = Modifier
                .graphicsLayer { alpha = if (locked) 0.65f else 1f }
                .pressableClickable(enabled = !locked, onClick = onClick),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(DS.Spacing.md)
        ) {
            // Number badge
            val badgeColors = listOf(ds.accent, ds.brand, ds.success, ds.warning)
            val badgeColor = badgeColors[(level.levelNumber - 1) % badgeColors.size]
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(
                        if (locked) {
                            Brush.linearGradient(listOf(Color.Gray.copy(alpha = 0.5f), Color.Gray.copy(alpha = 0.5f)))
                        } else {
                            Brush.linearGradient(listOf(badgeColor, badgeColor.copy(alpha = 0.75f)))
                        },
                        CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                if (locked) {
                    Icon(
                        Icons.Rounded.Lock, contentDescription = null,
                        tint = Color.White, modifier = Modifier.size(18.dp)
                    )
                } else {
                    Text(
                        "${level.levelNumber}",
                        fontWeight = FontWeight.Black,
                        fontSize = 15.sp,
                        color = Color.White
                    )
                }
            }

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(DS.Spacing.xs)
            ) {
                Text(
                    level.title,
                    style = DSText.body.copy(fontWeight = FontWeight.Bold),
                    color = if (locked) ds.textSecondary else ds.textPrimary,
                    maxLines = 1
                )
                if (unlockHint != null) {
                    Text(unlockHint, style = DSText.caption, color = ds.textSecondary)
                } else {
                    Text(
                        level.subtitle,
                        style = DSText.caption,
                        color = ds.textSecondary,
                        maxLines = 1
                    )
                    Text(
                        level.objective,
                        style = DSText.caption2,
                        color = ds.link,
                        maxLines = 2
                    )
                }
            }

            if (!locked) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(DS.Spacing.xs + 2.dp)
                ) {
                    StarRating(stars = stars, size = 11.dp)
                    Icon(
                        if (completed) Icons.Rounded.CheckCircle else Icons.Rounded.PlayCircle,
                        contentDescription = null,
                        tint = if (completed) ds.success else ds.link,
                        modifier = Modifier.size(22.dp)
                    )
                }
            }
        }
    }
}
