# Weapon proposal 03 — GPT Image 2.5

**Rejected style / stroke experiment.** The user identified a mismatch with the
cats and supplied the more specific weapon detail reference on Figma page
`3470:2`. The thin original and the blanket thickened version both fail: the
former has incidental fine detail; the latter loses material area and open
spaces. Do not upload these as approved proposals or integrate them. See the
[reference study](../reference-study/README.md) and the updated weapon design
skill before the next design pass. No V3 weapon raster was uploaded to the
requested review page.

Four representative weapons generated with **gpt-image-2.5-sunburst**: sword,
axe, firearm and magic staff. This proposal follows the user's requested switch
from programmatic SVG concept construction to raster image generation, while
matching the existing flat cartoon cats.

The original destination file refused AI generation. The actual generations ran
in the user-authorized draft in Quoc Nguyen's team:
<https://www.figma.com/design/2uKzqvXeOSPQqfaow6s7TU> (nodes `1:2` through `4:2`).
The requested review destination is the existing art page:
<https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3539-2>.

`generation.json` preserves the exact prompts, model and source node IDs.
`raw/` preserves the original 1024 x 1024 raster generations. `processed/`
contains transparent PNGs, reduced-size icons and held-cat review composites.
Processing retains the generated silhouettes; it extracts the white backdrop,
limits material colors and adjusts the outer contour for the cat art. It does
not recreate the weapons as hand-coded SVG geometry.

Review images:

- [Four weapon designs](weapons-gpt-v3.png)
- [Current cats holding the proposal](cats-with-gpt-v3.png)
- [SVG proposal 02 versus GPT proposal 03](v2-vs-gpt.png)
- [Unscaled 48/64 px review](native-size-review.png)

Reproduce image cleanup and boards from the project root:

```powershell
python -B docs/design/2026-10-19/weapon-redesign/v3-ai/prepare_review.py
```

The helper uses Godot's SVG renderer for unchanged, unarmed cat source images,
then composites the generated transparent raster props and front paw. This is
an art review, not a native runtime integration test. Production weapon icons,
troop textures, gameplay and save data are unchanged.

The reusable skill source under `tools/skills/casual-weapon-design/` and its
installed personal copy were updated to retain this approved raster workflow.
