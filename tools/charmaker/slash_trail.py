"""Slash trail: draws a crescent afterimage of a sword swing over animation frames.

The trail is a flat effect with no outline (bright edge, blue body, fading tail), drawn in
front of the body but never over the blade itself, so the sword stays readable.

trail(size, centre, a0, a1, r0, r1, width, progress, fade) returns an RGBA layer:
  centre      pivot of the swing (the shoulder), in canvas pixels
  a0 -> a1    start and end angle in degrees, screen space (0 = right, -90 = up, clockwise)
  r0 -> r1    tip radius at the start and the end of the swing
  width       crescent thickness at its widest
  progress    how much of the swing the trail covers (0-1)
  fade        0 = fresh trail, 1 = almost gone (thinner, broken into dashes)
  sx          horizontal stretch: above 1 the arc reaches further forward
"""
import math

from PIL import Image

EDGE = (255, 255, 255, 255)
LIGHT = (196, 238, 255, 255)
MID = (112, 196, 250, 255)
DEEP = (58, 132, 226, 255)


def trail(size, centre, a0, a1, r0, r1, width, progress=1.0, fade=0.0, sx=1.0):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    p = layer.load()
    cx, cy = centre
    steps = 900
    for i in range(int(steps * progress) + 1):
        t = i / steps
        a = math.radians(a0 + (a1 - a0) * t)
        r = r0 + (r1 - r0) * t
        u = t / max(progress, 1e-6)              # 0 at the tail, 1 at the sword
        w = width * math.sin(math.pi * min(1.0, 0.15 + 0.85 * u)) * (1 - 0.6 * fade)
        if u < 0.12:
            w *= u / 0.12                         # thin tail
        if fade > 0 and int(t * 40) % 3 == 0 and fade > 0.4:
            continue                              # broken dashes as it fades
        for k in range(int(w) + 1):
            x = round(cx + math.cos(a) * (r - k) * sx)
            y = round(cy + math.sin(a) * (r - k))
            if not (0 <= x < size[0] and 0 <= y < size[1]):
                continue
            f = k / max(w, 1)
            c = EDGE if k == 0 else LIGHT if f < 0.35 else MID if f < 0.7 else DEEP
            if fade > 0.4 and c in (EDGE, LIGHT):
                c = MID if c == EDGE else c
            p[x, y] = c
    # stretching leaves single-pixel holes: fill any pixel enclosed by trail on 3+ sides
    for _ in range(2):
        holes = []
        for y in range(1, size[1] - 1):
            for x in range(1, size[0] - 1):
                if p[x, y][3] == 0:
                    n = [p[x + 1, y], p[x - 1, y], p[x, y + 1], p[x, y - 1]]
                    filled = [c for c in n if c[3]]
                    if len(filled) >= 3:
                        holes.append((x, y, filled[0]))
        for x, y, c in holes:
            p[x, y] = c
    return layer


def is_blade(c):
    """Steel or blue effect pixels already in the frame: left untouched by the trail."""
    r, g, b, a = c
    return a > 0 and b >= r + 15 and b > 150


def over(frame, layer):
    """Composites the trail in front of the frame, except over the blade."""
    out = frame.copy()
    op, lp = out.load(), layer.load()
    for y in range(out.height):
        for x in range(out.width):
            if lp[x, y][3] and not is_blade(op[x, y]):
                op[x, y] = lp[x, y]
    return out


def speed_lines(size, lines, colour=(232, 244, 255, 255)):
    """Short horizontal streaks behind a lunging body: lines = [(x0, x1, y), ...]."""
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    p = layer.load()
    for x0, x1, y in lines:
        for x in range(x0, x1 + 1):
            if 0 <= x < size[0] and 0 <= y < size[1]:
                p[x, y] = colour
    return layer


def dust(size, x, y, spread=1.0):
    """A small kicked-up dust puff at the feet, fanning backwards (to the left)."""
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    p = layer.load()
    light, shade = (236, 228, 214, 255), (196, 184, 166, 255)
    puffs = [(-3, 0, 2), (-8, -1, 2), (-13, -2, 1), (-6, -4, 1), (-11, -6, 1)]
    for dx, dy, r in puffs:
        cx, cy = x + round(dx * spread), y + round(dy * spread)
        for yy in range(-r, r + 1):
            for xx in range(-r - 1, r + 2):
                if xx * xx / 1.6 + yy * yy <= r * r + 0.5 and 0 <= cx + xx < size[0] and 0 <= cy + yy < size[1]:
                    p[cx + xx, cy + yy] = shade if yy == r else light
    return layer
