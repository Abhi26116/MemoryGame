#!/usr/bin/env python3
"""
Build the App Store app preview (886x1920) for Memory Match v1.1.

Takes a raw simulator recording of one full level and cuts it to ~25s:
  memorize countdown -> board conceals -> matching -> three-star finish.

Captions are rendered with PIL rather than ffmpeg's drawtext because Fredoka
is a variable font and drawtext would render it at its Light default.

Usage:  python3 scripts/build_app_preview.py
"""

from __future__ import annotations

import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SCRATCH = Path(
    "/private/tmp/claude-501/-Users-mac-MemoryGame/"
    "0c4e5652-4d25-44c6-a5d9-2280fe9764f8/scratchpad"
)
WORK = SCRATCH / "vid"
OUT = ROOT / "AppStoreScreenshots_v1.1" / "preview"

FPS = 30
FREDOKA = str(ROOT / "MemoryGame/Resources/Fredoka.ttf")

# One profile per device family. Segment times are mapped from a 1fps frame
# dump of that device's own recording — the iPad boots and previews slower, so
# its beats land much later than the iPhone's.
#
# `size` is Apple's required app-preview resolution for the family:
#   iPhone 6.5"/6.7"/6.9" -> 886x1920
#   iPad 12.9"/13"        -> 1200x1600
DEVICES = {
    "iphone": dict(
        raw="verify.mov",
        out="MemoryMatch_preview_iPhone_886x1920.mp4",
        size=(886, 1920),
        capture_w=1290,
        segments=[(16.5, 22.3), (22.3, 35.3), (37.0, 41.5)],
        captions=[
            ("Match every pair from memory", 8.0, 4.0, 0.360),
            ("50 levels · fully offline", 14.2, 4.2, 0.360),
        ],
        caption_pt=58,
        poster_at=12.5,
    ),
    "ipad": dict(
        raw="raw_ipad.mov",
        out="MemoryMatch_preview_iPad_1200x1600.mp4",
        size=(1200, 1600),
        capture_w=2048,
        # The jump from mid-match to the win screen is deliberately hidden
        # behind the second caption's fade.
        segments=[(15.8, 21.6), (21.6, 34.6), (39.5, 44.0)],
        captions=[
            # Low on the screen: on iPad the board starts high, so a mid-board
            # pill would cover face-up cards. Down here it only ever sits over
            # card backs during both caption windows.
            ("Match every pair from memory", 8.0, 4.0, 0.885),
            ("50 levels · fully offline", 14.2, 4.2, 0.885),
        ],
        caption_pt=52,
        poster_at=11.0,
    ),
}

# (text, start, duration, y) on the FINAL cut timeline. `y` is a fraction of
# screen height for the pill's centre.
#
# Placement is per-caption on purpose. During the memorize phase the banner
# fills the usual gap, so caption 1 sits below the board instead. The last
# caption has to finish before the result screen arrives (~19.0s) or it lands
# on top of "Level Complete!".
# The opening beat needs no caption: the app draws its own "Memorize!" banner
# with a live countdown, and now that the board fills the full height there is
# no free strip to put a pill in without covering cards.
CAPTIONS = [
    ("Match every pair from memory", 6.4,  4.0, 0.360),
    ("50 levels · fully offline",    13.6, 4.1, 0.360),
]


def run(cmd: list[str]) -> None:
    subprocess.run(cmd, check=True, capture_output=True)


def probe_duration(path: Path) -> float:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "csv=p=0", str(path)],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    return float(out)


def make_status_strip(video: Path, path: Path, dev: dict) -> None:
    """Render a clean 9:41 status bar sized to the preview's own screen."""
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from build_store_assets import draw_status_bar, draw_status_bar_ipad

    frame = WORK / "frame0.png"
    run(["ffmpeg", "-y", "-v", "error", "-ss", "1", "-i", str(video),
         "-frames:v", "1", str(frame)])

    img = Image.open(frame).convert("RGB")
    if dev["capture_w"] == 1290:
        # The preview is already scaled down from the 1290-wide capture, so the
        # bar geometry has to be scaled to the video's width, not the device's.
        scale = img.width / 1290
        draw_status_bar(img, scale=scale)
        bar_h = int(150 * scale)
    else:
        full = Image.open(frame).convert("RGB").resize((2048, 2732), Image.LANCZOS)
        draw_status_bar_ipad(full)
        bar_h = int(50 * img.width / 2048)
        img = full.resize(img.size, Image.LANCZOS)
    img.crop((0, 0, img.width, bar_h)).save(path)


