# Menu polish runtime review

Production scenes captured through the local Godot MCP at native **720×1280**, **450×800**, and **360×640**. The 450×800 captures match the user's screenshot size.

Run:

```powershell
node tools/review/mcp_ui_review.mjs docs/ui_review/2026-10-19/menu-polish/plan.json
```

The MCP client isolates APPDATA/LOCALAPPDATA under `mcp/profile/`; the fixture sets `PlayerData.persist = false` before resetting its in-memory player state.

## Result

**17 native screenshots, 21 actual mouse-click routes, 0 failures.** The process exited normally with code 0. No GDScript errors or resize event loop occurred. Godot emitted the existing Windows certificate-store message.

- Both level pager directions work at all three sizes.
- Shop lock and unlock work at all three sizes.
- Sẵn sàng starts the wave and becomes disabled at all three sizes.
- All four other navigation tabs open through their actual hit targets at 450×800; the battle tab returns to the lobby.
- Castle overlay opens, keeps the background aligned, and its actual back button returns to the lobby.
- Essential visible controls remain inside the 720×1280 design canvas; Sell and Ready do not overlap.

## Geometry

These design-space rectangles are identical at all three native sizes:

| Control | Rectangle `[x, y, width, height]` |
| --- | --- |
| Previous level | `[127, 852, 70, 62]` |
| Next level | `[523, 852, 70, 62]` |
| Previous arrow | `[145, 862, 34, 34]` |
| Next arrow | `[541, 862, 34, 34]` |
| Trận chiến | `[180, 974, 360, 104]` |
| CTA content row | `[236, 989, 248, 52]` |
| Bán | `[16, 1196, 152, 76]` |
| Sẵn sàng | `[182, 1196, 520, 76]` |
| Shop lock | `[391, 530, 200, 76]` |

CTA icon/text gap is 12 design pixels; reward/CTA gap is 16. CTA-to-navigation gap is 42 design pixels (26.25 native pixels at 450×800). Sell/Ready share the same top and bottom, with a 14-pixel gap.

At 450×800, the selected battle tab's left/right edges now have mirrored raster values. At row 730, columns 171–173 are `(88,63,33)`, `(88,63,33)`, `(160,127,93)`; columns 276–278 contain the same values in reverse. The footer edges match too.

Background pixels at x=0 and y=71,100,200,300,400,500,600,699 are identical between the lobby and hero/troops/shop/summon/castle captures. The castle background uses the same screen coordinates as the surrounding lobby.

## Images

- [Lobby, 450×800](lobby_450x800.png) · [native footer](lobby_450x800_footer.png)
- [Battle preparation, 450×800](battle_prepare_450x800.png) · [native footer](battle_prepare_450x800_footer.png)
- [Locked shop, 450×800](battle_locked_450x800.png)
- [Wave started, 450×800](battle_wave_started_450x800.png)
- [Hero](hero_450x800.png) · [Troops](troops_450x800.png) · [Shop](shop_450x800.png) · [Summon](summon_450x800.png)
- [Castle overlay](castle_overlay_450x800.png)
- [Lobby, 720×1280](lobby_720x1280.png) · [Battle preparation, 720×1280](battle_prepare_720x1280.png)
- [Lobby, 360×640](lobby_360x640.png) · [Battle preparation, 360×640](battle_prepare_360x640.png)

Every capture has a corresponding `_geometry.json`. `manifest.json` contains the complete image list, geometry, route results, and isolated profile path. `mcp/mcp-results.json` contains the runtime log.
