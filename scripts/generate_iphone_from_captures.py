#!/usr/bin/env python3
"""
Build App Store assets from real app captures + screen recording.

Outputs:
  AppStoreScreenshots/iPhone_6.7/  → 1290×2796
  AppStoreScreenshots/iPhone_6.5/  → 1284×2778
  AppStoreScreenshots/iPad_12.9/   → 2048×2732
  preview.mp4 in each folder
"""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ICON = ROOT / "MemoryGame/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
SOURCES = ROOT / "AppStoreScreenshots/sources"

# App Store required sizes
DEVICE_SIZES = {
    "iPhone_6.7": {"canvas": (1290, 2796), "preview": (886, 1920), "device": "iphone"},
    "iPhone_6.5": {"canvas": (1284, 2778), "preview": (886, 1920), "device": "iphone"},
    "iPad_12.9": {"canvas": (2048, 2732), "preview": (1200, 1600), "device": "ipad"},
}

# Legacy alias
IPHONE_SIZES = {k: v["canvas"] for k, v in DEVICE_SIZES.items() if k.startswith("iPhone")}
PREVIEW = (886, 1920)

SCREEN_BG = (15, 22, 34)  # DS.Color.screen dark

VIDEO = Path("/Users/mac/Downloads/ScreenRecording_07-04-2026 13-13-42_1.MP4")
IPAD_VIDEO = ROOT / "AppStoreScreenshots/sources/ipad/screen_recording.mp4"

# Full-res iPhone screenshots (1179×2556)
DOWNLOADS = Path("/Users/mac/Downloads")
CAPTURES = {
    "home": DOWNLOADS / "IMG_0649.PNG",
    "victory": DOWNLOADS / "IMG_0647.PNG",
    "achievements": DOWNLOADS / "IMG_0648.PNG",
    "settings": DOWNLOADS / "IMG_0650.PNG",
    "gameplay_fruits": DOWNLOADS / "IMG_0653.PNG",
    "game_over": DOWNLOADS / "IMG_0652.PNG",
}

# iPad simulator captures (711×1024)
IPAD_SOURCES = ROOT / "AppStoreScreenshots/sources/ipad"
IPAD_CAPTURES = {
    "home": IPAD_SOURCES / "Simulator_Screenshot_-_iPad-Demo_-_2026-07-04_at_13.50.15-890628a6-5d86-45f7-add5-b501680cc530.png",
    "achievements": IPAD_SOURCES / "Simulator_Screenshot_-_iPad-Demo_-_2026-07-04_at_13.50.30-c54e5d8f-6298-4278-8cea-d1cf591e2dd7.png",
    "settings": IPAD_SOURCES / "Simulator_Screenshot_-_iPad-Demo_-_2026-07-04_at_13.51.16-da047d20-bdfb-4f87-9b6b-b6b8d2bdb6c8.png",
    "gameplay": IPAD_SOURCES / "Simulator_Screenshot_-_iPad-Demo_-_2026-07-04_at_13.51.42-c5f47504-054c-47fb-ad3d-8e60f8c435c6.png",
    "victory": IPAD_SOURCES / "Simulator_Screenshot_-_iPad-Demo_-_2026-07-04_at_13.52.14-4d1f7357-2c41-4874-ae27-ce2e8e0ca516.png",
    "memorize": IPAD_SOURCES / "Simulator_Screenshot_-_iPad-Demo_-_2026-07-04_at_13.52.42-87efdb83-651f-4164-b571-cf2ab75baf8e.png",
}

# Best frame from iPhone screen recording (extracted earlier)
VIDEO_FRAMES = ROOT / "AppStoreScreenshots/source_frames"