def make_caption(text: str, path: Path, W: int, pt: int) -> None:
    """Render a caption as a translucent pill with the brand typeface."""
    box_h = 200
    img = Image.new("RGBA", (W, box_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    f = ImageFont.truetype(FREDOKA, pt)
    try:
        f.set_variation_by_axes([600, 100])
    except Exception:
        pass

    tw = d.textlength(text, font=f)
    pad_x, pill_h = int(pt * 0.8), int(pt * 1.8)
    pill_w = int(tw) + pad_x * 2
    x0 = (W - pill_w) // 2
    y0 = (box_h - pill_h) // 2

    # drop shadow so the pill reads over both the dark board and the cards
    shadow = Image.new("L", (W, box_h), 0)
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x0, y0 + 6, x0 + pill_w, y0 + pill_h + 6), radius=pill_h // 2, fill=150
    )
    img.paste((0, 0, 0), (0, 0), shadow.filter(ImageFilter.GaussianBlur(14)))

    d.rounded_rectangle((x0, y0, x0 + pill_w, y0 + pill_h),
                        radius=pill_h // 2, fill=(12, 16, 30, 215))
    d.rounded_rectangle((x0, y0, x0 + pill_w, y0 + pill_h),
                        radius=pill_h // 2, outline=(255, 255, 255, 46), width=2)
    d.text((W // 2, y0 + pill_h // 2), text, font=f,
           fill=(255, 255, 255, 255), anchor="mm")
    img.save(path)


def build(name: str, dev: dict) -> None:
    W, H = dev["size"]
    work = WORK / name
    work.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)

    # 0. Normalise the recording to constant frame rate FIRST. `simctl
    # recordVideo` can emit a variable-frame-rate file (the iPad one averaged
    # ~22fps on a 600 timebase), and seeking into that is wildly inaccurate —
    # a 14.4s request came back as 30.1s, blowing past Apple's 30s cap.
    raw = work / "cfr.mp4"
    run(["ffmpeg", "-y", "-v", "error", "-i", str(SCRATCH / dev["raw"]),
         "-vf", f"fps={FPS}", "-an", "-c:v", "libx264", "-crf", "16",
         "-preset", "fast", str(raw)])

    # 1. cut segments, normalising size up front
    parts = []
    for i, (start_s, end_s) in enumerate(dev["segments"]):
        part = work / f"part{i}.mp4"
        run([
            "ffmpeg", "-y", "-v", "error",
            "-ss", str(start_s), "-to", str(end_s), "-i", str(raw),
            "-vf", f"scale={W}:{H}:flags=lanczos,fps={FPS},format=yuv420p",
            "-an", "-c:v", "libx264", "-crf", "17", "-preset", "slow", str(part),
        ])
        parts.append(part)

    listing = work / "parts.txt"
    listing.write_text("".join(f"file '{p}'\n" for p in parts))
    joined = work / "joined.mp4"
    run(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0",
         "-i", str(listing), "-c", "copy", str(joined)])

    # 2. clean status bar overlaid for the whole clip — the recordings carry a
    # live clock because simctl's status_bar override is a no-op here.
    bar_png = work / "statusbar.png"
    make_status_strip(joined, bar_png, dev)

    # 3. captions. Each PNG must be looped into a real stream: a bare `-i
    # image.png` is one frame at t=0, so a later alpha fade leaves it
    # permanently transparent.
    total = probe_duration(joined)
    overlays = ["-loop", "1", "-framerate", str(FPS), "-t", f"{total:.2f}", "-i", str(bar_png)]
    filters = ["[0:v][1:v]overlay=0:0[v0];"]
    chain = "[v0]"

    captions = dev["captions"]
    for i, (text, start_t, dur, cy) in enumerate(captions):
        png = work / f"cap{i}.png"
        make_caption(text, png, W, dev["caption_pt"])
        overlays += ["-loop", "1", "-framerate", str(FPS),
                     "-t", f"{total:.2f}", "-i", str(png)]
        filters.append(
            f"[{i + 2}:v]format=rgba,"
            f"fade=t=in:st={start_t}:d=0.45:alpha=1,"
            f"fade=t=out:st={start_t + dur - 0.45}:d=0.45:alpha=1[c{i}];"
        )
        y = int(H * cy) - 100
        nxt = f"[v{i + 1}]" if i < len(captions) - 1 else "[vout]"
        filters.append(
            f"{chain}[c{i}]overlay=0:{y}:"
            f"enable='between(t,{start_t},{start_t + dur})'{nxt};"
        )
        chain = f"[v{i + 1}]"

    n_inputs = 2 + len(captions)
    final = OUT / dev["out"]
    run([
        "ffmpeg", "-y", "-v", "error",
        "-i", str(joined), *overlays,
        "-f", "lavfi", "-t", "40", "-i", "anullsrc=r=44100:cl=stereo",
        "-filter_complex", "".join(filters).rstrip(";"),
        "-map", "[vout]", "-map", f"{n_inputs}:a",
        "-c:v", "libx264", "-profile:v", "high", "-level", "4.0",
        "-crf", "19", "-preset", "slow", "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "128k", "-shortest",
        "-movflags", "+faststart", str(final),
    ])

    dur = probe_duration(final)
    print(f"{final.relative_to(ROOT)}  {W}x{H}  {dur:.1f}s  "
          f"{final.stat().st_size / 1_000_000:.1f} MB")

    poster = OUT / f"poster_{name}.png"
    run(["ffmpeg", "-y", "-v", "error", "-ss", str(dev["poster_at"]),
         "-i", str(final), "-frames:v", "1", str(poster)])
    print(f"{poster.relative_to(ROOT)}  (suggested poster frame)")


def main() -> None:
    for name, dev in DEVICES.items():
        build(name, dev)


if __name__ == "__main__":
    main()
