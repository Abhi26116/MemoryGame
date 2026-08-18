#!/usr/bin/env python3
"""
Build App Store marketing screenshots for Memory Match (v1.1).

Reads raw simulator captures (1290x2796, dark mode) and composites them into
marketing frames at every size App Store Connect accepts for iPhone.

Key differences from the v1.0 set this replaces:
  * headline type roughly 2x larger, so it survives the gallery thumbnail
  * device art fills ~72% of the canvas instead of ~55% (no dead margins)
  * the redundant app-icon lockup at the top is gone
  * a clean synthetic status bar (9:41, full battery) replaces the captured one,
    because `simctl status_bar override` is a no-op on the iOS 17.2 runtime here
  * copy is benefit-led and each frame makes a different claim

Usage:  python3 scripts/build_store_assets.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
CAPS = Path(
    "/private/tmp/claude-501/-Users-mac-MemoryGame/"
    "0c4e5652-4d25-44c6-a5d9-2280fe9764f8/scratchpad/caps"
)
OUT = ROOT / "AppStoreScreenshots_v1.1"

FREDOKA = str(ROOT / "MemoryGame/Resources/Fredoka.ttf")
SF_TEXT = "/System/Library/Fonts/SFNSText.ttf"
SF_DISPLAY = "/System/Library/Fonts/SFNS.ttf"
HELV = "/System/Library/Fonts/HelveticaNeue.ttc"

# Output canvases per device family. 6.9" and 13" are the sizes Apple asks for
# first; the smaller pair fills the slots the current listing already uses.
# `prefix` selects which raw captures feed the set (d_* iPhone, p_* iPad).
DEVICES = {
    "iphone": dict(
        prefix="d_",
        capture=(1290, 2796),
        ref_width=1320,
        device_frac=0.76,
        island=True,
        canvases={"iPhone_6.9": (1320, 2868), "iPhone_6.5": (1284, 2778)},
    ),
    "ipad": dict(
        prefix="p_",
        capture=(2048, 2732),
        ref_width=2048,
        # iPad is far wider relative to its height, so the slab has to be
        # narrower as a fraction of the canvas or it crowds the headline out.
        device_frac=0.74,
        island=False,
        canvases={"iPad_13": (2064, 2752), "iPad_12.9": (2048, 2732)},
    ),
}

BRAND = {
    "blue": (91, 141, 239),
    "pink": (255, 107, 157),
    "purple": (155, 77, 239),
    "orange": (255, 149, 0),
    "green": (52, 199, 89),
    "deep": (18, 24, 38),
}

# (source capture, headline, subtitle, gradient stops, crop hint)
# `crop` used to trim a dead band out of the game screens: the board was
# bottom-anchored and left a void under the objective banner. GameView now
# spreads that slack into the row gaps, so the captures need no doctoring and
# crop is off. The machinery is kept for any future screen that needs it.
FRAMES = [
    dict(
        src="preview",
        head="Can You Remember\nAll 30?",
        sub="Study the board — then match it from memory",
        grad=((124, 92, 255), (91, 141, 239), (34, 52, 110)),
        crop=False,
    ),
    dict(
        src="math",
        head="More Than\nJust Matching",
        sub="Letters, opposites, flags, sums & baby animals",
        grad=((255, 107, 157), (196, 77, 255), (74, 48, 140)),
        crop=False,
    ),
    dict(
        src="game4x4",
        head="50 Levels That\nGrow With You",
        sub="From 4 cards to 30, with hearts and timers",
        grad=((91, 141, 239), (62, 111, 214), (24, 40, 78)),
        crop=False,
    ),
    dict(
        src="win",
        head="Beat Your\nBest Every Time",
        sub="Stars, accuracy, combos and record times",
        grad=((255, 168, 46), (255, 94, 58), (150, 40, 70)),
        crop=False,
    ),
    dict(
        src="home",
        head="Play Anywhere.\nNo WiFi Needed.",
        sub="Fully offline. No login, no interruptions.",
        grad=((52, 199, 89), (26, 143, 120), (18, 52, 78)),
        crop=False,
    ),
    dict(
        src="awards",
        head="Collect Every\nTrophy",
        sub="10 achievements and a daily streak to keep",
        grad=((255, 176, 32), (233, 96, 88), (92, 38, 96)),
        crop=False,
    ),
]


# --------------------------------------------------------------------------
# drawing helpers
# --------------------------------------------------------------------------

def font(path: str, size: int, weight: float | None = None) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(path, size)
    if weight is not None:
        try:
            f.set_variation_by_axes([weight, 100])
        except Exception:
            pass
    return f


def lerp(a, b, t):
    return tuple(int(x + (y - x) * t) for x, y in zip(a, b))


def gradient(size, stops) -> Image.Image:
    """Three-stop vertical gradient with a soft diagonal light source."""
    w, h = size
    top, mid, bot = stops
    base = Image.new("RGB", (1, h))
    px = base.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        px[0, y] = lerp(top, mid, t / 0.5) if t < 0.5 else lerp(mid, bot, (t - 0.5) / 0.5)
    img = base.resize(size, Image.BILINEAR)

    glow = Image.new("L", (w // 4, h // 4), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse((-w // 8, -h // 20, w // 3, h // 8), fill=70)
    gd.ellipse((w // 6, h // 6, w // 4 + w // 8, h // 4), fill=38)
    glow = glow.resize(size, Image.BILINEAR).filter(ImageFilter.GaussianBlur(w // 12))
    img = Image.composite(Image.new("RGB", size, (255, 255, 255)), img, glow.point(lambda v: v // 2))
    return img


def rounded_shadow(size, radius, blur, spread, opacity) -> Image.Image:
    w, h = size
    pad = blur * 3
    layer = Image.new("L", (w + pad * 2, h + pad * 2), 0)
    ImageDraw.Draw(layer).rounded_rectangle(
        (pad - spread, pad - spread, pad + w + spread, pad + h + spread),
        radius=radius + spread, fill=opacity,
    )
    return layer.filter(ImageFilter.GaussianBlur(blur))


def draw_status_bar(screen: Image.Image, scale: float, island: bool = True) -> None:
    """Paint a clean 9:41 / full-battery status bar over the captured one.

    The runtime ignores `simctl status_bar override`, so the raw captures carry
    a live clock, a dead cellular indicator and a partial battery. Rather than
    ship that, the strip is repainted from the screen's own background colour.
    """
    d = ImageDraw.Draw(screen)
    w = screen.width
    bar_h = int(150 * scale)

    # Sample the background just under the bar so the patch is invisible.
    bg = screen.getpixel((int(w * 0.06), bar_h + int(10 * scale)))
    d.rectangle((0, 0, w, bar_h), fill=bg)

    fg = (255, 255, 255) if sum(bg) < 380 else (12, 18, 30)
    f_clock = font(SF_DISPLAY, int(58 * scale), None)

    # iPad has no Dynamic Island and puts the clock hard left; iPhone centres
    # the island and shows cellular bars.
    clock_x = 0.135 if island else 0.058
    d.text((int(w * clock_x), int(58 * scale)), "9:41", font=f_clock, fill=fg, anchor="mm")

    if island:
        isl_w, isl_h = int(370 * scale), int(105 * scale)
        d.rounded_rectangle(
            ((w - isl_w) // 2, int(26 * scale), (w + isl_w) // 2, int(26 * scale) + isl_h),
            radius=isl_h // 2, fill=(0, 0, 0),
        )

        x = int(w * 0.735)
        base_y = int(78 * scale)
        for i in range(4):
            bh = int((13 + i * 7) * scale)
            bw = int(11 * scale)
            d.rounded_rectangle((x, base_y - bh, x + bw, base_y), radius=int(3 * scale), fill=fg)
            x += int(17 * scale)

    # wifi
    cx, cy = int(w * (0.845 if island else 0.915)), int(70 * scale)
    for i, r in enumerate((int(34 * scale), int(23 * scale), int(12 * scale))):
        d.arc((cx - r, cy - r, cx + r, cy + r), 215, 325, fill=fg, width=int(8 * scale))
    d.ellipse((cx - int(5 * scale), cy + int(10 * scale),
               cx + int(5 * scale), cy + int(20 * scale)), fill=fg)

    # battery, full
    bx, by = int(w * (0.895 if island else 0.945)), int(52 * scale)
    bw, bh = int(70 * scale), int(34 * scale)
    d.rounded_rectangle((bx, by, bx + bw, by + bh), radius=int(10 * scale),
                        outline=fg, width=int(4 * scale))
    d.rounded_rectangle((bx + int(5 * scale), by + int(5 * scale),
                         bx + bw - int(5 * scale), by + bh - int(5 * scale)),
                        radius=int(5 * scale), fill=fg)
    d.rounded_rectangle((bx + bw + int(3 * scale), by + int(11 * scale),
                         bx + bw + int(8 * scale), by + bh - int(11 * scale)),
                        radius=int(3 * scale), fill=fg)


def find_dead_band(img: Image.Image, search=(0.28, 0.62), min_run=90) -> tuple[int, int] | None:
    """Locate the longest run of visually empty rows in the middle of a screen.

    On a 6.7" screen the game board is bottom-anchored, so there is a tall band
    of flat background between the objective banner and the first row of cards.
    It reads as emptiness at thumbnail size. Rows are "empty" when every sample
    across the row is within a small tolerance of the row's own mean, which is
    true of the gradient background and false of any card, banner or text.
    """
    w, h = img.size
    px = img.load()
    xs = range(int(w * 0.06), int(w * 0.94), 12)
    y0, y1 = int(h * search[0]), int(h * search[1])

    flat = []
    for y in range(y0, y1):
        vals = [px[x, y] for x in xs]
        mean = [sum(c[i] for c in vals) / len(vals) for i in range(3)]
        if max(max(abs(c[i] - mean[i]) for i in range(3)) for c in vals) < 14:
            flat.append(y)

    if not flat:
        return None

    best = run_start = flat[0]
    best_len = run_len = 1
    prev = flat[0]
    for y in flat[1:]:
        if y == prev + 1:
            run_len += 1
        else:
            run_start, run_len = y, 1
        if run_len > best_len:
            best, best_len = run_start, run_len
        prev = y

    if best_len < min_run:
        return None
    # Leave a little breathing room at both ends so the cut is invisible.
    keep = 34
    return best + keep, best + best_len - keep


def draw_status_bar_ipad(screen: Image.Image) -> None:
    """Repaint the iPad status bar: 24pt tall, clock left, wifi + battery right.

    Deliberately NOT a scaled version of the iPhone bar — the iPad strip is a
    third of the height but carries proportionally larger text, so scaling the
    iPhone geometry painted straight over the navigation bar underneath.
    """
    d = ImageDraw.Draw(screen)
    w = screen.width
    bar_h = 50   # 24pt at @2x, plus a pixel of slack

    bg = screen.getpixel((int(w * 0.5), bar_h + 6))
    d.rectangle((0, 0, w, bar_h), fill=bg)

    fg = (255, 255, 255) if sum(bg) < 380 else (12, 18, 30)
    f = font(SF_DISPLAY, 30, None)

    d.text((32, bar_h // 2), "9:41 AM", font=f, fill=fg, anchor="lm")

    # wifi
    cx, cy = w - 205, bar_h // 2 - 2
    for r in (19, 13, 7):
        d.arc((cx - r, cy - r, cx + r, cy + r), 215, 325, fill=fg, width=5)
    d.ellipse((cx - 3, cy + 7, cx + 3, cy + 13), fill=fg)

    d.text((w - 168, bar_h // 2), "100%", font=f, fill=fg, anchor="lm")

    bx, by, bw, bh = w - 78, bar_h // 2 - 12, 52, 25
    d.rounded_rectangle((bx, by, bx + bw, by + bh), radius=7, outline=fg, width=3)
    d.rounded_rectangle((bx + 4, by + 4, bx + bw - 4, by + bh - 4), radius=4, fill=fg)
    d.rounded_rectangle((bx + bw + 3, by + 8, bx + bw + 7, by + bh - 8), radius=2, fill=fg)


def prepare_screen(name: str, crop: bool, profile: dict) -> Image.Image:
    """Load a capture, repaint its status bar, and squeeze out dead space."""
    capture_size = profile["capture"]
    img = Image.open(CAPS / f"{profile['prefix']}{name}.png").convert("RGB")
    if img.size != capture_size:
        img = img.resize(capture_size, Image.LANCZOS)

    if profile["island"]:
        draw_status_bar(img, scale=img.width / 1290, island=True)
    else:
        draw_status_bar_ipad(img)

    if crop:
        band = find_dead_band(img)
        if band:
            y0, y1 = band
            top = img.crop((0, 0, img.width, y0))
            bottom = img.crop((0, y1, img.width, img.height))
            out = Image.new("RGB", (img.width, top.height + bottom.height))
            out.paste(top, (0, 0))
            out.paste(bottom, (0, top.height))
            # Re-stretch to the true device aspect so the phone frame stays honest.
            img = out.resize(capture_size, Image.LANCZOS)
    return img


def device_frame(screen: Image.Image, target_w: int, profile: dict) -> tuple[Image.Image, Image.Image]:
    """Wrap a screen capture in a titanium-style device body. Returns (rgba, shadow)."""
    capture_size = profile["capture"]
    aspect = capture_size[1] / capture_size[0]
    sw = target_w
    sh = int(sw * aspect)
    bezel = max(6, int(sw * (0.026 if profile["island"] else 0.021)))
    # iPad corners are much less rounded relative to the slab width.
    radius = int(sw * (0.135 if profile["island"] else 0.045))

    body_w, body_h = sw + bezel * 2, sh + bezel * 2
    body = Image.new("RGBA", (body_w, body_h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)

    # brushed metal edge
    bd.rounded_rectangle((0, 0, body_w, body_h), radius=radius + bezel, fill=(198, 202, 212, 255))
    bd.rounded_rectangle((int(bezel * 0.35), int(bezel * 0.35),
                          body_w - int(bezel * 0.35), body_h - int(bezel * 0.35)),
                         radius=radius + int(bezel * 0.6), fill=(88, 94, 108, 255))
    bd.rounded_rectangle((bezel * 0.8, bezel * 0.8, body_w - bezel * 0.8, body_h - bezel * 0.8),
                         radius=radius + int(bezel * 0.2), fill=(14, 16, 22, 255))

    screen_r = Image.new("RGBA", (sw, sh), 0)
    screen_r.paste(screen.resize((sw, sh), Image.LANCZOS), (0, 0))
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius=radius, fill=255)
    body.paste(screen_r, (bezel, bezel), mask)

    shadow = rounded_shadow((body_w, body_h), radius + bezel,
                            blur=int(sw * 0.075), spread=int(sw * 0.012), opacity=120)
    return body, shadow


def wrap_center(draw, text, fnt, max_w):
    lines = []
    for para in text.split("\n"):
        words, cur = para.split(), ""
        for word in words:
            trial = f"{cur} {word}".strip()
            if draw.textlength(trial, font=fnt) <= max_w or not cur:
                cur = trial
            else:
                lines.append(cur)
                cur = word
        lines.append(cur)
    return lines


# --------------------------------------------------------------------------
# frame composition
# --------------------------------------------------------------------------

def build_frame(spec: dict, canvas: tuple[int, int], profile: dict) -> Image.Image:
    W, H = canvas
    s = W / profile["ref_width"]

    img = gradient(canvas, spec["grad"]).convert("RGBA")

    # Soft top-down scrim. The gold/amber frame puts white type on a light
    # background, which fails at thumbnail size; a scrim fixes that frame
    # without making the darker ones look different.
    scrim_h = int(H * 0.24)
    scrim = Image.new("L", (1, scrim_h))
    sp = scrim.load()
    for y in range(scrim_h):
        sp[0, y] = int(74 * (1 - y / scrim_h) ** 1.5)
    scrim = scrim.resize((W, scrim_h), Image.BILINEAR)
    img.paste(Image.new("RGB", (W, scrim_h), (10, 12, 26)), (0, 0), scrim)

    d = ImageDraw.Draw(img)

    head_size = int(112 * s)
    f_head = font(FREDOKA, head_size, weight=600)
    f_sub = font(HELV, int(46 * s), None)

    margin = int(78 * s)
    max_text_w = W - margin * 2

    lines = wrap_center(d, spec["head"], f_head, max_text_w)
    while len(lines) > 2 and head_size > 70 * s:
        head_size -= int(6 * s)
        f_head = font(FREDOKA, head_size, weight=600)
        lines = wrap_center(d, spec["head"], f_head, max_text_w)

    line_h = int(head_size * 1.14)
    y = int(118 * s)
    for line in lines:
        d.text((W // 2 + int(3 * s), y + int(4 * s)), line, font=f_head,
               fill=(0, 0, 0, 90), anchor="ma")
        d.text((W // 2, y), line, font=f_head, fill=(255, 255, 255, 255), anchor="ma")
        y += line_h

    y += int(14 * s)
    for line in wrap_center(d, spec["sub"], f_sub, int(max_text_w * 0.94)):
        d.text((W // 2, y), line, font=f_sub, fill=(255, 255, 255, 225), anchor="ma")
        y += int(60 * s)

    # Device: as wide as the canvas allows, bleeding off the bottom edge so the
    # frame reads as a real phone rather than a floating sticker.
    screen = prepare_screen(spec["src"], spec["crop"], profile)
    body, shadow = device_frame(screen, target_w=int(W * profile["device_frac"]), profile=profile)
    bx = (W - body.width) // 2
    by = y + int(56 * s)

    pad = shadow.width - body.width
    img.paste((0, 0, 0), (bx - pad // 2, by - pad // 2 + int(26 * s)), shadow)
    img.paste(body, (bx, by), body)
    return img.convert("RGB")


def main() -> None:
    for profile in DEVICES.values():
        for label, canvas in profile["canvases"].items():
            out_dir = OUT / label
            out_dir.mkdir(parents=True, exist_ok=True)
            for i, spec in enumerate(FRAMES, start=1):
                frame = build_frame(spec, canvas, profile)
                path = out_dir / f"{i:02d}_{spec['src']}.png"
                frame.save(path, "PNG", optimize=True)
                print(f"  {path.relative_to(ROOT)}  {frame.size[0]}x{frame.size[1]}")
    print("\nDone.")


if __name__ == "__main__":
    main()
