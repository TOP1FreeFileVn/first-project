# Cat chest stroke pilot

One proposal for review, not production integration. The visual thesis is a soft, wide wooden travel chest with a low bevelled lid, brass corner shoes and one cat-head latch. Its squared body and restrained corner hardware replace the production puffed dome and paired straps.

The natural authoring origin is the centre of the rear seam. Lid and brass caps move together; body and latch remain fixed. The open sample uses one rotation and lift, not a mechanically fixed hinge, and keeps an explicit cavity behind the front edge.

Stroke hierarchy is authored before export: 9 px warm brown `#583f21` for silhouette, the cat-head latch and primary lid/front overlap on the 256 px board. Material-related secondary lines are 3 px wood brown / ochre brass. This is an item-specific choice. Broad board regions and brass fills do not receive their own closed outlines. Shared seam is drawn once. No gradients, shine or cast shadow.

`chest.js` records the paths once through the shared Pen engine; `preview.html` renders the canvas and `export.mjs` serializes identical paths to SVG. Symbols below 48 px omit wood grain, rivets and subordinate brass joins, while preserving latch and silhouette.

Review at 256, 128, 96 (shop), 64 and 26 px (reward symbol). Production opening uses a 250 px chest in a 720 px design viewport, about 125 px on a 360 px phone. Shop stages are 188/200 design px, about 94/100 px on the phone. Compare those practical sizes, not only the enlarged board.

Rebuild: `node docs/design/2026-10-22/chest-stroke-pilot/export.mjs`; use the existing canvas-vector-art `snap.ps1` and `godot_render.ps1` against this folder.

## Review and verification

- `round-1.png`: first canvas review; the lifted lid was clipped at the top. Corrected framing only, keeping geometry unchanged.
- `round-2.png`: final canvas board, closed/open plus unchanged cat and actual 128/96/64/26 px canvases. No lid clipping.
- `compare.png`: production chest versus the proposed silhouette at equal displayed width, plus the separate opened state and actual-size native thumbnails.
- `current-production-crop.png`: crop of the wood AFTER example in `docs/design/2026-10-21/chest-redesign/before-after-native.png`, used as the current art reference.
- `svg/`: five closed symbol sizes and one open 256 px SVG, all exported from the canvas path list.
- `godot/`: all six SVGs successfully rendered through `tools/ui/render_svg_png.gd`; 256 px open and 64 px closed inspected directly and agree with the authored paths.

At 26 px the latch and chunky silhouette remain the message; secondary construction is intentionally omitted. At 64 px the material marks are quiet but the main contour stays distinct. This proposal changes no live game assets, economy, opening timings or scene code.
