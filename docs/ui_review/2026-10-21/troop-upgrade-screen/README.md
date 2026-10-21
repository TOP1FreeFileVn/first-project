# Dedicated troop upgrade screen

Native production Home coverage at 360×640 and 450×800: **230 checks, 20 captures, 0 failures**, exit code 0.

Run `tests/ui_review/TroopUpgradeScreenReview.tscn` with native Godot rendering. The former `TroopPopupLayering.tscn` entry now runs this same dedicated-screen fixture; historical popup screenshots remain unchanged in their earlier folder.

Coverage includes opening through real roster cards; full-screen layer and lobby visibility; native level/star confirmation with exact spending, updated preview and feedback; insufficient gold/cards; cap/default-star/max/locked states; a light centered question over the locked silhouette; Back restoring roster animation, rarity filter and nonzero scroll; full-team swap completion; and the last-unit removal guard.

The final captures use the reference-directed layout: centered troop artwork above its name and stars, metadata badges on the left, two-column stat tiles with green upgrade gains, and adjacent Upgrade/Team actions in the fixed footer. Visual review covered the funded level view at 360×640, star view at 450×800, locked silhouette at 360×640 and long support description at 450×800. The information area scrolls independently and clears both footer actions.

A duplicate RAM-only Sách Phép resource exercises the support role and long ability text, because the production cat roster currently contains no support-role unit. The fixture restores the original resource afterwards. Layout checks cover action bounds, separate tabs, the fixed primary action clearing the scroll area and a primary hit target of at least 44 physical pixels at both sizes.

All player state stays in RAM (`PlayerData.persist = false`) under an isolated `output/troop-upgrade-screen-qa-profile` profile. No save or troop resource file is changed. `manifest.json` records each check and capture.
