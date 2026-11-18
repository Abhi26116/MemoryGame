# -*- coding: utf-8 -*-
"""Frame-by-frame overlay renderer: sticker pop-ins, countdown ring, confetti, flash."""
import os, math, random, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import style2 as st
from PIL import Image, ImageDraw

FPS = 30


def ease_out_back(u, s=1.9):
    u = u - 1.0
    return 1.0 + (s + 1.0) * u ** 3 + s * u ** 2


def ease_out_cubic(u):
    return 1.0 - (1.0 - u) ** 3


def _draw_sprite(canvas, spr, cx, cy, scale, alpha, dy=0):
    if alpha <= 0.01 or scale <= 0.01:
        return
    w = max(1, int(spr.width * scale))
    h = max(1, int(spr.height * scale))
    im = spr if (w == spr.width and h == spr.height) else spr.resize((w, h), Image.LANCZOS)
    if alpha < 0.995:
        im = im.copy()
        im.putalpha(im.split()[3].point(lambda v: int(v * alpha)))
    canvas.alpha_composite(im, (int(cx - w / 2), int(cy - h / 2 + dy)))


def _state(t, t_in, t_out, pop=0.26, out=0.16, bob=True):
    """Returns (scale, alpha, dy) for a popping element."""
    if t < t_in or t > t_out:
        return None
    age = t - t_in
    left = t_out - t
    if age < pop:
        u = age / pop
        return ease_out_back(u), min(1.0, u * 3.5), 0.0
    if left < out:
        v = 1.0 - left / out
        return 1.0 - 0.22 * v, 1.0 - v, 0.0
    if bob:
        ph = (age - pop) * 1.7
        return 1.0 + 0.010 * math.sin(ph), 1.0, 2.6 * math.sin(ph * 0.85)
    return 1.0, 1.0, 0.0


class Confetti:
    def __init__(self, t_in, n=110, seed=7):
        rnd = random.Random(seed)
        self.t_in = t_in
        self.p = []
        for _ in range(n):
            self.p.append(dict(
                x=rnd.uniform(-40, st.W + 40), y=rnd.uniform(-640, 30),
                vy=rnd.uniform(620, 1180), vx=rnd.uniform(-130, 130),
                w=rnd.uniform(14, 30), h=rnd.uniform(20, 42),
                rot=rnd.uniform(0, 360), vr=rnd.uniform(-420, 420),
                c=rnd.choice(st.CONFETTI)))

    def draw(self, canvas, t):
        dt = t - self.t_in
        if dt < 0:
            return
        layer = Image.new("RGBA", (st.W, st.H), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        for p in self.p:
            x = p["x"] + p["vx"] * dt
            y = p["y"] + p["vy"] * dt + 300 * dt * dt
            if y > st.H + 60:
                continue
            ang = math.radians(p["rot"] + p["vr"] * dt)
            hw, hh = p["w"] / 2, p["h"] / 2 * abs(math.cos(ang))
            if hh < 1.2:
                hh = 1.2
            d.rectangle([x - hw, y - hh, x + hw, y + hh], fill=p["c"] + (240,))
        canvas.alpha_composite(layer)


def render(elements, duration, outdir, confetti=None, flashes=()):
    os.makedirs(outdir, exist_ok=True)
    total = int(round(duration * FPS))
    ring_cache = {}
    for i in range(total):
        t = i / FPS
        c = Image.new("RGBA", (st.W, st.H), (0, 0, 0, 0))
        for el in elements:
            s = _state(t, el["in"], el["out"], bob=el.get("bob", True))
            if not s:
                continue
            scale, alpha, dy = s
            if el["kind"] == "ring":
                span = el["out"] - el["in"]
                frac = max(0.0, 1.0 - (t - el["in"]) / span)
                key = (el["n"], round(frac * 90))
                if key not in ring_cache:
                    ring_cache[key] = st.countdown_ring(el["n"], frac)
                spr = ring_cache[key]
            else:
                spr = el["img"]
            _draw_sprite(c, spr, el["cx"], el["cy"], scale * el.get("s", 1.0), alpha, dy)
        if confetti:
            confetti.draw(c, t)
        for (ft, fd) in flashes:
            if ft <= t < ft + fd:
                a = int(150 * (1.0 - (t - ft) / fd) ** 1.9)
                if a > 2:
                    c.alpha_composite(Image.new("RGBA", (st.W, st.H), (255, 255, 255, a)))
        c.save(os.path.join(outdir, "f%04d.png" % i))
    return total
