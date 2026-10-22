# Cardboard gear work tray

The gear board becomes a low open carton work tray, using the battle castle's warm cardboard, cream tape and brown line. Broad folded edges describe its construction without a ramp, cast shadow or a second UI frame. The center stays quiet for gear rarity colors.

`board.js` records one path list for Canvas and SVG. `preview.html` shows 450 px and 360 px arrangements; `export.mjs` writes `game/assets/battle/cardboard-board/board.svg` and its placement manifest.

Place the 720 × 480 SVG at world `(0, 720)`, below the castle facade, board cells, core orb and gears. Its opaque silhouette covers the old board well. The existing 6 × 4 grid remains at world `(60, 760)` with 100 px cells. Cardboard-colored cell faces have 8 px corners. Small registration corners replace the old circular plus; locked-cell locks, special tiles and drag/merge responses stay functional.

The user's follow-up requested the board reach the screen edges. The current export is `battle-cardboard-board-v2-edge-to-edge`: its opaque contour centerline runs from x = 2.3 to 717.7; the 4.6 px main stroke reaches visible x = 0 and 720 without being clipped. Top and bottom registration remain y = 14 and 474. The inner deck remains x = 49–671, y = 28–450; cells, gear positions and hitboxes are unchanged. The associated castle revision removes the two triangular roofs above the central gate.

Visual verification: `round-2-edge-to-edge.png` was inspected at 450 px and 360 px after widening the contour. `round-1.png` and `godot/board.png` retain the earlier inset-board review, rather than being presented as the current edge-to-edge version. The preview's sample cells/core are a composition guide; actual gameplay captures and layer/input checks are recorded in `docs/ui_review/2026-10-22/battle-cardboard-castle/`.

The final native `layers-v3` capture was inspected at 450 × 800 and 360 × 640. The board reaches both edges, the central gate has no triangular roofs, and both outer castle sides keep their contour. Native layer/input checks pass 13/13. The unchanged 450 × 440 gameplay crop is `docs/ui_review/2026-10-22/battle-cardboard-castle/layers-v3-castle-board.png`.
