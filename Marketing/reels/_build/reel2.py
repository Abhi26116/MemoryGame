# -*- coding: utf-8 -*-
"""Builds background video frames and the animated overlay track for both cuts."""
import os, sys, math, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import style2 as st
import anim
from PIL import Image, ImageDraw, ImageFilter

B = os.path.dirname(os.path.abspath(__file__))
FPS = 30

# ---------------------------------------------------------------- sprites
def sprites():
    s = {}
    s["head"] = st.sticker([("t", "MEMORIZE ALL "), ("t", "16", st.YELLOW), ("e", "\U0001F440")], 86)
    s["find"] = st.sticker([("t", "FIND BOTH "), ("e", "\U0001F308")], 94)
    s["comment"] = st.pill_sticker(
        st._line([("t", "COMMENT YOUR ANSWER"), ("e", "\U0001F447")], 44, st.INK, "SemiBold", 14),
        pad_x=48, pad_y=26, fill=(255, 255, 255, 242))
    for key, txt, em in [("c_lv", "50 BRAIN LEVELS", "\U0001F9E0"),
                         ("c_off", "WORKS OFFLINE", "✈️"),
                         ("c_kid", "KIDS LOVE IT", "\U0001F9D2")]:
        s[key] = st.pill_sticker(
            st._line([("t", txt), ("e", em)], 64, st.INK, "Bold", 16),
            pad_x=46, pad_y=26, fill=(255, 255, 255, 242))
    s["w_pairs"] = st.sticker([("t", "8 / 8 PAIRS "), ("e", "✅")], 92, st.LIME)
    s["w_perf"] = st.sticker([("t", "100% PERFECT "), ("e", "\U0001F4AF")], 92, st.YELLOW)
    ic = Image.open(os.path.join(B, "icon.png")).convert("RGBA").resize((60, 60), Image.LANCZOS)
    ic.putalpha(st.rounded_mask(60, 60, 15))
    lbl = st._line([("t", "Memory Match")], 42, (255, 255, 255), "SemiBold", 0)
    row = Image.new("RGBA", (60 + 16 + lbl.width, max(60, lbl.height)), (0, 0, 0, 0))
    row.alpha_composite(ic, (0, (row.height - 60) // 2))
    row.alpha_composite(lbl, (76, (row.height - lbl.height) // 2))
    s["brand"] = st.pill_sticker(row, pad_x=30, pad_y=18, fill=(14, 6, 36, 205), ow=5)
    # CTA pieces
    big = Image.open(os.path.join(B, "icon.png")).convert("RGBA").resize((340, 340), Image.LANCZOS)
    big.putalpha(st.rounded_mask(340, 340, 78))
    gl = Image.new("RGBA", (460, 460), (0, 0, 0, 0))
    ImageDraw.Draw(gl).rounded_rectangle([60, 60, 399, 399], radius=78, fill=st.PINK + (235,))
    gl = gl.filter(ImageFilter.GaussianBlur(46))
    gl.alpha_composite(big, (60, 60))
    s["cta_icon"] = gl
    s["cta_title"] = st.sticker([("t", "Memory Match")], 104)
    s["cta_sub"] = st.sticker([("t", "50 levels · offline · free")], 46, (238, 232, 255), outline=7)
    s["cta_pill"] = st.pill_sticker(
        st._line([("t", "LINK IN BIO"), ("e", "\U0001F446")], 70, st.INK, "Bold", 18),
        pad_x=64, pad_y=34, fill=st.YELLOW + (255,), ow=9)
    s["cta_plat"] = st.pill_sticker(
        st._line([("t", "iPhone  ·  iPad  ·  Android")], 40, (255, 255, 255), "Medium", 0),
        pad_x=36, pad_y=20, fill=(14, 6, 36, 190), ow=5)
    return s


# ---------------------------------------------------------------- timelines
HEAD_Y, RING_Y, CHIP_Y, BRAND_Y = 230, 418, 300, 1546


def timeline(cut, S):
    """Returns (elements, duration, confetti_start, flashes, plate_end)."""
    E = []
    def add(kind, img, cx, cy, t0, t1, **kw):
        d = dict(kind=kind, img=img, cx=cx, cy=cy, **{"in": t0, "out": t1}); d.update(kw); E.append(d)

    if cut == "12":
        dur, plate_end = 12.00, 9.80
        add("s", S["head"], 540, HEAD_Y, 0.06, 3.60)
        for n, (a, b) in zip([3, 2, 1], [(0.10, 1.30), (1.30, 2.45), (2.45, 3.60)]):
            E.append(dict(kind="ring", img=None, n=n, cx=540, cy=RING_Y, **{"in": a, "out": b}, bob=False))
        add("s", S["find"], 540, HEAD_Y, 3.88, 5.70)
        add("s", S["comment"], 540, 412, 4.16, 5.70)
        add("s", S["c_lv"], 540, CHIP_Y, 5.76, 7.02)
        add("s", S["c_off"], 540, CHIP_Y, 7.06, 8.34)
        add("s", S["w_perf"], 540, 288, 8.48, 9.76)
        add("s", S["brand"], 540, BRAND_Y, 0.40, 9.76)
        conf, flash = 8.42, [(8.40, 0.13)]
        add("s", S["cta_icon"], 540, 548, 9.86, dur)
        add("s", S["cta_title"], 540, 826, 9.98, dur)
        add("s", S["cta_sub"], 540, 918, 10.08, dur)
        add("s", S["cta_pill"], 540, 1094, 10.22, dur)
        add("s", S["cta_plat"], 540, 1252, 10.36, dur)
    else:
        dur, plate_end = 21.90, 18.30
        add("s", S["head"], 540, HEAD_Y, 0.06, 4.40)
        for n, (a, b) in zip([4, 3, 2, 1], [(0.10, 1.18), (1.18, 2.26), (2.26, 3.34), (3.34, 4.40)]):
            E.append(dict(kind="ring", img=None, n=n, cx=540, cy=RING_Y, **{"in": a, "out": b}, bob=False))
        add("s", S["find"], 540, HEAD_Y, 4.72, 6.30)
        add("s", S["comment"], 540, 412, 5.00, 6.30)
        add("s", S["c_lv"], 540, CHIP_Y, 6.36, 8.90)
        add("s", S["c_off"], 540, CHIP_Y, 8.96, 11.54)
        add("s", S["c_kid"], 540, CHIP_Y, 11.60, 14.24)
        add("s", S["w_pairs"], 540, 288, 14.36, 15.24)
        add("s", S["w_perf"], 540, 288, 15.38, 18.26)
        add("s", S["brand"], 540, BRAND_Y, 0.40, 18.26)
        conf, flash = 14.32, [(14.30, 0.13)]
        add("s", S["cta_icon"], 540, 548, 18.36, dur)
        add("s", S["cta_title"], 540, 826, 18.48, dur)
        add("s", S["cta_sub"], 540, 918, 18.58, dur)
        add("s", S["cta_pill"], 540, 1094, 18.72, dur)
        add("s", S["cta_plat"], 540, 1252, 18.86, dur)
    return E, dur, conf, flash, plate_end


def build_bg(dur, out_mp4, frames_dir):
    os.makedirs(frames_dir, exist_ok=True)
    n = int(round(dur * FPS))
    loop = 7.0 * FPS           # slow drift, 7s period
    for i in range(n):
        st.bg_frame((i % loop) / loop).save(os.path.join(frames_dir, "b%04d.png" % i))
    subprocess.run(["ffmpeg", "-nostdin", "-v", "error", "-framerate", str(FPS),
                    "-i", os.path.join(frames_dir, "b%04d.png"),
                    "-c:v", "libx264", "-preset", "veryfast", "-crf", "16",
                    "-pix_fmt", "yuv420p", out_mp4, "-y"], check=True)


if __name__ == "__main__":
    what, cut = sys.argv[1], sys.argv[2]
    dur = 12.00 if cut == "12" else 21.90
    if what == "bg":
        build_bg(dur, os.path.join(B, f"bg{cut}.mp4"), os.path.join(B, f"bgf{cut}"))
        print("bg done", cut)
    elif what == "ov":
        S = sprites()
        E, dur, conf, flash, pend = timeline(cut, S)
        d = os.path.join(B, f"ovf{cut}")
        for f in os.listdir(d) if os.path.isdir(d) else []:
            os.remove(os.path.join(d, f))
        n = anim.render(E, dur, d, confetti=anim.Confetti(conf), flashes=flash)
        print("overlay frames", n, "plate_end", pend)
