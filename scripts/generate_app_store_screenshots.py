#!/usr/bin/env python3
"""
Generate App Store marketing screenshots for Memory Match.
Outputs iPhone 6.7" (1290×2796) and iPad Pro 12.9" (2048×2732) PNGs.
"""

from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ICON_PATH = ROOT / "MemoryGame/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
OUT_DIR = ROOT / "AppStoreScreenshots"

# App Store required sizes
IPHONE_SIZE = (1290, 2796)
IPAD_SIZE = (2048, 2732)

# Brand palette — DARK MODE tokens (matches DesignTokens.swift dark values)
C = {
    "brand": (91, 141, 239),
    "brand_deep": (62, 111, 214),
    "accent": (255, 107, 157),
    "accent_deep": (229, 85, 127),
    "success": (52, 199, 89),
    "warning": (255, 149, 0),
    "star": (255, 214, 10),
    # Dark surfaces
    "screen": (15, 22, 34),          # #0F1622
    "surface": (26, 36, 51),         # #1A2433
    "surface_elevated": (35, 47, 66),  # #232F42
    "fill": (42, 56, 80),            # #2A3850
    # Dark text
    "text_primary": (232, 240, 250),   # #E8F0FA
    "text_secondary": (154, 176, 200),  # #9AB0C8
    "text_tertiary": (110, 128, 153),   # #6E8099
    "section_title": (184, 212, 255),   # #B8D4FF
    "link": (107, 163, 255),            # #6BA3FF
    "border": (46, 60, 84),          # #2E3C54
    "track": (58, 80, 112),          # #3A5070
    # Card backs (classic gradient)
    "card_back_1": (91, 141, 239),
    "card_back_2": (123, 91, 239),
    "card_back_3": (155, 77, 239),
    "cta_orange": (255, 149, 0),
    "cta_red": (255, 94, 58),
    "white": (255, 255, 255),
    "black": (0, 0, 0),
}


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def lerp_color(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t))


def vertical_gradient(size: tuple[int, int], top: tuple, mid: tuple, bottom: tuple) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        if t < 0.55:
            c = lerp_color(top, mid, t / 0.55)
        else:
            c = lerp_color(mid, bottom, (t - 0.55) / 0.45)
        for x in range(w):
            px[x, y] = c
    return img


def marketing_gradient(size: tuple[int, int], hue: str = "blue") -> Image.Image:
    palettes = {
        "blue": ((91, 141, 239), (62, 111, 214), (30, 58, 95)),
        "pink": ((255, 107, 157), (196, 77, 255), (62, 111, 214)),
        "sunset": ((255, 149, 0), (255, 94, 58), (255, 107, 157)),
        "green": ((52, 199, 89), (26, 143, 80), (30, 58, 95)),
        "purple": ((155, 77, 239), (91, 141, 239), (30, 58, 95)),
    }
    top, mid, bot = palettes.get(hue, palettes["blue"])
    w, h = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        c = lerp_color(top, mid, min(t * 1.4, 1.0))
        if t > 0.5:
            c = lerp_color(mid, bot, (t - 0.5) / 0.5)
        draw.line([(0, y), (w, y)], fill=c)
    # soft orbs
    orb = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(orb)
    od.ellipse((-w * 0.15, h * 0.08, w * 0.55, h * 0.55), fill=(255, 255, 255, 35))
    od.ellipse((w * 0.45, h * 0.55, w * 1.1, h * 1.05), fill=(255, 255, 255, 22))
    img = Image.alpha_composite(img.convert("RGBA"), orb).convert("RGB")
    return img


EMOJI_PATH = "/System/Library/Fonts/Apple Color Emoji.ttc"
# Apple Color Emoji is a bitmap font that only ships specific strike sizes.
# PIL must be asked for one of these exact sizes; other sizes render as a
# missing-glyph box. We render at 160 and downscale for crispness.
_APPLE_EMOJI_STRIKE = 160


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    if os.path.exists(EMOJI_PATH):
        try:
            return ImageFont.truetype(EMOJI_PATH, _APPLE_EMOJI_STRIKE, index=0)
        except OSError:
            pass
    return load_text_font(size)


