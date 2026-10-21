# Equipment icon orientation and fitting

Applied to the real hero's five weapon icons and five stat-only equipment icons,
with 32/48/64/96/256 variants. No rings were added. Accepted colors, outlines,
internal strokes, silhouette and weapon bends are retained.

Inventory icons point from bottom-left to top-right at 45 degrees. Helmet and
armor keep their authored upright pose. The main direction follows the working
axis: sword/staff/axe shaft, bowstring attachments, glove cuff to fingers, boot
sole heel to toe, or amulet body to hanging loop. Explicit source anchors and
their references are stored in `game/ui/art/equipment-sources.json`. Alpha PCA
is reported separately: asymmetric heads, thumbs and shoe uppers shift mass and
must not dictate the functional direction. Integer sampling can move a measured
32px line by less than one degree; the source-space rigid rotation targets
exactly -45 degrees in screen coordinates.

Each size is independently sampled from the same oriented high-resolution
accepted artwork. All nonzero alpha pixels stay inside an 8% inset on every
side, rounded up to whole pixels. Painted alpha bounds are centered with at
most one pixel rounding difference. Root UI uses a .78-card artwork square at
(.11,.22) to leave clear space for the header and badges. Held hero and soldier
sprites remain byte-identical; icon rotations never change the held poses.

Reproduce the icon update:

```powershell
python -B tools/ui/install_equipment_art.py --icons-only
python -B docs/design/2026-10-21/equipment-icon-fit/review.py
python -B docs/design/2026-10-21/equipment-icon-fit/verify_regeneration.py
```

- `before-sheet.png` and `after-sheet.png`: all ten families, large inspection
  images plus exact 32/48/64/96px thumbnails. The mint line is the functional
  direction, and the box marks the transparent safety inset.
- `baseline-hashes.json` and `before/`: pre-edit evidence; baseline is never
  overwritten by the review script.
- `geometry-and-preservation.json`: all-alpha bounds, centroids, functional
  direction, independent PCA and preservation checks.
- `regeneration-check.json`: repeat icon install idempotence, full installer
  reproduction in a temporary workspace folder, and held/soldier hashes.

The full installer can still reproduce every override. `--icons-only` preserves
all unrelated PNGs and provenance records without regenerating held artwork.
