"""Exports modular characters as the game's party sprites, with a weapon module per role.

For each party slot it takes the character's side-view frames (the base pack faces
left, so they are mirrored to face right), finds the hand in every frame, draws the
role's weapon there at a per-frame angle, and writes:
  assets/sprites/<slot>.png                 standing pose (portrait, title, feet)
  assets/sprites/anim/<slot>_walk_<0..4>.png  0 = standing pose, 1-4 = run cycle
  assets/sprites/anim/<slot>_attack_<0..3>.png

Usage: python3 tools/charmaker/export_party.py   (after charmaker.py)
"""
import json
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SHEETS = ROOT / "assets/characters/sheets"
SPRITES = ROOT / "assets/sprites"
ANIM = SPRITES / "anim"
DEFS = ROOT / "assets/characters/characters.json"

# party slot -> (character id, weapon)
PARTY = {
    "knight": ("ash_swordsman", "greatsword"),
    "archer": ("forest_hunter", "bow"),
    "cleric": ("dawn_priestess", "mace"),
    "pyro": ("ember_mage", "staff"),
}
SIDE_Y = 88
ATTACK_X = [32, 64, 96, 128]
RUN_X = [176, 208, 240, 272]
CW, CH = 32, 48
# weapon angle per frame in degrees (0 = pointing forward/right, 90 = up)
RUN_ANGLE = 125           # carried up and back over the shoulder
ATTACK_ANGLES = [5, 105, -35, 55]  # thrust, wind-up, cut down, recover
OUTLINE = (12, 8, 10, 255)


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def find_hand(img, skin):
    """The frontmost skin pixel below the head: where the hand is."""
    px = img.load()
    top = next((y for y in range(CH) for x in range(CW) if px[x, y][3]), 0)
    best = None
    for y in range(top + 16, min(CH, top + 26)):  # below the shoulders, so the chin never counts
        for x in range(CW):
            if px[x, y][3] and px[x, y][:3] in skin:
                if best is None or x > best[0]:
                    best = (x, y)
    if best is None:  # hand hidden: hold the weapon at the chest
        xs = [x for y in range(top + 15, top + 19) for x in range(CW) if px[x, y][3]]
        best = (max(xs) if xs else 18, top + 17)
    return best


def line(px, x0, y0, x1, y1, c, w=1):
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(n + 1):
        x = round(x0 + (x1 - x0) * i / n)
        y = round(y0 + (y1 - y0) * i / n)
        for dx in range(w):
            for dy in range(w):
                if 0 <= x + dx < px_size[0] and 0 <= y + dy < px_size[1]:
                    px[x + dx, y + dy] = c


px_size = (CW + 16, CH + 16)


def weapon_layer(kind, hand, angle, frame_kind, fi):
    """Draws one weapon into a padded layer (8 px margin), returns it."""
    layer = Image.new("RGBA", px_size, (0, 0, 0, 0))
    p = layer.load()
    hx, hy = hand[0] + 8, hand[1] + 8
    a = math.radians(angle)
    dx, dy = math.cos(a), -math.sin(a)
    if kind == "greatsword":
        L = 17
        tip = (round(hx + dx * L), round(hy + dy * L))
        line(p, hx - round(dx * 3), hy - round(dy * 3), hx, hy, hexc("#5a3018"), 2)          # grip
        line(p, hx + round(-dy * 3), hy + round(dx * 3), hx - round(-dy * 3), hy - round(dx * 3), hexc("#c89a3a"))  # guard
        line(p, hx + round(dx * 2), hy + round(dy * 2), tip[0], tip[1], hexc("#7a8090"), 2)   # blade
        line(p, hx + round(dx * 3), hy + round(dy * 3), tip[0], tip[1], hexc("#c8ccd8"))      # edge
        for i in (6, 10, 14):                                                                 # ember runes
            p[round(hx + dx * i), round(hy + dy * i)] = hexc("#ff8a2a")
    elif kind == "mace":
        L = 9
        head = (round(hx + dx * L), round(hy + dy * L))
        line(p, hx, hy, head[0], head[1], hexc("#6a4a2a"))
        for ox in (-1, 0, 1):
            for oy in (-1, 0, 1):
                p[head[0] + ox, head[1] + oy] = hexc("#f6d466")
        p[head[0], head[1]] = hexc("#fff6d0")
    elif kind == "staff":
        # held upright beside the body; tilts forward when casting
        tilt = math.radians(90 - (35 if frame_kind == "attack" and fi in (0, 2) else 8))
        tx, ty = math.cos(tilt), -math.sin(tilt)
        top = (round(hx + tx * 15), round(hy + ty * 15))
        line(p, round(hx - tx * 6), round(hy - ty * 6), top[0], top[1], hexc("#4a2e1a"))
        glow = "#ffd27a" if frame_kind == "attack" and fi in (0, 2) else "#ff8a2a"
        for ox in (-1, 0, 1):
            for oy in (-1, 0, 1):
                if abs(ox) + abs(oy) < 2:
                    p[top[0] + ox, top[1] + oy - 1] = hexc(glow)
        p[top[0], top[1] - 1] = hexc("#fff6d8")
    elif kind == "bow":
        # a bow held out in front; drawn back on the attack's first frames
        bx = hx + 2
        pull = 3 if frame_kind == "attack" and fi in (0, 1) else 0
        for t in range(-7, 8):
            x = bx + round(2.2 * math.cos(t / 7 * math.pi / 2))
            p[x, hy + t] = hexc("#8a5a2a")
        line(p, bx - pull, hy - 6, bx - pull, hy + 6, hexc("#e8e0d0"))
        line(p, bx, hy - 7, bx - pull, hy, hexc("#e8e0d0"))
        line(p, bx, hy + 7, bx - pull, hy, hexc("#e8e0d0"))
        if pull:
            line(p, bx - pull - 4, hy, bx + 7, hy, hexc("#c9b48a"))
            p[bx + 7, hy] = hexc("#e8e8f0")
    return outline(layer)


