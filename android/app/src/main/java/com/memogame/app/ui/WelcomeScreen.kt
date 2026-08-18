package com.memogame.app.ui

import androidx.compose.animation.Crossfade
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ArrowForward
import androidx.compose.material.icons.rounded.GridView
import androidx.compose.material.icons.rounded.HeartBroken
import androidx.compose.material.icons.rounded.LockOpen
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.memogame.app.core.APP_NAME
import com.memogame.app.core.DS
import com.memogame.app.core.DSCard
import com.memogame.app.core.DSScreenBackground
import com.memogame.app.core.DSText
import com.memogame.app.core.LocalDSColors
import com.memogame.app.core.PrimaryButton
import com.memogame.app.core.pressableClickable
import com.memogame.app.services.StoreManager

/**
 * One-time first-launch onboarding: a quick "how it works" page, then a
 * skippable "go ad-free" page.
 */
@Composable
fun WelcomeScreen(storeManager: StoreManager, onFinish: () -> Unit) {
    val ds = LocalDSColors.current
    var page by remember { mutableIntStateOf(0) }
    var showParentalGate by remember { mutableStateOf(false) }
    val context = LocalContext.current

    DSScreenBackground {
        // enableEdgeToEdge() draws behind the system nav bar, so without this
        // inset the Next button on page 1 sits partly hidden behind it.
        Column(modifier = Modifier.fillMaxSize().navigationBarsPadding()) {
            Crossfade(targetState = page, label = "welcomePage", modifier = Modifier.weight(1f)) { current ->
                if (current == 0) {
                    // With purchases disabled this build, there is no ad-free
                    // pitch page — Next finishes onboarding directly.
                    WelcomePage(onNext = {
                        if (StoreManager.PURCHASES_ENABLED) page = 1 else onFinish()
                    })
                } else {
                    RemoveAdsPage(storeManager, onFinish, onBuy = { showParentalGate = true })
                }
            }

            // Page indicator (only meaningful when there are two pages)
            if (StoreManager.PURCHASES_ENABLED) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = DS.Spacing.lg),
                    horizontalArrangement = Arrangement.Center
                ) {
                    repeat(2) { index ->
                        Box(
                            modifier = Modifier
                                .padding(horizontal = DS.Spacing.xs)
                                .size(8.dp)
                                .background(
                                    if (index == page) ds.brand else ds.textSecondary.copy(alpha = 0.35f),
                                    CircleShape
                                )
                        )
                    }
                }
            } else {
                Spacer(Modifier.height(DS.Spacing.lg))
            }
        }
    }

    if (showParentalGate) {
        ParentalGateDialog(
            onDismiss = { showParentalGate = false },
            onPass = {
                showParentalGate = false
                context.findActivity()?.let { storeManager.purchaseRemoveAds(it) }
            }
        )
    }
}

@Composable
private fun WelcomePage(onNext: () -> Unit) {
    val ds = LocalDSColors.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = DS.Layout.screenPadding, vertical = DS.Spacing.xxl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(DS.Spacing.xl)
    ) {
        // Flexible spacers above AND below keep the content vertically centered
        // between the top and the Next button — same as the iOS Spacer pair.
        Spacer(Modifier.weight(1f))

        Box(
            modifier = Modifier
                .size(112.dp)
                .background(
                    Brush.linearGradient(
                        listOf(ds.brand.copy(alpha = 0.22f), ds.accent.copy(alpha = 0.22f))
                    ),
                    CircleShape
                )
                .border(2.5.dp, ds.accentGradient, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Text("🧠", fontSize = 52.sp)
        }

        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(DS.Spacing.sm)) {
            Text(
                "Welcome to $APP_NAME",
                style = DSText.largeTitle.copy(brush = ds.accentGradient),
                textAlign = TextAlign.Center
            )
            Text(
                "Train your memory with delightful, bite-sized levels.",
                style = DSText.callout,
                color = ds.textSecondary,
                textAlign = TextAlign.Center
            )
        }

        Column(verticalArrangement = Arrangement.spacedBy(DS.Spacing.md)) {
            FeatureRow(Icons.Rounded.GridView, ds.brand, "Flip & Match",
                "Find every matching pair to clear a level.")
            FeatureRow(Icons.Rounded.Star, ds.star, "Earn Stars",
                "Finish fast with few moves to earn 3 stars.")
            FeatureRow(Icons.Rounded.LockOpen, ds.success, "Unlock Levels",
                "Beat a level to open the next challenge.")
        }

        Spacer(Modifier.weight(1f))

        PrimaryButton(title = "Next", icon = Icons.Rounded.ArrowForward, onClick = onNext)
    }
}

