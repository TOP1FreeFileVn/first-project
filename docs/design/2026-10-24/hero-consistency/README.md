# Equipment screen and chest reward consistency

The user clarified that the orange cat in the equipment screen should be removed. The crank operator is a separate cat and stays unchanged. `HeroCatPage` now shows equipment power and HP/ATK/DEF between the four equipped slots, with no portrait or circular backdrop. Inventory, details, upgrades and navigation keep their existing behavior.

Follow-up: the user's newer request restores the original equipment hero and adds idle animation using its separated model parts and Spine rig. The circular backdrop remains removed, and the crank operator remains separate. The current portrait implementation and its verification supersede the portrait-removal state described above: see [restored hero idle](../hero-idle/README.md).

Equipment art was already contributing stats. A runtime combat regression exercises public equip/upgrade actions, real battle skill casts, soldier spawns and siege damage. With starter equipment, sword Lv.1 deals 45.5 skill damage; upgrading it to Lv.2 raises ATK from 130 to 135 and skill damage to 47.25. The paired-class soldier bonus is separate from hero ATK. No combat balance was changed.

Chest reward cards previously used legacy category symbols and frames because only the equipment page applied the accepted paperboard face. `EquipmentCard.gd` now provides that face through `Ui.gear_card()` for all equipment categories, including chest reveals and reward rows. Filled white glyphs, rarity accents, 20% darker badge colors and outlined Lv text use one implementation. Main equipment raster art and the selected B chest artwork are preserved.

Verification:

- Native equipment UI: 283 checks, 18 captures, zero failures at 360×640 and 450×800. [Equipment screen](equipment/full-bag_450x800.png), [small screen](equipment/full-bag_360x640.png), [report](equipment/review.json).
- Actual `ChestOpening` reward summary: 410 checks, 8 captures, zero failures across four equipment categories, four rarities and both display sizes. [Common rewards](chest-rewards/rarity-0-360x640.png), [legendary rewards](chest-rewards/rarity-3-450x800.png), [report](chest-rewards/review.json).
- `HeroEquipmentCombatStatsTest`: 32 checks, zero failures; verifies equipment totals, power, action refresh signals, live skill damage, class bonuses and castle HP/DEF. All fixtures use isolated profiles with persistence disabled.
