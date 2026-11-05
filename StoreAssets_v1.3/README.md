# Store assets: Memory Match v1.3 (Kids & Family, 7 languages)

Listing copy for both stores, including localized fields and the in-app
event text, is in [LISTING.md](LISTING.md).

## Folders

```
<lang>/                      en, hi, es, pt, id, de, fr
  iPhone_6.9/                1320×2868, 7 frames  → App Store, 6.9" iPhone
  iPad_13/                   2064×2752, 7 frames  → App Store, 13" iPad
  GooglePlay_phone/          1080×1920, 7 frames  → Play, phone screenshots
  GooglePlay_feature_graphic.png   1024×500       → Play, feature graphic
AppStore_InAppEvent/
  event_card_1920x1080.png         → In-App Event card (search results + product page)
  event_details_1080x1920.png      → In-App Event details page
```

Apple scales the 6.9" and 13" sets down for smaller devices, so those two sizes
are all App Store Connect needs.

## Upload order

Search results show only the first three images, so the order matters:

| # | Frame | What it says |
|---|---|---|
| 1 | `01_prev` | Flip, find & match: cute animal cards |
| 2 | `02_math` | Learn while you play: ABC, 123, flags |
| 3 | `03_game` | 50 levels of brain fun |
| 4 | `04_win` | Win stars, confetti |
| 5 | `05_home` | Play anywhere, no WiFi |
| 6 | `06_awards` | Collect every trophy |
| 7 | `07_dark` | Cozy dark mode for bedtime |

## Locale mapping

| Folder | App Store Connect locale | Play Console locale |
|---|---|---|
| en | English (U.S.) | English (United States) – en-US |
| hi | Hindi | Hindi – hi-IN |
| es | Spanish (Mexico) **and** Spanish (Spain) | Spanish (Latin America) – es-419 **and** Spanish (Spain) – es-ES |
| pt | Portuguese (Brazil) | Portuguese (Brazil) – pt-BR |
| id | Indonesian | Indonesian – id |
| de | German | German – de-DE |
| fr | French | French (France) – fr-FR |

## Regenerating

1. Build the app for the simulator, then capture every screen in every language
   (`d_*` on the iPhone 15 Pro Max simulator, `p_*` on iPad Pro 12.9"). The app's
   `SHOT_*` launch environment hooks pose each screen, and `-AppleLanguages`
   picks the language. Give each launch 30–40 seconds to settle, and check the
   result: an overloaded Mac leaves some captures stuck on the splash screen.
2. `python3 scripts/build_store_assets_v13.py [lang ...]`

Hindi text goes through `scripts/render_text.swift` (Core Text), because
Pillow's basic layout can't shape Devanagari. The script compiles it on first
use; this needs Xcode's `swiftc`.