@Composable
private fun RemoveAdsPage(
    storeManager: StoreManager,
    onFinish: () -> Unit,
    onBuy: () -> Unit
) {
    val ds = LocalDSColors.current
    val adsRemoved = storeManager.adsRemoved

    val subtitle = if (adsRemoved) {
        "Your Remove Ads purchase is active. Enjoy uninterrupted play!"
    } else {
        storeManager.removeAdsDisplayPrice?.let {
            "One-time purchase — $it. Remove all ads and keep the focus on play. You can always do this later in Settings."
        } ?: "Remove all ads with a one-time purchase and keep the focus on play. You can always do this later in Settings."
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = DS.Layout.screenPadding, vertical = DS.Spacing.xxl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(DS.Spacing.xl)
    ) {
        // Same flexible-spacer pair as page 1 → content vertically centered.
        Spacer(Modifier.weight(1f))

        Box(
            modifier = Modifier
                .size(112.dp)
                .background(ds.accent.copy(alpha = 0.16f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                if (adsRemoved) Icons.Rounded.Verified else Icons.Rounded.HeartBroken,
                contentDescription = null,
                tint = if (adsRemoved) ds.success else ds.accent,
                modifier = Modifier.size(48.dp)
            )
        }

        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(DS.Spacing.sm)) {
            Text(
                if (adsRemoved) "You're Ad-Free!" else "Play Ad-Free",
                style = DSText.title.copy(brush = ds.accentGradient),
                textAlign = TextAlign.Center
            )
            Text(subtitle, style = DSText.callout, color = ds.textSecondary, textAlign = TextAlign.Center)
        }

        Spacer(Modifier.weight(1f))

        Column(verticalArrangement = Arrangement.spacedBy(DS.Spacing.sm)) {
            if (adsRemoved) {
                PrimaryButton(title = "Continue", icon = Icons.Rounded.ArrowForward, onClick = onFinish)
            } else {
                StoreStatusBanner(storeManager)

                PrimaryButton(
                    title = storeManager.removeAdsButtonTitle,
                    icon = Icons.Rounded.HeartBroken,
                    enabled = !storeManager.isWorking,
                    onClick = onBuy
                )

                // No "Restore Purchases" on Android — Play Billing restores the
                // entitlement automatically when the app connects.
                Text(
                    "Skip for now",
                    style = DSText.button,
                    color = ds.textSecondary,
                    modifier = Modifier
                        .fillMaxWidth()
                        .defaultMinSize(minHeight = 44.dp)
                        .pressableClickable { onFinish() }
                        .padding(vertical = DS.Spacing.sm),
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

@Composable
fun FeatureRow(icon: ImageVector, tint: Color, title: String, subtitle: String) {
    val ds = LocalDSColors.current
    DSCard(padding = DS.Spacing.md) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(DS.Spacing.md)
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(tint.copy(alpha = 0.16f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(22.dp))
            }
            Column(verticalArrangement = Arrangement.spacedBy(DS.Spacing.xxs)) {
                Text(title, style = DSText.body.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = ds.textPrimary)
                Text(subtitle, style = DSText.caption, color = ds.textSecondary)
            }
        }
    }
}

/** Inline purchase / restore feedback for Remove Ads screens. */
@Composable
fun StoreStatusBanner(storeManager: StoreManager) {
    val ds = LocalDSColors.current
    val message = storeManager.statusMessage ?: return
    if (message.isEmpty()) return
    val isError = storeManager.isStatusError

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                (if (isError) ds.danger else ds.brand).copy(alpha = 0.12f),
                androidx.compose.foundation.shape.RoundedCornerShape(DS.Radius.md)
            )
            .padding(DS.Spacing.md),
        horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm)
    ) {
        Icon(
            Icons.Rounded.Verified,
            contentDescription = null,
            tint = if (isError) ds.danger else ds.brand,
            modifier = Modifier.size(18.dp)
        )
        Text(
            message,
            style = DSText.caption,
            color = if (isError) ds.danger else ds.textSecondary
        )
    }
}
