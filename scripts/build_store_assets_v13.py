#!/usr/bin/env python3
"""
Build the v1.3 "Kids & Family" store screenshots for App Store and Google Play,
in every app language.

What changed from the v1.1 set (scripts/build_store_assets.py):
  * light-mode captures on bright, sunny backgrounds instead of dark UI on dark
    gradients, which read as a grown-up brain trainer
  * playful, parent-facing headlines with one highlighted word
  * emoji "stickers" and a feature chip on every frame
  * a Google Play set (1080x1920, no iPhone frame) so Android shoppers don't
    see Apple hardware
  * one set per language, from captures of the app running in that language

Captures live in CAPS/<lang>/ as d_<src>.png (iPhone 15 Pro Max) and
p_<src>.png (iPad Pro 12.9"); see StoreAssets_v1.3/README.md for how to take
them. Only the sizes the stores ask for first are built: 6.9" iPhone and 13"
iPad (Apple scales those down for smaller devices) and Play phone.

Reuses the drawing helpers from build_store_assets.py.

Usage:  python3 scripts/build_store_assets_v13.py [lang ...]
"""

from __future__ import annotations

import random
import subprocess
import sys
import tempfile
from functools import lru_cache
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

import build_store_assets as v11
from build_store_assets import device_frame, draw_status_bar, draw_status_bar_ipad, font, gradient

ROOT = Path(__file__).resolve().parents[1]
CAPS = Path(
    "/private/tmp/claude-501/-Users-mac-MemoryGame/"
    "24e3c9ce-a095-4aa7-bab3-0c4741855fa6/scratchpad/caps"
)
OUT = ROOT / "StoreAssets_v1.3"

FREDOKA = v11.FREDOKA
# Fredoka has no Devanagari, so Hindi headlines use Kohinoor Devanagari Bold.
KOHINOOR = "/System/Library/Fonts/Kohinoor.ttc"
EMOJI = "/System/Library/Fonts/Apple Color Emoji.ttc"
NAVY = (27, 33, 72)

DEVICES = {
    "iphone": dict(
        prefix="d_", capture=(1290, 2796), ref_width=1320, device_frac=0.78, island=True,
        canvases={"iPhone_6.9": (1320, 2868)},
    ),
    "ipad": dict(
        prefix="p_", capture=(2048, 2732), ref_width=2048, device_frac=0.72, island=False,
        canvases={"iPad_13": (2064, 2752)},
    ),
    # Play phone screenshots: same iPhone captures, framed as a generic
    # bezel-less phone with no Dynamic Island or iOS status bar.
    "play": dict(
        prefix="d_", capture=(1290, 2796), ref_width=1080, device_frac=0.80, island=True,
        generic=True, canvases={"GooglePlay_phone": (1080, 1920)},
    ),
}

# Visual style per frame, in upload order. `src` names the raw capture.
FRAMES = [
    dict(src="prev", grad=((255, 236, 153), (255, 196, 92), (255, 150, 92)),
         hi=(233, 64, 110), stickers="🐱🦊⭐🐼"),
    dict(src="math", grad=((176, 232, 255), (120, 196, 255), (98, 150, 250)),
         hi=(255, 214, 10), stickers="🔢🅰️✏️🌍"),
    dict(src="game", grad=((206, 250, 214), (134, 226, 170), (64, 196, 150)),
         hi=(122, 60, 230), stickers="🍎🚗🌈🎈"),
    dict(src="win", grad=((255, 214, 232), (255, 160, 200), (230, 112, 190)),
         hi=(255, 230, 60), stickers="🎉⭐🏆🎊"),
    dict(src="home", grad=((225, 214, 255), (186, 164, 255), (140, 112, 245)),
         hi=(255, 230, 60), stickers="✈️🚙☁️🎒"),
    dict(src="awards", grad=((255, 236, 153), (255, 200, 100), (250, 140, 80)),
         hi=(122, 60, 230), stickers="🏆🥇🔥⭐"),
    # Last on purpose: shows the dark theme without darkening the first three
    # frames, which are the only ones search results show.
    dict(src="dark", grad=((120, 110, 220), (70, 64, 160), (34, 30, 92)),
         hi=(255, 214, 10), stickers="🌙⭐✨🧸", light_text=True),
]

