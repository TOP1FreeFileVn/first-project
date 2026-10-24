# Gem-pack illustrations

Six individually generated shop illustrations: three gems, drawstring pouch, shallow tray, deep carton box, open chest, and overflowing chest. Production PNGs contain no text or UI.

Generated through the user-selected local 9Router Responses route. The requested image model was `gpt-image-2.5-sunburst`. `response_model` identifies the response orchestrator, not the image generator; only `reported_image_model` records an explicitly reported image model. A missing or null reported image model means unknown; no identity is inferred. Per-image safe generation metadata and original/output SHA-256 hashes are in [manifest.json](manifest.json). Prompts are in [prompts](prompts/). Original images remain unchanged under `output/imagegen/gem-packs-2026-10-24/`.

Images 03 and 06 preserve their generated alpha within the meaningful ink crop. The crop ignores source alpha below 8 outside the illustration (faint stray transparency); object alpha and colors are retained. Opaque images 01, 02, 04, and 05 remove only offwhite pixels connected to the image border, leaving enclosed cream materials intact. No tracing, drawing, recoloring, or stroke replacement is applied.

Each production image is RGBA 512×512, fitted within 32…480, with its meaningful ink bbox centered on both axes. Scaling uses premultiplied RGBA Lanczos. [contact-sheet.png](contact-sheet.png) shows the assets at 148×148 thumbnail size on the shop card color.

Reinstall: `python -B tools/ui/install_shop_gem_packs.py`

Read-only verification: `python -B tools/ui/install_shop_gem_packs.py --check`

Allow incomplete source batches: add `--partial`. The installer never accesses credentials, a generation API, Godot, balances, or player data.
