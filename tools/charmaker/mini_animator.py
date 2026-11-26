"""Mini animator: one rig of part offsets that gives every 16x16 mini character a
walk cycle and an attack, so a motion designed on one character applies to all.

The rig splits a character into head (above the chin), body, and feet (the bottom two
rows, split into left and right at the feet's centre), then moves the parts per frame.

  walk   (4 frames): feet cross in turn, arms swing against them, the body bobs
  attack (5 frames): wind up with the arm and torso, strike with a slash, follow through, recover

Usage:
  python3 tools/charmaker/mini_animator.py assets/characters/verarc/source/char_09.png
  python3 tools/charmaker/mini_animator.py --all          # every source, palette and mix character
Outputs: assets/characters/verarc/anim/<id>_{walk,attack}_<i>.png and, for single
characters, <id>_preview.gif (8x, both motions looped) and <id>_strip.png.
"""
import argparse
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from mini_mixer import analyse, chin_row  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
VERARC = ROOT / "assets/characters/verarc"
OUT = VERARC / "anim"
CANVAS = (28, 28)     # room to lean and to draw the slash
ORIGIN = (4, 6)       # where the 16x18 character sits on the canvas

# the rig: per frame, offsets in pixels (dx, dy) for each part
# walk, 4 frames: contact (left foot ahead), passing (right foot lifted past it),
# contact (right foot ahead), passing (left foot lifted). Feet cross, arms swing
# against the feet, the body rises a pixel on each passing pose.
WALK = [
    {"head": (0, 0), "torso": (0, 0), "lfoot": (1, 0), "rfoot": (-1, 0), "farm": (-1, 0), "barm": (1, 0)},
    {"head": (0, -1), "torso": (0, -1), "lfoot": (0, 0), "rfoot": (0, -1), "farm": (0, -1), "barm": (0, -1)},
    {"head": (0, 0), "torso": (0, 0), "lfoot": (-1, 0), "rfoot": (1, 0), "farm": (1, 0), "barm": (-1, 0)},
    {"head": (0, -1), "torso": (0, -1), "lfoot": (0, -1), "rfoot": (0, 0), "farm": (0, -1), "barm": (0, -1)},
]
# attack, 5 frames: anticipation, wind-up (front arm raised back, torso and head lean back),
# strike (arm thrown forward, torso twists in, the body sinks a pixel), follow-through, recover.
# "all" moves the whole character; the back arm counter-swings for balance.
ATTACK = [
    {"all": (0, 0), "head": (-1, 0), "torso": (-1, 0), "farm": (-1, -1), "barm": (1, 0), "slash": 0},
    {"all": (-1, 0), "head": (-2, -1), "torso": (-1, 0), "farm": (-2, -3), "barm": (1, 1), "slash": 0},
    {"all": (1, 1), "head": (2, 0), "torso": (1, 0), "farm": (3, 1), "barm": (-1, 0), "slash": 2},
    {"all": (1, 0), "head": (1, 0), "torso": (1, 0), "farm": (2, 2), "barm": (-1, 0), "slash": 1},
    {"all": (0, 0), "head": (0, 0), "torso": (0, 0), "farm": (0, 0), "barm": (0, 0), "slash": 0},
]
SLASH_CORE = (255, 250, 228, 255)
SLASH_EDGE = (255, 214, 120, 255)
SLASH_FADE = (255, 214, 120, 150)


def parts(img):
    """Splits a 16-wide character into head, torso, front and back arm, and the two feet.

    The arms are the body pixels outside the torso core: the core is the collar's width
    around its centre, so sleeves, hands and held items swing with the arms.
    """
    w, h = img.size
    px = img.load()
    rows = [y for y in range(h) if any(px[x, y][3] for x in range(w))]
    top, bottom = rows[0], rows[-1]
    g = analyse(img)
    chin = chin_row(img, g["skin"]) if g["skin"] else None
    if chin is None or not (top + 5 <= chin <= bottom - 3):
        chin = top + (bottom - top) * 10 // 16  # no face found: the pack's usual proportion
    foot_y = bottom - 1
    xs = [x for y in range(foot_y, bottom + 1) for x in range(w) if px[x, y][3]]
    mid = (min(xs) + max(xs) + 1) // 2 if xs else w // 2
    collar = [x for x in range(w) if px[x, chin][3]]
    cx = (min(collar) + max(collar)) // 2 if collar else w // 2
    core_l, core_r = cx - 3, cx + 3

    def cut(box, keep=lambda x, y: True):
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        lp = layer.load()
        x0, y0, x1, y1 = box
        for y in range(y0, y1):
            for x in range(x0, x1):
                if px[x, y][3] and keep(x, y):
                    lp[x, y] = px[x, y]
        return layer
    body = (0, chin, w, foot_y)
    return {
        "head": cut((0, 0, w, chin)),
        "torso": cut(body, lambda x, y: core_l <= x <= core_r),
        "barm": cut(body, lambda x, y: x < core_l),
        "farm": cut(body, lambda x, y: x > core_r),
        "lfoot": cut((0, foot_y, w, h), lambda x, y: x < mid),
        "rfoot": cut((0, foot_y, w, h), lambda x, y: x >= mid),
        "chin": chin, "top": top, "bottom": bottom,
        "right_edge": max(x for y in rows for x in range(w) if px[x, y][3]),
    }


