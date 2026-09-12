package com.memogame.app.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AccessTime
import androidx.compose.material.icons.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.material.icons.rounded.FavoriteBorder
import androidx.compose.material.icons.rounded.GridView
import androidx.compose.material.icons.rounded.Lightbulb
import androidx.compose.material.icons.rounded.Pause
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.SwapHoriz
import androidx.compose.material.icons.rounded.Timer
import androidx.compose.material.icons.rounded.TrackChanges
import androidx.compose.material.icons.rounded.Visibility
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.memogame.app.core.DS
import com.memogame.app.core.DSScreenBackground
import com.memogame.app.core.DSText
import com.memogame.app.core.DialogCard
import com.memogame.app.core.LocalDSColors
import com.memogame.app.core.PrimaryButton
import com.memogame.app.core.ProgressRing
import com.memogame.app.core.RoundIconButton
import com.memogame.app.core.pressableClickable
import com.memogame.app.core.softShadow
import com.memogame.app.data.LevelCatalog
import com.memogame.app.services.AdsManager
import com.memogame.app.services.ProgressStore
import com.memogame.app.services.StoreManager
import com.memogame.app.ui.components.BannerAdSlot
import com.memogame.app.ui.components.ConfettiOverlay
import com.memogame.app.ui.components.MemoryCard
import com.memogame.app.viewmodel.GameViewModel
import kotlinx.coroutines.delay

