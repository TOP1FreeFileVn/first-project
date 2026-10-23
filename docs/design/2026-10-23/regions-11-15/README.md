# Regional art — stages 11–15

Five new regional panoramas and matching battlefield ground illustrations:
Bến Cảng, Rừng Sương, Đồi Cừu, Mỏ Vàng and Cầu Đá.

Generated individually with GPT Image 2.5 Sunburst through the previously selected
local 9Router API fallback. References: the approved meadow panorama, orange cat
hero, and ground-only pilot. Each battlefield also references its matching panorama.
The generator supplied only scenery: labels and border remain composed separately.

- `review-sheet.png`: all five title/ground pairs, with separately overlaid title proofs.
- `prompts.json`: the complete prompt set for both image types.
- `sources.json`: source files retained under `output/imagegen/`.
- Production panoramas: `game/assets/lobby/map-titles/11-ben-cang.png` through `15-cau-da.png`.
- Production ground: `game/assets/battle/regions/11-ben-cang.png` through `15-cau-da.png`.

Panoramas use the existing 476×90 crop, radius 10, 3px brown (#583f21) inside
outline and no shadow. Ground art is 720×740 with an open playable center and
cropped props at the side margins. The castle, flags, troops and gear table remain
separate runtime layers. Original AI renders are retained without modification.