# (headline, chip) per frame. *word* is highlighted; the chip's leading emoji
# run is separated from its text by two spaces.
COPY = {
    "en": [
        ("Flip, Find\n& *Match!*", "🐶  Cute animal cards"),
        ("Learn While\nYou *Play*", "🔤  ABC, 123, flags & more"),
        ("50 Levels of\n*Brain* Fun", "🧠  Grows with your child"),
        ("Win *Stars*,\nCheer Loud!", "⭐⭐⭐  Confetti on every win"),
        ("Play *Anywhere*,\nNo WiFi Needed", "✈️  Great for trips"),
        ("Collect Every\n*Trophy*", "🏆  Daily streaks & badges"),
        ("Cozy *Dark* Mode\nfor Bedtime", "🌙  Easy on little eyes"),
    ],
    "hi": [
        ("पलटो, ढूँढो\nऔर *मिलाओ!*", "🐶  प्यारे जानवर कार्ड"),
        ("खेल-खेल में\n*सीखो*", "🔤  ABC, 123, झंडे और भी"),
        ("50 लेवल\n*दिमागी* मज़ा", "🧠  बच्चे के साथ बढ़ता खेल"),
        ("*स्टार* जीतो,\nखुशी मनाओ!", "⭐⭐⭐  हर जीत पर कॉन्फ़ेटी"),
        ("*कहीं भी* खेलो,\nइंटरनेट नहीं चाहिए", "✈️  सफ़र के लिए बढ़िया"),
        ("हर *ट्रॉफ़ी*\nजीतो", "🏆  रोज़ की लय और बैज"),
        ("सोने से पहले\n*डार्क* मोड", "🌙  आँखों के लिए आरामदेह"),
    ],
    "es": [
        ("¡Voltea, busca\ny *une!*", "🐶  Tiernas cartas de animales"),
        ("Aprende\n*jugando*", "🔤  ABC, 123, banderas y más"),
        ("50 niveles de\n*diversión*", "🧠  Crece con tu hijo"),
        ("¡Gana *estrellas*\ny celebra!", "⭐⭐⭐  Confeti en cada victoria"),
        ("Juega *donde sea*,\nsin wifi", "✈️  Ideal para viajes"),
        ("Colecciona\ncada *trofeo*", "🏆  Rachas diarias e insignias"),
        ("Modo *oscuro*\npara dormir", "🌙  Suave para los ojos"),
    ],
    "pt": [
        ("Vire, ache\ne *combine!*", "🐶  Cartas de bichinhos fofos"),
        ("Aprenda\n*brincando*", "🔤  ABC, 123, bandeiras e mais"),
        ("50 fases de\n*diversão*", "🧠  Cresce com seu filho"),
        ("Ganhe *estrelas*\ne comemore!", "⭐⭐⭐  Confete em cada vitória"),
        ("Jogue *onde quiser*,\nsem Wi-Fi", "✈️  Ótimo para viagens"),
        ("Colecione todos\nos *troféus*", "🏆  Sequências e medalhas"),
        ("Modo *escuro*\nna hora de dormir", "🌙  Suave para os olhos"),
    ],
    "id": [
        ("Balik, cari\n& *cocokkan!*", "🐶  Kartu hewan lucu"),
        ("Belajar sambil\n*bermain*", "🔤  ABC, 123, bendera & lainnya"),
        ("50 level\n*asah otak*", "🧠  Tumbuh bersama anak"),
        ("Raih *bintang*,\nayo rayakan!", "⭐⭐⭐  Konfeti setiap menang"),
        ("Main *di mana saja*,\ntanpa WiFi", "✈️  Cocok untuk perjalanan"),
        ("Kumpulkan\nsemua *piala*", "🏆  Rentetan harian & lencana"),
        ("Mode *gelap*\nsebelum tidur", "🌙  Nyaman di mata"),
    ],
    "de": [
        ("Umdrehen, suchen\n& *finden!*", "🐶  Süße Tierkarten"),
        ("Spielend\n*lernen*", "🔤  ABC, 123, Flaggen & mehr"),
        ("50 Level\n*Kopf*-Spaß", "🧠  Wächst mit deinem Kind"),
        ("*Sterne* holen,\nlaut jubeln!", "⭐⭐⭐  Konfetti bei jedem Sieg"),
        ("Spiel *überall*,\nohne WLAN", "✈️  Super für Reisen"),
        ("Sammle\njeden *Pokal*", "🏆  Tagesserien & Abzeichen"),
        ("*Dunkel*-Modus\nzum Schlafen", "🌙  Schont kleine Augen"),
    ],
    "fr": [
        ("Retourne, cherche\net *assemble !*", "🐶  Jolies cartes animaux"),
        ("Apprendre\nen *jouant*", "🔤  ABC, 123, drapeaux et plus"),
        ("50 niveaux\nde *fun*", "🧠  Grandit avec ton enfant"),
        ("Gagne des *étoiles*,\nfais la fête !", "⭐⭐⭐  Confettis à chaque victoire"),
        ("Joue *partout*,\nsans Wi-Fi", "✈️  Parfait en voyage"),
        ("Collectionne\ntous les *trophées*", "🏆  Séries et badges"),
        ("Mode *sombre*\npour le coucher", "🌙  Doux pour les yeux"),
    ],
}

