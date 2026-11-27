# Animation frames

## Party (knight, archer, cleric, pyro), 2026-11-27

The party is four original chibi characters made in this project with the PixelLab API
(v2 create-image-pro-flash, style taken from the project's own Serin B sprite, own palettes),
animated with v2 `animate-with-text-v3` and `edit-image-pro-flash`, then finished in code:

| slot | character | source folder |
|---|---|---|
| knight | K, human swordsman (greatsword on his back) | assets/characters/originals/warrior |
| pyro | F, human mage girl | assets/characters/originals/mage |
| archer | c, elf archer girl | assets/characters/originals/elf |
| cleric | b, human priestess | assets/characters/originals/priest |

Per slot: `<slot>_walk_0` is the standing pose and `_walk_1..4` the walk loop; `_attack_0..3`
the attack (K forward slash with a trail, F staff cast with a sparkle, c two-handed bow shot,
b holy light). Faces are locked to the standing sprite (tools/charmaker/face_lock.py);
trails, arrows, sparkles and beams are drawn by tools/charmaker/slash_trail.py. All frames
of one slot share one canvas, centred on the body, feet on the standing pose's bottom row, so
the character never jumps between motions; drawn 1:1 in game. Outlines are cleaned to a
single dark outline (no white sticker outline in game).

## Enemies

Every other `<name>_<walk|attack>_<i>.png` here was made with the PixelLab API v2
`animate-with-text-v3` (2026-11-24), taking the matching sprite in `assets/sprites/`
(itself an original PixelLab Pro Flash design) as the first frame. Frame 0 repeats
the source pose; walk cycles loop frames 1-8, attacks play 0-8 once.
