# -*- coding: utf-8 -*-
"""Visual system for the Memory Match reels: candy palette, sticker type, plate geometry."""
import os, math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

S = os.path.dirname(os.path.abspath(__file__))
W, H = 1080, 1920
# gameplay plate
PX, PY, PW, PH = 90, 468, 900, 1020
RAD = 44
# source crops (886x1920 preview)
CROP_GRID = (820, 929, 32, 808)     # cards only
CROP_WIN = (886, 1004, 0, 270)      # win panel

FRED = "/Users/mac/MemoryGame/MemoryGame/Resources/Fredoka.ttf"
EMOJI = "/System/Library/Fonts/Apple Color Emoji.ttc"

INK = (19, 7, 38)
WHITE = (255, 255, 255)
YELLOW = (255, 217, 61)
LIME = (163, 255, 61)
PINK = (255, 46, 136)
VIOLET = (139, 92, 246)
BLUE = (46, 139, 255)
CYAN = (34, 211, 238)
CONFETTI = [PINK, YELLOW, LIME, CYAN, VIOLET, (255, 255, 255)]


def fred(size, weight="Bold"):
    f = ImageFont.truetype(FRED, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


_ec = {}


def emoji_img(ch, h):
    k = (ch, h)
    if k in _ec:
        return _ec[k]
    f = ImageFont.truetype(EMOJI, 160)
    tmp = Image.new("RGBA", (280, 280), (0, 0, 0, 0))
    ImageDraw.Draw(tmp).text((50, 50), ch, font=f, embedded_color=True)
    bb = tmp.getbbox()
    g = tmp.crop(bb) if bb else Image.new("RGBA", (h, h), (0, 0, 0, 0))
    g = g.resize((max(1, int(g.width * h / g.height)), h), Image.LANCZOS)
    _ec[k] = g
    return g


def rounded_mask(w, h, r, ss=4):
    m = Image.new("L", (w * ss, h * ss), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w * ss - 1, h * ss - 1], radius=r * ss, fill=255)
    return m.resize((w, h), Image.LANCZOS)


