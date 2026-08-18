# App Store assets — Memory Match v1.1

Regenerate with:

```bash
python3 scripts/build_store_assets.py   # screenshots, iPhone + iPad
python3 scripts/build_app_preview.py    # preview videos, iPhone + iPad
```

Both read raw simulator captures from the scratchpad path defined at the top of
each script. See "Recapturing" below to rebuild those from scratch.

## Upload order (this order matters)

App Store search results show only the **first three assets**. The v1.0 listing
spent two of those three on Achievements and Settings, which sell nothing to
someone who has never heard of the app.

| Slot | Asset | What it argues |
|-----|-------|----------------|
| 1 | the preview video for that device | the game in motion, three-star payoff |
| 2 | `01_preview.png` — *Can You Remember All 30?* | the hook: a 30-card board and a countdown |
| 3 | `02_math.png` — *More Than Just Matching* | the differentiator: sums, letters, flags |
| 4 | `03_game4x4.png` — *50 Levels That Grow With You* | depth / content volume |
| 5 | `04_win.png` — *Beat Your Best Every Time* | progression and replay loop |
| 6 | `05_home.png` — *Play Anywhere. No WiFi Needed.* | offline, no login (parent objection) |
| 7 | `06_awards.png` — *Collect Every Trophy* | long-term goals |

Set each video's poster frame to the matching `poster_*.png` (a mid-match
board) rather than letting App Store Connect pick frame 0, which is a
countdown screen.

## Sizes

Screenshots:

| Folder | Size | Notes |
|---|---|---|
| `iPhone_6.9/` | 1320×2868 | upload first; Apple downsamples for smaller iPhones |
| `iPhone_6.5/` | 1284×2778 | fills the slot the current listing already uses |
| `iPad_13/` | 2064×2752 | the 13" slot Apple now asks for first |
| `iPad_12.9/` | 2048×2732 | 12.9" fallback |

Previews (`preview/`) — both H.264, 30 fps, with a silent stereo AAC track,
which App Store Connect requires even for a silent video:

| File | Size | Length |
|---|---|---|
| `MemoryMatch_preview_iPhone_886x1920.mp4` | 886×1920 | 23.3s |
| `MemoryMatch_preview_iPad_1200x1600.mp4` | 1200×1600 | 23.3s |

Apple accepts 15–30s. Neither preview has music — if you add a track it must be
licensed for commercial use, or App Review will reject it.

## Recapturing

Raw screens came from an iPhone 15 Pro Max and an iPad Pro 12.9" (6th gen),
both on iOS 17.2, in dark mode, driven by temporary launch-argument hooks that
routed straight to a level, posed the board, and auto-played a level for the
videos. Those hooks were reverted after capture; `git status` on `MemoryGame/`
should show only intentional changes.

Four things worth knowing before redoing this:

- `xcrun simctl status_bar override` is a **no-op** on the iOS 17.2 runtimes
  here, so captures carry a live clock and a dead cellular indicator. Both
  scripts repaint a clean status bar instead — `draw_status_bar` for iPhone and
  `draw_status_bar_ipad` for iPad. They are separate functions on purpose: the
  iPad strip is a third of the height but carries proportionally larger text,
  so scaling the iPhone geometry painted straight over the navigation bar.
- `simctl recordVideo` can emit a **variable-frame-rate** file. The iPad
  recording averaged ~22fps on a 600 timebase, and seeking into it was wildly
  inaccurate — a 14.4s segment request came back as 30.1s, pushing the cut past
  Apple's 30s cap. `build_app_preview.py` now normalises every recording to
  constant 30fps before cutting.
- Segment times in `build_app_preview.py` are **per device** and mapped from a
  1fps frame dump of that device's own recording. The iPad boots and previews
  more slowly, so its beats land much later than the iPhone's. If you
  re-record, re-dump and re-map rather than reusing the numbers.
- Give captures a long settle delay (20s+). A shorter one catches the splash
  screen, or the card grid mid-relayout — one 4×4 capture came back with two
  rows drawn on top of each other.

## Card grid: overlap bug

The memorize phase used to draw the **bottom row of cards on top of the row
above it**, wiping that row's labels. It was in the shipped app, not the capture
pipeline, and it landed in both screenshots and video.

The chain, from the bottom up:

1. Each countdown dot in the memorize banner is 13pt wide while active and 6pt
   once spent, so the dots row got 7pt narrower **on every tick**.
2. That shrank the banner's VStack, which re-wrapped the objective text sitting
   beside the dots, which changed the banner's **height**.
3. The banner's height decides how much room is left for `cardGrid`, so the card
   size was recomputed once a second.
4. `.animation(value: cardWidth)` then animated every card's frame toward its
   new size — but LazyVGrid repositions its rows in a single layout pass. Mid
   animation the rows were closer together than the cards were tall, so they
   overlapped.

Three changes, at each level of that chain:

- `previewSecondDots` reserves the width of the all-active state, so ticking
  can no longer change the banner's width or height.
- `cardWidth` is floored to a whole point, so sub-pixel noise can't retrigger a
  relayout.
- the implicit animation on `cardWidth` is gone. The grid still resizes once per
  level (taller memorize banner to one-line objective banner), but now in one
  step with no inconsistent intermediate state. Per-card flip, pulse and shake
  animations are untouched — they live in `MemoryCardView` and don't affect
  layout.

Verified by sampling the memorize phase and the transition frame by frame at
native resolution on both devices, before and after.

## Card grid spacing

Row and column gaps in [GameView.swift](../MemoryGame/Views/Game/GameView.swift)
are the **same value**, on purpose.

An intermediate version padded the row gaps out to absorb the leftover vertical
space in the board area. It did fill the space, but it made the grid read as a
set of separated rows instead of one block — worse than the gap it removed. It
was reverted.

The leftover height that remains is geometric, not a bug: at 4 and 5 columns the
board is **width**-constrained, so the cards cannot grow into spare height, and
the grid's height is effectively fixed once its width is. It stays centered.
Closing that gap further, with gaps kept equal, would mean either fewer columns
(a gameplay change) or non-square cards (a card-design change) — both bigger
decisions than a layout tweak.

`crop` is off for every frame, so the screenshots show the real layout rather
than a doctored one.