IPHONE_SCREENSHOTS = [
    {
        "id": "01_hero",
        "headline": "Train Your Memory",
        "subtitle": "Delightful bite-sized levels for all ages",
        "hue": "pink",
        "source": CAPTURES["home"],
    },
    {
        "id": "02_gameplay",
        "headline": "Flip. Match. Win!",
        "subtitle": "Beautiful cards, smooth animations & fun emojis",
        "hue": "purple",
        "source": VIDEO_FRAMES / "frame_05.png",  # Level 4 — matched pairs
    },
    {
        "id": "03_memorize",
        "headline": "Memorize & Match",
        "subtitle": "Preview all cards before the clock runs out",
        "hue": "blue",
        "source": VIDEO_FRAMES / "frame_02.png",  # Memorize countdown
    },
    {
        "id": "04_victory",
        "headline": "Earn Stars & Celebrate",
        "subtitle": "Track moves, time & accuracy on every win",
        "hue": "sunset",
        "source": CAPTURES["victory"],
    },
    {
        "id": "05_achievements",
        "headline": "Unlock Achievements",
        "subtitle": "Badges, streaks & milestones keep you going",
        "hue": "green",
        "source": CAPTURES["achievements"],
    },
    {
        "id": "06_settings",
        "headline": "Make It Yours",
        "subtitle": "Dark mode, card styles, sounds & haptics",
        "hue": "blue",
        "source": CAPTURES["settings"],
    },
]

IPAD_SCREENSHOTS = [
    {
        "id": "01_hero",
        "headline": "Train Your Memory",
        "subtitle": "Delightful bite-sized levels for all ages",
        "hue": "pink",
        "source": IPAD_CAPTURES["home"],
    },
    {
        "id": "02_gameplay",
        "headline": "Flip. Match. Win!",
        "subtitle": "Beautiful cards, smooth animations & fun emojis",
        "hue": "purple",
        "source": IPAD_CAPTURES["gameplay"],
    },
    {
        "id": "03_memorize",
        "headline": "Memorize & Match",
        "subtitle": "Preview all cards before the clock runs out",
        "hue": "blue",
        "source": IPAD_CAPTURES["memorize"],
    },
    {
        "id": "04_victory",
        "headline": "Earn Stars & Celebrate",
        "subtitle": "Track moves, time & accuracy on every win",
        "hue": "sunset",
        "source": IPAD_CAPTURES["victory"],
    },
    {
        "id": "05_achievements",
        "headline": "Unlock Achievements",
        "subtitle": "Badges, streaks & milestones keep you going",
        "hue": "green",
        "source": IPAD_CAPTURES["achievements"],
    },
    {
        "id": "06_settings",
        "headline": "Make It Yours",
        "subtitle": "Dark mode, card styles, sounds & haptics",
        "hue": "blue",
        "source": IPAD_CAPTURES["settings"],
    },
]

SCREENSHOTS = IPHONE_SCREENSHOTS  # legacy alias


# ── helpers ──────────────────────────────────────────────────────────────────

def lerp(a, b, t):
    return int(a + (b - a) * t)


def lerp_color(c1, c2, t):
    return (lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t))


