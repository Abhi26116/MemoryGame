# Memory Match — Android (Jetpack Compose)

Kotlin + Jetpack Compose port of the iOS SwiftUI app (`../MemoryGame`). Same 50-level
catalog, game engine, star rules, achievements, design system, ads and Remove-Ads
purchase flow.

## Open & run

1. Open **this `android/` folder** in Android Studio (not the repo root).
2. Let Gradle sync (first sync downloads dependencies).
3. Run the `app` configuration on an emulator or device (Android 8.0+ / API 26+).

Debug builds use **Google's test ad units** automatically — safe to tap.

## Project map (iOS → Android)

| iOS (SwiftUI)                        | Android (Compose)                                   |
| ------------------------------------ | --------------------------------------------------- |
| `Models/`, `GameEnums.swift`          | `model/` (`Models.kt`, `GameEnums.kt`)              |
| `Engine/GameEngine.swift` + strategies | `engine/`                                          |
| `Data/LevelCatalog.swift`             | `data/LevelCatalog.kt`                              |
| SwiftData (`ProgressStore`)           | `services/ProgressStore.kt` (SharedPreferences JSON) |
| `Monetization.swift` (AdMob+StoreKit) | `services/AdsManager.kt` + `services/StoreManager.kt` (AdMob + Play Billing) |
| `NotificationManager.swift`           | `services/ReminderScheduler.kt` (AlarmManager)      |
| `ReviewPromptGate` / `RemoveAdsPromptGate` | `services/Gates.kt` (+ Play In-App Review)     |
| `DesignTokens/DSControls/DSContainers` | `core/` (`DesignTokens.kt`, `DsComponents.kt`)    |
| Views (Root/Splash/Home/Game/…)       | `ui/` screens, navigation in `ui/RootNavigation.kt` |

Not ported: `UpdateCheckManager` (iTunes lookup is iOS-only; Play Store handles
update prompts itself).

## Before publishing — TODO

1. **AdMob (Android app + units)** — the iOS AdMob IDs will NOT serve on Android.
   - Create an *Android* app in the AdMob console, put its App ID in
     `app/src/main/AndroidManifest.xml` (currently Google's sample ID).
   - Create Android banner + interstitial units and fill in
     `LIVE_BANNER_UNIT_ID` / `LIVE_INTERSTITIAL_UNIT_ID` in
     `app/src/main/java/com/memogame/app/services/AdsManager.kt`.
2. **Play Billing** — create the in-app product `com.memogame.removeads`
   (one-time purchase) in Play Console → Monetize → Products.
3. **Signing** — add a release keystore + `signingConfig` in `app/build.gradle.kts`.
4. **Play "Designed for Families"** — the ads are configured child-directed
   (COPPA / G-rated) like iOS; declare the same in the Play Console questionnaire.
