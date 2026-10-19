# Weapon set — 15 new illustrations + approved sword

Review artwork for the existing 16-soldier roster. Production `game/ui/skin`
artwork and gameplay data are unchanged.

## Art direction

- Match the accepted V6 sword and existing cats: warm brown `#583f21`, flat
  steel planes, honey brass, warm wood, selective turquoise/purple/coral.
- Main held outline: **9 px on the 256 × 240 unit canvas**, equivalent to
  4.5 px at native 128 × 120. Thin structural strings are subordinate;
  the bowstring is **1.5 unit px**.
- Keep every cat's face, coat, outfit, rarity and identity. Fit each prop to
  its own measured grip. Keep eyes and mouth clear.
- The user's follow-up reduces the bend in `dao` and `katana`. The original
  generated blade cross-sections are moved onto a gentler centerline;
  the original raw files, guard and grip remain intact.

## Deliverables

- `weapon-set-review.png`: complete labeled set, enlarged and native views.
- `processed/<id>-cropped.png`: isolated transparent artwork.
- `processed/unit_<id>.png`: transparent cat-held artwork, 768 × 720 (3×).
- `processed/unit_<id>_128.png`: 128 × 120 preview.
- `processed/icon_w_<id>_{32,48,64,96}.png`: native icon sizes.
- `processed/<id>.json`: per-item scale, angle, grip and bounds.
- `native/`: disposable Godot rendering/compatibility review.
- `independent-qa.json`: independent face/edge/native verification.

## Source and generation

The new illustrations were generated with **GPT Image 2.5** through the
explicitly authorized Figma `generate_image` route, model
`gpt-image-2.5-sunburst`, in draft file `2uKzqvXeOSPQqfaow6s7TU`.
This was not a CLI or built-in `image_gen` run. This route accepts text
prompts, so the references informed the written brief; they were not
direct image-conditioning inputs.

- `raw/`: untouched generation PNGs (plus retained greatsword iteration).
- `prompts/<id>.txt`: exact final prompt for each new weapon.
- `manifests/<id>.json`: generation file/node/model provenance.
- `sources/`: unchanged native cat geometry with the approved 9 px outline,
  rendered by Godot at 3×. No code-generated weapon substitutes are used.
- The accepted sword is copied from `../weapon-redesign/v6-nine-px`.

## Contour cues

| Family | Items | Distinguishing shapes |
| --- | --- | --- |
| Infantry | sword, axe, dao, katana | broad straight point, deep axe beard, broad dao belly, slim lightly swept blade |
| Ranged | bow, crossbow, gun, cannon | open bow arc, horizontal bow limbs, flared muzzle, squat barrel and wheels |
| Magic | staff, potion, tome, wand | orb cradle, round flask, open blank pages, five-point star |
| Heavy | spear, greatsword, mace, hammer | leaf point, wide chamfered slab, flanged head, horizontal hammer block |

## Rebuild

Run from the repository root:

```powershell
python -u -X utf8 -B docs/design/2026-10-19/weapon-rollout/build_review.py
```

The builder cleans white backgrounds and holes, flattens material fields,
normalizes the main contour with fractional Euclidean-radius coverage,
preserves lighter strings, and composes individual poses. The fixed raw
artwork, exact prompts and measured source grips stay available for revision.

Figma review links and asset node IDs are recorded in `figma.json` once
uploaded. Labels/layout are editable; each illustration remains a separate
transparent PNG.
