# Staggered boots badge — approved and integrated

Supersedes the rejected round-boot glyph in `../boots-badge-redraw/`. The user
approved round 2 and authorized integration on 2026-10-23.

Reference viewed: the local Figma captures `boots-figma.png` and
`boots-steel-figma.png` in `../../2026-10-20/stroke-reference-study/` (KingEquip,
Boots0111 `3447:7581`, Boots0113 `3447:7587`).

Brief: just two chunky, same-facing boots; rear-left higher and front-right
lower, partly covering the rear. Retain straight short shafts and broad toes.
No buckles, gems, seams or ornate cuffs. One 16/256 white category contour;
the hidden rear edge is omitted. This tiny menu symbol is separate from the
detailed steel equipment artwork. Cream rim and rarity colors are retained.

`boots.js` authors one path list for Canvas and SVG. `round-1.png` records the
Canvas review. Round 2 shortens the shafts, straightens the rear heel and
separates the visible rear contour from the foreground boot to avoid a doubled
white knot. `round-2.png` is the accepted design. `node export.mjs` exports those
same paths after inspection.
The existing isolated `equipment-badge-demo` runner can mount the result as a
temporary override in the actual Hero screen without saving or changing game art.

Native proposal previews were rendered at 360×640, 450×800 and 720×1280. The
proposal card crop is `card_boots.png`.

Production uses the identical exported paths in
`game/ui/art/equipment_badge_boots.svg`, loaded by `HeroCatPage.gd`. Only the tiny
category badge changes; detailed boots and empty-slot symbols are retained.
All category glyphs are cropped to their alpha bounds and fitted at creation to
avoid a stale minimum size shifting them off center. After the approved follow-up
adjustments, badges protrude 2 logical pixels above/left (a total 6-pixel shift
down/right from the original preview), with 8-pixel inventory edge clearance.

The production review in `../equipment-ui-integration/` passed **281 checks and
18 screenshots with 0 failures** at 360×640 and 450×800, including worn, inventory
and comparison cards. Its screenshots show the final integrated layout.
