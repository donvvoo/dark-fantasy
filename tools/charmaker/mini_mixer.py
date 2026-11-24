"""Mini mixer: makes many new 16x16 characters from a pack of whole mini characters.

The source pack (VerArc Stash Mini Characters, supplied by the project owner) has
whole characters, not layers. This tool splits each one into parts by colour and
position, then:
  1. recolours hair/hat and clothing to new palettes (palette variants)
  2. swaps heads and bodies between humanoids at the chin line (head/body mixes)

Not used by the game: output goes to assets/characters/verarc/ (Godot-ignored).

Usage: python3 tools/charmaker/mini_mixer.py <pack_dir> [--seed N] [--mixes N]
Outputs: assets/characters/verarc/{source,palette,mix}/*.png, sheet_*.png, catalog.json
"""
import argparse
import colorsys
import json
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/characters/verarc"

HAIR_RAMPS = {
    "ash": ["#2a2a30", "#4a4a54", "#74747e", "#a4a4ae", "#d0d0d8"],
    "raven": ["#0e0e18", "#1c1c2c", "#2c2c44", "#40405c", "#585878"],
    "ember": ["#4a0e0a", "#7a1c12", "#aa2e1a", "#d4482a", "#f06a3a"],
    "gold": ["#6a4a12", "#9a701e", "#c89a2e", "#e8c454", "#fae28a"],
    "moss": ["#1a3418", "#2a4e24", "#3c6a32", "#548a44", "#74aa5c"],
    "frost": ["#2a4a6a", "#3e6a8e", "#5a8eb2", "#82b2d2", "#b4d8ee"],
    "rose": ["#5a1a34", "#84264a", "#ac3a62", "#d05a80", "#ee86a4"],
    "violet": ["#2a1444", "#3e1e62", "#562c82", "#7442a4", "#9a66c6"],
}
CLOTH_RAMPS = {
    "crimson": ["#2a0a0e", "#4e1218", "#761c22", "#a02a2c", "#c8463a"],
    "navy": ["#0e1630", "#18244c", "#24366c", "#344c8e", "#4c68ae"],
    "forest": ["#0e2014", "#183420", "#244a2c", "#346438", "#4c824a"],
    "bone": ["#4a4438", "#6e6656", "#968c78", "#bcb29c", "#e0d8c4"],
    "plum": ["#200e22", "#381836", "#52244c", "#6e3264", "#8e4680"],
    "rust": ["#3a1a0a", "#5e2c12", "#84421c", "#a85e2a", "#ca7e40"],
    "slate": ["#14181e", "#242a32", "#363e48", "#4c5662", "#68727e"],
    "teal": ["#0a2626", "#123c3c", "#1c5656", "#287272", "#3a9090"],
}


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def is_skin(c):
    r, g, b = c
    # light skin only: orange fur and tan cloth fail the blue floor
    return r > 200 and r >= g >= b - 10 and r - b > 25 and lum(c) > 170 and b > 140


def analyse(img):
    """Classifies each colour: outline, skin, hair (upper), cloth (lower) or detail."""
    px = img.load()
    stats = {}
    for y in range(img.height):
        for x in range(img.width):
            p = px[x, y]
            if p[3] == 0:
                continue
            s = stats.setdefault(p[:3], [0, 0])
            s[0] += 1
            s[1] += y
    groups = {"outline": set(), "skin": set(), "hair": set(), "cloth": set(), "detail": set()}
    for c, (n, ys) in stats.items():
        ay = ys / n
        if lum(c) < 38:
            groups["outline"].add(c)
        elif is_skin(c) and 3.5 <= ay <= 12.5:
            groups["skin"].add(c)
        elif n <= 2:
            groups["detail"].add(c)  # eyes, highlights, tiny trims stay as drawn
        elif ay < 7.0 and not (lum(c) > 190 and c[0] >= c[1] >= c[2]):  # pale scalp shades stay
            groups["hair"].add(c)
        elif ay >= 9.0:
            groups["cloth"].add(c)
        else:
            groups["detail"].add(c)
    return groups


def chin_row(img, skin):
    """The first row under the face: the end of the first unbroken run of skin rows.

    Hands share the face's skin colour, so only the run that starts at the face counts.
    """
    px = img.load()
    rows = [y for y in range(2, 15) if sum(1 for x in range(img.width) if px[x, y][3] and px[x, y][:3] in skin) >= 2]
    if not rows:
        return None
    end = rows[0]
    while end + 1 in rows:
        end += 1
    return end + 1


def _parts_ok(img, chin, skin):
    """A head worth reusing (a real face) and a body worth reusing (enough pixels)."""
    px = img.load()
    head = sum(1 for y in range(chin) for x in range(16) if px[x, y][3])
    face = sum(1 for y in range(chin) for x in range(16) if px[x, y][3] and px[x, y][:3] in skin)
    body = sum(1 for y in range(chin, 16) for x in range(16) if px[x, y][3])
    return head >= 60 and face >= 10 and body >= 18


