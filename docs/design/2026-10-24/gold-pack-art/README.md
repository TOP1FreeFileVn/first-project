# Gold shop illustrations

Six separately generated gold illustrations reuse the approved gem-pack concepts in the same order. The only subject change is replacing purple diamonds with bright yellow gold coins carrying the game's simple gear stamp. Containers and their composition remain paired with the gem set: a small cluster, drawstring pouch, shallow tray, deep carton box, open chest, and overflowing chest.

- Concept references: `game/ui/art/shop_gem_packs/01.png` through `06.png`.
- Untouched generated sources and safe API metadata: `output/imagegen/gold-packs-2026-10-24/`.
- Per-image prompts: [prompts](prompts/).
- Production artwork: `game/ui/art/shop_gold_packs/01.png` through `06.png`.
- Preparation metadata and source/output SHA-256: [manifest.json](manifest.json).
- Small-size review: [contact-sheet.png](contact-sheet.png).

Generation uses the user-selected 9Router Responses fallback, requesting `gpt-image-2.5-sunburst`. A requested model is not proof of the returned image model; only an explicitly reported image model is recorded in metadata. Credentials are never serialized.

Preparation reuses the existing gem pipeline: preserve generated transparency, or remove only a border-connected offwhite matte from an opaque result. Preserve original object RGB, crop meaningful alpha bounds and fit to a centered RGBA 512x512 canvas with a 32px inset. Scaling uses premultiplied RGBA Lanczos. There is no tracing, procedural coin-pile fallback, recoloring or stroke replacement.

Install with `python -B tools/ui/install_shop_gold_packs.py`; verify source/output reproducibility with `python -B tools/ui/install_shop_gold_packs.py --check`. Add `--partial` only while waiting for incomplete generation batches.

The production card uses one centered texture for each `art_level`. Existing offer values, gold-colored backdrop, buttons, daily eligibility and exchange behavior stay as before.

All six results contain genuine generated alpha, which preparation preserves within the meaningful object crop. Read-only reproduction verified six unique production assets and matching metadata. The native Shop review passed 507 checks and 18 captures at 360x640 and 450x800, including assigned unique gold textures, painted centering and containment, daily gold and exchange pointer interactions.

- [Gold offers at 450x800](../../../ui_review/2026-10-24/shop-sections/gold-offers-before-claim-450x800.png)
- [Gold offers at 360x640](../../../ui_review/2026-10-24/shop-sections/gold-offers-before-claim-360x640.png)
- [Native review manifest](../../../ui_review/2026-10-24/shop-sections/manifest.json)
