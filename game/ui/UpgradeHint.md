# Upgrade prompts

`UpgradeHint.gd` draws the existing green upgrade arrow, with a 1.1 second scale cycle from 90% to 116% and a 3px upward bob. The visual moves independently of its Control rectangle. It ignores mouse input and stops/reset its animation when hidden.

- Troop collection: 48px arrows extend 18px above the card. The arrow always comes first at the left edge; the equipped/team check follows it. Both use the card's default draw layer: the arrow is added last to draw above its sibling badges, while modal popups still cover the entire roster. The level stays at the right. Star readiness takes priority over level readiness. Locked or unavailable upgrades have no arrow. Scroll padding and row spacing preserve the overflow.
- Courtyard: `CastleBubble.gd` places a speech bubble above the castle's near ear, clear of the flag. Its 56px arrow pulses beyond the bubble's top edge when the castle can be upgraded. Otherwise, a dim static arrow keeps the information entry recognizable.
- Tapping the bubble or castle illustration opens the castle detail card, including its stats, upgrade cost and workshop. Opening the card never spends gold; upgrading happens through its own button. Swiping across the illustration still changes the selected stage. The former separate castle shortcut is removed.

Home keeps the courtyard, its cats, the bubble and its hint alive through data refreshes and changes of menu context.
