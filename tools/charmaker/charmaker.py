"""Character maker: builds full character sheets from modular layers.

Layers (all on the same 623x192 grid as the base pack: 3 animations x 4 frames,
3 directions, 32x48 cells):
  hair_back  (derived: long hair falling behind the body)
  body       (base_human, recoloured to a skin tone)
  outfit     (outfit_explorer, recoloured: top / bottom / accent ramps)
  hair       (hair_short recoloured, or turned into a hood or helmet, or none)

Usage:
  python3 tools/charmaker/charmaker.py            # builds every character in characters.json
  python3 tools/charmaker/charmaker.py --preview  # also writes a preview sheet

Inputs:  assets/characters/modules/*.png, assets/characters/characters.json
Outputs: assets/characters/sheets/<id>.png, assets/characters/preview.png
"""
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MOD = ROOT / "assets/characters/modules"
OUT = ROOT / "assets/characters/sheets"
DEFS = ROOT / "assets/characters/characters.json"

OUTLINE = (0, 0, 0)
EYE_GREYS = {(0xa5, 0xa5, 0xa5), (0xe2, 0xe2, 0xe2), (0xff, 0xff, 0xff), (0x52, 0x52, 0x52), (0x05, 0x05, 0x05), (0x33, 0x33, 0x33)}


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def ramp_map(colors, ramp):
    """Maps source colours to a target ramp by brightness rank (dark to light)."""
    src = sorted(set(colors), key=lum)
    ramp = [hexc(c) for c in ramp]
    out = {}
    for i, c in enumerate(src):
        j = round(i * (len(ramp) - 1) / max(1, len(src) - 1))
        out[c] = ramp[j]
    return out


def recolor(img, mapping):
    img = img.copy()
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b) in mapping:
                nr, ng, nb = mapping[(r, g, b)]
                px[x, y] = (nr, ng, nb, a)
    return img


def colors_of(img, keep=lambda c: True):
    return {p[:3] for p in img.get_flattened_data() if p[3] and keep(p[:3])}


def skin(base, ramp):
    """Recolours the body's skin pixels; outline and eye greys stay."""
    cs = colors_of(base, lambda c: c != OUTLINE and c not in EYE_GREYS)
    return recolor(base, ramp_map(cs, ramp))


def outfit(img, top, bottom, accent):
    """Splits the outfit by brightness and hue: light cloth = top, dark = bottom, green = accent."""
    cs = colors_of(img, lambda c: lum(c) > 14)  # keep the near-black outline
    green = {c for c in cs if c[1] > c[0] + 20 and c[1] > c[2]}
    rest = cs - green
    light = {c for c in rest if lum(c) >= 70}
    dark = rest - light
    m = {}
    m.update(ramp_map(light, top))
    m.update(ramp_map(dark, bottom))
    m.update(ramp_map(green, accent))
    return recolor(img, m)


def outline(mask_img, color=(0, 0, 0, 255)):
    """A 1-pixel outline around every opaque pixel, drawn under the layer."""
    w, h = mask_img.size
    src = mask_img.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3]:
                    px[x, y] = color
                    break
    out.alpha_composite(mask_img)
    return out


CELL_W, CELL_H = 32, 48
COL_X = [32 + i * 32 for i in range(4)] + [176 + i * 32 for i in range(4)] + [320 + i * 32 for i in range(4)]
ROW_Y = [40, 88, 136]


def _cells():
    for x0 in COL_X:
        for y0 in ROW_Y:
            yield x0, y0


def _dilate(mask, r=1):
    out = set(mask)
    for (x, y) in mask:
        for dx in range(-r, r + 1):
            for dy in range(-r, r + 1):
                if abs(dx) + abs(dy) <= r:
                    out.add((x + dx, y + dy))
    return out


