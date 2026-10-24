extends Node2D

# A contact sheet of the hero cat's rig animations: one row per clip, frames across time.
# Run (windowed): Godot --path . --resolution 1200x1280 res://tests/ui/HeroRigSheet.tscn -- <family> <out.png>

const SoldierRig = preload("res://game/battle/SoldierRig.gd")
const CLIPS := ["idle", "walk", "run", "attack", "train", "pose", "look", "cheer"]
const FRAMES := 6
const CELL := Vector2(190, 150)

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var family: String = args[0] if args.size() > 0 else "melee"
	var out: String = args[1] if args.size() > 1 else "user://hero_rig_sheet.png"
	RenderingServer.set_default_clear_color(Color("eaf0e9"))
	var path := "res://game/assets/hero/%s/%s.json" % [family, family]
	var rows: Array = []
	for r in CLIPS.size():
		var label := Label.new()
		label.text = CLIPS[r]
		label.position = Vector2(6, r * CELL.y + 6)
		label.add_theme_color_override("font_color", Color("583f21"))
		add_child(label)
		for f in FRAMES:
			var rig := SoldierRig.new()
			rig.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			rig.load_skeleton(path)
			rig.play(CLIPS[r])
			rig.speed = 0.0
			rig.scale = Vector2.ONE * 0.5
			rig.position = Vector2(80 + f * CELL.x, (r + 1) * CELL.y - 12)
			add_child(rig)
			rows.append([rig, CLIPS[r], f])
	await get_tree().process_frame
	for entry in rows:
		var rig = entry[0]
		var dur: float = rig._duration(rig._anims.get(entry[1], {}))
		rig._time = dur * entry[2] / float(FRAMES)
		rig.queue_redraw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()