# Play feature graphic tagline lines per language.
FEATURE = {
    "en": ("Flip, find & match!", "50 levels of brain fun for kids"),
    "hi": ("पलटो, ढूँढो और मिलाओ!", "बच्चों के लिए 50 मज़ेदार लेवल"),
    "es": ("¡Voltea, busca y une!", "50 niveles de diversión para niños"),
    "pt": ("Vire, ache e combine!", "50 fases divertidas para crianças"),
    "id": ("Balik, cari & cocokkan!", "50 level seru untuk anak"),
    "de": ("Umdrehen, suchen, finden!", "50 lustige Level für Kinder"),
    "fr": ("Retourne, cherche, assemble !", "50 niveaux amusants pour enfants"),
}


def text_font(lang: str, size: int, weight: int) -> ImageFont.FreeTypeFont:
    if lang == "hi":
        return ImageFont.truetype(KOHINOOR, size, index=3)
    return font(FREDOKA, size, weight=weight)


# Pillow's basic layout can't shape Devanagari (matras land on the wrong side
# of their consonant), so Hindi text is rendered by Core Text via a tiny Swift
# helper instead, compiled once into the temp dir.
RENDER_SRC = Path(__file__).with_name("render_text.swift")
RENDER_BIN = Path(tempfile.gettempdir()) / "memorymatch_render_text"
RENDER_PAD = 2


@lru_cache(maxsize=None)
def shaped(text: str, size: int, color: tuple) -> Image.Image:
    if not RENDER_BIN.exists():
        subprocess.run(["swiftc", "-O", str(RENDER_SRC), "-o", str(RENDER_BIN)], check=True)
    out = Path(tempfile.mkstemp(suffix=".png")[1])
    subprocess.run([str(RENDER_BIN), text, "KohinoorDevanagari-Bold", str(size),
                    *(str(c) for c in color[:3]), str(out)], check=True)
    img = Image.open(out).convert("RGBA")
    img.load()
    out.unlink()
    return img


def text_width(d: ImageDraw.ImageDraw, lang: str, text: str, f, size: int) -> float:
    if lang == "hi" and text:
        return shaped(text, size, NAVY).width - RENDER_PAD * 2
    return d.textlength(text, font=f)


