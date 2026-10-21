# Left-hand bow with a visible secondary string

User correction: the bow belongs in the left paw; weapons are held, while the other five gear pieces only contribute stats and should not be worn on the cat in this review.

`bow-left.svg` retains the v3 authored bow shape, with only its string changed to a visible **3 px secondary stroke** (`#8a6240`), subordinate to the main9px contour. The previous1.4px string was nearly invisible at128 ×120. The string is drawn first so its ends remain behind the tip sockets. Surface seams retain1.8px; this does not impose3px on every internal detail.

The SVG wraps the weapon in `translate(254 0) scale(-1 1)`, mapping the old right grip160,166 to the left grip94,166. The string's centre is x32, spanning y97–231. The cat and cape are never mirrored. Render with `native/render_bow.gd` at3×, then run `build_bow_left.py` to apply the1.10 paint brightening once while preserving the main brown ink. The resulting secondary string is `#986c46`.

Compose in this order:

1. Original `hero-base.png` with original body/head/ears/cape.
2. `bow-left-weapon-layer.png`.
3. Small rounded ginger-fur palm fill, masking the grip inside the open C-shaped paw without a glove or cuff.
4. Original `hero-paws.png`, copied as `original-paws-occlusion.png` for convenience.

`bow-left-original-paw-occlusion.png` is only the unchanged left native hook stroke. It is supplied if the final composition already draws the neutral right paw separately. It is not a replacement glove, filled mitten or new pose; the cat is never mirrored. Do not add both versions of the left stroke twice.

The left bow stays inside native bounds24.333,87.667,110.667,238.333, with no clipping. Full768×720 and native128×120 bare-cat contexts and a review sheet have been opened visually. Both eyes and mouth remain clear.

Reproduce by rendering `bow-left.svg`, running `bow/build_bow_left.py`, then the root `build_review.py`. `processing.json` records the authored source hashes, string weight/color/axis, grip and bounds. The V3 originals and production art are unchanged. These remain proposed carry poses, not production integration or attack animations.