def outline(layer):
    w, h = layer.size
    src = layer.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    o = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3]:
                continue
            for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + ddx, y + ddy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3]:
                    o[x, y] = OUTLINE
                    break
    out.alpha_composite(layer)
    return out


def frame(sheet, x, kind, weapon, skin, fi, angle):
    """One mirrored frame with its weapon, on a padded 48x64 canvas so blades never clip."""
    body = sheet.crop((x, SIDE_Y, x + CW, SIDE_Y + CH)).transpose(Image.FLIP_LEFT_RIGHT)
    hand = find_hand(body, skin)
    canvas = Image.new("RGBA", px_size, (0, 0, 0, 0))
    w = weapon_layer(weapon, hand, angle, kind, fi)
    if weapon in ("greatsword", "staff") and kind == "walk":
        canvas.alpha_composite(w)            # carried behind the body while walking
        canvas.alpha_composite(body, (8, 8))
    else:
        canvas.alpha_composite(body, (8, 8))
        canvas.alpha_composite(w)            # held in front while striking
    return canvas


def main():
    defs = json.loads(DEFS.read_text(encoding="utf-8"))
    chars = {c["id"]: c for c in defs["characters"]}
    ANIM.mkdir(parents=True, exist_ok=True)
    for slot, (cid, weapon) in PARTY.items():
        for old in ANIM.glob(f"{slot}_*.png"):
            old.unlink()
        sheet = Image.open(SHEETS / f"{cid}.png").convert("RGBA")
        skin = {hexc(c)[:3] for c in chars[cid]["skin"]}
        run = [frame(sheet, x, "walk", weapon, skin, i, RUN_ANGLE) for i, x in enumerate(RUN_X)]
        attack = [frame(sheet, x, "attack", weapon, skin, i, ATTACK_ANGLES[i]) for i, x in enumerate(ATTACK_X)]
        stand = run[0]
        # the face for portraits, cut from the bare body so no weapon gets in the way
        body = sheet.crop((RUN_X[0], SIDE_Y, RUN_X[0] + CW, SIDE_Y + CH)).transpose(Image.FLIP_LEFT_RIGHT)
        bb = body.getbbox()
        body.crop((bb[0] + 2, bb[1], bb[0] + 22, bb[1] + 20)).save(SPRITES / f"{slot}_face.png")
        stand.save(SPRITES / f"{slot}.png")
        stand.save(ANIM / f"{slot}_walk_0.png")
        for i, im in enumerate(run):
            im.save(ANIM / f"{slot}_walk_{i + 1}.png")
        for i, im in enumerate(attack):
            im.save(ANIM / f"{slot}_attack_{i}.png")
        print("exported", slot, "<-", cid, weapon)


if __name__ == "__main__":
    main()
