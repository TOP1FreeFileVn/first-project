# Cat lower-foot separation for Figma / Spine preparation

Review assets only. Production game sprites are unchanged. The new vectors
are repartitioned from existing native SVGs, not generated or redrawn cats.

Editable Figma board: [Mèo · Tách chân cho Spine](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3636-2).
Use the `02 · Layer để rig` frames. Their named attachment frames share the
256 × 240 canvas and have transparent PNG exports configured at 3×. The source
pose is preserved separately above each rig; the bottom row is inspection only.
`figma.json` records the exact rig and attachment node IDs. `figma-preview.png`
is the verified Figma board render; all artwork on the board is vector, with no
image-filled layers.

## Assets

- `svg/{cat_cream,cat_tabby,cat_grey,cat_calico,cat_hero,hero_neutral_9px}/`
- Each folder has independent `foot_L_image.svg`, `foot_R_image.svg`, `body.svg`,
  `head.svg`, `paw_L_image.svg`, `paw_R_image.svg` and `tail.svg`.
- Hero folders also retain `back_accessories.svg` (cape and, for legacy hero,
  the original slung sword). Neutral hero retains the approved 9 px outline;
  the other five retain their production 12 px body outlines.
- `assembled.svg` preserves the source pose; `exploded.svg` shows the feet
  apart for inspection. `overlap-test.svg` tests modest foot rotation/lift.
- Corresponding transparent 768 × 720 PNGs are in `png/` (3× render scale).
- `review.png` compares source, new assembly and separated feet for all six cats.
- `manifest.json` records source hashes, layer order and proposed pivots.
- `attachment-bounds.json` gives measured alpha bounds in source and render pixels.
- `qa.json` measures the source/assembly image difference.

## Attachment rules

Every SVG uses the same logical **256 × 240** canvas. Keep this alignment when
importing into Figma or exporting transparent PNGs. `L_image` / `R_image` mean
the left/right of the image, avoiding anatomical naming ambiguity.

The two actual lower feet are filled vectors with hidden upper overlap extending
to y184. Their original visible outline starts around y204. Proposed pivots are
(82,203) and (174,203). The torso retains the central lower-belly notch. Neither
the top of the foot nor the torso cut gets a new cross-belly outline.

The two C-shaped strokes at chest height are the original **front paws**, named
`paw_L_image` and `paw_R_image`. They are not the newly separated lower feet.
They remain strokes rather than complete filled arm attachments.

`head` includes ears, markings, eyes and mouth; this task does not subdivide a
facial rig. This package is preparation for Spine, **not a Spine skeleton,
weights or finished walk animation**. Motion tests use about 10° rotation and a
4 px lift. A larger stride or leg deformation needs additional pose work.

## Verification

Godot's CPU SVG renderer rendered sources and outputs at 3×. All six assembled
poses preserve the count of pixels with alpha >127 exactly. Differences above
8/255 affect 20–88 pixels out of roughly 356k–404k visible pixels (at most 0.025%).
These small differences occur around partition antialiasing and joined strokes.
Colours, face, coat patches and source outline widths are retained.

Visual review confirmed the assembled pose matches the source and the modest
motion test has no transparent inner-belly wedge after adding hidden fill overlap.

## Rebuild

From the repository root:

```powershell
python docs/design/2026-10-20/cat-spine-parts/build_parts.py
$renderProcess = Start-Process -FilePath 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe' -ArgumentList @('--headless','--path','docs/design/2026-10-20/cat-spine-parts/renderer','--script','render.gd') -WindowStyle Hidden -Wait -PassThru
python docs/design/2026-10-20/cat-spine-parts/qa_review.py
```

The isolated renderer does not launch the game or change saved player data.
Use a waiting process invocation on Windows so review generation starts after
all SVG renders finish.
