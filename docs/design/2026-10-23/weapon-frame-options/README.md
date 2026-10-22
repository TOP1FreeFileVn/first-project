# Weapon-frame proposals

Decision: the user selected A (cardboard tray) and natural palette 1 on 2026-10-23. Palette comparisons are under `colors/`; production integration review is under `integration/`.

Review-only proposals: five different frame constructions beside the current game card. Use the actual approved item PNGs, game font, top-left slot symbol, top-right Lv and upgrade arrow. Keep every art fit identical; the small row represents five118logical-px cards at360px screen width. No production assets or theme are changed.

A is a front-facing cardboard tray with a rarity-coloured insert. B uses a chamfered steel rim with broad corner guards. C is a single flat stock-label silhouette with side notches. D uses four separate cardboard brackets around a broad rarity field. E separates the metadata band from the art through flat material fills. No drop shadow, darker foot, extrusion, gradients, rivets or tiny ornament.

`frames.js` uses the shared Pen paths. `export.mjs` writes the review SVGs; `PreviewFrames.gd/.tscn` renders the same paths in Godot beside unchanged production cards and item art. `preview.png` is the review sheet. Drafts remain here until the user selects a direction.