def put(canvas, layer, dx, dy):
    canvas.alpha_composite(layer, (ORIGIN[0] + dx, ORIGIN[1] + dy))


def slash(canvas, p, dx, strength):
    """A crescent of light in front of the character, at shoulder height."""
    if not strength:
        return
    cp = canvas.load()
    cx = ORIGIN[0] + p["right_edge"] + dx + 2
    cy = ORIGIN[1] + p["chin"]
    arc = [(0, -6), (1, -6), (2, -5), (3, -4), (4, -3), (4, -2), (5, -1), (5, 0), (5, 1), (4, 2), (4, 3), (3, 4), (2, 5), (1, 6), (0, 6)]
    for i, (ax, ay) in enumerate(arc):
        x, y = cx + ax, cy + ay
        if 0 <= x < CANVAS[0] and 0 <= y < CANVAS[1]:
            end = i < 2 or i > len(arc) - 3
            cp[x, y] = SLASH_FADE if strength == 1 else (SLASH_EDGE if end else SLASH_CORE)
            if strength == 2 and not end and 0 <= x - 1 < CANVAS[0]:
                cp[x - 1, y] = SLASH_EDGE


def _frame(p, pose, all_dx=0, all_dy=0):
    """Draws one pose: back arm, feet, torso, head, then the front arm over the chest."""
    c = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    for part in ("barm", "lfoot", "rfoot", "torso", "head", "farm"):
        dx, dy = pose.get(part, (0, 0))
        if part in ("lfoot", "rfoot"):
            put(c, p[part], all_dx + dx, dy)  # feet stay planted when the body sinks
        else:
            put(c, p[part], all_dx + dx, all_dy + dy)
    return c


def walk_frames(p):
    return [_frame(p, pose) for pose in WALK]


def attack_frames(p):
    frames = []
    for pose in ATTACK:
        ax, ay = pose["all"]
        c = _frame(p, pose, ax, ay)
        slash(c, p, ax, pose["slash"])
        frames.append(c)
    return frames


def load16(path):
    """Characters are 16x16 (source) or 16x18 (palette and mix): pad to 16x18, feet at the bottom."""
    img = Image.open(path).convert("RGBA")
    if img.height == 18:
        return img
    canvas = Image.new("RGBA", (16, 18), (0, 0, 0, 0))
    canvas.alpha_composite(img, (0, 18 - img.height))
    return canvas


def animate(path, preview=False):
    img = load16(path)
    p = parts(img)
    walk, attack = walk_frames(p), attack_frames(p)
    cid = Path(path).stem
    OUT.mkdir(parents=True, exist_ok=True)
    for i, f in enumerate(walk):
        f.save(OUT / f"{cid}_walk_{i}.png")
    for i, f in enumerate(attack):
        f.save(OUT / f"{cid}_attack_{i}.png")
    if preview:
        scale, bg = 8, (42, 36, 46, 255)
        big = lambda im: Image.alpha_composite(Image.new("RGBA", im.size, bg), im).resize((im.width * scale, im.height * scale), Image.NEAREST)
        seq = walk * 3 + attack + attack[-1:]
        durations = [140] * (len(walk) * 3) + [110, 150, 80, 130, 160, 320]
        imgs = [big(f).convert("P", palette=Image.ADAPTIVE) for f in seq]
        imgs[0].save(OUT / f"{cid}_preview.gif", save_all=True, append_images=imgs[1:], duration=durations, loop=0, disposal=2)
        strip = Image.new("RGBA", (CANVAS[0] * 9 * scale + 8 * 8, CANVAS[1] * scale), bg)
        for i, f in enumerate(walk + attack):
            strip.alpha_composite(big(f), (i * (CANVAS[0] * scale + 8), 0))
        strip.save(OUT / f"{cid}_strip.png")
    return cid


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="*")
    ap.add_argument("--all", action="store_true")
    a = ap.parse_args()
    paths = [Path(p) for p in a.paths]
    if a.all:
        paths = sorted((VERARC / "source").glob("*.png")) + sorted((VERARC / "palette").glob("*.png")) + sorted((VERARC / "mix").glob("*.png"))
    for p in paths:
        animate(p, preview=not a.all)
    print("animated", len(paths))


if __name__ == "__main__":
    main()