def headgear(base, hair, ramp, kind):
    """A hood or helmet drawn from the head's own outline, cell by cell.

    hood:   a rounded cloth shell over the head and hair, a ring around the face,
            the face itself left open.
    helmet: a metal dome down to the brow with a bright rim and a crest.
    """
    ramp = [hexc(c) for c in ramp]
    out = Image.new("RGBA", base.size, (0, 0, 0, 0))
    bp, hp, op = base.load(), hair.load(), out.load()
    for x0, y0 in _cells():
        head, hairm = set(), set()
        top = None
        for y in range(y0, y0 + CELL_H):
            for x in range(x0, x0 + CELL_W):
                if bp[x, y][3]:
                    top = y if top is None else top
        if top is None:
            continue
        for y in range(top, top + 14):
            for x in range(x0, x0 + CELL_W):
                if bp[x, y][3]:
                    head.add((x, y))
        for y in range(y0, y0 + CELL_H):
            for x in range(x0, x0 + CELL_W):
                if hp[x, y][3]:
                    hairm.add((x, y))
        brow = top + 6
        shell = _dilate(head | hairm, 2 if kind == "hood" else 1)
        if kind == "hood":
            inner = {(x, y) for (x, y) in head if y >= brow - 1 and all((x + dx, y) in head for dx in (1, -1))}
            mask = {(x, y) for (x, y) in shell if (x, y) not in inner and y <= top + 15}
        else:
            mask = {(x, y) for (x, y) in shell if y <= brow}
        if not mask:
            continue
        ys = [y for _, y in mask]
        xs = [x for x, _ in mask]
        ymin, ymax, xmin, xmax = min(ys), max(ys), min(xs), max(xs)
        for (x, y) in mask:
            # light from the top left: brighter up and left, darker down and right
            v = 1.0 - 0.65 * (y - ymin) / max(1, ymax - ymin) - 0.25 * (x - xmin) / max(1, xmax - xmin)
            c = ramp[max(0, min(len(ramp) - 1, round(v * (len(ramp) - 1))))]
            op[x, y] = (*c, 255)
        if kind == "helmet":
            for (x, y) in mask:
                if y == brow:
                    op[x, y] = (*ramp[-1], 255)
            cx = (xmin + xmax) // 2
            for dy in range(1, 4):
                op[cx, ymin - dy] = (*ramp[1], 255)
                op[cx + 1, ymin - dy] = (*ramp[2], 255)
    return outline(out)


def long_hair_back(hair, ramp, length=9):
    """Hair falling behind the shoulders: the hair mask stretched down, a shade darker."""
    cs = colors_of(hair)
    dark = recolor(hair, ramp_map(cs, ramp[:max(2, len(ramp) - 1)]))
    back = Image.new("RGBA", hair.size, (0, 0, 0, 0))
    for d in range(2, length + 1, 2):
        back.alpha_composite(dark, (0, d))
    return outline(back)


def build(char, mods):
    hair_ramp = char.get("hair_color")
    layers = []
    if char.get("hair") == "long":
        layers.append(long_hair_back(mods["hair"], hair_ramp))
    layers.append(skin(mods["base"], char["skin"]))
    o = char["outfit"]
    layers.append(outfit(mods["outfit"], o["top"], o["bottom"], o.get("accent", o["top"])))
    style = char.get("hair", "short")
    if style in ("short", "long"):
        layers.append(recolor(mods["hair"], ramp_map(colors_of(mods["hair"]), hair_ramp)))
    elif style in ("hood", "helmet"):
        layers.append(headgear(mods["base"], mods["hair"], char[style], style))
    sheet = Image.new("RGBA", mods["base"].size, (0, 0, 0, 0))
    for layer in layers:
        sheet.alpha_composite(layer)
    # the pack's sheet has its animation labels baked in at the top: cut them off
    label_cut = Image.new("RGBA", (sheet.width, 40), (0, 0, 0, 0))
    sheet.paste(label_cut, (0, 0))
    return sheet


def main():
    mods = {
        "base": Image.open(MOD / "base_human.png").convert("RGBA"),
        "outfit": Image.open(MOD / "outfit_explorer.png").convert("RGBA"),
        "hair": Image.open(MOD / "hair_short.png").convert("RGBA"),
    }
    defs = json.loads(DEFS.read_text(encoding="utf-8"))
    OUT.mkdir(parents=True, exist_ok=True)
    sheets = {}
    for c in defs["characters"]:
        sheets[c["id"]] = build(c, mods)
        sheets[c["id"]].save(OUT / f"{c['id']}.png")
        print("built", c["id"])
    if "--preview" in sys.argv:
        preview(defs, sheets)


def preview(defs, sheets):
    """One row per character: the side-view attack, run and wave frames at 3x."""
    chars = defs["characters"]
    cell_w, cell_h, scale = 32, 48, 3
    frames = [(32 + i * 32, 88) for i in range(4)] + [(176 + i * 32, 88) for i in range(4)] + [(320 + i * 32, 88) for i in range(4)]
    front = (32, 40)
    out = Image.new("RGBA", ((len(frames) + 1) * cell_w * scale + 40, len(chars) * cell_h * scale), (42, 36, 46, 255))
    for r, c in enumerate(chars):
        sh = sheets[c["id"]]
        tiles = [front] + frames
        for i, (x, y) in enumerate(tiles):
            tile = sh.crop((x, y, x + cell_w, y + cell_h)).resize((cell_w * scale, cell_h * scale), Image.NEAREST)
            out.alpha_composite(tile, (i * cell_w * scale + (40 if i else 0), r * cell_h * scale))
    out.save(ROOT / "assets/characters/preview.png")
    print("preview", out.size)


if __name__ == "__main__":
    main()