def ramp_map(colors, ramp):
    src = sorted(colors, key=lum)
    ramp = [hexc(c) for c in ramp]
    return {c: ramp[round(i * (len(ramp) - 1) / max(1, len(src) - 1))] for i, c in enumerate(src)}


# ---- Colour harmony: keep the pack's own shading, move only the hue --------------------------

def hsv(c):
    return colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)


def rgb(h, s_, v):
    r, g, b = colorsys.hsv_to_rgb(h % 1.0, max(0.0, min(1.0, s_)), max(0.0, min(1.0, v)))
    return (round(r * 255), round(g * 255), round(b * 255))


def group_hue(colors):
    """The group's dominant hue, weighted by saturation (greys barely count)."""
    import math
    x = y = w = 0.0
    for c in colors:
        h, s_, v = hsv(c)
        x += math.cos(h * 2 * math.pi) * s_
        y += math.sin(h * 2 * math.pi) * s_
        w += s_
    if w < 1e-6:
        return None
    return (math.atan2(y, x) / (2 * math.pi)) % 1.0


def main_family(colors, width=0.11):
    """The colours of the group's dominant hue family (plus near-greys): the hair itself,
    not the headband, ribbon or hairpin drawn in another hue, which stay as drawn."""
    base = group_hue(colors)
    if base is None:
        return set(colors)
    out = set()
    for c in colors:
        h, s_, v = hsv(c)
        d = min(abs(h - base), 1 - abs(h - base))
        if s_ < 0.18 or d <= width:
            out.add(c)
    return out


def hue_shift_map(colors, target_hue, sat_scale=1.0, min_sat=0.0):
    """Rotates every colour to the target hue, keeping its own saturation and value,
    so highlights, shadows and outline contrast stay exactly as the artist drew them."""
    m = {}
    for c in main_family(colors):
        h, s_, v = hsv(c)
        m[c] = rgb(target_hue, max(min_sat, s_ * sat_scale), v)
    return m


