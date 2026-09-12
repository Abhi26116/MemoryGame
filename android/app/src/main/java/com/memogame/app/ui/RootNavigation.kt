package com.memogame.app.ui

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
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
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.memogame.app.core.LocalDSColors
import com.memogame.app.services.ProgressStore
import com.memogame.app.services.RemoveAdsPromptGate
import com.memogame.app.services.ReminderScheduler
import com.memogame.app.services.StoreManager
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

/** Full-screen pushes that sit ON TOP of the tab Scaffold (iOS-style). */
private sealed interface FullScreenDest {
    data class Game(val levelNumber: Int) : FullScreenDest
    data object Levels : FullScreenDest
}

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

    androidx.compose.animation.Crossfade(
        targetState = phase,
        animationSpec = tween(450),
        label = "launchPhase"
    ) { current ->
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

    // Game / Levels push over the tab Scaffold instead of replacing a NavHost
    // route inside it. Hiding the bottomBar used to change Scaffold content
    // padding mid-transition, which made Home→Game jump vertically ("up-down"
    // UI). Keeping the tab chrome mounted underneath matches iOS (tab bar
    // hidden by covering it, not by resizing the layout).
    val fullScreenStack = remember { mutableStateListOf<FullScreenDest>() }
    val topFullScreen = fullScreenStack.lastOrNull()

    fun pushFullScreen(dest: FullScreenDest) {
        fullScreenStack.add(dest)
    }

    fun popFullScreen() {
        if (fullScreenStack.isNotEmpty()) {
            fullScreenStack.removeAt(fullScreenStack.lastIndex)
        }
    }

    BackHandler(enabled = fullScreenStack.isNotEmpty()) {
        popFullScreen()
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Scaffold(
            containerColor = ds.screen,
            bottomBar = {
                if (topFullScreen == null) {
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
                } else {
                    // Invisible stand-in for the tab bar: keeps Scaffold content
                    // padding stable (no Home jump on return) without drawing an
                    // elevated NavigationBar over Game / Result.
                    Spacer(
                        modifier = Modifier
                            .fillMaxWidth()
                            .navigationBarsPadding()
                            .height(80.dp)
                    )
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
                        onPlayLevel = { level ->
                            pushFullScreen(FullScreenDest.Game(level.levelNumber))
                        }
                    )
                }
                composable("awards") {
                    AchievementScreen(store = store)
                }
                composable("settings") {
                    SettingsScreen(
                        store = store,
                        storeManager = storeManager,
                        onOpenLevels = { pushFullScreen(FullScreenDest.Levels) }
                    )
                }
            }
        }

        // Horizontal push over the stable tab Scaffold (no vertical resize).
        // zIndex keeps this above Scaffold's elevated bottom bar.
        AnimatedContent(
            targetState = topFullScreen,
            modifier = Modifier
                .fillMaxSize()
                .zIndex(1f),
            transitionSpec = {
                val opening = initialState == null && targetState != null
                val closing = initialState != null && targetState == null
                val deeper = initialState is FullScreenDest.Levels && targetState is FullScreenDest.Game
                val backFromGame = initialState is FullScreenDest.Game && targetState is FullScreenDest.Levels

                when {
                    opening || deeper -> {
                        (slideInHorizontally(animationSpec = tween(320)) { it } + fadeIn(tween(200))) togetherWith
                            (slideOutHorizontally(animationSpec = tween(320)) { -it / 4 } + fadeOut(tween(200)))
                    }
                    closing || backFromGame -> {
                        (slideInHorizontally(animationSpec = tween(300)) { -it / 4 } + fadeIn(tween(200))) togetherWith
                            (slideOutHorizontally(animationSpec = tween(300)) { it } + fadeOut(tween(180)))
                    }
                    else -> fadeIn(tween(200)) togetherWith fadeOut(tween(200))
                }
            },
            label = "fullScreenPush"
        ) { dest ->
            when (dest) {
                is FullScreenDest.Game -> {
                    GameScreen(
                        levelNumber = dest.levelNumber,
                        store = store,
                        storeManager = storeManager,
                        onExit = { popFullScreen() }
                    )
                }
                FullScreenDest.Levels -> {
                    LevelsScreen(
                        store = store,
                        onPlayLevel = { level ->
                            pushFullScreen(FullScreenDest.Game(level.levelNumber))
                        },
                        onBack = { popFullScreen() }
                    )
                }
                null -> {
                    // Must NOT fill the screen — otherwise this layer eats every
                    // tap on the tab Scaffold underneath after the push pops.
                    Box(modifier = Modifier)
                }
            }
        }
    }
}
