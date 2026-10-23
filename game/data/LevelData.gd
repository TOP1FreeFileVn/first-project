extends Resource

# One playable level: castle HP, starting meat and the enemy waves to survive.

@export var display_name := ""
## Ground-only art (720x740). The castle and gear table are separate battle layers.
## Null keeps the original woodland field for levels without regional art yet.
@export var battlefield: Texture2D
## Regional panorama behind the separately rendered stage name in Home.
@export var lobby_banner: Texture2D
## Unused since teams replaced per-level troop pools (kept so old .tres files load).
@export var troop_pool: Array = []
@export var start_meat := 6.0
@export var core_hp := 100.0
## Multiplies enemy HP and damage for the whole level.
@export var enemy_power := 1.0
## Seconds to build before the first wave.
@export var prep_time := 12.0
## Each wave: {"gap": seconds, "groups": [{"troop": id, "count": n, "interval": s,
## "start": s (optional), "elite": bool (optional)}]}.
## A wave ends once all its enemies have spawned and died; the shop break follows.
## ("gap" and prep_time are left over from the old real-time flow and are unused.)
@export var waves: Array = []
## Special board cells: {"rock": [Vector2i, ...], "gold": [...], "rust": [...], "ice": [...]}.
## See GearBoard.TILE_INFO for what each does.
@export var tiles := {}
