# Boots category glyph redraw

Review-only redraw of the small white boots symbol in the rarity badge.
The detailed steel-boots item artwork is retained.

Visual brief: paired short boots with subtly flared cuffs and plump rounded
toes. The rear-left boot is raised; the front-right boot sits slightly lower.
A wide gap separates both silhouettes at native badge size. One 18/256 white
main contour; no secondary seams, cuff ellipses or decorative surface lines
at this tiny symbol size. Badge rim and rarity palette are preserved.

`boots.js` is the shared Canvas/SVG path source. Inspect `round-3.png` before
exporting with `node export.mjs`. Native Hero previews use runtime-only texture
overrides via `../equipment-badge-demo/run-preview.ps1`, with saves disabled.

Round 2 shortens the shafts and broadens the toes. Round 3 centers the actual
painted bounds and loads the original game font before drawing the review sheet.
The exported paths were inspected in native Godot at 360×640, 450×800 and
720×1280. `card_boots.png` is the native card crop; `geometry.json` records zero
glyph/frame center error. Production art has not been replaced.