def load_text_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    """Rounded sans for headlines and UI labels (not emoji)."""
    candidates = [
        "/System/Library/Fonts/SFNSRounded.ttf",
        "/System/Library/Fonts/Supplemental/Arial Rounded MT Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return load_font(size)


_EMOJI_CACHE: dict[tuple[str, int], Image.Image] = {}


def render_emoji_tile(emoji: str, size: int) -> Image.Image | None:
    """Render a color emoji to an RGBA tile of the requested pixel size."""
    if not os.path.exists(EMOJI_PATH):
        return None
    key = (emoji, size)
    if key in _EMOJI_CACHE:
        return _EMOJI_CACHE[key]
    try:
        font = ImageFont.truetype(EMOJI_PATH, _APPLE_EMOJI_STRIKE, index=0)
    except OSError:
        return None
    big = Image.new("RGBA", (_APPLE_EMOJI_STRIKE, _APPLE_EMOJI_STRIKE), (0, 0, 0, 0))
    bd = ImageDraw.Draw(big)
    try:
        bd.text((0, 0), emoji, font=font, embedded_color=True)
    except Exception:
        return None
    bbox = big.getbbox()
    if bbox:
        big = big.crop(bbox)
    tile = big.resize((size, size), Image.LANCZOS)
    _EMOJI_CACHE[key] = tile
    return tile


# `draw` here is an ImageDraw bound to a base image; we paste onto that image.
def draw_emoji(draw, emoji: str, x: int, y: int, size: int):
    tile = render_emoji_tile(emoji, size)
    if tile is None:
        draw.text((x, y), emoji, font=load_text_font(size))
        return
    draw._image.paste(tile, (int(x), int(y)), tile)


def draw_play_triangle(draw, x: int, y: int, size: int, color=(255, 255, 255)):
    """A crisp filled play (▶) triangle."""
    draw.polygon(
        [(x, y), (x, y + size), (x + int(size * 0.86), y + size // 2)],
        fill=color,
    )


def rounded_rect(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int, int, int],
    radius: int,
    fill=None,
    outline=None,
    width: int = 1,
):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def draw_text_centered(
    draw: ImageDraw.ImageDraw,
    text: str,
    y: int,
    width: int,
    font: ImageFont.ImageFont,
    fill: tuple,
    shadow: bool = True,
):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    x = (width - tw) // 2
    if shadow:
        draw.text((x + 2, y + 3), text, font=font, fill=(0, 0, 0, 80))
    draw.text((x, y), text, font=font, fill=fill)


def draw_subtitle_centered(draw, text, y, width, font, fill):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    x = (width - tw) // 2
    draw.text((x, y), text, font=font, fill=fill)


def phone_frame(size: tuple[int, int], is_ipad: bool, content_h: float = 1.0) -> tuple[int, int, int, int]:
    """Return (x, y, w, h) for the device mockup content area.

    `content_h` (0<v<=1) shortens the frame for screens whose UI is compact, so
    there's no large dead space below the content.
    """
    w, h = size
    if is_ipad:
        fw = int(w * 0.80)
        fh = int(fw * 4 / 3 * content_h)
        fx = (w - fw) // 2
        fy = int(h * 0.30)
    else:
        fw = int(w * 0.84)
        fh = int(fw * 19.5 / 9 * content_h)
        fx = (w - fw) // 2
        fy = int(h * 0.235)
    return fx, fy, fw, fh


def draw_device_shell(base: Image.Image, frame: tuple[int, int, int, int], is_ipad: bool):
    fx, fy, fw, fh = frame
    draw = ImageDraw.Draw(base)
    radius = 48 if is_ipad else 56
    # shadow
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((fx + 8, fy + 14, fx + fw + 8, fy + fh + 14), radius=radius, fill=(0, 0, 0, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    base.alpha_composite(shadow)
    # bezel — dark titanium frame for dark-mode device
    draw.rounded_rectangle((fx - 7, fy - 7, fx + fw + 7, fy + fh + 7), radius=radius + 7, fill=(58, 66, 82))
    draw.rounded_rectangle((fx - 3, fy - 3, fx + fw + 3, fy + fh + 3), radius=radius + 3, fill=(20, 26, 36))
    draw.rounded_rectangle((fx, fy, fx + fw, fy + fh), radius=radius, fill=C["screen"])
    if not is_ipad:
        # dynamic island
        iw, ih = int(fw * 0.28), 34
        ix = fx + (fw - iw) // 2
        draw.rounded_rectangle((ix, fy + 16, ix + iw, fy + 16 + ih), radius=17, fill=(10, 12, 18))


def sky_bg(w: int, h: int) -> Image.Image:
    """App's real dark screen background: flat dark screen + soft brand/accent glows."""
    img = Image.new("RGB", (w, h), C["screen"])
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    s = w / 400.0  # scale glows to the content-area width

    def orb(cx, cy, r, color, alpha):
        gd.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color + (alpha,))

    orb(int(-40 * s), int(-30 * s), int(150 * s), C["brand"], 42)
    orb(int(w + 30 * s), int(h * 0.45), int(140 * s), C["accent"], 36)
    orb(int(w * 0.55), int(h * 0.9), int(130 * s), C["brand"], 26)
    glow = glow.filter(ImageFilter.GaussianBlur(int(60 * s)))
    return Image.alpha_composite(img.convert("RGBA"), glow).convert("RGB")


def draw_card_back(draw, x, y, size, radius=14):
    rounded_rect(draw, (x, y, x + size, y + int(size * 1.15)), radius, fill=C["card_back_1"])
    # gradient overlay simulation
    rounded_rect(draw, (x + 4, y + 4, x + size - 4, y + int(size * 1.15) - 4), radius - 4, fill=C["card_back_2"])
    cx, cy = x + size // 2, y + int(size * 1.15) // 2
    draw.text((cx - size * 0.12, cy - size * 0.20), "?", fill=(255, 255, 255, 235), font=load_text_font(int(size * 0.4)))


def draw_card_face(draw, x, y, size, emoji: str, radius=14):
    rounded_rect(draw, (x, y, x + size, y + int(size * 1.15)), radius, fill=C["surface_elevated"], outline=C["border"], width=2)
    draw_emoji(draw, emoji, x + int(size * 0.29), y + int(size * 0.30), int(size * 0.42))


def mock_home(content: Image.Image, frame: tuple, scale: float):
    fx, fy, fw, fh = frame
    layer = sky_bg(fw, fh)
    d = ImageDraw.Draw(layer)
    pad = int(24 * scale)

    # brain icon circle
    cx = fw // 2
    r = int(44 * scale)
    d.ellipse((cx - r, pad, cx + r, pad + r * 2), fill=(91, 141, 239, 70))
    d.ellipse((cx - r, pad, cx + r, pad + r * 2), outline=C["accent"], width=max(2, int(2 * scale)))
    draw_emoji(d, "🧠", cx - int(14 * scale), pad + int(18 * scale), int(36 * scale))

    title_font = load_text_font(int(28 * scale))
    bbox = d.textbbox((0, 0), "Memory Match", font=title_font)
    tw = bbox[2] - bbox[0]
    d.text((cx - tw // 2, pad + r * 2 + int(8 * scale)), "Memory Match", font=title_font, fill=C["accent"])

    sub_font = load_text_font(int(13 * scale))
    sub = "Complete a level to unlock the next!"
    bbox = d.textbbox((0, 0), sub, font=sub_font)
    d.text((cx - (bbox[2] - bbox[0]) // 2, pad + r * 2 + int(42 * scale)), sub, font=sub_font, fill=C["text_secondary"])

    # progress card
    cy = pad + r * 2 + int(78 * scale)
    card_h = int(110 * scale)
    mx = pad
    mw = fw - pad * 2
    rounded_rect(d, (mx, cy, mx + mw, cy + card_h), int(18 * scale), fill=C["surface"], outline=C["border"], width=1)
    d.text((mx + int(14 * scale), cy + int(12 * scale)), "Your Journey", font=load_text_font(int(16 * scale)), fill=C["section_title"])

    stat_w = (mw - int(32 * scale)) // 3
    stats = [("12", "Completed", "🏁"), ("28", "Stars", "⭐"), ("5", "Gold", "👑")]
    for i, (val, label, icon) in enumerate(stats):
        sx = mx + int(14 * scale) + i * (stat_w + int(4 * scale))
        sy = cy + int(38 * scale)
        rounded_rect(d, (sx, sy, sx + stat_w - int(6 * scale), sy + int(58 * scale)), int(12 * scale), fill=C["fill"])
        draw_emoji(d, icon, sx + int(8 * scale), sy + int(4 * scale), int(16 * scale))
        d.text((sx + int(10 * scale), sy + int(24 * scale)), val, font=load_text_font(int(20 * scale)), fill=C["text_primary"])
        d.text((sx + int(10 * scale), sy + int(42 * scale)), label, font=load_text_font(int(10 * scale)), fill=C["text_secondary"])

    # play button
    by = cy + card_h + int(18 * scale)
    rounded_rect(d, (mx, by, mx + mw, by + int(54 * scale)), int(27 * scale), fill=C["cta_orange"])
    play_font = load_text_font(int(18 * scale))
    pt = "Play Level 13"
    bbox = d.textbbox((0, 0), pt, font=play_font)
    tw = bbox[2] - bbox[0]
    block_w = tw + int(34 * scale)
    start_x = mx + (mw - block_w) // 2
    draw_play_triangle(d, start_x, by + int(15 * scale), int(16 * scale))
    d.text((start_x + int(28 * scale), by + int(15 * scale)), pt, font=play_font, fill=C["white"])

    # tip card
    ty = by + int(68 * scale)
    rounded_rect(d, (mx, ty, mx + mw, ty + int(52 * scale)), int(14 * scale), fill=C["surface"], outline=C["border"], width=1)
    draw_emoji(d, "💡", mx + int(12 * scale), ty + int(8 * scale), int(16 * scale))
    d.text((mx + int(36 * scale), ty + int(10 * scale)), "Tip: Match pairs quickly for 3 stars!", font=load_text_font(int(12 * scale)), fill=C["text_secondary"])

    content.paste(layer, (fx, fy))


def mock_levels(content: Image.Image, frame: tuple, scale: float):
    fx, fy, fw, fh = frame
    layer = sky_bg(fw, fh)
    d = ImageDraw.Draw(layer)
    pad = int(20 * scale)
    d.text((pad, pad + int(8 * scale)), "Levels", font=load_text_font(int(22 * scale)), fill=C["text_primary"])

    levels = [
        ("1", "Warm Up", "2×2 grid · Easy", 3, False),
        ("2", "Getting Started", "2×3 grid", 2, False),
        ("3", "Quick Eyes", "3×2 grid", 1, False),
        ("4", "Focus Time", "3×3 grid", 0, False),
        ("5", "Pattern Pro", "3×3 grid", 0, True),
        ("6", "Memory Boost", "4×3 grid", 0, True),
    ]
    y = pad + int(48 * scale)
    row_h = int(72 * scale)
    for num, title, sub, stars, locked in levels:
        rounded_rect(d, (pad, y, fw - pad, y + row_h - int(8 * scale)), int(16 * scale), fill=C["surface"], outline=C["border"], width=1)
        badge_r = int(22 * scale)
        bx = pad + int(14 * scale)
        by = y + int(14 * scale)
        badge_color = C["fill"] if locked else C["brand"]
        d.ellipse((bx, by, bx + badge_r * 2, by + badge_r * 2), fill=badge_color)
        num_font = load_text_font(int(16 * scale))
        nb = d.textbbox((0, 0), num, font=num_font)
        d.text((bx + badge_r - (nb[2] - nb[0]) // 2, by + badge_r - (nb[3] - nb[1]) // 2 - 2), num, font=num_font, fill=C["white"] if not locked else C["text_tertiary"])

        tx = bx + badge_r * 2 + int(14 * scale)
        d.text((tx, y + int(14 * scale)), title, font=load_text_font(int(15 * scale)), fill=C["text_secondary"] if locked else C["text_primary"])
        d.text((tx, y + int(34 * scale)), sub, font=load_text_font(int(11 * scale)), fill=C["text_secondary"])
        d.text((tx, y + int(50 * scale)), "Match all pairs", font=load_text_font(int(10 * scale)), fill=C["link"])

        if locked:
            draw_emoji(d, "🔒", fw - pad - int(30 * scale), y + int(20 * scale), int(18 * scale))
        else:
            for si in range(3):
                col = C["star"] if si < stars else C["track"]
                stx = fw - pad - int(66 * scale) + si * int(20 * scale)
                d.text((stx, y + int(24 * scale)), "★", font=load_text_font(int(16 * scale)), fill=col)
        y += row_h

    content.paste(layer, (fx, fy))


def mock_gameplay(content: Image.Image, frame: tuple, scale: float):
    fx, fy, fw, fh = frame
    layer = sky_bg(fw, fh)
    d = ImageDraw.Draw(layer)
    pad = int(18 * scale)

    # HUD
    rounded_rect(d, (pad, pad, fw - pad, pad + int(52 * scale)), int(16 * scale), fill=C["surface"], outline=C["border"], width=1)
    d.text((pad + int(12 * scale), pad + int(8 * scale)), "Level 8", font=load_text_font(int(14 * scale)), fill=C["text_primary"])
    d.text((pad + int(12 * scale), pad + int(28 * scale)), "Moves: 6", font=load_text_font(int(11 * scale)), fill=C["text_secondary"])
    draw_emoji(d, "⏱", fw // 2 - int(38 * scale), pad + int(14 * scale), int(16 * scale))
    d.text((fw // 2 - int(16 * scale), pad + int(16 * scale)), "0:42", font=load_text_font(int(16 * scale)), fill=C["text_primary"])
    for hi in range(3):
        draw_emoji(d, "❤️", fw - pad - int(66 * scale) + hi * int(20 * scale), pad + int(16 * scale), int(15 * scale))

    # objective
    oy = pad + int(62 * scale)
    rounded_rect(d, (pad, oy, fw - pad, oy + int(36 * scale)), int(12 * scale), fill=C["fill"])
    draw_emoji(d, "🎯", pad + int(12 * scale), oy + int(8 * scale), int(14 * scale))
    d.text((pad + int(34 * scale), oy + int(10 * scale)), "Match all 6 pairs", font=load_text_font(int(12 * scale)), fill=C["section_title"])

    # card grid 3x4
    cols, rows = 3, 4
    card_size = int(min((fw - pad * 2 - int(16 * scale) * (cols - 1)) / cols, int(130 * scale)))
    gap = int(12 * scale)
    grid_w = cols * card_size + (cols - 1) * gap
    gx = (fw - grid_w) // 2
    gy = oy + int(52 * scale)

    faces = ["🍎", "🍎", "🐶", "🐶", "⭐", "⭐", "🎈", "🎈", "🌈", "🌈", "🎵", "🎵"]
    idx = 0
    for r in range(rows):
        for c in range(cols):
            x = gx + c * (card_size + gap)
            y = gy + r * (int(card_size * 1.15) + gap)
            if idx in (0, 1, 4, 5, 8):  # some flipped
                draw_card_face(d, x, y, card_size, faces[idx])
            else:
                draw_card_back(d, x, y, card_size)
            idx += 1

    content.paste(layer, (fx, fy))


def mock_victory(content: Image.Image, frame: tuple, scale: float):
    fx, fy, fw, fh = frame
    layer = sky_bg(fw, fh)
    d = ImageDraw.Draw(layer)
    pad = int(22 * scale)

    draw_emoji(d, "🎉", fw // 2 - int(28 * scale), pad, int(52 * scale))

    rounded_rect(d, (pad, pad + int(70 * scale), fw - pad, pad + int(170 * scale)), int(20 * scale), fill=C["surface"], outline=C["border"], width=1)
    hf = load_text_font(int(20 * scale))
    hb = d.textbbox((0, 0), "Level Complete!", font=hf)
    d.text((fw // 2 - (hb[2] - hb[0]) // 2, pad + int(82 * scale)), "Level Complete!", font=hf, fill=C["text_primary"])
    star_size = int(28 * scale)
    for si in range(3):
        draw_emoji(d, "⭐", fw // 2 - int(44 * scale) + si * int(32 * scale), pad + int(116 * scale), star_size)
    pf = load_text_font(int(13 * scale))
    pb = d.textbbox((0, 0), "Perfect match!", font=pf)
    d.text((fw // 2 - (pb[2] - pb[0]) // 2, pad + int(154 * scale)), "Perfect match!", font=pf, fill=C["text_secondary"])

    # stats
    sy = pad + int(188 * scale)
    rounded_rect(d, (pad, sy, fw - pad, sy + int(100 * scale)), int(18 * scale), fill=C["surface"], outline=C["border"], width=1)
    d.text((pad + int(16 * scale), sy + int(12 * scale)), "Your Results", font=load_text_font(int(15 * scale)), fill=C["section_title"])
    stats = [("Moves", "8"), ("Time", "1:24"), ("Accuracy", "100%")]
    sw = (fw - pad * 2 - int(32 * scale)) // 3
    for i, (label, val) in enumerate(stats):
        sx = pad + int(16 * scale) + i * sw
        d.text((sx, sy + int(40 * scale)), label, font=load_text_font(int(11 * scale)), fill=C["text_secondary"])
        d.text((sx, sy + int(58 * scale)), val, font=load_text_font(int(20 * scale)), fill=C["text_primary"])

    # buttons
    by = sy + int(118 * scale)
    rounded_rect(d, (pad, by, fw - pad, by + int(48 * scale)), int(24 * scale), fill=C["cta_orange"])
    bt = "Next Level"
    btf = load_text_font(int(16 * scale))
    btb = d.textbbox((0, 0), bt, font=btf)
    tw = btb[2] - btb[0]
    startx = fw // 2 - (tw + int(24 * scale)) // 2
    d.text((startx, by + int(14 * scale)), bt, font=btf, fill=C["white"])
    draw_play_triangle(d, startx + tw + int(8 * scale), by + int(15 * scale), int(15 * scale))

    content.paste(layer, (fx, fy))


def mock_achievements(content: Image.Image, frame: tuple, scale: float):
    fx, fy, fw, fh = frame
    layer = sky_bg(fw, fh)
    d = ImageDraw.Draw(layer)
    pad = int(20 * scale)
    d.text((pad, pad + int(6 * scale)), "Achievements", font=load_text_font(int(22 * scale)), fill=C["text_primary"])

    badges = [
        ("🏅", "First Win", "Complete your first level", True),
        ("🔥", "On a Roll", "Win 5 levels in a row", True),
        ("⭐️", "Star Collector", "Earn 25 stars", True),
        ("👑", "Gold Rush", "Get 3 stars on 5 levels", False),
        ("🧠", "Memory Master", "Complete 25 levels", False),
        ("🏆", "Champion", "Beat all 50 levels", False),
    ]
    y = pad + int(50 * scale)
    for icon, title, desc, earned in badges:
        h = int(68 * scale)
        rounded_rect(d, (pad, y, fw - pad, y + h), int(16 * scale), fill=C["surface"], outline=C["border"], width=1)
        # circular badge behind icon (brand gradient when earned)
        br = int(22 * scale)
        bcx, bcy = pad + int(16 * scale), y + int(12 * scale)
        d.ellipse((bcx, bcy, bcx + br * 2, bcy + br * 2), fill=C["brand"] if earned else C["fill"])
        draw_emoji(d, icon, bcx + int(8 * scale), bcy + int(8 * scale), int(24 * scale))
        d.text((bcx + br * 2 + int(14 * scale), y + int(14 * scale)), title, font=load_text_font(int(15 * scale)), fill=C["text_primary"] if earned else C["text_secondary"])
        d.text((bcx + br * 2 + int(14 * scale), y + int(36 * scale)), desc, font=load_text_font(int(11 * scale)), fill=C["text_secondary"])
        if earned:
            d.text((fw - pad - int(30 * scale), y + int(22 * scale)), "✓", font=load_text_font(int(22 * scale)), fill=C["success"])
        else:
            draw_emoji(d, "🔒", fw - pad - int(30 * scale), y + int(22 * scale), int(16 * scale))
        y += h + int(10 * scale)

    content.paste(layer, (fx, fy))


def mock_ipad_home(content: Image.Image, frame: tuple, scale: float):
    """Wider iPad layout with side-by-side stats."""
    fx, fy, fw, fh = frame
    layer = sky_bg(fw, fh)
    d = ImageDraw.Draw(layer)
    pad = int(36 * scale)

    cx = fw // 2
    r = int(56 * scale)
    d.ellipse((cx - r, pad, cx + r, pad + r * 2), fill=(91, 141, 239, 70))
    d.ellipse((cx - r, pad, cx + r, pad + r * 2), outline=C["accent"], width=3)
    draw_emoji(d, "🧠", cx - int(22 * scale), pad + int(24 * scale), int(48 * scale))
    tf = load_text_font(int(36 * scale))
    tb = d.textbbox((0, 0), "Memory Match", font=tf)
    d.text((cx - (tb[2] - tb[0]) // 2, pad + r * 2 + int(10 * scale)), "Memory Match", font=tf, fill=C["accent"])

    # two column layout
    left_x = pad
    right_x = fw // 2 + int(12 * scale)
    col_w = fw // 2 - pad - int(18 * scale)
    top_y = pad + r * 2 + int(70 * scale)

    rounded_rect(d, (left_x, top_y, left_x + col_w, top_y + int(200 * scale)), int(20 * scale), fill=C["surface"], outline=C["border"], width=1)
    d.text((left_x + int(18 * scale), top_y + int(16 * scale)), "Your Journey", font=load_text_font(int(20 * scale)), fill=C["section_title"])
    stats = [("12", "Levels Done"), ("28", "Total Stars"), ("5", "Gold Levels")]
    for i, (val, label) in enumerate(stats):
        sy = top_y + int(56 * scale) + i * int(48 * scale)
        rounded_rect(d, (left_x + int(16 * scale), sy, left_x + col_w - int(16 * scale), sy + int(40 * scale)), int(12 * scale), fill=C["fill"])
        d.text((left_x + int(28 * scale), sy + int(8 * scale)), val, font=load_text_font(int(22 * scale)), fill=C["text_primary"])
        d.text((left_x + int(80 * scale), sy + int(12 * scale)), label, font=load_text_font(int(14 * scale)), fill=C["text_secondary"])

    rounded_rect(d, (right_x, top_y, right_x + col_w, top_y + int(200 * scale)), int(20 * scale), fill=C["surface"], outline=C["border"], width=1)
    d.text((right_x + int(18 * scale), top_y + int(16 * scale)), "Continue Playing", font=load_text_font(int(20 * scale)), fill=C["section_title"])
    rounded_rect(d, (right_x + int(16 * scale), top_y + int(56 * scale), right_x + col_w - int(16 * scale), top_y + int(110 * scale)), int(16 * scale), fill=C["fill"])
    d.text((right_x + int(28 * scale), top_y + int(68 * scale)), "Level 13 — Pattern Match", font=load_text_font(int(16 * scale)), fill=C["text_primary"])
    d.text((right_x + int(28 * scale), top_y + int(92 * scale)), "4×3 grid · Match 6 pairs", font=load_text_font(int(13 * scale)), fill=C["text_secondary"])
    rounded_rect(d, (right_x + int(16 * scale), top_y + int(124 * scale), right_x + col_w - int(16 * scale), top_y + int(170 * scale)), int(24 * scale), fill=C["cta_orange"])
    draw_play_triangle(d, right_x + int(70 * scale), top_y + int(138 * scale), int(16 * scale))
    d.text((right_x + int(94 * scale), top_y + int(138 * scale)), "Play Now", font=load_text_font(int(18 * scale)), fill=C["white"])

    # mini game preview bottom
    gy = top_y + int(220 * scale)
    rounded_rect(d, (pad, gy, fw - pad, gy + int(280 * scale)), int(20 * scale), fill=C["surface"], outline=C["border"], width=1)
    d.text((pad + int(18 * scale), gy + int(14 * scale)), "Quick Match Preview", font=load_text_font(int(18 * scale)), fill=C["section_title"])
    card_size = int(72 * scale)
    gap = int(14 * scale)
    gx = pad + int(40 * scale)
    gyy = gy + int(60 * scale)
    emojis = ["🍎", "🍎", "🐶", "?", "⭐", "?", "🎈", "🎈"]
    for i, em in enumerate(emojis):
        x = gx + (i % 4) * (card_size + gap)
        y = gyy + (i // 4) * (int(card_size * 1.15) + gap)
        if em == "?":
            draw_card_back(d, x, y, card_size)
        else:
            draw_card_face(d, x, y, card_size, em)

    content.paste(layer, (fx, fy))


SCREENSHOTS = [
    {
        "id": "01_hero",
        "headline": "Train Your Memory",
        "subtitle": "Delightful bite-sized levels for all ages",
        "hue": "pink",
        "mock": "home",
        "content_h": 0.62,
        "content_h_ipad": 0.72,
    },
    {
        "id": "02_levels",
        "headline": "50 Progressive Levels",
        "subtitle": "From easy 2×2 grids to expert challenges",
        "hue": "blue",
        "mock": "levels",
        "content_h": 0.92,
        "content_h_ipad": 0.9,
    },
    {
        "id": "03_gameplay",
        "headline": "Flip. Match. Win!",
        "subtitle": "Beautiful cards, smooth animations & fun emojis",
        "hue": "purple",
        "mock": "gameplay",
        "content_h": 1.0,
        "content_h_ipad": 0.95,
    },
    {
        "id": "04_victory",
        "headline": "Earn Stars & Celebrate",
        "subtitle": "Track moves, time & accuracy on every win",
        "hue": "sunset",
        "mock": "victory",
        "content_h": 0.6,
        "content_h_ipad": 0.7,
    },
    {
        "id": "05_achievements",
        "headline": "Unlock Achievements",
        "subtitle": "Badges, streaks & milestones keep you going",
        "hue": "green",
        "mock": "achievements",
        "content_h": 0.92,
        "content_h_ipad": 0.9,
    },
]


def render_screenshot(size: tuple[int, int], spec: dict, is_ipad: bool) -> Image.Image:
    w, h = size
    scale = w / 1290  # base scale from iPhone width
    if is_ipad:
        scale *= 0.85

    img = marketing_gradient(size, spec["hue"]).convert("RGBA")
    draw = ImageDraw.Draw(img)

    # headline area
    headline_size = int(72 * scale) if not is_ipad else int(88 * scale)
    sub_size = int(28 * scale) if not is_ipad else int(34 * scale)
    headline_font = load_text_font(headline_size)
    sub_font = load_text_font(sub_size)

    hy = int(120 * scale) if not is_ipad else int(140 * scale)
    draw_text_centered(draw, spec["headline"], hy, w, headline_font, C["white"], shadow=True)
    draw_subtitle_centered(draw, spec["subtitle"], hy + headline_size + int(16 * scale), w, sub_font, (255, 255, 255, 220))

    # app icon badge top-left area (optional small branding)
    if ICON_PATH.exists():
        icon = Image.open(ICON_PATH).convert("RGBA").resize((int(56 * scale), int(56 * scale)), Image.LANCZOS)
        mask = Image.new("L", icon.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, icon.size[0], icon.size[1]), radius=int(12 * scale), fill=255)
        icon.putalpha(mask)
        img.alpha_composite(icon, (int(40 * scale), int(40 * scale)))

    content_h = spec.get("content_h_ipad" if is_ipad else "content_h", 1.0)
    frame = phone_frame(size, is_ipad, content_h=content_h)
    draw_device_shell(img, frame, is_ipad)

    fw = frame[2]
    # Mock UI was designed against a ~380pt reference width; scale content so it
    # fills the device frame width edge-to-edge (no dead space).
    mock_scale = fw / (760.0 if is_ipad else 380.0)

    mock_fn = {
        "home": mock_home,
        "levels": mock_levels,
        "gameplay": mock_gameplay,
        "victory": mock_victory,
        "achievements": mock_achievements,
    }[spec["mock"]]

    if is_ipad and spec["mock"] == "home":
        mock_ipad_home(img, frame, mock_scale)
    else:
        mock_fn(img, frame, mock_scale)

    return img.convert("RGB")


def main():
    iphone_dir = OUT_DIR / "iPhone_6.7"
    ipad_dir = OUT_DIR / "iPad_12.9"
    iphone_dir.mkdir(parents=True, exist_ok=True)
    ipad_dir.mkdir(parents=True, exist_ok=True)

    for spec in SCREENSHOTS:
        iphone_img = render_screenshot(IPHONE_SIZE, spec, is_ipad=False)
        ipad_spec = dict(spec)
        if spec["mock"] == "home":
            ipad_spec["mock"] = "home"  # uses mock_ipad_home
        ipad_img = render_screenshot(IPAD_SIZE, spec, is_ipad=True)

        iphone_path = iphone_dir / f"{spec['id']}.png"
        ipad_path = ipad_dir / f"{spec['id']}.png"
        iphone_img.save(iphone_path, "PNG", optimize=True)
        ipad_img.save(ipad_path, "PNG", optimize=True)
        print(f"✓ {iphone_path.name}  ({IPHONE_SIZE[0]}×{IPHONE_SIZE[1]})")
        print(f"✓ {ipad_path.name}  ({IPAD_SIZE[0]}×{IPAD_SIZE[1]})")

    print(f"\nDone! {len(SCREENSHOTS)} screenshots × 2 devices → {OUT_DIR}")


if __name__ == "__main__":
    main()
