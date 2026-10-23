# Courtyard props matching the cardboard castle

Five prop designs now share the castle's closed flat colors, warm brown contour,
single broad shadow plane and sparse structural detail. No image API was used:
these are editable SVG production assets.

- Cat house/tunnel: pink ear panels, broad paper tape, no projecting side plane.
- Resting tray: broad folded cardboard walls and a plain floor.
- Scratching post: cardboard base/cap, simplified rope grooves, teal fish toy.
- Yarn ball: one orange fill, one shadow shape and four broad strand lines.
- Cushion: teal fill, one lower shadow band and a few broad creases.

The main outline resolves to approximately 6px and structural details to 3px in
the 720px logical scene, matching the castle. Material colors retain their identity.
Cat art, position, scale, front-facing poses and routes are unchanged. House and
tray keep rear/interior/cat/front layering and an open floor for entry and exit.

Three formerly baked props were removed from a new terrain derivative using
explicit masks. Original terrain is preserved, pixels outside masks remain exact,
and the existing castle contact shadow is retained. Static props now have their
own SVG and foot depth sorting.

Production assets: `game/assets/lobby/cardboard/{tunnel,bed,props}/`.
Builder for the three standalone props and terrain derivative:
`tools/ui/restyle_lobby_props.py`. Palette, anchors and hashes are in
`game/assets/lobby/cardboard/props/manifest.json`.

Native Home review screenshots and entry/exit captures:
`docs/ui_review/2026-10-23/courtyard-props-style/`.