def put_text(img: Image.Image, xy, text: str, f, size: int, color, lang: str,
             middle: bool = False) -> None:
    """Draw text with its top-left at xy, or vertically centred on xy[1]."""
    x, y = xy
    if lang == "hi":
        if not text:
            return
        t = shaped(text, size, tuple(color[:3]))
        top = y - t.height / 2 if middle else y
        img.paste(t, (int(x - RENDER_PAD), int(top)), t)
    else:
        ImageDraw.Draw(img).text((x, y), text, font=f, fill=color, anchor="lm" if middle else None)


def emoji_img(ch: str, px: int) -> Image.Image:
    """Render a colour emoji. Apple Color Emoji only rasterises at its bitmap
    strike sizes, so draw at 160 and scale."""
    f = ImageFont.truetype(EMOJI, 160)
    im = Image.new("RGBA", (220, 220), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((110, 110), ch, font=f, embedded_color=True, anchor="mm")
    bbox = im.getbbox() or (0, 0, 220, 220)
    im = im.crop(bbox)
    scale = px / max(im.size)
    return im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.LANCZOS)


def split_graphemes(s: str) -> list[str]:
    """Good-enough emoji splitter: keeps variation selectors with their base."""
    out: list[str] = []
    for ch in s:
        if out and ch in "️‍":
            out[-1] += ch
        else:
            out.append(ch)
    return out


def prepare(path: Path, profile: dict) -> Image.Image:
    img = Image.open(path).convert("RGB")
    if img.size != profile["capture"]:
        img = img.resize(profile["capture"], Image.LANCZOS)
    if profile.get("generic"):
        # Blank the iOS status bar entirely; Play frames show no OS chrome.
        d = ImageDraw.Draw(img)
        bar_h = 150
        bg = img.getpixel((int(img.width * 0.06), bar_h + 10))
        d.rectangle((0, 0, img.width, bar_h), fill=bg)
    elif profile["island"]:
        draw_status_bar(img, scale=img.width / 1290, island=True)
    else:
        draw_status_bar_ipad(img)
    return img


def generic_phone(screen: Image.Image, target_w: int) -> tuple[Image.Image, Image.Image]:
    """A neutral black-bezel phone with a punch-hole camera."""
    aspect = screen.height / screen.width
    sw, sh = target_w, int(target_w * aspect)
    bezel = max(8, int(sw * 0.03))
    radius = int(sw * 0.09)
    bw, bh = sw + bezel * 2, sh + bezel * 2
    body = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.rounded_rectangle((0, 0, bw, bh), radius=radius + bezel, fill=(24, 26, 34, 255))
    scr = screen.resize((sw, sh), Image.LANCZOS)
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius=radius, fill=255)
    body.paste(scr, (bezel, bezel), mask)
    cam = int(sw * 0.028)
    cx = bw // 2
    bd.ellipse((cx - cam, bezel + int(sw * 0.03), cx + cam, bezel + int(sw * 0.03) + cam * 2),
               fill=(10, 10, 14, 255))
    shadow = v11.rounded_shadow((bw, bh), radius + bezel, blur=int(sw * 0.06),
                                spread=int(sw * 0.01), opacity=90)
    return body, shadow


