package com.memogame.app.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AccessTime
import androidx.compose.material.icons.rounded.ArrowForward
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.LockOpen
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Replay
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.StarOutline
import androidx.compose.material.icons.rounded.SwapHoriz
import androidx.compose.material.icons.rounded.TrackChanges
import androidx.compose.material.icons.rounded.Videocam
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.memogame.app.core.DS
import com.memogame.app.core.DSCard
import com.memogame.app.core.DSScreenBackground
import com.memogame.app.core.DSText
import com.memogame.app.core.LocalDSColors
import com.memogame.app.core.PrimaryButton
import com.memogame.app.core.StatCard
import com.memogame.app.core.pressableClickable
import com.memogame.app.services.ReviewPromptGate
import com.memogame.app.ui.components.ConfettiOverlay
import kotlinx.coroutines.delay

@Composable
fun ResultScreen(
    levelTitle: String,
    levelWon: Boolean,
    matchedPairs: Int,
    totalPairs: Int,
    stars: Int,
    moves: Int,
    elapsed: Double,
    accuracy: Int,
    maxCombo: Int,
    bestTime: Double,
    isNewBestTime: Boolean,
    lossReasonText: String?,
    milestoneText: String?,
    nextLevelUnlocked: Boolean,
    nextLevelTitle: String?,
    eligibleForReviewPrompt: Boolean,
    onPlayAgain: () -> Unit,
    onWatchAdToContinue: (() -> Unit)?,
    onNextLevel: (() -> Unit)?,
    onHome: () -> Unit
) {
    val ds = LocalDSColors.current
    val context = LocalContext.current

    // Fires the Play in-app rating prompt a moment after a celebratory win,
    // once the player has earned enough good moments. The gate self-limits.
    LaunchedEffect(Unit) {
        if (levelWon && eligibleForReviewPrompt && ReviewPromptGate.shouldRequest(context)) {
            ReviewPromptGate.markRequested(context)
            delay(1200)
            context.findActivity()?.let { ReviewPromptGate.launchReview(it) }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        DSScreenBackground {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .statusBarsPadding()
                    .navigationBarsPadding()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = DS.Layout.screenPadding)
                    .padding(top = DS.Spacing.xl, bottom = DS.Spacing.xxxl),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(DS.Spacing.lg)
            ) {
                // Hero card
                Box(modifier = Modifier.widthIn(max = DS.Layout.contentMaxWidth)) {
                    DSCard(padding = DS.Spacing.xl) {
                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(DS.Spacing.md)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                if (levelWon) {
                                    Box(
                                        modifier = Modifier
                                            .size(170.dp)
                                            .background(
                                                Brush.radialGradient(
                                                    listOf(ds.star.copy(alpha = 0.55f), ds.star.copy(alpha = 0f))
                                                ),
                                                CircleShape
                                            )
                                    )
                                }
                                Text(if (levelWon) "🎉" else "😅", fontSize = 60.sp)
                            }

                            Text(
                                if (levelWon) "Level Complete!" else "Game Over!",
                                style = DSText.title.copy(
                                    brush = if (levelWon) ds.accentGradient else ds.ctaGradient
                                ),
                                textAlign = TextAlign.Center
                            )

                            if (!levelWon && totalPairs > 0) {
                                Text(
                                    "Matched $matchedPairs of $totalPairs pairs",
                                    style = DSText.subheadline,
                                    color = ds.textSecondary
                                )
                            }

                            Text(
                                levelTitle,
                                style = DSText.subheadline,
                                color = ds.textSecondary,
                                modifier = Modifier
                                    .background(ds.fill, CircleShape)
                                    .padding(horizontal = DS.Spacing.md + 2.dp, vertical = DS.Spacing.xs + 2.dp)
                            )

                            Row(horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)) {
                                repeat(3) { i ->
                                    Icon(
                                        if (i < stars) Icons.Rounded.Star else Icons.Rounded.StarOutline,
                                        contentDescription = null,
                                        tint = if (i < stars) ds.star else ds.track,
                                        modifier = Modifier.size(40.dp)
                                    )
                                }
                            }
                        }
                    }
                }

                // Milestone banner
                if (levelWon && milestoneText != null) {
                    Text(
                        milestoneText,
                        style = DSText.headline.copy(fontSize = 18.sp),
                        color = Color.White,
                        textAlign = TextAlign.Center,
                        modifier = Modifier
                            .widthIn(max = DS.Layout.contentMaxWidth)
                            .fillMaxWidth()
                            .background(ds.accentGradient, RoundedCornerShape(DS.Radius.md))
                            .padding(DS.Spacing.lg)
                    )
                }

                // Unlock / loss banner
                if (nextLevelUnlocked && nextLevelTitle != null) {
                    Row(
                        modifier = Modifier
                            .widthIn(max = DS.Layout.contentMaxWidth)
                            .fillMaxWidth()
                            .background(ds.success.copy(alpha = 0.15f), RoundedCornerShape(DS.Radius.md))
                            .padding(DS.Spacing.lg - 2.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)
                    ) {
                        Icon(Icons.Rounded.LockOpen, contentDescription = null, tint = ds.success)
                        Text(
                            "$nextLevelTitle is now unlocked!",
                            style = DSText.subheadline.copy(fontWeight = FontWeight.Bold),
                            color = ds.textPrimary
                        )
                    }
                } else if (!levelWon) {
                    Row(
                        modifier = Modifier
                            .widthIn(max = DS.Layout.contentMaxWidth)
                            .fillMaxWidth()
                            .background(ds.warning.copy(alpha = 0.15f), RoundedCornerShape(DS.Radius.md))
                            .padding(DS.Spacing.lg - 2.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)
                    ) {
                        Icon(Icons.Rounded.Replay, contentDescription = null, tint = ds.warning)
                        Text(
                            lossReasonText ?: "Out of moves — play again to match all the pairs!",
                            style = DSText.caption.copy(fontWeight = FontWeight.SemiBold),
                            color = ds.textSecondary
                        )
                    }
                }

                // Stats
                Box(modifier = Modifier.widthIn(max = DS.Layout.contentMaxWidth)) {
                    DSCard {
                        Row(horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)) {
                            StatCard(
                                value = "$moves", label = "Moves",
                                icon = Icons.Rounded.SwapHoriz,
                                horizontal = true, modifier = Modifier.weight(1f)
                            )
                            StatCard(
                                value = formatElapsed(elapsed), label = "Time",
                                icon = Icons.Rounded.AccessTime, tint = ds.accent,
                                horizontal = true, modifier = Modifier.weight(1f)
                            )
                        }
                        Row(horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)) {
                            StatCard(
                                value = "$accuracy%", label = "Accuracy",
                                icon = Icons.Rounded.TrackChanges, tint = ds.success,
                                horizontal = true, modifier = Modifier.weight(1f)
                            )
                            StatCard(
                                value = "×$maxCombo", label = "Combo",
                                icon = Icons.Rounded.LocalFireDepartment, tint = ds.warning,
                                horizontal = true, modifier = Modifier.weight(1f)
                            )
                        }

                        // Only shown when the player beats their record.
                        if (levelWon && isNewBestTime && bestTime > 0) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .background(ds.star.copy(alpha = 0.15f), RoundedCornerShape(DS.Radius.md))
                                    .padding(horizontal = DS.Spacing.md, vertical = DS.Spacing.sm + 2.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)
                            ) {
                                Icon(Icons.Rounded.EmojiEvents, contentDescription = null, tint = ds.star)
                                Text(
                                    "New Best Time!",
                                    style = DSText.subheadline.copy(fontWeight = FontWeight.Bold),
                                    color = ds.textPrimary
                                )
                                Spacer(Modifier.weight(1f))
                                Text(
                                    formatElapsed(bestTime),
                                    style = DSText.subheadline.copy(fontWeight = FontWeight.ExtraBold),
                                    color = ds.star
                                )
                            }
                        }
                    }
                }

                // Actions
                Column(
                    modifier = Modifier.widthIn(max = DS.Layout.contentMaxWidth),
                    verticalArrangement = Arrangement.spacedBy(DS.Spacing.md)
                ) {
                    if (!levelWon && onWatchAdToContinue != null) {
                        PrimaryButton(
                            title = "Watch Ad to Continue", icon = Icons.Rounded.Videocam,
                            gradient = ds.accentGradient, onClick = onWatchAdToContinue
                        )
                    }
                    if (nextLevelUnlocked && onNextLevel != null) {
                        PrimaryButton(
                            title = "Next Level", icon = Icons.Rounded.ArrowForward,
                            gradient = ds.accentGradient, onClick = onNextLevel
                        )
                    }
                    PrimaryButton(
                        title = "Play Again", icon = Icons.Rounded.Refresh,
                        gradient = ds.ctaGradient, onClick = onPlayAgain
                    )
                    Text(
                        "Back to Home",
                        style = DSText.button,
                        color = ds.link,
                        textAlign = TextAlign.Center,
                        modifier = Modifier
                            .fillMaxWidth()
                            .defaultMinSize(minHeight = 44.dp)
                            .pressableClickable { onHome() }
                            .padding(vertical = DS.Spacing.sm)
                    )
                }
            }
        }

        if (levelWon) {
            ConfettiOverlay(isActive = true, modifier = Modifier.fillMaxSize())
        }
    }
}

private fun formatElapsed(t: Double): String {
    val s = t.toInt()
    return "%d:%02d".format(s / 60, s % 60)
}