@Composable
fun GameScreen(
    levelNumber: Int,
    store: ProgressStore,
    storeManager: StoreManager,
    onExit: () -> Unit
) {
    val ds = LocalDSColors.current
    val context = LocalContext.current
    val level = remember(levelNumber) { LevelCatalog.level(levelNumber) ?: LevelCatalog.allLevels.first() }
    val viewModel = remember(levelNumber) { GameViewModel(level, store) }
    DisposableEffect(viewModel) {
        onDispose { viewModel.dispose() }
    }

    var showResult by remember { mutableStateOf(false) }
    var adFlowDone by remember { mutableStateOf(false) }
    var showTutorial by remember { mutableStateOf(level.levelNumber == 1 && !store.hasSeenTutorial) }

    // Level finished → maybe interstitial → result screen (mirrors iOS flow).
    LaunchedEffect(viewModel.gameFinished) {
        if (viewModel.gameFinished) {
            AdsManager.handleLevelFinished(
                activity = context.findActivity(),
                adsRemoved = storeManager.adsRemoved
            ) {
                adFlowDone = true
            }
        } else {
            adFlowDone = false
        }
    }
    LaunchedEffect(adFlowDone) {
        if (adFlowDone) {
            delay(800) // small pause so the last match animation is visible
            showResult = true
        }
    }

    BackHandler(enabled = !showResult) { onExit() }

    val activeLevel = viewModel.level
    val nextLevel = LevelCatalog.level(activeLevel.levelNumber + 1)
    val nextLevelJustUnlocked = viewModel.levelWon && nextLevel != null
    val milestoneMessage = if (viewModel.levelWon) {
        when (activeLevel.levelNumber) {
            10 -> "🔥 10 levels done — you're on a roll!"
            25 -> "⭐️ 25 levels complete — amazing!"
            50 -> "🏆 Memory Master! You beat every level!"
            else -> null
        }
    } else null

    Box(modifier = Modifier.fillMaxSize()) {
        DSScreenBackground {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .statusBarsPadding(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Top bar: back · title · pause
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = DS.Spacing.lg, vertical = DS.Spacing.sm),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RoundIconButton(
                        icon = Icons.Rounded.ArrowBack,
                        contentDescription = "Back",
                        onClick = onExit
                    )
                    Column(
                        modifier = Modifier.weight(1f),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            activeLevel.title,
                            fontWeight = FontWeight.Bold,
                            fontSize = 17.sp,
                            color = ds.textPrimary
                        )
                        Text(
                            activeLevel.subtitle,
                            style = DSText.caption2,
                            color = ds.textSecondary
                        )
                    }
                    RoundIconButton(
                        icon = if (viewModel.isPaused) Icons.Rounded.PlayArrow else Icons.Rounded.Pause,
                        contentDescription = if (viewModel.isPaused) "Resume" else "Pause",
                        onClick = { viewModel.isPaused = !viewModel.isPaused }
                    )
                }

                // HUD
                GameHud(viewModel)

                Spacer(Modifier.height(DS.Spacing.sm))

                // Preview / objective banner
                if (viewModel.isPreviewPhase) {
                    PreviewBanner(viewModel)
                } else {
                    ObjectiveBanner(
                        objective = activeLevel.objective,
                        showHint = viewModel.canUseHint && AdsManager.rewardedAdAvailable,
                        hintsRemaining = viewModel.hintsRemaining,
                        onHintClick = {
                            // Mirror iOS: hint completes the pair the player already
                            // started. On Android the reward callback fires WHILE the
                            // ad is still showing, so we reserve the partner first,
                            // pause the timer, and apply the hint only after dismiss
                            // — otherwise canUseHint/tapCard no-op and a finishing
                            // match can try to open an interstitial over the rewarded ad.
                            val partner = viewModel.reserveHintPartner() ?: return@ObjectiveBanner
                            viewModel.isPaused = true
                            var earned = false
                            AdsManager.showRewardedAd(
                                activity = context.findActivity(),
                                onReward = { earned = true },
                                onClosed = {
                                    viewModel.isPaused = false
                                    if (earned) viewModel.revealHint(partner)
                                }
                            )
                        }
                    )
                }

                // One label font size for the WHOLE grid, sized to the longest
                // label among the dealt cards — otherwise each card shrinks its
                // own text independently based on its own word length, so a
                // short word like "Dice" renders visibly bigger than "Carousel"
                // right next to it.
                // A fixed size for every card's label — NOT reduced based on
                // the longest label on the board. That tiered reduction was
                // overly cautious: on a board like "Toys" (longest label
                // "Carousel", 8 letters), it dragged EVERY card's label down
                // from 11pt to 9pt, even short ones like "Dice" that never
                // needed to shrink — 8-letter bold text fits a card's width
                // fine at 11pt without wrapping. That unnecessary shrink
                // read as the whole board's text going blurry/small.
                // MemoryCard's own maxLines + auto-shrink is still there as
                // a per-card safety net for a genuinely long label.
                val cardLabelFontSize = if (viewModel.accessibilityLargeText) 14f else 11f

                // Card grid — sized to fit BOTH width and remaining height.
                BoxWithConstraints(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .padding(horizontal = DS.Layout.screenPadding),
                    contentAlignment = Alignment.Center
                ) {
                    val spacing = DS.Spacing.sm
                    val cols = viewModel.columns
                    val rows = viewModel.rows
                    val widthBased = (maxWidth - spacing * (cols - 1)) / cols
                    val heightBased = ((maxHeight - spacing * (rows - 1)) / rows) / 1.15f
                    val cardSize = minOf(widthBased, heightBased, 200.dp).coerceAtLeast(44.dp)

                    Column(verticalArrangement = Arrangement.spacedBy(spacing)) {
                        for (row in 0 until rows) {
                            Row(horizontalArrangement = Arrangement.spacedBy(spacing)) {
                                for (col in 0 until cols) {
                                    val index = row * cols + col
                                    val card = viewModel.cards.getOrNull(index) ?: continue
                                    MemoryCard(
                                        card = card,
                                        size = cardSize,
                                        largeText = viewModel.accessibilityLargeText,
                                        highContrast = viewModel.highContrast,
                                        colorBlindMode = viewModel.colorBlindMode,
                                        cardBackStyle = store.cardBackStyle,
                                        labelFontSize = cardLabelFontSize
                                    ) {
                                        if (viewModel.canInteract) viewModel.tapCard(index)
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer(Modifier.height(DS.Spacing.md))

                // iOS parity: banner lives only on the game screen (GameView's
                // safeAreaInset), never on Home / Awards / Settings.
                BannerAdSlot(
                    adsRemoved = storeManager.adsRemoved,
                    modifier = Modifier.navigationBarsPadding()
                )
            }
        }

        if (viewModel.showConfetti) {
            ConfettiOverlay(isActive = true, modifier = Modifier.fillMaxSize())
        }

        if (viewModel.isPaused && !showResult) {
            DialogCard {
                Icon(
                    Icons.Rounded.Pause,
                    contentDescription = null,
                    tint = ds.brand,
                    modifier = Modifier.size(56.dp)
                )
                Text("Paused", style = DSText.title.copy(fontSize = 24.sp), color = ds.textPrimary)
                PrimaryButton(title = "Resume", gradient = ds.ctaGradient) {
                    viewModel.isPaused = false
                }
            }
        }

        if (showTutorial) {
            DialogCard {
                Text("👋", fontSize = 54.sp)
                Text("How to play", style = DSText.title.copy(fontSize = 24.sp), color = ds.textPrimary)
                Text(
                    "Tap two cards to flip them over and find the matching pairs. Match them all to win!",
                    style = DSText.body,
                    color = ds.textSecondary,
                    textAlign = TextAlign.Center
                )
                PrimaryButton(title = "Got it!", gradient = ds.ctaGradient) {
                    showTutorial = false
                    store.setHasSeenTutorial(true)
                }
            }
        }

        if (showResult) {
            ResultScreen(
                levelTitle = viewModel.level.title,
                levelWon = viewModel.levelWon,
                matchedPairs = viewModel.matchedPairs,
                totalPairs = viewModel.totalPairs,
                stars = viewModel.earnedStars,
                moves = viewModel.moves,
                elapsed = viewModel.elapsed,
                accuracy = viewModel.accuracy,
                maxCombo = viewModel.maxCombo,
                bestTime = viewModel.bestTime,
                isNewBestTime = viewModel.isNewBestTime,
                lossReasonText = viewModel.lossReasonText,
                milestoneText = milestoneMessage,
                nextLevelUnlocked = nextLevelJustUnlocked,
                nextLevelTitle = nextLevel?.title,
                eligibleForReviewPrompt = store.completedLevels >= 5,
                onPlayAgain = {
                    showResult = false
                    viewModel.reset()
                },
                onWatchAdToContinue = if (viewModel.canWatchAdToContinue && AdsManager.rewardedAdAvailable) {
                    {
                        AdsManager.showRewardedAd(
                            activity = context.findActivity(),
                            onReward = {
                                viewModel.continueAfterAd()
                                showResult = false
                            },
                            onClosed = {}
                        )
                    }
                } else null,
                onNextLevel = if (nextLevelJustUnlocked) {
                    {
                        val next = nextLevel
                        if (next != null) {
                            showResult = false
                            viewModel.loadLevel(next)
                        }
                    }
                } else null,
                onHome = {
                    showResult = false
                    onExit()
                }
            )
        }

        // While a full-screen ad is up, blank the game UI completely — the ad
        // activity leaves the status-bar strip transparent, so without this
        // the back button / level title peek through above the ad.
        if (AdsManager.fullScreenAdShowing) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(ds.screen)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null
                    ) {}
            )
        }
    }
}