def load_text_font(size: int):
    for path in (
        "/System/Library/Fonts/SFNSRounded.ttf",
        "/System/Library/Fonts/Supplemental/Arial Rounded MT Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    ):
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                pass
    return ImageFont.load_default()


def marketing_gradient(size, hue="blue"):
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
    orb = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(orb)
    od.ellipse((-w * 0.15, h * 0.08, w * 0.55, h * 0.55), fill=(255, 255, 255, 35))
    od.ellipse((w * 0.45, h * 0.55, w * 1.1, h * 1.05), fill=(255, 255, 255, 22))
    return Image.alpha_composite(img.convert("RGBA"), orb).convert("RGB")


def draw_text_centered(draw, text, y, width, font, fill, shadow=True):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    x = (width - tw) // 2
    if shadow:
        draw.text((x + 2, y + 3), text, font=font, fill=(0, 0, 0, 80))
    draw.text((x, y), text, font=font, fill=fill)


def ipad_ad_strip_metrics(height: int) -> tuple[int, int, int]:
    """Return (content_top_height, tab_bar_height, ad_band_height) for a capture."""
    tab_bar_h = max(48, int(height * 0.056))
    ad_h = max(44, int(height * 0.056))
    gap = max(4, int(height * 0.006))
    top_h = height - tab_bar_h - ad_h - gap
    return top_h, tab_bar_h, ad_h


def strip_ipad_ad_banner(capture: Image.Image) -> Image.Image:
    """Remove AdMob banner above the tab bar — for App Store marketing only."""
    w, h = capture.size
    top_h, tab_bar_h, _ad_h = ipad_ad_strip_metrics(h)
    if top_h < int(h * 0.45):
        return capture
    top = capture.crop((0, 0, w, top_h))
    bottom = capture.crop((0, h - tab_bar_h, w, h))
    out = Image.new("RGB", (w, top.height + bottom.height))
    out.paste(top, (0, 0))
    out.paste(bottom, (0, top.height))
    return out


def ffprobe_video_size(path: Path) -> tuple[int, int]:
    import json

    result = subprocess.run(
        [
            "ffprobe", "-v", "error", "-select_streams", "v:0",
            "-show_entries", "stream=width,height", "-of", "json", str(path),
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    stream = json.loads(result.stdout)["streams"][0]
    return int(stream["width"]), int(stream["height"])


def fit_screenshot(capture: Image.Image, fw: int, fh: int) -> Image.Image:
    """Scale & centre-crop a phone capture to fill (fw × fh)."""
    cw, ch = capture.size
    scale = max(fw / cw, fh / ch)
    nw, nh = int(cw * scale), int(ch * scale)
    resized = capture.resize((nw, nh), Image.LANCZOS)
    left = (nw - fw) // 2
    top = (nh - fh) // 2
    return resized.crop((left, top, left + fw, top + fh))


def fit_screenshot_contain(capture: Image.Image, fw: int, fh: int) -> Image.Image:
    """Scale to fit inside frame, letterboxed — matches iPad centered-column layout."""
    cw, ch = capture.size
    scale = min(fw / cw, fh / ch)
    nw, nh = int(cw * scale), int(ch * scale)
    resized = capture.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGB", (fw, fh), SCREEN_BG)
    canvas.paste(resized, ((fw - nw) // 2, (fh - nh) // 2))
    return canvas


def device_frame_rect(
    canvas_w,
    canvas_h,
    device: str = "iphone",
    source_size: tuple[int, int] | None = None,
):
    if device == "ipad":
        if source_size:
            source_aspect = source_size[0] / source_size[1]
        else:
            source_aspect = 2048 / 2732

        scale = canvas_w / 2048
        header_end = int(190 * scale)
        bottom_margin = int(56 * scale)
        available_h = canvas_h - header_end - bottom_margin

        max_fw = int(canvas_w * 0.86)
        max_fh = available_h

        fh = min(max_fh, int(max_fw / source_aspect))
        fw = int(fh * source_aspect)
        if fw > max_fw:
            fw = max_fw
            fh = int(fw / source_aspect)

        fx = (canvas_w - fw) // 2
        fy = header_end + max(0, (available_h - fh) // 2)
        radius = max(24, int(32 * scale))
        return fx, fy, fw, fh, radius

    fw = int(canvas_w * 0.84)
    fh = int(fw * 2556 / 1179)
    max_fh = int(canvas_h * 0.68)
    if fh > max_fh:
        fh = max_fh
        fw = int(fh * 1179 / 2556)
    fx = (canvas_w - fw) // 2
    fy = int(canvas_h * 0.22)
    radius = max(28, int(56 * canvas_w / 1290))
    return fx, fy, fw, fh, radius


def phone_frame_rect(canvas_w, canvas_h):
    return device_frame_rect(canvas_w, canvas_h, "iphone")


def draw_marketing_header(img: Image.Image, hue: str, headline: str, subtitle: str, device: str = "iphone"):
    """Draw gradient background, centered app icon, headline, subtitle."""
    w, h = img.size
    is_ipad = device == "ipad" or w >= 2000
    scale = w / 2048 if is_ipad else w / 1290
    bg = marketing_gradient((w, h), hue).convert("RGBA")
    img.paste(bg, (0, 0))

    draw = ImageDraw.Draw(img)
    headline_size = int(62 * scale) if is_ipad else int(72 * scale)
    sub_size = int(24 * scale) if is_ipad else int(28 * scale)

    icon_size = int(46 * scale) if is_ipad else int(52 * scale)
    icon_y = int(48 * scale) if is_ipad else int(58 * scale)
    text_top = int(118 * scale) if is_ipad else int(145 * scale)

    if ICON.exists():
        icon = Image.open(ICON).convert("RGBA").resize((icon_size, icon_size), Image.LANCZOS)
        mask = Image.new("L", icon.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, icon_size, icon_size), radius=int(11 * scale), fill=255)
        icon.putalpha(mask)
        img.alpha_composite(icon, ((w - icon_size) // 2, icon_y))

    draw_text_centered(draw, headline, text_top, w, load_text_font(headline_size), (255, 255, 255))
    bbox = draw.textbbox((0, 0), subtitle, font=load_text_font(sub_size))
    draw.text(
        ((w - (bbox[2] - bbox[0])) // 2, text_top + headline_size + int(14 * scale)),
        subtitle,
        font=load_text_font(sub_size),
        fill=(255, 255, 255, 210),
    )


def draw_frame_overlay(base: Image.Image, frame, radius: int, device: str = "iphone"):
    """Draw bezel (+ dynamic island on iPhone) on a transparent layer."""
    fx, fy, fw, fh = frame
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        (fx + 8, fy + 14, fx + fw + 8, fy + fh + 14), radius=radius, fill=(0, 0, 0, 90)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(max(10, radius // 3)))
    overlay = Image.alpha_composite(overlay, shadow)

    draw.rounded_rectangle(
        (fx - 7, fy - 7, fx + fw + 7, fy + fh + 7), radius=radius + 7, fill=(58, 66, 82, 255)
    )
    draw.rounded_rectangle(
        (fx - 3, fy - 3, fx + fw + 3, fy + fh + 3), radius=radius + 3, fill=(20, 26, 36, 255)
    )

    if device == "iphone":
        ref_w = 1290
        iw, ih = int(fw * 0.28), max(22, int(34 * base.size[0] / ref_w))
        ix = fx + (fw - iw) // 2
        draw.rounded_rectangle((ix, fy + 16, ix + iw, fy + 16 + ih), radius=ih // 2, fill=(10, 12, 18, 255))

    base.alpha_composite(overlay)
    return fx, fy, fw, fh


def make_screen_mask(fw: int, fh: int, radius: int) -> Image.Image:
    mask = Image.new("L", (fw, fh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, fw, fh), radius=radius, fill=255)
    return mask


def draw_device_bezel(base: Image.Image, frame, device: str = "iphone"):
    fx, fy, fw, fh, radius = frame if len(frame) == 5 else (*frame, 56)
    draw_frame_overlay(base, (fx, fy, fw, fh), radius, device=device)


def render_marketing_screenshot(spec: dict, canvas: tuple[int, int], device: str = "iphone") -> Image.Image:
    w, h = canvas
    img = Image.new("RGBA", canvas, (0, 0, 0, 255))
    draw_marketing_header(img, spec["hue"], spec["headline"], spec["subtitle"], device=device)

    capture = Image.open(spec["source"]).convert("RGB")
    if device == "ipad":
        capture = strip_ipad_ad_banner(capture)
    frame = device_frame_rect(w, h, device, source_size=capture.size if device == "ipad" else None)
    fx, fy, fw, fh, radius = frame
    draw_device_bezel(img, frame, device=device)

    if device == "ipad":
        fitted = fit_screenshot_contain(capture, fw, fh)
    else:
        fitted = fit_screenshot(capture, fw, fh)
    mask = make_screen_mask(fw, fh, radius)
    fitted_rgba = fitted.convert("RGBA")
    fitted_rgba.putalpha(mask)
    img.paste(fitted_rgba, (fx, fy), fitted_rgba)

    return img.convert("RGB")


# Preview uses gameplay headline (matches screen-recording content)
PREVIEW_SPEC = {
    "headline": "Flip. Match. Win!",
    "subtitle": "Beautiful cards, smooth animations & fun emojis",
    "hue": "purple",
}


def ipad_capture_size() -> tuple[int, int]:
    for path in IPAD_CAPTURES.values():
        if path.exists():
            with Image.open(path) as img:
                cleaned = strip_ipad_ad_banner(img.convert("RGB"))
                return cleaned.size
    return (1640, 2214)


def create_app_preview(out_dir: Path, preview_size: tuple[int, int], device: str = "iphone", video: Path | None = None):
    """App Preview: marketing frame + screen recording inside the device area."""
    video_path = video or (IPAD_VIDEO if device == "ipad" else VIDEO)
    if not video_path.exists():
        print(f"⚠ Video not found: {video_path}")
        return

    w, h = preview_size
    source_size = ipad_capture_size() if device == "ipad" else None
    fx, fy, fw, fh, radius = device_frame_rect(w, h, device, source_size=source_size)

    tmp = out_dir / "_preview_assets"
    tmp.mkdir(exist_ok=True)

    background = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    draw_marketing_header(background, PREVIEW_SPEC["hue"], PREVIEW_SPEC["headline"], PREVIEW_SPEC["subtitle"], device=device)
    bg_path = tmp / "background.png"
    background.save(bg_path)

    frame_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw_frame_overlay(frame_layer, (fx, fy, fw, fh), radius, device=device)
    frame_path = tmp / "frame_overlay.png"
    frame_layer.save(frame_path)

    mask_path = tmp / "screen_mask.png"
    make_screen_mask(fw, fh, radius).save(mask_path)

    out = out_dir / "preview.mp4"
    if device == "ipad":
        vw, vh = ffprobe_video_size(video_path)
        top_h, tab_h, ad_h = ipad_ad_strip_metrics(vh)
        bot_y = vh - tab_h
        vid_strip = (
            f"[1:v]split=2[iv1][iv2];"
            f"[iv1]crop={vw}:{top_h}:0:0[ivtop];"
            f"[iv2]crop={vw}:{tab_h}:0:{bot_y}[ivtab];"
            f"[ivtop][ivtab]vstack=inputs=2[ivclean];"
        )
        vid_scale = (
            f"{vid_strip}"
            f"[ivclean]scale={fw}:{fh}:force_original_aspect_ratio=decrease,"
            f"pad={fw}:{fh}:(ow-iw)/2:(oh-ih)/2:color=0x0F1622,"
        )
    else:
        vid_scale = (
            f"[1:v]scale={fw}:{fh}:force_original_aspect_ratio=increase,"
            f"crop={fw}:{fh},"
        )
    filt = (
        f"{vid_scale}fps=30,format=rgba[vid];"
        f"[2:v]scale={fw}:{fh},format=gray[alpha];"
        f"[vid][alpha]alphamerge[screen];"
        f"[0:v][screen]overlay={fx}:{fy}:shortest=1[withvid];"
        f"[withvid][3:v]overlay=0:0:shortest=1,format=yuv420p[out]"
    )
    cmd = [
        "ffmpeg", "-y",
        "-loop", "1", "-framerate", "30", "-i", str(bg_path),
        "-i", str(video_path),
        "-loop", "1", "-framerate", "30", "-i", str(mask_path),
        "-loop", "1", "-framerate", "30", "-i", str(frame_path),
        "-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=48000",
        "-t", "15",
        "-filter_complex", filt,
        "-map", "[out]",
        "-map", "4:a",
        "-c:v", "libx264",
        "-profile:v", "high",
        "-level", "4.0",
        "-preset", "slow",
        "-crf", "20",
        "-pix_fmt", "yuv420p",
        "-r", "30",
        "-c:a", "aac",
        "-b:a", "256k",
        "-ar", "48000",
        "-ac", "2",
        "-movflags", "+faststart",
        "-shortest",
        str(out),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(result.stderr[-2000:])
        result.check_returncode()
    print(f"✓ preview.mp4  ({w}×{h}, 15 s, {device})")


def copy_sources():
    SOURCES.mkdir(parents=True, exist_ok=True)
    for name, path in CAPTURES.items():
        if path.exists():
            shutil.copy2(path, SOURCES / f"{name}.png")
    if VIDEO.exists():
        shutil.copy2(VIDEO, SOURCES / "screen_recording.mp4")


def generate_for_device(folder: str, config: dict):
    canvas = config["canvas"]
    device = config["device"]
    specs = IPAD_SCREENSHOTS if device == "ipad" else IPHONE_SCREENSHOTS
    video = IPAD_VIDEO if device == "ipad" else VIDEO
    out_dir = ROOT / "AppStoreScreenshots" / folder
    out_dir.mkdir(parents=True, exist_ok=True)
    for spec in specs:
        src = spec["source"]
        if not src.exists():
            print(f"⚠ Missing source: {src}")
            continue
        out_path = out_dir / f"{spec['id']}.png"
        render_marketing_screenshot(spec, canvas, device=device).save(out_path, "PNG", optimize=True)
        print(f"✓ {folder}/{out_path.name}  ({canvas[0]}×{canvas[1]})  ← {src.name}")
    create_app_preview(out_dir, config["preview"], device=device, video=video)
    return out_dir


def main():
    copy_sources()
    for folder, config in DEVICE_SIZES.items():
        out = generate_for_device(folder, config)
        print(f"  → {out}\n")
    print("Done.")


if __name__ == "__main__":
    main()
