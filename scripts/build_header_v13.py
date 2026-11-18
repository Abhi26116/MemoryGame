#!/usr/bin/env python3
"""
Build the App Store product-page header (3840x1646) for v1.3 "Kids & Family".

Same look as the in-app event card: a sunny gradient, floating picture cards
and the app icon in the middle. It has no text, so one image works in every
language. The App Store draws the app name and Get button over the bottom of
the header, so the busy parts stay in the upper two thirds.

Usage:  python3 scripts/build_header_v13.py
"""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

import build_store_assets as v11
from build_store_assets_v13 import emoji_img

ROOT = Path(__file__).resolve().parents[1]
ICON = ROOT / "MemoryGame/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
OUT = ROOT / "StoreAssets_v1.3/AppStore_Header/header_3840x1646.png"
W, H = 3840, 1646

# (centre x, centre y, rotation, emoji or None for a card back), card height 520
CARDS = [
    (330, 520, 8, "🐶"), (860, 330, -12, "🚗"), (720, 1020, 10, None),
    (1240, 820, -6, "🍎"), (2600, 820, 7, "⭐"), (3000, 330, -9, "🌈"),
    (3130, 1010, 12, None), (3540, 540, -7, "🍓"),
]


def card(ch: str | None, h: int) -> Image.Image:
    w = int(h * 0.74)
    r = int(h * 0.09)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if ch:
        d.rounded_rectangle((0, 0, w - 1, h - 1), radius=r, fill=(255, 230, 242, 255))
        b = int(h * 0.018)
        d.rounded_rectangle((b, b, w - 1 - b, h - 1 - b), radius=r - b, fill=(255, 255, 255, 255))
        e = emoji_img(ch, int(w * 0.62))
        img.alpha_composite(e, ((w - e.width) // 2, (h - e.height) // 2))
    else:
        back = v11.gradient((w, h), ((118, 160, 245), (128, 104, 238), (160, 92, 240)))
        mask = Image.new("L", (w, h), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=r, fill=255)
        img.paste(back, (0, 0), mask)
        q = v11.font(v11.FREDOKA, int(h * 0.42), weight=700)
        d.text((w / 2, h / 2), "?", font=q, fill=(230, 20, 40, 255), anchor="mm")
    return img


def place(canvas: Image.Image, im: Image.Image, cx: int, cy: int, rot: float, shadow: int) -> None:
    sh = v11.rounded_shadow(im.size, int(im.height * 0.09), blur=shadow, spread=4, opacity=70)
    sh_img = Image.new("RGBA", sh.size, (90, 40, 90, 0))
    sh_img.putalpha(sh)
    sh_img = sh_img.rotate(rot, resample=Image.BICUBIC, expand=True)
    canvas.alpha_composite(sh_img, (cx - sh_img.width // 2 + shadow // 3, cy - sh_img.height // 2 + shadow // 2))
    im = im.rotate(rot, resample=Image.BICUBIC, expand=True)
    canvas.alpha_composite(im, (cx - im.width // 2, cy - im.height // 2))


def confetti(canvas: Image.Image) -> None:
    rnd = random.Random(13)
    d = ImageDraw.Draw(canvas)
    palette = [(255, 255, 255, 140), (255, 255, 255, 100), (255, 110, 140, 120),
               (120, 150, 240, 120), (255, 210, 80, 150), (255, 140, 110, 140)]
    for _ in range(44):
        x, y = rnd.randint(0, W), rnd.randint(0, H)
        r = rnd.randint(14, 44)
        c = rnd.choice(palette)
        if rnd.random() < 0.5:
            d.ellipse((x - r, y - r, x + r, y + r), fill=c)
        else:
            d.rounded_rectangle((x - r, y - r // 2, x + r, y + r // 2), radius=r // 3, fill=c)


def main() -> None:
    bg = v11.gradient((W, H), ((255, 228, 140), (250, 178, 160), (196, 150, 240))).convert("RGBA")
    confetti(bg)
    for cx, cy, rot, ch in CARDS:
        place(bg, card(ch, 520), cx, cy, rot, shadow=40)

    icon = Image.open(ICON).convert("RGBA").resize((820, 820), Image.LANCZOS)
    mask = Image.new("L", icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 819, 819), radius=int(820 * 0.225), fill=255)
    icon.putalpha(mask)
    place(bg, icon, W // 2, 640, 0, shadow=60)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    bg.convert("RGB").save(OUT, optimize=True)
    print(OUT, bg.size)


if __name__ == "__main__":
    main()
