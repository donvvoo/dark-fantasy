"""Face lock: keeps a character's face and eyes pixel-identical across generated animation frames.

Generated frames tend to smear the small face (eyes melt, the mouth changes). For each frame
this finds how far the head moved from the base sprite (best match of the head region over a
small shift range) and pastes the base sprite's face box back at that shift.

Usage: python3 tools/charmaker/face_lock.py <base.png> <face x0,y0,x1,y1> <head x0,y0,x1,y1> <frame.png>... --out DIR [--reach 3] [--keep-blade]
Example: face_lock.py serin_v5_b_raw.png 20,20,45,34 10,2,50,34 walk_*.png --out anim/locked
"""
import argparse
from pathlib import Path

from PIL import Image


def box(s):
    return tuple(int(v) for v in s.split(","))


def diff(base, frame, head, dx, dy):
    """Mean colour distance between the base head region and the frame region shifted by dx, dy."""
    bp, fp = base.load(), frame.load()
    w, h = frame.size
    tot = n = 0
    for y in range(head[1], head[3]):
        for x in range(head[0], head[2]):
            fx, fy = x + dx, y + dy
            if not (0 <= fx < w and 0 <= fy < h):
                continue
            a, b = bp[x, y], fp[fx, fy]
            if a[3] == 0 and b[3] == 0:
                continue
            tot += sum(abs(a[i] - b[i]) for i in range(3)) + (0 if (a[3] > 0) == (b[3] > 0) else 300)
            n += 1
    return tot / max(n, 1)


def is_blade(c):
    """Blue steel or a blue effect: kept when it passes in front of the face."""
    return c[3] > 0 and c[2] > c[0] + 20


def lock(base, frame, face, head, reach=3, keep_blade=False):
    """Returns the frame with the base face pasted at the head's shift, and that shift.

    keep_blade leaves the frame's blue blade pixels in place where a weapon crosses the face.
    """
    best = min(((diff(base, frame, head, dx, dy), dx, dy) for dx in range(-reach, reach + 1) for dy in range(-reach, reach + 1)))
    _, dx, dy = best
    out = frame.copy()
    bp, op = base.load(), out.load()
    for y in range(face[1], face[3]):
        for x in range(face[0], face[2]):
            tx, ty = x + dx, y + dy
            if 0 <= tx < out.width and 0 <= ty < out.height and not (keep_blade and is_blade(op[tx, ty])):
                op[tx, ty] = bp[x, y]
    return out, (dx, dy)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("base")
    ap.add_argument("face")
    ap.add_argument("head")
    ap.add_argument("frames", nargs="+")
    ap.add_argument("--out", required=True)
    ap.add_argument("--reach", type=int, default=3, help="largest head shift searched, in pixels")
    ap.add_argument("--keep-blade", action="store_true", help="keep blue weapon pixels that cross the face")
    a = ap.parse_args()
    base = Image.open(a.base).convert("RGBA")
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    for f in a.frames:
        im, shift = lock(base, Image.open(f).convert("RGBA"), box(a.face), box(a.head), a.reach, a.keep_blade)
        im.save(out / Path(f).name)
        print(Path(f).name, "head shift", shift)


if __name__ == "__main__":
    main()
