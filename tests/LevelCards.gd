extends Node

# Renders every level's card art (the level select picture) to PNG, for documents.
# Run (windowed): Godot --path . res://tests/LevelCards.tscn -- --out=C:/some/folder

const LevelArt = preload("res://game/menu/widgets/LevelArt.gd")
const SIZE := Vector2i(560, 440)

var _out := ""
var _viewports: Array = []
var _frames := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.get_slice("=", 1)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.unlocked_levels = PlayerData.LEVELS.size()
	for i in PlayerData.LEVELS.size():
		var viewport := SubViewport.new()
		viewport.size = SIZE
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		var art = LevelArt.new()
		art.level_index = i
		art.size = Vector2(SIZE)
		var ids := []
		for wave in PlayerData.level_data(i).waves:
			for group in wave["groups"]:
				if not ids.has(group["troop"]):
					ids.append(group["troop"])
		art.enemy_ids = ids
		viewport.add_child(art)
		_viewports.append(viewport)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames < 30:
		return
	for i in _viewports.size():
		_viewports[i].get_texture().get_image().save_png("%s/level_%02d.png" % [_out, i + 1])
	get_tree().quit()
