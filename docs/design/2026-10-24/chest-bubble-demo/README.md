# Chest reward bubbles — 24 October 2026

Review-only native Godot demo of three shop layouts. No production game files
were changed for this demo. It reuses the actual Home header, shop canopy,
scrolling backdrop, carton bottom navigation, chest artwork, game font and
original button skins.

## Layout choices

- **A — Reference:** chest on the left, dark reward bubble on the right.
- **B — Paper:** light reward bubble on the left, chest on the right, with a
  full-width purchase button below.
- **C — Floating:** reward bubble above, chest at the lower left and purchase
  button at the lower right.

Each bubble contains the actual rewards and rarity guarantee. The current data
is:

| Chest | Rewards shown inside the bubble | Action cost |
| --- | --- | --- |
| Gold | 6 equipment items, 70–90 Forge Stones, at least 2 Epic-or-better items | 120 gems |
| Silver | 3 equipment items, 25–35 Forge Stones, at least 1 Rare-or-better item | 600 gold |
| Wood | 1 equipment item, 8–14 Forge Stones, 50–100 bonus gold | Free every 4 hours |

Copy and prices are read from the current Economy data. The designs do not add
fictional “Get 10” rewards, discounts, or an extra pity teaser. Gold already
guarantees two Epic-or-better items per chest.

## Run and capture

From this directory, run `./run.ps1` to open the visible preview, or run
`ChestBubbleDemo.tscn` in Godot. Press **1**, **2**, or **3** to choose a layout;
**R** resets the review account. Arrow keys and **G** also cycle the layouts.

Run `./run.ps1 -Capture` for a hidden native capture session. The `captures/`
directory contains full-screen screenshots, Gold-card crops, scrolled exchange
states, the missing-funds state, and `manifest.json` with the observed checks.

The runner isolates APPDATA/LOCALAPPDATA under ignored
`output/chest-bubble-demo-profile`. The fixture sets `PlayerData.persist = false`
before resetting its account; regular player saves are unchanged. The shared
bottom navigation remains present in every layout.

## Verification result

The final native run passed **90 checks with no failures** at **360×640** and
**450×800**. Captures of A/B/C and the missing-funds state were visually inspected.
There were no parse errors in the final run. Logs retain the machine
certificate-store warning and shutdown ObjectDB/resource cleanup warnings.

These checks verify the review layouts and their state handling. They are not a
user study or evidence that one layout increases purchases.
