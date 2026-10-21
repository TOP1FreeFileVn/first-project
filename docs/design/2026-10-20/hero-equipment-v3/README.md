# Hero equipment v3

Review set: four weapon families (sword, bow, staff, axe), and five fixed wearable slots (helmet, armor, gloves, boots, amulet). Production game files remain untouched.

## Review images

- `hero-equipment-review.png`: complete set, worn poses, 128 × 120 heroes and old/new comparison.
- `tone-plus-10-review.png`: the same revised bow/staff equipment with original and 10% brighter fill values.
- `native-size-review.png`: four unscaled 128 × 120 previews.
- `native/godot-review.png`: engine viewport verification, after running the native fixture.

## Sources and authorship

`raw/`, `prompts/`, `manifests/`, `weapons/`, `gear-details/` and `weapons-heavy/` preserve the GPT Image 2.5 generations, exact prompts and Figma node IDs. Generation was text-only, informed by studied references; the tool did not receive reference images as input.

Helmet, armor, gloves, boots, amulet and sword retain generated contours with palette/alpha cleanup. Bow, staff and axe required deliberate manual vector refinement because their generated contours failed at held scale. Their SVGs revise proportions and linework together; no morphology, dilation or segmented-edge reconstruction is used. The accepted spear is a style reference, not a substitute for the hero's axe family.

Main vector stroke is 9 units on a 256 × 240 canvas. Bowstring is 1.4 units, and surface marks are subordinate and material-colored. Generated contours vary; see processing manifests for actual measurements rather than assuming every pixel is 9 units.

The 10% color treatment multiplies painted sRGB channels by 1.10 and clamps at 255. Warm contour ink stays unchanged. Original tones are preserved in `processed/*-tone-original.png`; the cat face, coat and cape stay unchanged.

## Rebuild

Render `staff-refined.svg` with `native/render_staff.gd` at 3×, then run `build_review.py` with Python, Pillow and NumPy. Bow and axe render helpers live with their source SVGs. Finally run `native/run.ps1` for the isolated Godot texture check.

All worn layers remain registered to 768 × 720, corresponding to 256 × 240 at 3×. Paw sockets are always (94,166) and (160,166). Wearable transforms are identical across poses. These are carry/reference poses, not animation clips or runtime equipment integration.
