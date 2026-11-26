# Elf archer girl

**Chosen: `elf_c.png`** (72x72 raw `elf_c_raw.png`; 74x74 with the white sticker outline, transparent).

Serin B's rendering style (style image, colour copying off) with her own palette: long golden
blonde hair in a side braid, long pointed elf ears, emerald eyes, a leaf hair clip, a green
hooded short cloak with gold trim, brown leather bracers and boots, a quiver on her back and a
wooden longbow held upright at her side. a-c golden blonde, d-f silver-mint alternative.

Edit on c: the boots touched the canvas bottom, so the canvas was widened to 72x72 and only
the bottom strip inpainted to finish the soles (pixels above it unchanged).

Motions in `anim/`, 4 frames each:
- walk4 (60x74): face-locked walk.
- shoot (130x73): nock and aim, full two-handed draw (bow arm out, string pulled to the cheek;
  the pose made with edit-image-pro-flash), release (the V string erased and redrawn straight,
  the drawing hand open behind, a flash at the string and the arrow flying), follow-through
  (arrow far ahead). The release image's palette was mapped back to the base palette and its
  face locked, so the skin tone matches the other frames. Arrows, streaks and the flash are
  drawn in code (tools/charmaker/slash_trail.py).