def snap_to_palette(mapping, palette, max_sat=0.62):
    """Moves every new colour onto the nearest colour the pack already uses, so a new
    character never shows a colour the original artist did not pick. Where two shades of
    a ramp would land on the same pack colour, the shade keeps its own (saturation-capped)
    colour instead, so the shading never collapses."""
    def dist(a, b):  # perceptual-ish: luminance matters most
        return 3 * (lum(a) - lum(b)) ** 2 + (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2
    out, used = {}, {}
    for src_c, new_c in sorted(mapping.items(), key=lambda kv: lum(kv[0])):
        best = min(palette, key=lambda p: dist(p, new_c))
        if dist(best, new_c) < 2200 and used.get(best, src_c) == src_c:
            out[src_c] = best
            used[best] = src_c
        else:
            h, s_, v = hsv(new_c)
            out[src_c] = rgb(h, min(s_, max_sat), v)
    return out


def pick_cloth_hue(hair_hue, rng):
    """A clothing hue that sits well beside the hair: analogous, complementary or split."""
    if hair_hue is None:
        return rng.random()
    scheme = rng.choice([0.08, -0.08, 0.5, 0.42, 0.58, 0.33, -0.33])
    return (hair_hue + scheme + rng.uniform(-0.02, 0.02)) % 1.0


def recolor(img, mapping):
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            p = px[x, y]
            if p[3] and p[:3] in mapping:
                px[x, y] = (*mapping[p[:3]], p[3])
    return out


def _centre_x(img, y0, y1, pick):
    px = img.load()
    xs = [x for y in range(y0, y1) for x in range(img.width) if px[x, y][3] and pick(px[x, y][:3])]
    return sum(xs) / len(xs) if xs else img.width / 2


def mix(head_img, head_chin, head_skin, body_img, body_chin):
    """Head of one character on the body of another, at the pack's own 16-pixel height.

    Pairs are chosen with chins within a pixel of each other, so the head-to-body ratio
    stays the pack's. The body is shifted so the collar sits under the middle of the face.
    """
    head = head_img.crop((0, 0, 16, head_chin))
    body = body_img.crop((0, body_chin, 16, 16))
    face_x = _centre_x(head_img, head_chin - 3, head_chin, lambda c: c in head_skin)
    collar_x = _centre_x(body_img, body_chin, body_chin + 2, lambda c: True)
    dx = max(-2, min(2, round(face_x - collar_x)))
    canvas = Image.new("RGBA", (16, 18), (0, 0, 0, 0))
    body_top = 18 - body.height
    head_top = body_top - head.height + (1 if head.height + body.height > 16 else 0)  # overlap a row to stay 16 tall
    canvas.alpha_composite(body, (dx, body_top))
    canvas.alpha_composite(head, (0, head_top))  # the head sits over the collar
    return canvas


def sheet(items, path, cols=16, scale=6, pad=4):
    if not items:
        return
    cw, ch = 18 * scale + pad, 18 * scale + pad
    rows = (len(items) + cols - 1) // cols
    out = Image.new("RGBA", (cols * cw + pad, rows * ch + pad), (42, 36, 46, 255))
    for i, im in enumerate(items):
        big = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        x = pad + (i % cols) * cw + (18 * scale - big.width) // 2
        y = pad + (i // cols) * ch + (18 * scale - big.height)
        out.alpha_composite(big, (x, y))
    out.save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pack")
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--mixes", type=int, default=192)
    ap.add_argument("--palettes", type=int, default=4, help="palette variants per humanoid")
    a = ap.parse_args()
    rng = random.Random(a.seed)
    src = sorted(Path(a.pack).glob("char_*.png"))
    for d in ("source", "palette", "mix"):
        (OUT / d).mkdir(parents=True, exist_ok=True)
        for old in (OUT / d).glob("*.png"):  # a rerun replaces the previous output
            old.unlink()
    (OUT / ".gdignore").touch()
    chars, catalog = [], {"source": [], "palette": [], "mix": []}
    for f in src:
        img = Image.open(f).convert("RGBA")
        g = analyse(img)
        chin = chin_row(img, g["skin"])
        humanoid = bool(g["skin"]) and chin is not None and 8 <= chin <= 12 and _parts_ok(img, chin, g["skin"])
        chars.append({"id": f.stem, "img": img, "g": g, "chin": chin, "humanoid": humanoid})
        img.save(OUT / "source" / f.name)
        catalog["source"].append({"id": f.stem, "humanoid": humanoid, "chin": chin})
    humans = [c for c in chars if c["humanoid"]]
    # 1. palette variants
    pal_items = []
    # hair hues the pack itself uses: new hair colours stay believable
    pack_hair_hues = [hh for c in humans for hh in [group_hue(c["g"]["hair"])] if hh is not None]
    # every colour the pack uses (outline and skin excluded): the palette new colours snap to
    master = {p[:3] for c in chars for p in c["img"].getdata() if p[3] and lum(p[:3]) >= 38 and not is_skin(p[:3])}
    for c in humans:
        for k in range(a.palettes):
            hair_hue = group_hue(c["g"]["hair"])
            hair_map = {}
            if c["g"]["hair"] and pack_hair_hues:
                # try a few pack hair hues; keep the first whose snapped colours stay calm
                for _ in range(6):
                    new_hair = rng.choice(pack_hair_hues)
                    capped = {src_c: rgb(hh, min(ss, 0.62), vv) for src_c, col in hue_shift_map(c["g"]["hair"], new_hair).items()
                              for hh, ss, vv in [hsv(col)]}
                    snapped = snap_to_palette(capped, master)
                    if max((hsv(col)[1] for col in snapped.values()), default=0) <= 0.72:
                        hair_map, hair_hue = snapped, new_hair
                        break
            cloth_hue = pick_cloth_hue(hair_hue, rng)
            cloth_map = snap_to_palette(hue_shift_map(c["g"]["cloth"], cloth_hue, min_sat=0.18), master) if c["g"]["cloth"] else {}
            im = recolor(c["img"], {**hair_map, **cloth_map})
            hk, ck = f"h{round((hair_hue or 0) * 360)}", f"c{round(cloth_hue * 360)}"
            name = f"{c['id']}_{hk}_{ck}_{k}"
            canvas = Image.new("RGBA", (16, 18), (0, 0, 0, 0))
            canvas.alpha_composite(im, (0, 2))
            canvas.save(OUT / "palette" / f"{name}.png")
            pal_items.append(canvas)
            catalog["palette"].append({"id": name, "from": c["id"], "hair": hk, "cloth": ck})
    # 2. head/body mixes, each pair once, never a character with itself
    pairs = [(h, b) for h in humans for b in humans if h is not b and abs(h["chin"] - b["chin"]) <= 1]
    rng.shuffle(pairs)
    mix_items = []
    for h, b in pairs[:a.mixes]:
        im = mix(h["img"], h["chin"], h["g"]["skin"], b["img"], b["chin"])
        name = f"{h['id']}_head__{b['id']}_body"
        im.save(OUT / "mix" / f"{name}.png")
        mix_items.append(im)
        catalog["mix"].append({"id": name, "head": h["id"], "body": b["id"]})
    sheet(pal_items, OUT / "sheet_palette.png")
    sheet(mix_items, OUT / "sheet_mix.png")
    (OUT / "catalog.json").write_text(json.dumps(catalog, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"source {len(chars)} (humanoid {len(humans)}) · palette {len(pal_items)} · mix {len(mix_items)}")


if __name__ == "__main__":
    main()
