#!/usr/bin/env python3
"""
Build the App Store *search results* creative asset (3840x2560, 3:2).

Apple's spec (App Store Connect Help, "Creative assets specifications"):

    Placement       Aspect  Resolution                  Art safe area
    Search results  3:2     min 1920x1280               max 2168 x 1030 px
                            max 3840x2560               (x: 836, y: 765)

    .jpeg, .jpg or .png, and images can't include alpha channels.

The safe area is a centred band: key artwork (the icon and the two cards
flanking it) stays inside x 836..3004, y 765..1795, while the background
gradient, confetti and the outer cards run to the full canvas.

Same look as the product-page header and the in-app event card — sunny
gradient, floating picture cards, app icon in the middle — so the three
creative assets read as one set with the app icon. No text, so one image
works in every language.

Usage:  python3 scripts/build_search_results_v13.py
"""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw

import build_store_assets as v11
from build_header_v13 import card, place

ROOT = Path(__file__).resolve().parents[1]
ICON = ROOT / "MemoryGame/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
OUT = ROOT / "StoreAssets_v1.3/AppStore_SearchResults/search_results_3840x2560.png"

W, H = 3840, 2560
SAFE = (836, 765, 836 + 2168, 765 + 1030)  # x0, y0, x1, y1
CARD_H = 600
ICON_PX = 900

# (centre x, centre y, rotation, emoji or None for a card back).
# The two middle cards and the icon sit inside the art safe area; the rest is
# atmosphere in the auxiliary area.
CARDS = [
    (520, 470, 9, "🐶"),
    (1340, 300, -11, "🚗"),
    (2500, 300, 8, "🌈"),
    (3320, 470, -9, "🍓"),
    (1140, 1360, -7, "⭐"),      # safe area, left of the icon
    (2700, 1360, 7, "🍎"),       # safe area, right of the icon
    (560, 1900, -8, None),
    (3280, 1900, 10, None),
    (1240, 2290, 7, "🐱"),
    (2600, 2290, -6, "🦊"),
]


def confetti(canvas: Image.Image) -> None:
    rnd = random.Random(13)
    d = ImageDraw.Draw(canvas)
    palette = [(255, 255, 255, 140), (255, 255, 255, 100), (255, 110, 140, 120),
               (120, 150, 240, 120), (255, 210, 80, 150), (255, 140, 110, 140)]
    for _ in range(60):
        x, y = rnd.randint(0, W), rnd.randint(0, H)
        r = rnd.randint(16, 48)
        c = rnd.choice(palette)
        if rnd.random() < 0.5:
            d.ellipse((x - r, y - r, x + r, y + r), fill=c)
        else:
            d.rounded_rectangle((x - r, y - r // 2, x + r, y + r // 2), radius=r // 3, fill=c)


def main() -> None:
    bg = v11.gradient((W, H), ((255, 228, 140), (250, 178, 160), (196, 150, 240))).convert("RGBA")
    confetti(bg)
    for cx, cy, rot, ch in CARDS:
        place(bg, card(ch, CARD_H), cx, cy, rot, shadow=46)

    icon = Image.open(ICON).convert("RGBA").resize((ICON_PX, ICON_PX), Image.LANCZOS)
    mask = Image.new("L", icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, ICON_PX - 1, ICON_PX - 1),
                                           radius=int(ICON_PX * 0.225), fill=255)
    icon.putalpha(mask)
    place(bg, icon, W // 2, (SAFE[1] + SAFE[3]) // 2, 0, shadow=66)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    bg.convert("RGB").save(OUT, optimize=True)  # RGB: no alpha channel, per Apple
    print(OUT, bg.size)


if __name__ == "__main__":
    main()
