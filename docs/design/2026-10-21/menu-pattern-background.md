# Shared scrolling menu backgrounds

All non-battle Home tabs, event pages, sheets and reward openings use the Shop's scrolling gear/paw motif. The cardboard Battle lobby and combat background retain their existing art.

Home owns one full-screen pattern so the header, content and navigation share the same scale and animation phase. Each registered surface supplies its color context. Closing a surface restores the newest remaining context; queued older surfaces cannot override a newer one. Menu surfaces pause the courtyard without rebuilding its cats. Full-screen chest and summon openings temporarily hide the underlying menu chrome.

The palette lives in `game/ui/Ui.gd` (`MENU_PATTERN_COLORS`): Shop blue, Hero mint, Troops sage, Summon violet, Castle stone green, Patrol leaf green, Events rose, Login sand, Quests pale blue, Profile blue green, Settings slate blue and Admin deep slate. Existing card and panel artwork is retained.

Shared sheets register through `UiKit.sheet_popup`; new Home page overlays register automatically. Standalone combat hosts keep their original opening dim/background behavior. Admin owns a local pattern because its CanvasLayer covers the Home canvas.

## Verification

- [Main menus and context transitions](../../ui_review/2026-10-21/menu-pattern-background/README.md): 1,058 checks, 36 captures and 2 isolated motion pairs; no failures.
- [Admin, chest and summon surfaces](../../ui_review/2026-10-21/menu-surface-review/README.md): 97 checks and 10 captures; no failures.
- Both native reviews cover 720×1280 and 360×640 with Compatibility rendering and isolated player profiles.
- Existing tap-routing, popup-close, cardboard-lobby and chest-layout regressions also passed.
