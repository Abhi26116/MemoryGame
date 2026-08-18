package com.memogame.app.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AutoAwesome
import androidx.compose.material.icons.rounded.Bolt
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.MenuBook
import androidx.compose.material.icons.rounded.School
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.Stars
import androidx.compose.material.icons.rounded.Timer
import androidx.compose.material.icons.rounded.Verified
import androidx.compose.material.icons.rounded.WorkspacePremium
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.memogame.app.core.DS
import com.memogame.app.core.DSCard
import com.memogame.app.core.DSScreenBackground
import com.memogame.app.core.DSText
import com.memogame.app.core.InlineTitleBar
import com.memogame.app.core.LocalDSColors
import com.memogame.app.model.AchievementModel
import com.memogame.app.services.ProgressStore

private fun achievementIcon(name: String): ImageVector = when (name) {
    "star" -> Icons.Rounded.Star
    "flame" -> Icons.Rounded.LocalFireDepartment
    "bolt" -> Icons.Rounded.Bolt
    "seal" -> Icons.Rounded.Verified
    "star_circle" -> Icons.Rounded.Stars
    "books" -> Icons.Rounded.MenuBook
    "sparkles" -> Icons.Rounded.AutoAwesome
    "crown" -> Icons.Rounded.WorkspacePremium
    "stopwatch" -> Icons.Rounded.Timer
    "graduation" -> Icons.Rounded.School
    else -> Icons.Rounded.Star
}

@Composable
fun AchievementScreen(store: ProgressStore) {
    val ds = LocalDSColors.current
    val unlockedIds = store.settings.unlockedAchievementIds

    DSScreenBackground {
        // iOS large-title behaviour: big title scrolls with the list, small
        // centered title fades into the pinned bar (same as SettingsScreen).
        val listState = rememberLazyListState()
        val collapseThresholdPx = with(LocalDensity.current) { 40.dp.toPx() }
        val collapsedFraction = if (listState.firstVisibleItemIndex > 0) {
            1f
        } else {
            (listState.firstVisibleItemScrollOffset / collapseThresholdPx).coerceIn(0f, 1f)
        }

        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            InlineTitleBar(title = "Achievements", alpha = collapsedFraction)
            LazyColumn(
                state = listState,
                modifier = Modifier
                    .widthIn(max = DS.Layout.contentMaxWidth)
                    .fillMaxHeight(),
                contentPadding = PaddingValues(
                    start = DS.Layout.screenPadding,
                    end = DS.Layout.screenPadding,
                    bottom = DS.Layout.screenPadding
                ),
                verticalArrangement = Arrangement.spacedBy(DS.Spacing.lg)
            ) {
                item {
                    Text(
                        "Achievements",
                        style = DSText.title.copy(fontSize = 24.sp),
                        color = ds.textPrimary,
                        modifier = Modifier.graphicsLayer { alpha = 1f - collapsedFraction }
                    )
                }
                items(AchievementModel.catalog, key = { it.id }) { achievement ->
                    val unlocked = achievement.id in unlockedIds
                    // The dimming for locked achievements used to live on a Box
                    // wrapping the whole DSCard (shadow included). A graphicsLayer
                    // with alpha < 1 forces its subtree into an offscreen layer
                    // bounded exactly to that Box's own layout size — so the
                    // card's soft shadow, which is meant to bleed a few dp past
                    // the card's edge, got hard-clipped right at that boundary.
                    // That clip is barely visible along a straight edge but very
                    // visible at a rounded corner, which is exactly where the
                    // shadow's diagonal falloff is widest — reads as a boxy/cut
                    // corner. Scoping the alpha to just this Row (fully inside
                    // the card's padding) keeps the dimming without clipping the
                    // shadow drawn outside the card.
                    DSCard {
                        Row(
                            modifier = Modifier.graphicsLayer { alpha = if (unlocked) 1f else 0.75f },
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(DS.Spacing.lg)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(52.dp)
                                    .background(
                                        if (unlocked) ds.brandGradient
                                        else androidx.compose.ui.graphics.Brush.linearGradient(
                                            listOf(Color.Gray.copy(alpha = 0.3f), Color.Gray.copy(alpha = 0.3f))
                                        ),
                                        CircleShape
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    achievementIcon(achievement.icon),
                                    contentDescription = null,
                                    tint = if (unlocked) Color.White else Color.Gray,
                                    modifier = Modifier.size(26.dp)
                                )
                            }
                            Column(
                                modifier = Modifier.weight(1f),
                                verticalArrangement = Arrangement.spacedBy(DS.Spacing.xs)
                            ) {
                                Text(
                                    achievement.title,
                                    style = DSText.headline.copy(fontSize = 18.sp),
                                    color = ds.textPrimary
                                )
                                Text(
                                    achievement.description,
                                    style = DSText.caption,
                                    color = ds.textSecondary
                                )
                            }
                            Icon(
                                if (unlocked) Icons.Rounded.Verified else Icons.Rounded.Lock,
                                contentDescription = if (unlocked) "Unlocked" else "Locked",
                                tint = if (unlocked) ds.success else Color.Gray,
                                modifier = Modifier.size(22.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}