def draw_confetti(img: Image.Image, seed: int, s: float) -> None:
    rnd = random.Random(seed)
    d = ImageDraw.Draw(img)
    W, H = img.size
    palette = [(255, 255, 255, 150), (255, 255, 255, 110), (255, 90, 140, 120),
               (90, 170, 255, 120), (255, 210, 60, 140)]
    for _ in range(26):
        x, y = rnd.randint(0, W), rnd.randint(0, H)
        r = int(rnd.uniform(8, 22) * s)
        c = rnd.choice(palette)
        if rnd.random() < 0.5:
            d.ellipse((x - r, y - r, x + r, y + r), fill=c)
        else:
            d.rounded_rectangle((x - r, y - r // 2, x + r, y + r // 2), radius=r // 3, fill=c)


def draw_headline(img: Image.Image, text: str, hi: tuple, top: int, s: float, max_w: int,
                  lang: str, base=NAVY) -> int:
    """Two-line headline in navy; the *word* gets a coloured pill."""
    d = ImageDraw.Draw(img)
    W = img.width
    size = int(132 * s)
    lines = text.split("\n")
    padx, pady = int(22 * s), int(6 * s)

    def line_width(line, f, sz):
        parts = line.split("*")
        # The pill reaches padx past its word on each side, so the word gets
        # that much extra room or the pill eats into its neighbours.
        return sum(text_width(d, lang, p, f, sz) + (2 * padx if i % 2 and p else 0)
                   for i, p in enumerate(parts))

    def measure(sz):
        f = text_font(lang, sz, 700)
        return f, max(line_width(l, f, sz) for l in lines)

    f, widest = measure(size)
    while widest > max_w and size > 60 * s:
        size -= int(4 * s) or 1
        f, widest = measure(size)

    # Devanagari sits lower in its em box and needs more line height.
    line_h = int(size * (1.32 if lang == "hi" else 1.18))
    y = top
    for line in lines:
        parts = line.split("*")
        x = (W - line_width(line, f, size)) / 2
        for i, part in enumerate(parts):
            pw = text_width(d, lang, part, f, size)
            if i % 2 == 1 and part:
                x += padx
                if lang == "hi":
                    ink = shaped(part, size, NAVY).getbbox()
                    bb = (0, y + ink[1], 0, y + ink[3])
                else:
                    bb = d.textbbox((x, y), part, font=f)
                d.rounded_rectangle((x - padx, bb[1] - pady * 2, x + pw + padx, bb[3] + pady * 2),
                                    radius=int(size * 0.32), fill=hi)
                txt_col = (255, 255, 255) if sum(hi) < 520 else NAVY
                put_text(img, (x, y), part, f, size, txt_col, lang)
                x += pw + padx
            else:
                put_text(img, (x, y), part, f, size, base, lang)
                x += pw
        y += line_h
    return y


def draw_chip(img: Image.Image, text: str, cy: int, s: float, lang: str) -> int:
    d = ImageDraw.Draw(img)
    fsize = int(50 * s)
    f = text_font(lang, fsize, 600)
    lead, _, rest = text.partition("  ")
    em = [emoji_img(g, int(56 * s)) for g in split_graphemes(lead)]
    em_w = sum(e.width for e in em) + int(4 * s) * max(0, len(em) - 1) + (int(14 * s) if em else 0)
    tw = text_width(d, lang, rest, f, fsize)
    w = int(em_w + tw + 70 * s)
    h = int(96 * s)
    x0 = (img.width - w) // 2
    y0 = cy
    d.rounded_rectangle((x0, y0, x0 + w, y0 + h), radius=h // 2, fill=(255, 255, 255, 235))
    x = x0 + int(35 * s)
    for e in em:
        img.paste(e, (x, y0 + (h - e.height) // 2), e)
        x += e.width + int(4 * s)
    if em:
        x += int(10 * s)
    put_text(img, (x, y0 + h // 2), rest, f, fsize, NAVY, lang, middle=True)
    return y0 + h


def place_stickers(img: Image.Image, stickers: str, dev_box, s: float, seed: int) -> None:
    rnd = random.Random(seed)
    x0, y0, x1, y1 = dev_box
    W, H = img.size
    em = split_graphemes(stickers)
    # Two on each side of the device, tucked over its edge.
    spots = [(x0 - 20 * s, y0 + (y1 - y0) * 0.12), (x1 + 20 * s, y0 + (y1 - y0) * 0.30),
             (x0 - 10 * s, y0 + (y1 - y0) * 0.55), (x1 + 10 * s, y0 + (y1 - y0) * 0.72)]
    for ch, (cx, cy) in zip(em, spots):
        size = int(rnd.uniform(150, 190) * s)
        e = emoji_img(ch, size).rotate(rnd.uniform(-16, 16), expand=True, resample=Image.BICUBIC)
        cx = min(max(cx, size * 0.45), W - size * 0.45)
        img.paste(e, (int(cx - e.width / 2), int(cy - e.height / 2)), e)


def build_frame(spec: dict, copy: tuple[str, str], idx: int, canvas: tuple[int, int],
                profile: dict, lang: str) -> Image.Image:
    W, H = canvas
    s = W / profile["ref_width"]
    head, chip = copy
    img = gradient(canvas, spec["grad"]).convert("RGBA")
    overlay = Image.new("RGBA", canvas, (0, 0, 0, 0))
    draw_confetti(overlay, seed=idx, s=s)
    img.alpha_composite(overlay)

    margin = int(70 * s)
    y = draw_headline(img, head, spec["hi"], int(110 * s), s, W - margin * 2, lang,
                      base=(255, 255, 255) if spec.get("light_text") else NAVY)
    y = draw_chip(img, chip, y + int(26 * s), s, lang)

    screen = prepare(CAPS / lang / f"{profile['prefix']}{spec['src']}.png", profile)
    target_w = int(W * profile["device_frac"])
    if profile.get("generic"):
        body, shadow = generic_phone(screen, target_w)
    else:
        body, shadow = device_frame(screen, target_w=target_w, profile=profile)
    bx = (W - body.width) // 2
    by = y + int(60 * s)
    pad = shadow.width - body.width
    img.paste((40, 30, 60), (bx - pad // 2, by - pad // 2 + int(24 * s)), shadow)
    img.paste(body, (bx, by), body)
    place_stickers(img, spec["stickers"], (bx, by, bx + body.width, min(H, by + body.height)), s, idx)
    return img.convert("RGB")


def feature_graphic(lang: str) -> Image.Image:
    """Google Play feature graphic, 1024x500."""
    W, H = 1024, 500
    img = gradient((W, H), ((255, 226, 120), (255, 180, 90), (255, 130, 120))).convert("RGBA")
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_confetti(ov, seed=99, s=0.6)
    img.alpha_composite(ov)
    icon_path = ROOT / "MemoryGame/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
    icon = Image.open(icon_path).convert("RGBA").resize((300, 300), Image.LANCZOS)
    m = Image.new("L", icon.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, 300, 300), radius=68, fill=255)
    sh = v11.rounded_shadow((300, 300), 68, blur=18, spread=4, opacity=90)
    img.paste((60, 30, 40), (70 - 54, 100 - 54 + 10), sh)
    img.paste(icon, (70, 100), m)
    d = ImageDraw.Draw(img)
    line1, line2 = FEATURE[lang]
    d.text((420, 150), "Memory Match", font=font(FREDOKA, 84, weight=700), fill=NAVY)
    # Shrink the taglines until they fit the space right of the icon.
    for size in range(40, 22, -2):
        f2 = text_font(lang, size, 600)
        if max(text_width(d, lang, line1, f2, size), text_width(d, lang, line2, f2, size)) <= W - 440:
            break
    put_text(img, (424, 258), line1, f2, size, (233, 64, 110), lang)
    put_text(img, (424, 312), line2, f2, size, NAVY, lang)
    for ch, (x, y) in zip(split_graphemes("🐶⭐🦊"), [(880, 40), (950, 380), (370, 400)]):
        e = emoji_img(ch, 90)
        img.paste(e, (x, y), e)
    return img.convert("RGB")


def main() -> None:
    langs = sys.argv[1:] or list(COPY)
    for lang in langs:
        for profile in DEVICES.values():
            for label, canvas in profile["canvases"].items():
                out_dir = OUT / lang / label
                out_dir.mkdir(parents=True, exist_ok=True)
                for i, (spec, copy) in enumerate(zip(FRAMES, COPY[lang]), start=1):
                    frame = build_frame(spec, copy, i, canvas, profile, lang)
                    frame.save(out_dir / f"{i:02d}_{spec['src']}.png", "PNG", optimize=True)
        feature_graphic(lang).save(OUT / lang / "GooglePlay_feature_graphic.png", "PNG", optimize=True)
        print(f"  {lang}: done")


if __name__ == "__main__":
    main()
