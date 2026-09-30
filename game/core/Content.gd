extends RefCounted

# Which troops and levels exist. Shared by PlayerData and Balance without either one
# depending on the other.

# Collection order: by rarity, then roughly by when the player meets them.
const TROOP_ORDER := ["pawn", "warrior", "archer", "miner", "smith", "lancer", "assassin", "guard", "fire_archer", "monk", "cook", "bomber", "general"]
const TROOP_PATH := "res://game/data/troops/%s.tres"
const LEVELS := [
	"res://game/data/levels/level_01.tres",
	"res://game/data/levels/level_02.tres",
	"res://game/data/levels/level_03.tres",
	"res://game/data/levels/level_04.tres",
	"res://game/data/levels/level_05.tres",
	"res://game/data/levels/level_06.tres",
	"res://game/data/levels/level_07.tres",
	"res://game/data/levels/level_08.tres",
	"res://game/data/levels/level_09.tres",
	"res://game/data/levels/level_10.tres",
	"res://game/data/levels/level_11.tres",
	"res://game/data/levels/level_12.tres",
	"res://game/data/levels/level_13.tres",
	"res://game/data/levels/level_14.tres",
	"res://game/data/levels/level_15.tres",
]
