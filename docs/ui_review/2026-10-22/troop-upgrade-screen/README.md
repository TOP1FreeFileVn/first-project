# Troop upgrade flow after compact roster cards

Native Godot regression: **230 checks, 20 captures, 0 failures**, at 360×640 and 450×800. The companion `../troops-five-column/` review covers the new collection layout and badge placement.

The production dedicated upgrade screen is exercised through native card taps: level/star spending, insufficient resources, progression caps, locked troops, full-team swap, last-unit protection, long support text, modal layering and Back restoring the roster, filter, scroll and animated hints.

The scroll fixture now selects the final troop in the collection. Sung fits in the visible second row after moving to five columns, so it no longer exercises a scrolled return.

All player state is temporary, with persistence disabled and an isolated profile under `output/troop-card-regression-profile`. `manifest.json` records the canonical results and capture names. Historical 2026-10-21 review artifacts are preserved.
