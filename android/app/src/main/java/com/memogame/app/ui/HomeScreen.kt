package com.memogame.app.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ChevronRight
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.Flag
import androidx.compose.material.icons.rounded.Lightbulb
import androidx.compose.material.icons.rounded.Map
import androidx.compose.material.icons.rounded.PlayCircle
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.WorkspacePremium
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.memogame.app.core.APP_NAME
import com.memogame.app.core.DS
import com.memogame.app.core.DSCard
import com.memogame.app.core.DSScreenBackground
import com.memogame.app.core.DSText
import com.memogame.app.core.LocalDSColors
import com.memogame.app.core.SectionHeader
import com.memogame.app.core.StatCard
import com.memogame.app.core.pressableClickable
import com.memogame.app.core.softShadow
import com.memogame.app.model.LevelModel
import com.memogame.app.services.ProgressStore
import com.memogame.app.services.RemoveAdsPromptGate
import com.memogame.app.services.StoreManager
import com.memogame.app.viewmodel.HomeViewModel

@Composable
fun HomeScreen(
    store: ProgressStore,
    storeManager: StoreManager,
    onPlayLevel: (LevelModel) -> Unit
) {
    val ds = LocalDSColors.current
    val context = LocalContext.current
    val viewModel = remember(store) { HomeViewModel(store) }
    var showRemoveAdsShowcase by remember { mutableStateOf(false) }

    // Soft Remove-Ads nudge: shown at most once, after the player has gotten
    // some value from the game (3+ completed levels). Never repeats.
    LaunchedEffect(Unit) {
        if (StoreManager.PURCHASES_ENABLED &&
            !storeManager.adsRemoved &&
            !store.hasSeenRemoveAdsPrompt &&
            store.completedLevels >= 3 &&
            !RemoveAdsPromptGate.shownToday(context)
        ) {
            store.setHasSeenRemoveAdsPrompt(true)   // mark immediately so it never nags
            RemoveAdsPromptGate.markShownToday(context)
            showRemoveAdsShowcase = true
        }
    }

    DSScreenBackground {
        // iOS parity: the dashboard is a readable-width column centered BOTH
        // ways — vertically inside the viewport (scrolls only if it overflows)
        // and horizontally capped on tablets.
        BoxWithConstraints {
            val viewportHeight = maxHeight
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Column(
                    modifier = Modifier
                        .heightIn(min = viewportHeight)
                        .widthIn(max = DS.Layout.contentMaxWidth)
                        .padding(horizontal = DS.Layout.screenPadding, vertical = DS.Spacing.lg),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(DS.Spacing.xl, Alignment.CenterVertically)
                ) {
            // Header
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(DS.Spacing.md)
            ) {
                // No elevation shadow here: under the translucent gradient fill
                // it shows through as a dark polygon plate behind the emoji.
                Box(
                    modifier = Modifier
                        .size(96.dp)
                        .background(
                            Brush.linearGradient(
                                listOf(ds.brand.copy(alpha = 0.22f), ds.accent.copy(alpha = 0.22f))
                            ),
                            CircleShape
                        )
                        .border(2.5.dp, ds.accentGradient, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text("🧠", fontSize = 44.sp)
                }
                Text(
                    APP_NAME,
                    style = DSText.largeTitle.copy(brush = ds.accentGradient),
                    textAlign = TextAlign.Center
                )
                Text(
                    "Complete a level to unlock the next one!",
                    style = DSText.callout,
                    color = ds.textSecondary,
                    textAlign = TextAlign.Center
                )
            }

            // Progress card
            Box(modifier = Modifier.widthIn(max = DS.Layout.contentMaxWidth)) {
                DSCard {
                    SectionHeader(title = "Your Journey", icon = Icons.Rounded.Map)
                    Row(horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)) {
                        StatCard(
                            value = "${viewModel.completedLevels}", label = "Completed",
                            icon = Icons.Rounded.Flag, modifier = Modifier.weight(1f)
                        )
                        StatCard(
                            value = "${viewModel.totalStars}", label = "Stars",
                            icon = Icons.Rounded.Star, tint = ds.star, modifier = Modifier.weight(1f)
                        )
                        StatCard(
                            value = "${store.goldLevels}", label = "Gold",
                            icon = Icons.Rounded.WorkspacePremium, tint = ds.warning,
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }

            // Continue card
            viewModel.suggestedLevel?.let { next ->
                ContinueCard(level = next, onClick = { onPlayLevel(next) })
            }

            // Tip of the day
            Box(modifier = Modifier.widthIn(max = DS.Layout.contentMaxWidth)) {
                DSCard {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(DS.Spacing.md)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .background(ds.star.copy(alpha = 0.16f), CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Rounded.Lightbulb, contentDescription = null, tint = ds.star)
                        }
                        Column(verticalArrangement = Arrangement.spacedBy(DS.Spacing.xxs)) {
                            Text(
                                "Tip of the Day",
                                style = DSText.caption.copy(fontWeight = FontWeight.Bold),
                                color = ds.sectionTitle
                            )
                            Text(viewModel.dailyTip, style = DSText.callout, color = ds.textSecondary)
                        }
                    }
                }
            }
                }
            }
        }
    }

    if (showRemoveAdsShowcase) {
        RemoveAdsShowcaseScreen(storeManager = storeManager, onDismiss = { showRemoveAdsShowcase = false })
    }
}

@Composable
private fun ContinueCard(level: LevelModel, onClick: () -> Unit) {
    val ds = LocalDSColors.current
    Row(
        modifier = Modifier
            .widthIn(max = DS.Layout.contentMaxWidth)
            .fillMaxWidth()
            .pressableClickable(onClick = onClick)
            .softShadow(shape = RoundedCornerShape(DS.Radius.lg), blurRadius = 12.dp, offsetY = 4.dp)
            .background(ds.ctaGradient, RoundedCornerShape(DS.Radius.lg))
            .padding(DS.Spacing.lg),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(DS.Spacing.md)
    ) {
        Icon(
            Icons.Rounded.PlayCircle,
            contentDescription = null,
            tint = Color.White,
            modifier = Modifier.size(40.dp)
        )
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(DS.Spacing.xxs)
        ) {
            Text(
                "CONTINUE",
                style = DSText.caption,
                color = Color.White.copy(alpha = 0.9f)
            )
            Text(
                level.title,
                fontSize = 22.sp,
                fontWeight = FontWeight.ExtraBold,
                color = Color.White
            )
            Text(
                level.subtitle,
                style = DSText.caption.copy(fontWeight = FontWeight.SemiBold),
                color = Color.White.copy(alpha = 0.85f),
                maxLines = 1
            )
        }
        Icon(
            Icons.Rounded.ChevronRight,
            contentDescription = null,
            tint = Color.White.copy(alpha = 0.9f)
        )
    }
}
