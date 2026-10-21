# Accepted carton navigation

Five cartons on a warm wooden shelf, with two side flaps and Paytone One captions. The earlier teal backboard has been replaced by a shallow pale wood rail, open space, and a brown shelf edge.

Source carton artwork and motion coordinates: `docs/design/2026-10-21/shoebox-nav-demo/art-v3/`. These production SVGs use four times the source raster dimensions while preserving the same viewBox, so they stay sharp at the 720px game resolution. Shop, hero and battle icons use the approved balanced crops from `bottom-nav-options/`. The troop tab uses `troops.svg`: a broad pale-steel shield with a turquoise field, ivory cat crest and selective interior ink. The summon tab uses the approved option A cat portal, copied unchanged from `docs/design/2026-10-21/lobby-feedback-demo/art/summon-portal.svg` to `summon.svg`. Earlier PNGs are preserved for comparison.

Keep mipmaps enabled for the carton/shelf SVGs, troop shield and summon portal, and use linear filtering with mipmaps on the control so reduced mobile sizes do not alias. Captions align their shaped glyph bounds to the front face's vertical center (y79.5); font ascent alone does not center Vietnamese accents consistently. Draw captions from a 52px font cache at the approved 12.5px visible size so enlarged low-resolution glyphs do not blur.

`CartonNav.gd` owns persistent states: press compresses a carton, selection opens its flaps before raising the icon, and leaving lowers the icon before closing. Repeated taps and badge refreshes preserve any running transition.

Closed cartons use a centered 26px icon on the front face and a pale packing-tape strip over the top seam. Opening fades the tape, raises/enlarges the icon to 44px, then reveals the caption as the icon clears the face.

The carton artwork sits 5 reference pixels above its original position so its base rests on the shelf top while leaving the wooden front edge visible. Hit areas stay unchanged.
