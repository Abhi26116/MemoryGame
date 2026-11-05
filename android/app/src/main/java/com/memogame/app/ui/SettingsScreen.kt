package com.memogame.app.ui

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Accessibility
import androidx.compose.material.icons.rounded.BarChart
import androidx.compose.material.icons.rounded.Brush
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.ChevronRight
import androidx.compose.material.icons.rounded.Contrast
import androidx.compose.material.icons.rounded.DarkMode
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.FormatListNumbered
import androidx.compose.material.icons.rounded.GridView
import androidx.compose.material.icons.rounded.HeartBroken
import androidx.compose.material.icons.rounded.Info
import androidx.compose.material.icons.rounded.Language
import androidx.compose.material.icons.rounded.LightMode
import androidx.compose.material.icons.rounded.Notifications
import androidx.compose.material.icons.rounded.OpenInNew
import androidx.compose.material.icons.rounded.PhoneAndroid
import androidx.compose.material.icons.rounded.PrivacyTip
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.RemoveRedEye
import androidx.compose.material.icons.rounded.SportsEsports
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.Storage
import androidx.compose.material.icons.rounded.TextFields
import androidx.compose.material.icons.rounded.TouchApp
import androidx.compose.material.icons.rounded.Translate
import androidx.compose.material.icons.rounded.VolumeUp
import androidx.compose.material.icons.rounded.WorkspacePremium
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.memogame.app.core.APP_NAME
import com.memogame.app.core.DS
import com.memogame.app.core.DSCard
import com.memogame.app.core.DSScreenBackground
import com.memogame.app.core.DSText
import com.memogame.app.core.InlineTitleBar
import com.memogame.app.core.L10n
import com.memogame.app.core.LocalDSColors
import com.memogame.app.core.SectionHeader
import com.memogame.app.core.StatCard
import com.memogame.app.core.cardBackBrush
import com.memogame.app.core.pressableClickable
import com.memogame.app.core.tr
import com.memogame.app.engine.StarRatingRules
import com.memogame.app.model.AppearanceMode
import com.memogame.app.model.CardBackStyle
import com.memogame.app.services.AdsManager
import com.memogame.app.services.ConsentManager
import com.memogame.app.services.GameAudio
import com.memogame.app.services.ProgressStore
import com.memogame.app.services.ReminderScheduler
import com.memogame.app.services.StoreManager

