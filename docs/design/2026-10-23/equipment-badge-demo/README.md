# Equipment category badge review — 2026-10-23

The centered, protruding badge layout is approved and integrated in
`game/menu/pages/HeroCatPage.gd`. This preserved proposal runner applies temporary
overrides to the real Home scene; use `../equipment-ui-integration/` to inspect
production without overrides. The accepted boots glyph is recorded in
`../boots-badge-staggered/` and installed as
`game/ui/art/equipment_badge_boots.svg`.

The original demo geometry below is preserved. Production subsequently moved the
whole badge 6 logical pixels down/right, leaving a 2-pixel protrusion and retaining
8-pixel inventory edge clearance.

- Same 29%-of-card badge size, cream rim and rarity palette as the current game.
- Badge sits 8 logical pixels above and left of the carton card corner.
- Each category's source texture is cropped to its actual alpha bounds, then
  centered and fitted inside a 24-pixel painted area on a 124-pixel card.
- The inventory has 8-pixel edge clearance so its first badge is never clipped.
  Five columns and left alignment are preserved.
- The original empty-slot symbols, equipment artwork and bottom bar are retained.

`run-preview.ps1` renders native 360×640, 450×800 and 720×1280 previews using an
isolated user profile with saving disabled. `make_review.py` builds the enlarged
four-category contact sheet from the actual native captures. `geometry.json`
records alpha bounds and the glyph/frame center error for visual review.
