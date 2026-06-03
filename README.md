# Memory Match Kids

Educational memory match game with **50 levels** that get progressively harder.

## Features

- 50 sequential levels (2×2 grid → 5×6 expert grids)
- Difficulty ramps automatically: more cards, association pairs, triple-match, timers, and move limits
- Stars, badges, and achievements
- Kid-friendly UI with flip animations, confetti, sounds, and haptics

## Run

Open `MemoryGame.xcodeproj` in Xcode and press **⌘R** (iOS 17.2+).

## App Icon & Splash Screen

- **App Icon:** `Assets.xcassets/AppIcon.appiconset` (1024×1024)
- **Splash:** `LaunchBackground` color + `LaunchLogo` image via `Info.plist` → `UILaunchScreen`

To replace the icon, swap `AppIcon.png` in the asset catalog (keep a square 1024×1024 PNG).

## Structure

- `Data/LevelCatalog.swift` — all 50 levels generated from level number
- `Engine/` — reusable match game logic
- `Views/Home/HomeView.swift` — level list + continue button
- `Views/Game/GameView.swift` — play screen

## Adding levels

Change `levelCount` in `LevelCatalog.swift` and adjust `gridSize(for:)`, `matchMode(for:)`, and `gameRules(for:)`.