@Composable
fun SettingsScreen(
    store: ProgressStore,
    storeManager: StoreManager,
    onOpenLevels: () -> Unit
) {
    val ds = LocalDSColors.current
    val context = LocalContext.current
    var showResetAlert by remember { mutableStateOf(false) }
    var showParentalGate by remember { mutableStateOf(false) }
    var showNotifDeniedAlert by remember { mutableStateOf(false) }
    var showLanguagePicker by remember { mutableStateOf(false) }
    var showPrivacyOptions by remember { mutableStateOf(false) }

    // Keyed on isReady so this re-reads once the launch consent flow settles —
    // it may still have been in flight when this screen was first composed.
    LaunchedEffect(AdsManager.isReady) {
        showPrivacyOptions = ConsentManager.privacyOptionsRequired(context)
    }

    val notificationPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            store.setRemindersEnabled(true)
            ReminderScheduler.scheduleReminders(context)
        } else {
            store.setRemindersEnabled(false)
            showNotifDeniedAlert = true
        }
    }

    DSScreenBackground {
        // iOS large-title behaviour: the big "Settings" scrolls away and a
        // small centered title fades into the pinned bar (see iOS recording).
        val scrollState = rememberScrollState()
        val collapseThresholdPx = with(LocalDensity.current) { 40.dp.toPx() }
        val collapsedFraction = (scrollState.value / collapseThresholdPx).coerceIn(0f, 1f)

        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            InlineTitleBar(title = tr("Settings"), alpha = collapsedFraction)
            Column(
                modifier = Modifier
                    .widthIn(max = DS.Layout.contentMaxWidth)
                    .weight(1f)
                    .verticalScroll(scrollState)
                    .padding(horizontal = DS.Layout.screenPadding)
                    .padding(bottom = DS.Spacing.lg),
                verticalArrangement = Arrangement.spacedBy(DS.Spacing.xl)
            ) {
                Text(
                    tr("Settings"),
                    style = DSText.title.copy(fontSize = 24.sp),
                    color = ds.textPrimary,
                    modifier = Modifier.graphicsLayer { alpha = 1f - collapsedFraction }
                )

            // Your Progress
            DSCard {
                SectionHeader(tr("Your Progress"), Icons.Rounded.BarChart)
                Row(horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)) {
                    StatCard("${store.completedLevels}", tr("Done"), Icons.Rounded.CheckCircle, Modifier.weight(1f))
                    StatCard("${store.totalStars}", tr("Stars"), Icons.Rounded.Star, Modifier.weight(1f), tint = ds.star)
                    StatCard("${store.goldLevels}", tr("Gold"), Icons.Rounded.WorkspacePremium, Modifier.weight(1f), tint = ds.star)
                }
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm)
                ) {
                    Icon(Icons.Rounded.EmojiEvents, contentDescription = null, tint = ds.star, modifier = Modifier.size(18.dp))
                    Text(tr("{0} achievements unlocked", store.achievementsUnlocked), style = DSText.caption, color = ds.textSecondary)
                }
            }

            // Levels
            DSCard {
                SectionHeader(tr("Levels"), Icons.Rounded.GridView)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .pressableClickable { onOpenLevels() },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(DS.Spacing.md)
                ) {
                    Icon(Icons.Rounded.FormatListNumbered, contentDescription = null, tint = ds.link)
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(DS.Spacing.xxs)) {
                        Text(tr("All Levels"), style = DSText.body.copy(fontWeight = FontWeight.Bold), color = ds.textPrimary)
                        Text(tr("Browse, replay, and check your stars"), style = DSText.caption, color = ds.textSecondary)
                    }
                    Icon(Icons.Rounded.ChevronRight, contentDescription = null, tint = ds.textSecondary)
                }
            }

            // Appearance
            DSCard {
                SectionHeader(tr("Appearance"), Icons.Rounded.Brush)
                Text(tr("Choose light, dark, or match your device."), style = DSText.caption, color = ds.textSecondary)
                Row(horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm)) {
                    AppearanceMode.entries.forEach { mode ->
                        val selected = store.appearanceMode == mode
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .pressableClickable {
                                    store.updateSettings { it.copy(appearanceModeRaw = mode.rawValue) }
                                }
                                .background(
                                    if (selected) ds.brand else ds.fill,
                                    RoundedCornerShape(DS.Radius.sm)
                                )
                                .padding(vertical = DS.Spacing.md),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(DS.Spacing.xs + 2.dp)
                        ) {
                            Icon(
                                when (mode) {
                                    AppearanceMode.SYSTEM -> Icons.Rounded.PhoneAndroid
                                    AppearanceMode.LIGHT -> Icons.Rounded.LightMode
                                    AppearanceMode.DARK -> Icons.Rounded.DarkMode
                                },
                                contentDescription = null,
                                tint = if (selected) Color.White else ds.textPrimary
                            )
                            Text(
                                mode.title,
                                style = DSText.caption2.copy(fontWeight = FontWeight.Bold),
                                color = if (selected) Color.White else ds.textPrimary
                            )
                        }
                    }
                }
            }

            // Language
            DSCard {
                SectionHeader(tr("Language"), Icons.Rounded.Language)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .pressableClickable { showLanguagePicker = true },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(DS.Spacing.md)
                ) {
                    Icon(Icons.Rounded.Translate, contentDescription = null, tint = ds.link)
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(DS.Spacing.xxs)) {
                        Text(
                            L10n.nativeNames[L10n.language] ?: "English",
                            style = DSText.body.copy(fontWeight = FontWeight.Bold),
                            color = ds.textPrimary
                        )
                        if (L10n.override == null) {
                            Text(tr("Same as device"), style = DSText.caption, color = ds.textSecondary)
                        }
                    }
                    Icon(Icons.Rounded.ChevronRight, contentDescription = null, tint = ds.textSecondary)
                }
            }

            // Card style
            DSCard {
                SectionHeader(tr("Card Style"), Icons.Rounded.GridView)
                Text(tr("Pick the look of the card backs."), style = DSText.caption, color = ds.textSecondary)
                Row(horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)) {
                    CardBackStyle.entries.forEach { style ->
                        val selected = store.cardBackStyle == style
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .pressableClickable { store.setCardBackStyle(style) },
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(DS.Spacing.xs + 2.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(58.dp)
                                    .background(cardBackBrush(style.colorHexes), RoundedCornerShape(DS.Radius.sm))
                                    .border(
                                        if (selected) 3.dp else 0.dp,
                                        if (selected) Color.White else Color.Transparent,
                                        RoundedCornerShape(DS.Radius.sm)
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                if (selected) {
                                    Icon(Icons.Rounded.Check, contentDescription = null, tint = Color.White)
                                }
                            }
                            Text(
                                style.label,
                                style = DSText.caption2.copy(fontWeight = FontWeight.SemiBold),
                                color = if (selected) ds.textPrimary else ds.textSecondary,
                                maxLines = 1
                            )
                        }
                    }
                }
            }

            // Gameplay
            DSCard {
                SectionHeader(tr("Gameplay"), Icons.Rounded.SportsEsports)
                SettingsToggle(
                    title = tr("Sound Effects"),
                    subtitle = tr("Flips, matches, and level complete sounds"),
                    icon = Icons.Rounded.VolumeUp,
                    checked = store.settings.soundEnabled
                ) { value ->
                    GameAudio.soundEnabled = value
                    store.updateSettings { it.copy(soundEnabled = value) }
                }
                SettingsToggle(
                    title = tr("Haptic Feedback"),
                    subtitle = tr("Gentle taps when you flip and match cards"),
                    icon = Icons.Rounded.TouchApp,
                    checked = store.settings.hapticsEnabled
                ) { value -> store.updateSettings { it.copy(hapticsEnabled = value) } }
                SettingsToggle(
                    title = tr("Memorize Preview"),
                    subtitle = tr("Show all cards to memorize at the start (level 3+)"),
                    icon = Icons.Rounded.RemoveRedEye,
                    checked = store.settings.memorizePreviewEnabled
                ) { value -> store.updateSettings { it.copy(memorizePreviewEnabled = value) } }
            }

            // Notifications
            DSCard {
                SectionHeader(tr("Notifications"), Icons.Rounded.Notifications)
                SettingsToggle(
                    title = tr("Reminders"),
                    subtitle = tr("A daily nudge, plus a friendly note if you've been away"),
                    icon = Icons.Rounded.Notifications,
                    checked = store.remindersEnabled
                ) { enabled ->
                    if (enabled) {
                        if (ReminderScheduler.hasPermission(context)) {
                            store.setRemindersEnabled(true)
                            ReminderScheduler.scheduleReminders(context)
                        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                        }
                    } else {
                        store.setRemindersEnabled(false)
                        ReminderScheduler.cancelAll(context)
                    }
                }
            }

            // Remove Ads — hidden while purchases are disabled for this build.
            if (StoreManager.PURCHASES_ENABLED) {
            DSCard {
                SectionHeader(tr("Ads"), Icons.Rounded.HeartBroken)
                if (storeManager.adsRemoved) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(DS.Spacing.sm + 2.dp)
                    ) {
                        Icon(Icons.Rounded.CheckCircle, contentDescription = null, tint = ds.success)
                        Text(
                            tr("Ads removed — thank you!"),
                            style = DSText.body.copy(fontWeight = FontWeight.SemiBold),
                            color = ds.textPrimary
                        )
                    }
                } else {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .pressableClickable(enabled = !storeManager.isWorking) {
                                storeManager.clearStatus()
                                showParentalGate = true
                            },
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(DS.Spacing.md)
                    ) {
                        Icon(Icons.Rounded.HeartBroken, contentDescription = null, tint = ds.link)
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(DS.Spacing.xxs)) {
                            Text(tr("Remove Ads"), style = DSText.body.copy(fontWeight = FontWeight.Bold), color = ds.link)
                            Text(
                                storeManager.removeAdsDisplayPrice?.let { tr("One-time purchase — {0}, no more ads", it) }
                                    ?: tr("One-time purchase — no more ads"),
                                style = DSText.caption,
                                color = ds.textSecondary
                            )
                        }
                        Icon(Icons.Rounded.ChevronRight, contentDescription = null, tint = ds.textSecondary)
                    }

                    StoreStatusBanner(storeManager)
                    // No "Restore Purchases" on Android — Play Billing restores
                    // the entitlement automatically.
                }
            }
            }

            // Accessibility
            DSCard {
                SectionHeader(tr("Accessibility"), Icons.Rounded.Accessibility)
                SettingsToggle(
                    title = tr("Large Text"),
                    subtitle = tr("Bigger emojis and labels on game cards"),
                    icon = Icons.Rounded.TextFields,
                    checked = store.settings.largeText
                ) { value -> store.updateSettings { it.copy(largeText = value) } }
                SettingsToggle(
                    title = tr("High Contrast"),
                    subtitle = tr("Thicker borders and sharper card faces"),
                    icon = Icons.Rounded.Contrast,
                    checked = store.settings.highContrast
                ) { value -> store.updateSettings { it.copy(highContrast = value) } }
                SettingsToggle(
                    title = tr("Color Blind Friendly"),
                    subtitle = tr("Uses blue accents instead of mixed colors"),
                    icon = Icons.Rounded.RemoveRedEye,
                    checked = store.settings.colorBlindMode
                ) { value -> store.updateSettings { it.copy(colorBlindMode = value) } }
            }

            // Data
            DSCard {
                SectionHeader(tr("Data"), Icons.Rounded.Storage)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .pressableClickable { showResetAlert = true },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(DS.Spacing.md)
                ) {
                    Icon(Icons.Rounded.Refresh, contentDescription = null, tint = ds.danger)
                    Column(verticalArrangement = Arrangement.spacedBy(DS.Spacing.xxs)) {
                        Text(tr("Reset All Progress"), style = DSText.body.copy(fontWeight = FontWeight.Bold), color = ds.danger)
                        Text(tr("Start over from Level 1"), style = DSText.caption, color = ds.textSecondary)
                    }
                }
            }

            // About
            DSCard {
                SectionHeader(tr("About"), Icons.Rounded.Info)
                InfoRow(tr("App"), APP_NAME)
                InfoRow(tr("Unlock rule"), tr("Complete a level to open the next"))
                InfoRow(
                    tr("Star guide"),
                    tr("3★ ≤ pairs moves · 2★ ≤ pairs + {0} · 1★ finish", StarRatingRules.TWO_STAR_EXTRA_MOVES)
                )
            }

            // Legal
            DSCard {
                SectionHeader(tr("Support & Privacy"), Icons.Rounded.Info)
                // Only shown where UMP says this user is owed a way back to
                // their consent answer — elsewhere there is no form to
                // re-present, so the row would dead-end.
                if (showPrivacyOptions) {
                    PrivacyOptionsLink(
                        onDismissed = {
                            showPrivacyOptions = ConsentManager.privacyOptionsRequired(context)
                        }
                    )
                }
                LegalLink(tr("Privacy Policy"), "$SITE_BASE_URL/privacy-policy.html")
                LegalLink(tr("Terms & Conditions"), "$SITE_BASE_URL/terms-and-conditions.html")
                LegalLink(tr("Contact Support"), "$SITE_BASE_URL/")
            }

            Spacer(Modifier.height(DS.Spacing.lg))
            }
        }
    }

    if (showResetAlert) {
        AlertDialog(
            onDismissRequest = { showResetAlert = false },
            title = { Text(tr("Reset all progress?")) },
            text = { Text(tr("This removes stars, level progress, and achievements. Your settings stay the same.")) },
            confirmButton = {
                TextButton(onClick = {
                    store.resetAllProgress()
                    showResetAlert = false
                }) { Text(tr("Reset"), color = ds.danger) }
            },
            dismissButton = {
                TextButton(onClick = { showResetAlert = false }) { Text(tr("Cancel")) }
            }
        )
    }

    if (showNotifDeniedAlert) {
        AlertDialog(
            onDismissRequest = { showNotifDeniedAlert = false },
            title = { Text(tr("Notifications are off")) },
            text = { Text(tr("Enable notifications for {0} in your device Settings to get daily reminders.", APP_NAME)) },
            confirmButton = {
                TextButton(onClick = {
                    showNotifDeniedAlert = false
                    val intent = Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, context.packageName)
                    runCatching { context.startActivity(intent) }
                }) { Text(tr("Open Settings")) }
            },
            dismissButton = {
                TextButton(onClick = { showNotifDeniedAlert = false }) { Text(tr("Not Now")) }
            }
        )
    }

    if (showLanguagePicker) {
        // null = follow the device; then each language in its own name.
        val options = listOf<String?>(null) + L10n.nativeNames.keys
        AlertDialog(
            onDismissRequest = { showLanguagePicker = false },
            title = { Text(tr("Language")) },
            text = {
                Column(Modifier.verticalScroll(rememberScrollState())) {
                    options.forEach { code ->
                        val selected = L10n.override == code
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .pressableClickable {
                                    showLanguagePicker = false
                                    context.findActivity()?.let { L10n.setOverride(it, code) }
                                }
                                .padding(vertical = DS.Spacing.sm),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                if (code == null) tr("Same as device") else L10n.nativeNames.getValue(code),
                                style = DSText.body.copy(fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal),
                                color = if (selected) ds.link else ds.textPrimary,
                                modifier = Modifier.weight(1f)
                            )
                            if (selected) Icon(Icons.Rounded.Check, contentDescription = null, tint = ds.link)
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showLanguagePicker = false }) { Text(tr("Cancel")) }
            }
        )
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