// MARK: - HUD

@Composable
private fun GameHud(viewModel: GameViewModel) {
    val ds = LocalDSColors.current
    Column(
        modifier = Modifier
            .widthIn(max = DS.Layout.contentMaxWidth)
            .fillMaxWidth()
            .padding(horizontal = DS.Spacing.lg)
            .softShadow(shape = RoundedCornerShape(DS.Radius.lg), blurRadius = 8.dp, offsetY = 2.dp)
            .background(ds.surface, RoundedCornerShape(DS.Radius.lg))
            .padding(DS.Spacing.sm + 2.dp),
        verticalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)) {
            val showsMoves = viewModel.rules.showsMoveCounter || viewModel.rules.maxMoves != null
            if (showsMoves) {
                val movesText = viewModel.rules.maxMoves?.let { "${viewModel.moves}/$it" }
                    ?: "${viewModel.moves}"
                HudTile(
                    icon = Icons.Rounded.SwapHoriz, tint = ds.brand,
                    label = "Moves", value = movesText,
                    modifier = Modifier.weight(1f)
                )
            }
            HudTile(
                icon = if (viewModel.rules.hasTimer) Icons.Rounded.Timer else Icons.Rounded.AccessTime,
                tint = ds.accent,
                label = if (viewModel.rules.hasTimer) "Time left" else "Time",
                value = if (viewModel.rules.hasTimer) {
                    formatTime(viewModel.remainingTime)
                } else {
                    formatTime(viewModel.elapsed.toInt())
                },
                modifier = Modifier.weight(1f)
            )
            HudTile(
                icon = Icons.Rounded.GridView, tint = ds.success,
                label = "Pairs", value = "${viewModel.matchedPairs}/${viewModel.totalPairs}",
                modifier = Modifier.weight(1f)
            )
        }

        if (viewModel.livesEnabled) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Lives", style = DSText.caption, color = ds.textSecondary)
                Spacer(Modifier.width(DS.Spacing.sm))
                repeat(viewModel.maxLives) { index ->
                    val alive = index < viewModel.livesRemaining
                    Icon(
                        if (alive) Icons.Rounded.Favorite else Icons.Rounded.FavoriteBorder,
                        contentDescription = null,
                        tint = if (alive) ds.danger else ds.track,
                        modifier = Modifier
                            .padding(horizontal = 2.dp)
                            .size(16.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun HudTile(
    icon: ImageVector,
    tint: Color,
    label: String,
    value: String,
    modifier: Modifier = Modifier
) {
    val ds = LocalDSColors.current
    Column(
        modifier = modifier
            .background(tint.copy(alpha = 0.1f), RoundedCornerShape(DS.Radius.sm))
            .padding(vertical = DS.Spacing.sm + 2.dp, horizontal = DS.Spacing.xs),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(DS.Spacing.xs)
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(18.dp))
        Text(label, fontSize = 10.sp, fontWeight = FontWeight.Medium, color = ds.textSecondary, maxLines = 1)
        Text(value, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = ds.textPrimary, maxLines = 1)
    }
}

@Composable
private fun ObjectiveBanner(
    objective: String,
    showHint: Boolean,
    hintsRemaining: Int,
    onHintClick: () -> Unit
) {
    val ds = LocalDSColors.current
    Row(
        modifier = Modifier
            .widthIn(max = DS.Layout.contentMaxWidth)
            .fillMaxWidth()
            .padding(horizontal = DS.Spacing.lg)
            .background(ds.brand.copy(alpha = 0.12f), RoundedCornerShape(DS.Radius.sm))
            .padding(horizontal = DS.Spacing.md, vertical = DS.Spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm)
    ) {
        Icon(
            Icons.Rounded.TrackChanges,
            contentDescription = null,
            tint = ds.brand,
            modifier = Modifier.size(16.dp)
        )
        Text(
            objective,
            style = DSText.caption.copy(fontWeight = FontWeight.SemiBold),
            color = ds.textPrimary,
            maxLines = 2,
            modifier = Modifier.weight(1f)
        )
        // Always laid out (never conditionally inserted/removed) — an `if`
        // here made the objective text reflow to a different number of
        // lines depending on whether the chip was competing for width,
        // which changed the WHOLE banner's height every time hint
        // availability toggled (i.e. constantly during play). Hiding via
        // alpha keeps the reserved width constant either way.
        Row(
            modifier = Modifier
                .alpha(if (showHint) 1f else 0f)
                .pressableClickable(enabled = showHint, onClick = onHintClick)
                .background(ds.warning.copy(alpha = 0.18f), RoundedCornerShape(percent = 50))
                .padding(horizontal = DS.Spacing.sm + 2.dp, vertical = DS.Spacing.xs + 2.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(DS.Spacing.xs)
        ) {
            Icon(
                Icons.Rounded.Lightbulb,
                contentDescription = null,
                tint = ds.warning,
                modifier = Modifier.size(14.dp)
            )
            // Always a single digit (max 4 hints) — the count showing or
            // changing never affects this chip's width/height.
            Text(
                "Hint ×${maxOf(1, hintsRemaining)}",
                style = DSText.caption2.copy(fontWeight = FontWeight.Bold),
                color = ds.warning
            )
        }
    }
}

@Composable
private fun PreviewBanner(viewModel: GameViewModel) {
    val ds = LocalDSColors.current
    val progress = if (viewModel.rules.previewSeconds > 0) {
        viewModel.previewSecondsLeft.toFloat() / viewModel.rules.previewSeconds.toFloat()
    } else 0f

    Row(
        modifier = Modifier
            .widthIn(max = DS.Layout.contentMaxWidth)
            .fillMaxWidth()
            .padding(horizontal = DS.Spacing.lg)
            .softShadow(shape = RoundedCornerShape(DS.Radius.lg), blurRadius = 8.dp, offsetY = 2.dp)
            .background(ds.surface, RoundedCornerShape(DS.Radius.lg))
            .padding(DS.Spacing.lg - 2.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(DS.Spacing.lg - 2.dp)
    ) {
        ProgressRing(
            progress = progress,
            modifier = Modifier.size(76.dp),
            colors = listOf(ds.warning, ds.accent, ds.brand)
        ) {
            Text(
                "${viewModel.previewSecondsLeft}",
                style = DSText.timer,
                color = ds.textPrimary
            )
        }

        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(DS.Spacing.sm)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(DS.Spacing.xs + 2.dp)
            ) {
                Icon(
                    Icons.Rounded.Visibility,
                    contentDescription = null,
                    tint = ds.brand,
                    modifier = Modifier.size(18.dp)
                )
                Text(
                    "Memorize!",
                    style = DSText.headline.copy(brush = ds.accentGradient)
                )
            }
            Text(
                viewModel.level.objective,
                style = DSText.caption,
                color = ds.textSecondary
            )
        }
    }
}

private fun formatTime(seconds: Int): String = "%d:%02d".format(seconds / 60, seconds % 60)
