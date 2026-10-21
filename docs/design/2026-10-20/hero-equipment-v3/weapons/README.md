# Hero equipment v3: weapon-family representatives

Created 2026-10-20 for the authorized hero-equipment redesign. These are new proposal assets; production art and game logic are unchanged.

## Latest bow correction

The user rejected the bow and staff after the first assembled review. For the bow, iteration4 added a crafted recurve shape but failed contour thickness again (only21–26sourcepx). After the parent explicitly authorized manual vector refinement, the bow silhouette and fill proportions were authored together as cubic Beziers in `authored/bow-refined.svg`. It uses9native-pixel main contours, a1.4px functional string and1.8px quieter leather seams. This is authored refinement of the generated design, not a generated image claimed to meet a prompt and not a global outline processing operation.

The current bow review layer is `authored/bow-refined-layer.png` (768×720), rendered by Godot from the SVG. See `authored/bow-refined-review.png` and `authored/authored-processing.json` for provenance, bounds and raster measurement. Earlier generated bow images and the contact sheet below are retained as iteration history.

## Selected generated sources

| Family | Raw source | Figma draft node | Main source measurement | Current context fit |
| --- | --- | --- | --- | --- |
| Melee: sword | raw/sword-iteration-2.png | 42:2 | blade sides49–50px | 8.91px at0.18 |
| Ranged: bow | raw/bow-iteration-3.png | 52:2 | wood arc around45–50px | approximately6.81px at0.145 |
| Magic: staff | raw/staff-iteration-3.png | 50:2 | straight shaft42px | 8.40px at0.20 |

Generation model: `gpt-image-2.5-sunburst` via Figma `generate_image`, in authorized draft file `2uKzqvXeOSPQqfaow6s7TU`. These were text-only generations informed by viewed project references. No image-input conditioning was supplied. Exact prompts, successful tool responses and full1024×1024 PNGs are retained in their named folders.

The final-fit values describe specific measured sections. The model varied width on guards, grip borders, the orb and the bow grip. **They are not proof of an exact9px contour everywhere.** The bow retains a thinner functional string and its current carry pose cannot honestly be described as9px throughout.

## Reproduce / consume

Run `python docs/design/2026-10-20/hero-equipment-v3/weapons/clean_weapons.py`.

- `clean/*-source-clean.png`: full1024² cleaned source, preserving source coordinates.
- `clean/{sword,bow,staff}.png`: cropped/padded isolated preview; use `crop_grip` from `processing.json` if consuming it.
- `clean/*-held-layer.png`: fitted weapon layer at768×720, for a256×240 hero at3× render scale.
- `clean/hero-*-context.png`: unchanged base cat and paw over weapon, to verify positioning.
- `weapon-contact-sheet.png`: isolated objects, cat-held context, native128×120 cat and64px inventory views.

Every current fit uses fixed target paw160,166. Bow mirrors horizontally before scaling so the string sits on the outside of the cheek; this is a carry/ready pose, with no arrow and no attack animation. Staff is tilted22degrees because a40degree fit at this height would extend too far right. Full source grips and bounds are recorded in `processing.json`; all current fits stay inside256×240.

## Cleanup limits

Palette flattening, white matte extraction and antialias coverage recovery only. The generated broad light wood plane on the bow is unified to the wood palette; the thin string stays quieter. No dilation, skeletonization, morphology, region-edge rebuilding or vector replacement. Broad unlined steel planes, material-colored wrap seams and generated contours are preserved.

Earlier attempts are retained as evidence, not selected artwork. The first generations had clean silhouettes but measured too thin at fitted size. Targeted prompt iterations increased the actual contour weight without programmatic thickening.