private const val SITE_BASE_URL = "https://tinygeniushubmemorymatch.netlify.app"

@Composable
private fun SettingsToggle(
    title: String,
    subtitle: String,
    icon: ImageVector,
    checked: Boolean,
    onChange: (Boolean) -> Unit
) {
    val ds = LocalDSColors.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = DS.Spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(DS.Spacing.md)
    ) {
        Icon(icon, contentDescription = null, tint = ds.link, modifier = Modifier.size(22.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(DS.Spacing.xxs)) {
            Text(title, style = DSText.body.copy(fontWeight = FontWeight.SemiBold), color = ds.textPrimary)
            Text(subtitle, style = DSText.caption, color = ds.textSecondary)
        }
        Switch(
            checked = checked,
            onCheckedChange = onChange,
            colors = SwitchDefaults.colors(checkedTrackColor = ds.brand)
        )
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    val ds = LocalDSColors.current
    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
        Text(label, style = DSText.caption, color = ds.textSecondary)
        Spacer(Modifier.width(DS.Spacing.md))
        Spacer(Modifier.weight(1f))
        Text(
            value,
            style = DSText.caption.copy(fontWeight = FontWeight.SemiBold),
            color = ds.textPrimary,
            textAlign = TextAlign.End
        )
    }
}

@Composable
private fun PrivacyOptionsLink(onDismissed: () -> Unit) {
    val ds = LocalDSColors.current
    val context = LocalContext.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .pressableClickable {
                // UMP owns the form's own error UI; all this needs to do is
                // re-check whether the row still applies afterwards.
                context.findActivity()?.let { activity ->
                    ConsentManager.showPrivacyOptions(activity) { onDismissed() }
                }
            }
            .padding(vertical = DS.Spacing.xs),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(DS.Spacing.md)
    ) {
        Icon(Icons.Rounded.PrivacyTip, contentDescription = null, tint = ds.link, modifier = Modifier.size(20.dp))
        Text(
            tr("Privacy Options"),
            style = DSText.body.copy(fontWeight = FontWeight.SemiBold),
            color = ds.textPrimary,
            modifier = Modifier.weight(1f)
        )
        Icon(Icons.Rounded.ChevronRight, contentDescription = null, tint = ds.textSecondary, modifier = Modifier.size(18.dp))
    }
}

@Composable
private fun LegalLink(title: String, url: String) {
    val ds = LocalDSColors.current
    val context = LocalContext.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .pressableClickable {
                runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
            }
            .padding(vertical = DS.Spacing.xs),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(DS.Spacing.md)
    ) {
        Icon(Icons.Rounded.OpenInNew, contentDescription = null, tint = ds.link, modifier = Modifier.size(20.dp))
        Text(
            title,
            style = DSText.body.copy(fontWeight = FontWeight.SemiBold),
            color = ds.textPrimary,
            modifier = Modifier.weight(1f)
        )
        Icon(Icons.Rounded.ChevronRight, contentDescription = null, tint = ds.textSecondary, modifier = Modifier.size(18.dp))
    }
}
