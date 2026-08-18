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
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AutoAwesome
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.material.icons.rounded.FlashOff
import androidx.compose.material.icons.rounded.HeartBroken
import androidx.compose.material.icons.rounded.Verified
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.memogame.app.core.APP_NAME
import com.memogame.app.core.DS
import com.memogame.app.core.DSScreenBackground
import com.memogame.app.core.DSText
import com.memogame.app.core.LocalDSColors
import com.memogame.app.core.PrimaryButton
import com.memogame.app.core.RoundIconButton
import com.memogame.app.core.pressableClickable
import com.memogame.app.core.softShadow
import com.memogame.app.services.StoreManager

/**
 * Premium, benefit-led "Remove Ads" showcase — shown as the one-time milestone
 * nudge and the once-a-day reminder. Always dismissible, and any purchase
 * routes through the parental gate.
 */
@Composable
fun RemoveAdsShowcaseScreen(storeManager: StoreManager, onDismiss: () -> Unit) {
    val ds = LocalDSColors.current
    val context = LocalContext.current
    var showParentalGate by remember { mutableStateOf(false) }

    // Auto-dismiss the moment the purchase lands.
    LaunchedEffect(storeManager.adsRemoved) {
        if (storeManager.adsRemoved) onDismiss()
    }

    // Re-fetch the price every time this screen shows, not just at app launch.
    LaunchedEffect(Unit) {
        if (storeManager.removeAdsProduct == null) storeManager.loadProduct()
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        DSScreenBackground {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .statusBarsPadding()
                    .navigationBarsPadding()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = DS.Layout.screenPadding),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Close button
                Row(modifier = Modifier.fillMaxWidth().padding(top = DS.Spacing.sm)) {
                    Spacer(Modifier.weight(1f))
                    RoundIconButton(
                        icon = Icons.Rounded.Close,
                        contentDescription = "Close",
                        tint = ds.textSecondary,
                        size = 36.dp,
                        onClick = onDismiss
                    )
                }

                Spacer(Modifier.height(DS.Spacing.xxl))

                // Hero
                Box(contentAlignment = Alignment.Center) {
                    Box(
                        modifier = Modifier
                            .size(200.dp)
                            .background(
                                Brush.radialGradient(
                                    listOf(ds.accent.copy(alpha = 0.5f), ds.accent.copy(alpha = 0f))
                                ),
                                CircleShape
                            )
                    )
                    Box(
                        modifier = Modifier
                            .size(108.dp)
                            .softShadow(shape = CircleShape, blurRadius = 14.dp, offsetY = 4.dp)
                            .background(ds.accentGradient, CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Rounded.AutoAwesome,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(46.dp)
                        )
                    }
                }

                Spacer(Modifier.height(DS.Spacing.lg))

                Text(
                    "Go Ad-Free",
                    style = DSText.largeTitle.copy(brush = ds.accentGradient),
                    textAlign = TextAlign.Center
                )
                Spacer(Modifier.height(DS.Spacing.xs))
                Text(
                    "Unlock the calmest way to play $APP_NAME.",
                    style = DSText.callout,
                    color = ds.textSecondary,
                    textAlign = TextAlign.Center
                )

                Spacer(Modifier.height(DS.Spacing.xl))

                Column(verticalArrangement = Arrangement.spacedBy(DS.Spacing.md)) {
                    FeatureRow(
                        Icons.Rounded.FlashOff, ds.brand, "No Interruptions",
                        "Play level after level without a single ad break."
                    )
                    FeatureRow(
                        Icons.Rounded.Favorite, ds.accent, "Support the Game",
                        "Your purchase directly funds new levels and features."
                    )
                    FeatureRow(
                        Icons.Rounded.Verified, ds.success, "Pay Once, Keep Forever",
                        "No subscription — a single purchase, forever ad-free."
                    )
                }

                Spacer(Modifier.height(DS.Spacing.xxl))

                Column(verticalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)) {
                    StoreStatusBanner(storeManager)

                    PrimaryButton(
                        title = storeManager.removeAdsButtonTitle,
                        icon = Icons.Rounded.HeartBroken,
                        gradient = ds.accentGradient,
                        enabled = !storeManager.isWorking
                    ) {
                        storeManager.clearStatus()
                        showParentalGate = true
                    }

                    // No "Restore Purchases" on Android — Play Billing restores
                    // the entitlement automatically.
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            "Not Now",
                            style = DSText.caption,
                            color = ds.textSecondary,
                            modifier = Modifier
                                .defaultMinSize(minHeight = 36.dp)
                                .pressableClickable { onDismiss() }
                                .padding(DS.Spacing.sm)
                        )
                    }
                }

                Spacer(Modifier.height(DS.Spacing.xl))
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
