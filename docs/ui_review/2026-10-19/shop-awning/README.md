# Shop awning review

Production capture: **6 native images, 49 passing checks, 0 failures**. Godot exited with code 0; no shader/GDScript errors occurred. The existing Windows certificate-store message remains in the log.

- [Shop 450×800](shop_450x800.png) · [Shop 360×640](shop_360x640.png)
- [Battle 450×800](battle_450x800.png) · real-time motion at [1 second](battle_motion_01_450x800.png), [2 seconds](battle_motion_02_450x800.png), [3 seconds](battle_motion_03_450x800.png)

Shop uses the darker `#4e78a3` pattern. The awning is visible only on Shop; actual Shop/Battle navigation passes at both sizes. Its rectangle is `[0,112,720,104]`, directly below the header. The first offer starts at y307, leaving 91 design pixels after the awning. All four offers fit; the last ends at y1104, 16 pixels before navigation.

After reducing Shop's bottom padding to 16, the vertical scrollbar is hidden at both sizes: `max_value=1008`, `page=1008`, `value=0`. Offer width is 672 design pixels.

Cloud motion is set to twice the previous drift rate; islands retain their gentle float. Four real-time frames over three seconds confirm motion while UI geometry stays fixed: 8,438 pixels differ between the first and last frame.

Actual input smoke checks pass for free chest opening, summary/Xong, and gem-to-gold exchange. The chest grants the expected card count (including cards consumed to unlock new troops), gold, and cooldown; closing preserves rewards. The fixture uses `PlayerData.persist=false` and the MCP client isolates its profile under `mcp/profile/`.

Reproduce with `node tools/review/mcp_ui_review.mjs docs/ui_review/2026-10-19/shop-awning/plan.json`. [Compact manifest](manifest.json) · [MCP runtime log](mcp/mcp-results.json).
