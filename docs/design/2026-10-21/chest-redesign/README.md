# Chest art redesign, 2026-10-21

The production chest now uses a wide, low body with softly rounded corners, a
puffed lid, two broad straps and one paw-shaped lock emblem. The old square
corners, repeated rivets and heavy black inset lines have been removed. Wood,
blue/silver and coral/gold retain their existing gameplay tier identities.

The main contour uses the accepted cat/weapon warm brown `#583f21`. Surface seams
use the local wood or metal color family; large paint areas stay open. Fine
grain and strap accents are omitted below 48 px. This is authored native vector
art so the existing lid flight and squash animation remain live.

`ChestArtBefore.gd` preserves the pre-redesign drawing solely for comparison.
Run `res://tests/ui_review/ChestArtRedesign.tscn` with a real rendering driver and
workspace-isolated APPDATA/LOCALAPPDATA. It writes an equal-width before/after
board, native 26/56/94/250 px views, an opening-state board, actual Shop 104 px
control crops and actual ChestOpening wait/open/card screenshots. PlayerData
persistence stays disabled. `manifest.json` records the render results.

Shop, wait, lid-flight and card states are rendered independently at both
720×1280 and 360×640. Shop control crops preserve their native 104 px / 52 px
output sizes; these are actual runtime crops rather than scaled presentation art.

The production `style_for` and `draw` signatures and the horizontal y=0 seam
are unchanged. The lid and all of its decoration move together; the front wall,
mouth and lock remain fixed. No economy or loot rules changed.

Final verification: **37 checks, 10 native captures, 0 failures**. Both actual
opening captures include the production vector sparkle/dust effects added with
this redraw. The independent visual review also checked the open lock's padding
and the lid's complete registration.
