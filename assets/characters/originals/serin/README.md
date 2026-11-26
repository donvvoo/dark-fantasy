# 세린 (SERIN): original fantasy warrior

An original character, made 2026-11-26 with PixelLab API v2 create-image-pro-flash
(128x128), in a chibi sticker style described in words from references the owner shared
(2.5 heads, black outline plus a white outer outline, chunky hair highlights, big eyes,
3-4 tone cel shading, one oversized signature item). No reference image was given to the
generator and no referenced character's design is used.

Ash-gold ponytail with a crimson ribbon, amber eyes, a small cheek scar, steel light armour
over a crimson tunic, torn crimson cape, and an oversized greatsword with ember runes.

- `serin_vN_raw.png`: generator output
- `serin_vN_sprite.png`: with the white sticker outline (tools/charmaker/name_card.py)
- `serin_vN_card.png`: 400x400 name card

## Reference-matched versions (64 px)

The shared references were measured at native size: each card is 100x100 dots shown 4x
(one shown 10x); the figures stand about 60-64 dots tall with the head (hair top to chin)
about 31-34 dots, half the figure: exactly 2 heads tall, head about 30 dots wide, eyes
6-7 dots tall low on the face, feet on y≈87 of the card.

`serin_64_a_*` and `serin_64_b_*` were generated on a 64x64 canvas to that layout and
measured: 61-62 dots tall, head ratio 0.53. Their heads are a little narrower than the
references' (about 24 vs 30 dots). `*_card_native.png` is the 100x100 card at 1:1;
`*_card.png` is it shown 4x, the references' display size.

## Proportion-matched version (current): `serin_64.png`

Built so the head, face, torso and size match the references' measurements:

1. A 64x64 proportion mannequin (head, face, torso, arms, legs at the measured sizes) was
   the init image for PixelLab pixflux; the front-facing result was re-laid out in code
   (face widened, the side hair thinned, the body stretched to its measured height) and run
   through pixflux once more at init strength 150 to clean it up.
2. The eyes are Serin's own 6x7 design (amber ramp, one large and one small highlight),
   pasted at the measured spot: the same size, spacing and height on the face as the
   references' eyes, none of their pixels.
3. A greatsword with ember runes, drawn in code behind her, gripped at her right hand.

| measure (dots) | references | serin_64 |
|---|---|---|
| figure height | 60-64 | 62 (63 with the sword tip) |
| head, hair top to chin | 31-34 | 35 |
| head width | 33-34 | 34 |
| face width | ~24 | 22 |
| eyes | 6 x 7, 8 apart | 6 x 7, 8 apart |
| torso | ~14 tall, 16-18 wide | 14 tall, 15-17 wide |
| legs and boots | ~16 | 12 |

`serin_card.png` is the 100x100 native card shown 4x; `serin_vs_reference.png` puts it
beside the references at the same scale.

## v4: style-matched (`serin_v4_[a-d]_*`)

Feedback on serin_64: wrong facing (front instead of three-quarter right), harsher and
muddier shading, a different feel. v4 re-learns the rendering:

- PixelLab v2 `create-image-pro-flash` (a, b) and `generate-with-style-v2` (c, d) at 64x64,
  with reference figures as *style* images and `color_palette` copying **off**, so only the
  outline, detail level and shading carry over; Serin's own 28-colour palette is forced with
  `target_palette`. (A v1 bitforge style transfer copied the references' hair colours and
  costumes even at low strength, so it was dropped.)
- Prompt carries the measured traits: 2 heads tall, three-quarter view to the right, pale
  skin with pink blush, big glossy eyes, soft hair gradients, an oversized weapon held
  diagonally across the front of the body (as in the LEONHARDT reference).
- Heights: a 55, b 63, c 64, d 64 dots (references 60-64).

## v5: greatsword on her back (`serin_v5_[a-g]_*`)

Same style learning as v4 (reference figures as style images, colour copying off, Serin's
palette forced), with the greatsword strapped across her back: hilt with the blue gem over
the shoulder, blade tip beside the legs. a-d: create-image-pro-flash (styles from three
references), e-g: generate-with-style-v2 (three references at once). All 63-64 dots tall.
`serin_v5_sheet.png` compares them with a reference at the same scale. `motion_spec.md`
holds the motion plan learned from the owner's animation sheet.
