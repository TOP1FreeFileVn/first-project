# Temporary gear sell target review

`tests/ui_review/GearSellDropTest.tscn` passed **116 checks, 6 native screenshots, 0 failures**, process exit 0, using Godot 4.7.2 with `gl_compatibility`.

The fixture instantiates the production Battle scene at **720×1280** and **360×640**. It uses native `InputEventMouseButton` and `InputEventMouseMotion` through `Input.parse_input_event`, transformed once from logical viewport coordinates into native window coordinates. No drag/drop, sell, merge, or swap behavior is invoked directly.

Checks cover:

- Sell target hidden while idle; READY fills the bottom area.
- Ordinary gear drag reveals the target; hover shows the exact refund.
- Release sells one gear and pays exactly once; duplicate release cannot sell again.
- Invalid drops restore the source cell without a refund.
- Weapon skill gear remains unsellable; target stays hidden and READY stays inactive during its drag.
- Merge and swap continue to work.
- Drag release over the sell area or a shop card cannot activate HUD buttons or buy an offer.
- `start_wave()` refuses to start during a drag.
- Focus-loss and ended-phase cancellation restore the source, hide the target, and pay nothing.

The last two cancellation branches use the production window notification and board process entry points. Other interactions use native mouse events.

All six screenshots were reviewed. The full-width READY and temporary sell target fit at both sizes; hover feedback and refund remain visible at360 px. The target intentionally draws over the dragged gear at the bottom edge.

The test uses an isolated workspace APPDATA/LOCALAPPDATA profile and disables PlayerData persistence. It opens all board cells in the RAM fixture to isolate merge/swap/drop behavior and raises the coin cap so exact refunds cannot be clipped by the purse limit. Actual user saves are unaffected.

`manifest.json` records every assertion and capture. The only stderr output is the environment's Windows root-certificate-store warning; no script, resource, or gameplay runtime errors were observed.

After the wallet-capacity UI fix, the targeted `-- --wallet-capacity-only` mode passed **26 checks, 2 captures, 0 failures**, exit0 at360×640. Full wallet displays `+0 xu`, warns that the purse is full, and selling pays no extra. A fractional fixture (9.8/10.75, nominal refund6) displays the visible whole-coin gain `+1 xu`, shows the capacity limit hint, caps the actual balance at10.75, and reports the received gain in the toast. Duplicate release cannot pay again. Evidence is under `wallet-capacity/`; the prior116-check full-suite manifest remains intact. The two new cases are also part of future full-suite runs.

- [Idle, 360 px](idle_360x640.png)
- [Dragging, 360 px](drag_360x640.png)
- [Hover, 360 px](hover_360x640.png)
- [Idle, 720 px](idle_720x1280.png)
- [Dragging, 720 px](drag_720x1280.png)
- [Hover, 720 px](hover_720x1280.png)
