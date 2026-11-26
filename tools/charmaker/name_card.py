"""Name card: a sticker outline around a sprite and a framed card with the name.

Usage: python3 tools/charmaker/name_card.py <sprite.png> <NAME> <bg #hex> <out_dir> [--scale 2]
Writes <out_dir>/<name>_sprite.png (outlined, native size) and <name>_card.png (400x400).
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONT = ROOT / "assets/fonts/Galmuri11-Bold.ttf"


def sticker(img, color=(255, 255, 255, 255)):
    """A 1-pixel outer outline (default white) around everything opaque, under the sprite."""
    w, h = img.size
    pad = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    pad.alpha_composite(img, (1, 1))
    src = pad.load()
    out = Image.new("RGBA", pad.size, (0, 0, 0, 0))
    o = out.load()
    for y in range(pad.height):
        for x in range(pad.width):
            if src[x, y][3] > 60:
                continue
            if any(0 <= x + dx < pad.width and 0 <= y + dy < pad.height and src[x + dx, y + dy][3] > 60
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1))):
                o[x, y] = color
    out.alpha_composite(pad)
    return out


def card(sprite, name, bg, scale=2, size=400, native=False):
    bg = tuple(int(bg.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))
    light = tuple(min(255, c + 40) for c in bg)
    floor = tuple(min(255, int(c * 1.18) + 18) for c in bg)
    c = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    d = ImageDraw.Draw(c)
    m = 3 if native else 12
    d.rectangle((m, m, size - m - 1, size - m - 1), fill=bg)               # panel
    band = size * 24 // 100
    d.rectangle((m, size - band, size - m - 1, size - m - 1), fill=floor)   # floor band
    d.rectangle((m, size - band - 1, size - m - 1, size - band - 1), fill=light)
    rail = 2 if native else 8
    for x in (m + rail, size - m - rail - 2):                                # inner rails
        d.rectangle((x, m, x + (0 if native else 1), size - m - 1), fill=(255, 255, 255, 255))
    font = ImageFont.truetype(str(FONT), 11 if native else 22)
    tw = d.textlength(name, font=font)
    d.text((size - m - (6 if native else 22) - tw, m + (3 if native else 14)), name, font=font, fill=(255, 255, 255, 255))
    big = sprite.resize((sprite.width * scale, sprite.height * scale), Image.NEAREST)
    bb = sprite.getbbox()
    feet = (bb[3] if bb else sprite.height) * scale
    x = (size - big.width) // 2
    y = size - (size * 13 // 100) - feet  # feet on the floor band, like the references (y≈87 of 100)
    c.alpha_composite(big, (x, y))
    return c


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sprite")
    ap.add_argument("name")
    ap.add_argument("bg")
    ap.add_argument("out")
    ap.add_argument("--scale", type=int, default=2)
    ap.add_argument("--native", type=int, default=0, help="build a native NxN card at sprite scale 1, then upscale it 4x")
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    s = sticker(Image.open(a.sprite).convert("RGBA"))
    s.save(out / f"{a.name.lower()}_sprite.png")
    if a.native:
        c = card(s, a.name, a.bg, 1, a.native, native=True)
        c.save(out / f"{a.name.lower()}_card_native.png")
        c.resize((c.width * 4, c.height * 4), Image.NEAREST).save(out / f"{a.name.lower()}_card.png")
    else:
        card(s, a.name, a.bg, a.scale).save(out / f"{a.name.lower()}_card.png")
    print("card", out / f"{a.name.lower()}_card.png")


if __name__ == "__main__":
    main()
