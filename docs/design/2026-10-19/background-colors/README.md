# Menu background color study

Status: visual study for discussion only; no production color changes.

The user rejected every divider alternative and asked whether the background color should change. This study compares three backgrounds using the current native game UI at 720 × 1280:

| Variant | Sky uniform | White motif alpha | Notes |
| --- | --- | --- | --- |
| Current | `#6fa3e0` | 16% | Existing production colors |
| Blue gray | `#9bb5c4` | 5% | Preferred: calmer, keeps a sky feeling and separates warm art from the background |
| Sage | `#a0b8a3` | 4% | Cozy, but shares more color with grass and green troop portraits |

All keep the existing vertical gradient (1.08 at the top, 0.94 at the bottom), art, controls, text, layout, and theme. Motif movement is frozen identically in each study so the screenshots compare like positions. These proposals intentionally compare the combined color/contrast direction; this is not an isolated hue experiment.

The motif opacity is reduced by changing only the preview material's texture alpha. There are no changes to `Home.gd`, `Ui.gd`, the production shader, or the shared tile SVG. PlayerData.persist is disabled and the MCP process uses a disposable profile.

`lobby-comparison.png`, `troops-comparison.png`, and `shop-comparison.png` come from native runtime captures. Full-resolution images are named by variant and page. Capture plan: `capture-plan.json`; contact-sheet script: `build_preview.py`.

All 9 screenshots were captured successfully with exit 0 and the lobby/troop comparisons visually inspected. Existing Windows certificate warning is unrelated to these previews.
