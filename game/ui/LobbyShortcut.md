# Lobby shortcut feedback

`LobbyShortcut.gd` is the persistent native Button used by Home's four side shortcuts: daily login, quests, events and castle. The button owns drawing and finite interaction tweens; Home owns alert refreshes, tap sound and destinations.

- Press shrinks the face to 94% and depresses it 4 logical pixels in 60ms. Release returns with a 180ms spring. The 108×128 logical hit rectangle stays fixed.
- Pointer hover and keyboard focus lift the face 3px and expose a warm rim. No continuous idle animation is used.
- Release animates a calendar page, check stamp, hanging banner, or castle door according to the shortcut type. Home opens its destination after 200ms so the response remains visible before a popup covers it.
- Repeated taps during that delay open one destination. Changing tabs cancels the pending shortcut. Alert updates preserve the button and its current animation.
- Pointer exit, canceled touch, Escape, focus loss and hiding release a held face; hidden buttons clear their visual state. Exiting kills their finite tweens.

The earlier study is under `docs/design/2026-10-21/lobby-feedback-demo/`. Production does not load scripts or artwork from that folder.
