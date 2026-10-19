# Bottom tab divider alternatives

Status: all three alternatives rejected by the user ("bỏ hết đi"). Not integrated into production; do not use these drafts as an accepted design reference.

The user rejected the wavy divider and asked for other ways to make the separator between icon and selected-tab caption more interesting. These alternatives change only that separator.

- A `rim.svg`: a shallow warm gold rim with pale highlight and a small darker lower edge.
- B `paw.svg`: a tiny cat paw on a raised cream centre, interrupting the thin separator. Preferred for adding game identity without a large decoration.
- C `plaque.svg`: a cream caption plaque with softly chamfered shoulders and a small bevel.

`comparison.png` shows the three proposals on the actual Cửa hàng tab. `whole-bar-comparison.png` shows their size in the whole navigation bar. These images come from native Godot runtime captures, using the existing icon, font, text position, and tab geometry.

Preview harness: `DividerPreview.tscn`. Capture via `node tools/review/mcp_ui_review.mjs docs/design/2026-10-19/bottom-divider/capture-plan.json`. PlayerData.persist is disabled; no production files or saved player progress were changed. The preview exited 0 and all 5 screenshots were captured and visually inspected. Existing Windows certificate-store warning remains unrelated.

Editable Figma board: https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5/?node-id=3582-115 . Uses vector dividers, a shared production shop icon component, and native Paytone One captions. Structural verification found no image fills; all 3 captions use Paytone One. Full node IDs are in `figma-state.json`.