def _line(parts, size, color, weight, gap, eratio=1.0):
    font = fred(size, weight)
    eh = int(size * eratio)
    ims = []
    for p in parts:
        if p[0] == "e":
            ims.append(emoji_img(p[1], eh))
        else:
            txt, col = p[1], (p[2] if len(p) > 2 else color)
            bb = font.getbbox(txt)
            tw, th = bb[2] - bb[0], bb[3] - bb[1]
            im = Image.new("RGBA", (max(1, tw) + 4, max(1, th) + 4), (0, 0, 0, 0))
            ImageDraw.Draw(im).text((2 - bb[0], 2 - bb[1]), txt, font=font, fill=col + (255,))
            ims.append(im)
    total = sum(i.width for i in ims) + gap * (len(ims) - 1)
    mh = max(i.height for i in ims)
    out = Image.new("RGBA", (total, mh), (0, 0, 0, 0))
    x = 0
    for im in ims:
        out.alpha_composite(im, (x, (mh - im.height) // 2))
        x += im.width + gap
    bb = out.getbbox()
    return out.crop(bb) if bb else out


def sticker(parts, size, color=WHITE, weight="Bold", gap=18, outline=10,
            outline_col=INK, shadow=True, eratio=1.05):
    """Thick-outlined sticker text with a drop shadow - reads instantly in a feed."""
    core = _line(parts, size, color, weight, gap, eratio)
    pad = outline + 26
    big = Image.new("RGBA", (core.width + pad * 2, core.height + pad * 2), (0, 0, 0, 0))
    big.alpha_composite(core, (pad, pad))
    a = big.split()[3]
    grown = a
    for _ in range(outline):
        grown = grown.filter(ImageFilter.MaxFilter(3))
    grown = grown.filter(ImageFilter.GaussianBlur(0.7)).point(lambda v: 255 if v > 90 else 0)
    out = Image.new("RGBA", big.size, (0, 0, 0, 0))
    if shadow:
        sh = grown.filter(ImageFilter.GaussianBlur(14))
        shim = Image.new("RGBA", big.size, (0, 0, 0, 0))
        shim.putalpha(sh.point(lambda v: int(v * 0.62)))
        out.alpha_composite(Image.composite(Image.new("RGBA", big.size, (5, 2, 16, 255)),
                                            Image.new("RGBA", big.size, (0, 0, 0, 0)),
                                            shim.split()[3]), (0, 12))
    ol = Image.new("RGBA", big.size, outline_col + (255,))
    ol.putalpha(grown)
    out.alpha_composite(ol)
    out.alpha_composite(big)
    bb = out.getbbox()
    return out.crop(bb) if bb else out


def pill_sticker(inner, pad_x=56, pad_y=30, fill=(255, 255, 255, 235), outline=INK, ow=8):
    w, h = inner.width + pad_x * 2, inner.height + pad_y * 2
    pad = ow + 20
    im = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    ss = 4
    body = Image.new("RGBA", (w * ss, h * ss), (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle([0, 0, w * ss - 1, h * ss - 1], radius=(h // 2) * ss,
                                           fill=fill, outline=outline + (255,), width=ow * ss)
    body = body.resize((w, h), Image.LANCZOS)
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    sh.alpha_composite(body, (pad, pad + 12))
    sa = sh.split()[3].filter(ImageFilter.GaussianBlur(14)).point(lambda v: int(v * 0.6))
    shim = Image.new("RGBA", im.size, (5, 2, 16, 255))
    shim.putalpha(sa)
    im.alpha_composite(shim)
    im.alpha_composite(body, (pad, pad))
    im.alpha_composite(inner, (pad + pad_x, pad + pad_y))
    bb = im.getbbox()
    return im.crop(bb) if bb else im


def countdown_ring(n, frac, size=250):
    """Big ring that depletes, with the digit inside."""
    ss = 3
    c = Image.new("RGBA", (size * ss, size * ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(c)
    wdt = 24 * ss
    pad = wdt // 2 + 6 * ss
    box = [pad, pad, size * ss - pad, size * ss - pad]
    d.ellipse([box[0] - wdt // 2, box[1] - wdt // 2, box[2] + wdt // 2, box[3] + wdt // 2],
              fill=(12, 5, 32, 215), outline=INK + (255,), width=7 * ss)
    d.arc(box, 0, 360, fill=(255, 255, 255, 48), width=wdt)
    if frac > 0.004:
        d.arc(box, -90, -90 + 360 * frac, fill=YELLOW + (255,), width=wdt)
    c = c.resize((size, size), Image.LANCZOS)
    dig = sticker([("t", str(n))], int(size * 0.46), WHITE, outline=8)
    c.alpha_composite(dig, ((size - dig.width) // 2, (size - dig.height) // 2))
    return c


# ---------- background ----------
def _blob(layer, cx, cy, r, color, alpha):
    d = ImageDraw.Draw(layer)
    steps = 26
    for i in range(steps, 0, -1):
        f = i / steps
        a = int(alpha * (1 - f) ** 1.9)
        rr = r * f
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=color + (a,))


def bg_frame(phase, w=270, h=480):
    """One frame of the drifting-glow background, rendered small then upscaled."""
    stops = [(0.00, (44, 16, 92)), (0.34, (86, 24, 140)), (0.62, (66, 20, 124)), (1.00, (28, 12, 66))]
    base = Image.new("RGB", (2, h))
    px = base.load()
    for y in range(h):
        t = y / (h - 1)
        for i in range(len(stops) - 1):
            a, ca = stops[i]
            b, cb = stops[i + 1]
            if a <= t <= b:
                f = (t - a) / (b - a)
                c = tuple(int(ca[k] + (cb[k] - ca[k]) * f) for k in range(3))
                break
        px[0, y] = c
        px[1, y] = c
    img = base.resize((w, h), Image.BICUBIC).convert("RGBA")
    L = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    tau = math.pi * 2
    _blob(L, w * (0.18 + 0.10 * math.sin(tau * phase)), h * (0.16 + 0.05 * math.cos(tau * phase)),
          w * 0.78, PINK, 215)
    _blob(L, w * (0.86 + 0.08 * math.cos(tau * phase + 1.2)), h * (0.34 + 0.07 * math.sin(tau * phase + 0.7)),
          w * 0.72, VIOLET, 225)
    _blob(L, w * (0.12 + 0.09 * math.cos(tau * phase + 2.3)), h * (0.78 + 0.06 * math.sin(tau * phase + 2.0)),
          w * 0.76, BLUE, 200)
    _blob(L, w * (0.78 + 0.10 * math.sin(tau * phase + 3.1)), h * (0.90 + 0.05 * math.cos(tau * phase)),
          w * 0.62, CYAN, 140)
    img.alpha_composite(L)
    return img.filter(ImageFilter.GaussianBlur(2)).resize((W, H), Image.BICUBIC).convert("RGB")


def plate_frame_png():
    """Bright rim + glow drawn on top of the gameplay plate."""
    f = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle([PX - 10, PY - 10, PX + PW + 10, PY + PH + 10],
                                           radius=RAD + 10, outline=PINK + (210,), width=18)
    f.alpha_composite(glow.filter(ImageFilter.GaussianBlur(30)))
    glow2 = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow2).rounded_rectangle([PX - 4, PY - 4, PX + PW + 4, PY + PH + 4],
                                            radius=RAD + 4, outline=CYAN + (150,), width=10)
    f.alpha_composite(glow2.filter(ImageFilter.GaussianBlur(16)))
    ss = 4
    rim = Image.new("RGBA", (PW * ss + 80, PH * ss + 80), (0, 0, 0, 0))
    ImageDraw.Draw(rim).rounded_rectangle([40, 40, PW * ss + 39, PH * ss + 39], radius=RAD * ss,
                                          outline=(255, 255, 255, 236), width=7 * ss)
    rim = rim.resize((PW + 20, PH + 20), Image.LANCZOS)
    f.alpha_composite(rim, (PX - 10, PY - 10))
    return f
