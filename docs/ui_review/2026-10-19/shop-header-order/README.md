# Shop header order review

**4 native screenshots, 54 passing checks, 0 failures.** Godot exited with code 0 and no shader/GDScript errors. The existing Windows certificate-store message remains in the log.

- [Shop 450×800](shop_450x800.png) · [Shop 360×640](shop_360x640.png)
- [Battle 450×800](battle_450x800.png) · [Battle 360×640](battle_360x640.png)

Shop's roof is `[0,0,720,104]`, sign `[0,24,720,64]`, Header `[0,104,720,112]`, and avatar `[14,116,80,84]`. Shop content starts at y216. Returning to Battle restores Header y0 and avatar y12, and hides the roof/sign.

All four offers retain their previous design positions: y307,507,707,956; width672; last bottom1104. They fit above navigation at y1120. Shop has no scrollbar at either native size: `max_value=page=904`, `value=0`, bar invisible.

Actual mouse clicks verify Shop→Battle→Shop, profile popup opening/closing, settings popup opening/closing, and both currency hit targets at their lowered Header positions, at both sizes. The review uses `PlayerData.persist=false` and an isolated profile under `mcp/profile/`.

Run `node tools/review/mcp_ui_review.mjs docs/ui_review/2026-10-19/shop-header-order/plan.json`. [Compact geometry and checks](manifest.json) · [Runtime log](mcp/mcp-results.json).
