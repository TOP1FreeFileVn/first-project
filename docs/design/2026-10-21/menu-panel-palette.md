# Menu panel palette

The beige Board in the Patrol screenshot also appears in Shop offers, Castle upgrades and workshops, the Hero bag header, and the Troops team group. The related beige Well appears in Hero equipment insets, empty team slots and event rows. These menu surfaces now use contextual variants; the original shared skin remains available to combat.

| Menu | Board face | Role |
| --- | --- | --- |
| Shop | `#aac9d7` | Muted blue to match the canopy and blue pattern |
| Hero | `#b6cec4` | Mint bag header and equipment insets |
| Troops | `#c5d3aa` | Sage team group, separate from rarity cards |
| Castle | `#b7cac4` | Stone green around cardboard art and upgrades |
| Patrol | `#c0cea8` | Leaf green information board |
| Events | `#d4bbc4` | Rose insets to match the event backdrop |

Panel geometry and nine-slice margins are retained. Frames keep the game's brown outline, with a quieter inner highlight. Group labels use dark text without thick outlines. Gold action buttons, title plaques, rarity colors and combat UI retain their existing roles. Green/red equipment comparison text is darkened for legibility on mint.

`tools/ui/make_menu_panels.py` is the editable source for the SVG variants in `game/ui/skin/menu/`. Run it from the project root, then let Godot import the assets. `Ui.menu_panel_style()` returns a copy of a style so local padding changes do not mutate shared resources. `Ui.menu_panel()` applies it to a container. Existing `UiKit.panel_style()` callers remain unchanged unless they supply a menu context.

Primary dark ink has approximately 7.5–8.6:1 contrast on Board faces. The visual review includes native before/after captures of the affected menus at 720×1280 and 360×640: [review folder](../../ui_review/2026-10-21/menu-panel-palette/).
