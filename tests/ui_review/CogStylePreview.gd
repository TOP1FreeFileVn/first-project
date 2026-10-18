extends Node2D

# A contact sheet of the production gears, not a second drawing implementation.
const Gear = preload("res://game/battle/Gear.gd")
const Core = preload("res://game/battle/Core.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const CogDraw = preload("res://game/battle/CogDraw.gd")
var _gears: Array = []


func _ready() -> void:
	get_window().size = Vector2i(720, 1280)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	PlayerData.persist = false
	PlayerData._reset()
	_add_gear(Vector2(144, 468), 2, true)
	_add_gear(Vector2(360, 468), 2, false)
	var core := Core.new()
	core.position = Vector2(576, 468)
	add_child(core)
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image().get_region(Rect2i(0, 0, 720, 720))
	var result := shot.save_png("res://docs/ui_review/2026-10-19/cog_style.png")
	print("COG_STYLE_CAPTURE result=", result)
	get_tree().quit()


func _add_gear(at: Vector2, rank: int, active: bool) -> void:
	var gear := Gear.new()
	gear.troop = PlayerData.TROOPS["kiem"]
	gear.position = at
	gear.tier = rank
	gear.powered = active
	add_child(gear)
	gear._clock = gear.spawn_interval() * 0.65
	_gears.append(gear)


func _process(delta: float) -> void:
	for gear in _gears:
		if gear.powered:
			gear.angle += delta * 0.6


func _draw() -> void:
	draw_rect(Rect2(0, 0, 720, 1280), Color("f4ead7"))
	var font := UiKit.game_font()
	var ink := Color("583f21")
	draw_string(font, Vector2(24, 58), "Bánh răng · phong cách mèo", HORIZONTAL_ALIGNMENT_CENTER, 672, 30, ink)
	draw_string(font, Vector2(24, 102), "Thân đĩa lớn · răng ngắn bè · viền sáng phía trong", HORIZONTAL_ALIGNMENT_CENTER, 672, 20, ink)
	for i in 5:
		var center := Vector2(72 + i * 144, 222)
		CogDraw.draw_cog(self, center, Gear.OUTER, Gear.INNER, Gear.TEETH, -0.3 * TAU / Gear.TEETH, Gear.METALS[i], ink)
		draw_string(font, center + Vector2(-30, 10), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 60, 28, ink)
		draw_string(font, Vector2(12 + i * 144, 324), "Bậc %d" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, 120, 22, ink)
	for entry in [[84, "Đang quay"], [300, "Ngắt nối"], [516, "Trục chính"]]:
		draw_string(font, Vector2(entry[0], 566), entry[1], HORIZONTAL_ALIGNMENT_CENTER, 120, 20, ink)
	draw_string(font, Vector2(24, 652), "Mặt lính đứng yên · vành răng chuyển động", HORIZONTAL_ALIGNMENT_CENTER, 672, 22, ink)
