# Lobby shortcut feedback

`LobbyShortcut.gd` is the persistent native Button used by Home's three side shortcuts: daily login, quests and events. The button owns drawing and finite interaction tweens; Home owns alert refreshes, tap sound and destinations. The castle's speech bubble and illustration open its detail card, where its upgrade action and workshop remain available.

The approved 2026-10-22 layout is borderless: an 84×84 icon sits above a
20px cream-white Paytone caption with a 3px dark outline. Home draws one
continuous translucent mask per side column, covering icons, captions and
the spaces between items. Both strips use #3f493f at 48% opacity with 10px
corners and no border or shadow. The mask stays still during interaction.
The castle speech bubble follows the flat-frame rule; raised action buttons
keep their button depth.

- Press shrinks the face to 94% and depresses it 4 logical pixels in 60ms. Release returns with a 180ms spring. The 108×128 logical hit rectangle stays fixed.
- Pointer hover and keyboard focus lift the icon and caption 3px. No frame or continuous idle animation is used.
- Release animates a calendar page, check stamp, hanging banner, or castle door according to the shortcut type. Home opens its destination after 200ms so the response remains visible before a popup covers it.
- Repeated taps during that delay open one destination. Changing tabs cancels the pending shortcut. Alert updates preserve the button and its current animation.
- Pointer exit, canceled touch, Escape, focus loss and hiding release a held face; hidden buttons clear their visual state. Exiting kills their finite tweens.

The approved mask study is under `docs/design/2026-10-22/lobby-mask-shortcuts/`.
Production draws it directly in `LobbyShortcut.gd` and `Home.gd`, with no
dependency on the design folder. The reward row and battle button sit 20
logical pixels lower, preserving their spacing and navigation clearance.
