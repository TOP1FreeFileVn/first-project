# Troop cards: full rarity color, earned stars, and locked silhouettes

Implemented in production `game/menu/pages/TroopsPage.gd` and the focused generated SVG skin assets.

- Removed the cream card face below the portrait and the cream backing on level/state markers. The card and portrait now share the rarity color.
- Added `icon_troop_star` assets: a flat, softly rounded gold star with the same warm brown outline as the cats. Card and detail rows display exactly the troop's earned star count, centered, without empty placeholders.
- Changed the star-up readiness marker to an upward arrow so readiness does not look like an additional earned star.
- Locked troops use their existing sprite alpha as a pure black silhouette, including any attached crown. A separate light `?` is centered over it. The collection omits the padlock, locked caption, level, and stars. Names and rarity colors remain visible; detail explains how to unlock.
- Kept the current menu background and four-column layout.

Validation: isolated native Godot MCP runs at 720 × 1280 and 360 × 640 each passed 395 checks with zero failures, including real card taps, wheel scrolling, closing both detail states, and an actual star-up click that spends the correct cards and immediately refreshes both roster and popup star rows. Eight native screenshots were captured and the collection, scrolled state, and locked detail were visually inspected. All fixtures have persistence disabled. Existing Windows certificate-store warnings are unrelated.

`card-overview.png` is a contact sheet cropped from the runtime captures; the 1/2/3 star states and two locked rarities are shown together. Full captures and machine-readable manifests are in this folder. Re-run with `node tools/review/mcp_ui_review.mjs docs/ui_review/2026-10-19/troops-flat-cards/capture-plan.json`, then `python docs/ui_review/2026-10-19/troops-flat-cards/build_overview.py`.
