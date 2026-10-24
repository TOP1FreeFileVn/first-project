# Silver chest structure upgrade

Redesign the chest itself so the silver tier differs structurally from wood, with a gently arched/chamfered lid, broad steel corner framing, sparse inset fasteners, blue recessed panels and central clasp. Preserve the established flat casual style and bold brown contour.

- Prompt: `prompt.txt`.
- References: existing wood, silver and gold closed chest art under `game/ui/art/chests/strongbox-b/`.
- Untouched generated image: `output/imagegen/silver-chest-2026-10-24/silver-raw.png`.
- Safe generation metadata: `output/imagegen/silver-chest-2026-10-24/silver-generation.json`.
- Generation: existing user-selected 9Router Responses fallback, requested image model `gpt-image-2.5-sunburst`. The response orchestrator model is recorded separately; an image model is only marked as reported when present in the image result.

Reproduce with `powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-24/silver-chest-upgrade/generate.ps1`. This preserves existing output and never serializes credentials.

The shop uses a plain rounded card with a cool pearl/blue backdrop for this tier. Metal framing and fasteners belong to the chest object, rather than its surrounding UI card. The prior silver drawing is retained as `silver-before.png` for comparison.

Production preparation uses `python -B tools/ui/build_strongbox_chests.py --tiers silver`. It preserves the generated RGB and alpha, fits a common seam frame, and extracts a moving lid, fixed body and fixed central clasp. The four aligned runtime textures live in `game/ui/art/chests/strongbox-b/silver/`; the metadata is shared by the shop and the actual opening animation.

Use `--review-dir docs/design/2026-10-24/silver-chest-upgrade/production-review` for a silver-only build to keep the original combined review boards intact. The current manifest records raw crop `[42,196,1210,1067]`, source frame `1168x871`, seam `(583.5,340)`, and a sampled main contour width of 4.694 at author width 208. Wood and gold production textures were not changed.

Native verification passed:

- Shop sections: 421 checks, 18 captures, no failures; [supply cards at 450x800](../../../ui_review/2026-10-24/shop-sections/supply-section-450x800.png).
- All chest tiers: 223 checks, 43 captures, no failures; [silver opening at 450x800](../../../ui_review/2026-10-23/chest-b-integration/actual-open-silver-450x800.png). The lid moves independently while the body and clasp remain fixed.
- Closed layer composition: wood/gold exact; silver maximum RGBA residual `[1,2,2,2]`, with no pixel differing by more than 3. See `docs/design/2026-10-23/chest-b-production/closed-layer-check.json`.
