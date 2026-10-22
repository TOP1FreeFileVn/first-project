# Upgrade prompts

`UpgradeHint.gd` draws the existing green upgrade arrow at a fixed size. It smoothly rises 6 logical pixels and returns over a 1.1 second cycle, without animated scaling. The visual moves independently of its Control rectangle. It ignores mouse input and stops/resets its animation when hidden.

- Troop collection: the 48px prompt sits at the upper-right corner, anchored 18px above the card. Its vertical scale is 84% to shorten the arrow while preserving its width and centered pivot. The equipped/team check sits at the lower right and the level at the upper left. Both markers use the card's default draw layer: the arrow is added last to draw above its sibling badges, while modal popups still cover the entire roster. Star readiness takes priority over level readiness. Locked or unavailable upgrades have no arrow. Scroll padding and row spacing preserve the overflow.
- Tapping a troop opens `menu/popups/TroopUpgradeScreen.gd` on a registered full-screen layer. Home hides the roster and shared navigation until Back frees that layer. Level and star previews have separate tabs, while the confirmation and cost remain fixed below the information scroll area. The screen owns its live data refresh; returning preserves the roster filter and scroll position.
- Courtyard: `CastleBubble.gd` places a speech bubble above the castle's near ear, clear of the flag. Its 56px arrow bobs above the bubble's top edge when the castle can be upgraded. Otherwise, a dim static arrow keeps the information entry recognizable.
- Tapping the bubble or castle illustration opens the castle detail card, including its stats, upgrade cost and workshop. Opening the card never spends gold; upgrading happens through its own button. Swiping across the illustration still changes the selected stage. The former separate castle shortcut is removed.

Home keeps the courtyard, its cats, the bubble and its hint alive through data refreshes and changes of menu context.
