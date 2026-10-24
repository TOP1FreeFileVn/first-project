# Gold chest A card and x1/x10 — production review

This fixture instantiates serialized `game/menu/Home.tscn` with the normal
production `ShopPage.gd`; it does not inject the demo. Only the gold offer uses
the approved A speech bubble design. Existing wood/silver supply cards, exchange,
and CartonNav remain part of the review.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/ui_review/2026-10-24/gold-chest-batch/run.ps1 -ImportAssets
```

The runner uses the existing desktop Godot 4.7.2, a hidden native compatibility
renderer, muted audio, and a separate APPDATA/LOCALAPPDATA profile in ignored
`output/`. `PlayerData.persist` is disabled before resetting the fixture account.
Import has a 60-second timeout; native capture has a 90-second timeout.

Review coverage:

- Native 360×640 and 450×800 screens with 2,400 gems, one gem less than the x10
  price, and no gems. x1 and x10 enable separately; funded silver and free wood
  retain their existing actions and supply layout.
- Real pointer taps open the rates sheet and buy x1/x10 from fresh production
  Home scenes. Prices come from Economy: 120/1,200 gems with current balance.
- The x10 opening holds all 60 equipment items and has a “Rương Vàng ×10” title.
  Stones, blueprints, inventory, and pity advance for all ten chests.
- The normal x10 chest burst goes directly to the complete scrollable summary.
  x1 keeps its individual card reveal; its real skip action reaches the summary.
  Summary actions stay visible, including after scrolling sixty rewards to the
  bottom. Revealing or skipping neither charges nor grants rewards a second time.
- Repeated purchase requests while an opening is active are rejected without any
  charge or reward. The real XONG action closes the overlay, then a fresh pointer
  purchase succeeds exactly once.

`manifest.json` records observed checks, failures, native control rectangles,
purchases, profile, and captures.

Verified on 2026-10-24 with Godot 4.7.2:

- Gold native integration: **197 checks, 13 captures, no failures**.
- Backend scene regression (`run-logic.ps1`): **102 checks, no failures**. Covers
  atomic payment, invalid requests, single-purchase compatibility, unique item
  UIDs, individual rarity/pity guarantees, one save notification, and seeded
  equivalence between one x10 purchase and ten x1 purchases.
- Existing shop regression: **106 checks, 7 captures, no failures**, including
  wood cooldown, silver, exchange, navigation, and pattern restoration.

Backend reproduction:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/ui_review/2026-10-24/gold-chest-batch/run-logic.ps1
```

Both runners require a successful completion marker. Logs also contain this
machine's certificate-store warning; native shutdown reports two ObjectDB
instances and one resource still in use. No script, parse, or compile errors
were reported in the completed runs.

Production screenshots: `funded-450x800.png`, `actual-x1-card-450x800.png`,
`actual-x10-summary-450x800.png`, and `actual-x10-summary-scrolled-450x800.png`.
