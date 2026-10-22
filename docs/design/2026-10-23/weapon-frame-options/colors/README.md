# A frame: palette review

The user selected the A cardboard-tray construction and natural palette 1 on 2026-10-23. These three comparison palettes reuse A's exact paths, stroke, item art, fitting, labels and upgrade arrow. The natural palette is now integrated through the dedicated `CardEquipment*` styles; see `../integration/` for the production review.

`natural` is recommended: unchanged warm carton with slightly brighter rarity inserts. `vivid` has stronger chroma; `soft` uses gentler paper-like fills. All retain the existing green / blue / purple / orange rarity mapping and the shared brown `#583F21` outline. No shadows, gradients or additional contours.

`palettes.json` is the color source. Run `node docs/design/2026-10-23/weapon-frame-options/colors/export.mjs` to write the twelve SVGs. `PreviewColors.tscn` renders these with real production cards and game font into `preview.png`. The small rows show the five-card inventory scale at a 360-pixel viewport.
