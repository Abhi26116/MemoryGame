package com.memogame.app.ui

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.SportsEsports
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.memogame.app.core.LocalDSColors
import com.memogame.app.services.AdsManager
import com.memogame.app.services.ProgressStore
import com.memogame.app.services.RemoveAdsPromptGate
import com.memogame.app.services.ReminderScheduler
import com.memogame.app.services.StoreManager
import com.memogame.app.ui.components.BannerAdSlot
import kotlinx.coroutines.delay

/** Walks up the context chain to the hosting Activity (needed for ads/billing). */
fun Context.findActivity(): Activity? {
    var ctx = this
    while (ctx is ContextWrapper) {
        if (ctx is Activity) return ctx
        ctx = ctx.baseContext
    }
    return null
}

private enum class LaunchPhase { SPLASH, ONBOARDING, MAIN }

@Composable
fun MemoryMatchRoot(store: ProgressStore) {
    val context = LocalContext.current
    val storeManager = remember { StoreManager.get(context) }
    var phase by remember { mutableStateOf(LaunchPhase.SPLASH) }
    var showDailyShowcase by remember { mutableStateOf(false) }

    val notificationPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        store.setRemindersEnabled(granted)
        if (granted) ReminderScheduler.scheduleReminders(context)
    }

    // Mirrors the iOS runPostOnboardingChecks: re-arm reminders, then at most
    // one Remove-Ads pitch per calendar day.
    val runPostOnboardingChecks: () -> Unit = {
        if (store.remindersEnabled) {
            if (ReminderScheduler.hasPermission(context)) {
                ReminderScheduler.scheduleReminders(context)
            } else {
                notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
        if (StoreManager.PURCHASES_ENABLED &&
            !storeManager.adsRemoved &&
            !RemoveAdsPromptGate.shownToday(context)
        ) {
            RemoveAdsPromptGate.markShownToday(context)
            showDailyShowcase = true
        }
    }

    LaunchedEffect(Unit) {
        delay(2500)
        if (store.hasSeenWelcome) {
            phase = LaunchPhase.MAIN
            runPostOnboardingChecks()
        } else {
            phase = LaunchPhase.ONBOARDING
        }
    }

    Crossfade(targetState = phase, animationSpec = tween(450), label = "launchPhase") { current ->
        when (current) {
            LaunchPhase.SPLASH -> SplashScreen()
            LaunchPhase.ONBOARDING -> WelcomeScreen(
                storeManager = storeManager,
                onFinish = {
                    store.setHasSeenWelcome(true)
                    store.setHasSeenRemoveAdsPrompt(true)
                    RemoveAdsPromptGate.markShownToday(context)
                    phase = LaunchPhase.MAIN
                    runPostOnboardingChecks()
                }
            )
            LaunchPhase.MAIN -> MainScaffold(store, storeManager)
        }
    }

    if (showDailyShowcase) {
        RemoveAdsShowcaseScreen(storeManager = storeManager, onDismiss = { showDailyShowcase = false })
    }
}

private data class TabItem(val route: String, val label: String, val icon: androidx.compose.ui.graphics.vector.ImageVector)

@Composable
private fun MainScaffold(store: ProgressStore, storeManager: StoreManager) {
    val ds = LocalDSColors.current
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    val tabs = listOf(
        TabItem("home", "Play", Icons.Rounded.SportsEsports),
        TabItem("awards", "Awards", Icons.Rounded.EmojiEvents),
        TabItem("settings", "Settings", Icons.Rounded.Settings)
    )
    val isTabRoot = tabs.any { it.route == currentRoute }

    // iOS parity: the banner shows ONLY on the game screen, not Home — keeps
    // the Home tab clean and puts the ad where the player already spends the
    // most time.
    val showBanner = currentRoute?.startsWith("game/") == true

    Scaffold(
        containerColor = ds.screen,
        bottomBar = {
            // Material3's NavigationBar pads itself above the system nav bar
            // automatically — but on the game route there's no NavigationBar
            // to do that, so the banner alone sat flush at the bottom edge
            // and got hidden behind the system 3-button/gesture bar. Add the
            // inset explicitly whenever the tab bar isn't there to cover it.
            val bottomBarModifier = if (isTabRoot) Modifier else Modifier.navigationBarsPadding()
            Column(modifier = bottomBarModifier) {
                if (showBanner) {
                    BannerAdSlot(adsRemoved = storeManager.adsRemoved)
                }
                if (isTabRoot) {
                    NavigationBar(containerColor = ds.surface) {
                        tabs.forEach { tab ->
                            NavigationBarItem(
                                selected = currentRoute == tab.route,
                                onClick = {
                                    navController.navigate(tab.route) {
                                        popUpTo(navController.graph.findStartDestination().id) {
                                            saveState = true
                                        }
                                        launchSingleTop = true
                                        restoreState = true
                                    }
                                },
                                icon = { Icon(tab.icon, contentDescription = tab.label) },
                                label = { Text(tab.label) },
                                colors = NavigationBarItemDefaults.colors(
                                    selectedIconColor = ds.link,
                                    selectedTextColor = ds.link,
                                    unselectedIconColor = ds.textSecondary,
                                    unselectedTextColor = ds.textSecondary,
                                    indicatorColor = ds.fill
                                )
                            )
                        }
                    }
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = "home",
            modifier = Modifier.padding(padding)
        ) {
            composable("home") {
                HomeScreen(
                    store = store,
                    storeManager = storeManager,
                    onPlayLevel = { level -> navController.navigate("game/${level.levelNumber}") }
                )
            }
            composable("awards") {
                AchievementScreen(store = store)
            }
            composable("settings") {
                SettingsScreen(
                    store = store,
                    storeManager = storeManager,
                    onOpenLevels = { navController.navigate("levels") }
                )
            }
            composable("levels") {
                LevelsScreen(
                    store = store,
                    onPlayLevel = { level -> navController.navigate("game/${level.levelNumber}") },
                    onBack = { navController.popBackStack() }
                )
            }
            composable("game/{levelNumber}") { entry ->
                val levelNumber = entry.arguments?.getString("levelNumber")?.toIntOrNull() ?: 1
                GameScreen(
                    levelNumber = levelNumber,
                    store = store,
                    storeManager = storeManager,
                    onExit = { navController.popBackStack() }
                )
            }
        }
    }
}
