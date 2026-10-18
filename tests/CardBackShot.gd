extends Control

# Face-down cards (chest and summon) at their real sizes and at 2x, for checking the back's
# layout. Run (windowed): Godot --path . res://tests/CardBackShot.tscn -- --out=C:/file.png

const UiKit = preload("res://game/ui/UiKit.gd")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const SummonOpening = preload("res://game/ui/SummonOpening.gd")


func _ready() -> void:
	theme = UiKit.make_theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var bg := ColorRect.new()
	bg.color = Color("1b1d2e")
	bg.size = Vector2(720, 1280)
	add_child(bg)
	var x := 30.0
	for item in [[ChestOpening.CARD_SIZE, false, 1.0], [SummonOpening.CARD_SIZE, true, 1.0], [ChestOpening.CARD_SIZE, false, 1.6], [SummonOpening.CARD_SIZE, true, 1.6]]:
		var back := UiKit.card_back_face(item[0], item[1])
		back.position = Vector2(x, 80)
		back.scale = Vector2(item[2], item[2])
		add_child(back)
		x += item[0].x * item[2] + 24
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			get_viewport().get_texture().get_image().save_png(arg.get_slice("=", 1))
	get_tree().quit()
