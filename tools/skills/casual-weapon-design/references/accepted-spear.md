# Cat-defender: accepted spear baseline

On 2026-10-20, after the stroke-reference study and one requested weapon sample, the user rated this spear **9/10** and asked to preserve the full project in Git, especially this skill. This is the current approved visual direction for stroke treatment, not approval of the earlier `hero-equipment` or `hero-equipment-v2` proposals.

Open [the included review image](../assets/accepted-spear-review.png): isolated spear, unchanged cat holding it, native-size hero and inventory thumbnails. The [Figma review](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3628-2) is node `3628:2` on page `3539:2`, file `wMtwWaYIiKUchUdq5YdTm5`.

Later hero-equipment display corrections are recorded in [cat-defender.md](cat-defender.md#current-hero-equipment-display-contract): only weapons are visible on the unchanged hero; the other five slots use stat-only icons, and the bow uses the left paw. These corrections do not change this sample's approved stroke treatment or grant approval to the later v4 proposal.

## What to carry forward

- Use a confident warm-brown main contour with broad colored areas inside. The main-line design target is **9 px on a 256 x 240 character canvas**. The selected raster's straight shaft measured **34 source px × 0.24 fitted scale = 8.16 px**, approximately 8.2 px. Generated widths vary locally; this sample is not evidence of exact 9 px everywhere.
- Keep the steel's two broad flat material planes unlined at their shared boundary. A darker filled steel plane is not an interior stroke or a lighting effect.
- Let the muted red-brown leather seams and ochre socket join explain construction with less force than the silhouette. Do not turn them into the outer contour color, outline each color patch, or assign all interiors one gray.
- Resolve a real shared edge once; keep contact/occlusion stronger when it needs to define the primary form. Do not infer thickness merely from whether a line falls inside the object.
- Preserve the cat's face, coat and cape; align the hand and grip and check the small result. The accepted review uses a fitted layer at -24 degrees and native 128 x 120 verification, not just a large isolated icon.

## Generation and cleanup provenance

The selected generation is `32:2` in draft file `2uKzqvXeOSPQqfaow6s7TU`, produced with `gpt-image-2.5-sunburst` via Figma `generate_image`. That run used a text brief informed by viewed references; it did **not** accept the reference pictures as image inputs. The exact successful prompt is [included here](../assets/accepted-spear-prompt.txt). Its source-pixel instructions are prompt guidance for that generation, not measured geometry or reusable universal ratios.

Post-processing removed the uniform white matte and flattened the palette, then fitted the intact generated design onto the cat. It did not dilate outlines, skeletonize boundaries or rebuild the spear from segmented regions. If a future generation lacks broad fills or readable construction, revise the generation rather than manufacturing those forms by global outline processing.

Full reproducibility artifacts in the project are under `docs/design/2026-10-20/spear-stroke-sample/`: `generation.json` (all three attempts and selected node), `raw/`, `processing.json`, `build_review.py`, `processed/`, and `native/` (Godot rendering). Raw selected image: `raw/spear-iteration-3.png`. Clean image: `processed/spear.png`. The sample is still a review asset; production integration is separate.
