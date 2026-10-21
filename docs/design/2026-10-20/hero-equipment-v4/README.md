# Hero equipment v4 — weapon-only appearance

Latest user correction on 2026-10-20: weapons are visibly held; the other five equipment slots only add stats and have inventory/upgrade icons. The bow belongs in the image-left paw, while sword/staff/axe use the image-right paw. `game/core/HeroCat.gd` already separates weapon style/skills from the five stat slots; no new balancing or runtime behavior was introduced.

## Review

- `pose-fix-review.png`: left bow and right staff, large and 128 × 120.
- `hero-equipment-review.png`: four weapon poses and five stat-only item icons.
- `native-size-review.png`: unscaled hero strip.
- `native/godot-review.png`: Godot viewport capture; `native/review-status.json` records the check.

The ginger body, face, ears and blue cape are the original unarmored template. Helmet, armor, gloves, boots and amulet are never composited onto these heroes. Their brighter icons are reused from v3. All previews retain the requested 10 percent brighter weapon colors exactly once.

## Pose and connection fixes

The bow alone is mirrored about x127: `x_new = 254 - x`. This maps its grip (160,166) exactly to (94,166), without flipping the cat or cape. `bow/processing.json` records the bow-specific provenance.

The staff's real leather centre (0,8) now maps to the right paw (160,166), at a 44-degree carry angle. Crystal, brass socket and shaft all share local x0 and rotate together. The independently upright crystal was rejected because its attachment joined at the side; the final SVG has no independent crown rotation. The shaft, leather and butt use one continuous exterior with unlined material fills, avoiding a dark stack of closed borders.

The original paws are only open C-shaped ink paths. A small rounded patch of the original ginger fur closes the holding palm over the grip, then the unchanged C contour draws above it. No equipment glove or cuff is added. This also removes the white patch that read as a glove when base chest pixels were restored.

See `processing.json` for exact sockets, transforms, component axis, palm bounds, weapon bounds and color provenance. Main vector contours remain9 units on256 ×240. The bowstring now uses an actual **3 px secondary stroke**, replacing the nearly invisible1.4px string. Secondary brown is `#8a6240` in the original-tone SVG and `#986c46` after the single10% paint brightening; it stays subordinate to the main9px contour. These are carry/reference poses for design review, not attack animation clips or production integration.

## Rebuild

Render `staff/staff-right.svg` using `native/render_staff.gd` and `bow/bow-left.svg` using `native/render_bow.gd` at3×. Run `bow/build_bow_left.py` to apply the bow's single brightness pass, then `build_review.py` with Python/Pillow/NumPy. Run `native/run.ps1` for the isolated Godot texture/viewport check. The native helper uses child-only profile directories inside this versioned folder.
