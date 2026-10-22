extends Control

const Ui = preload("res://game/ui/Ui.gd")
const OUT := "res://docs/design/2026-10-23/weapon-frame-options/colors"
const TONES := ["green", "blue", "purple", "orange"]
const RARITIES := ["Thường", "Hiếm", "Sử thi", "Huyền thoại"]
const ITEMS := ["hero_w_kiem", "hero_w_cung", "hero_w_gay_phep", "hero_w_riu", "hero_w_katana"]
const ITEM_TONES := ["green", "blue", "purple", "purple", "orange"]
var _textures := {}

func _ready() -> void:
	get_window().content_scale_size = Vector2i(900, 1136)
	get_window().size = Vector2i(900, 1136)
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	PlayerData.persist = false
	var bg := ColorRect.new()
	bg.color = Color("b6cbc3")
	bg.size = Vector2(900, 1136)
	add_child(bg)
	_text("KHUNG A · 3 HƯỚNG MÀU", Vector2(22, 17), Vector2(856, 42), 30)
	_text("Cùng khung, cùng trang bị · Giữ xanh lá → xanh dương → tím → cam", Vector2(22, 61), Vector2(856, 28), 18)
	var palettes: Array = JSON.parse_string(FileAccess.get_file_as_string(OUT.path_join("palettes.json")))
	for i in palettes.size():
		_option(palettes[i], Vector2(14, 105 + i * 328))
	_text("Viền nâu chung · Không bóng · Màu được so ở cả cỡ lớn và 5 ô/hàng", Vector2(20, 1095), Vector2(860, 28), 18)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var capture := get_viewport().get_texture().get_image()
	var result := capture.save_png(OUT.path_join("preview.png"))
	print("A_FRAME_COLORS_RENDERED size=", capture.get_size(), " save=", result)
	get_tree().quit(result)

func _option(data: Dictionary, at: Vector2) -> void:
	var tile := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("dbe5da")
	style.set_corner_radius_all(18)
	tile.add_theme_stylebox_override("panel", style)
	tile.position = at
	tile.size = Vector2(872, 316)
	add_child(tile)
	_text(data.title, at + Vector2(16, 9), Vector2(840, 36), 27)
	_text(data.note, at + Vector2(16, 45), Vector2(840, 27), 18)
	for j in TONES.size():
		_card(data.id, "hero_w_kiem", TONES[j], false, at + Vector2(118 + j * 170, 82), 125)
		_text(RARITIES[j], at + Vector2(105 + j * 170, 209), Vector2(151, 25), 18)
	for j in ITEMS.size():
		_card(data.id, ITEMS[j], ITEM_TONES[j], j == 0, at + Vector2(44 + j * 67, 244), 59)
	_text("Cỡ thật: 5 ô / màn 360px", at + Vector2(410, 254), Vector2(420, 27), 18)

func _card(palette: String, item: String, tone: String, upgrade: bool, at: Vector2, display: float) -> void:
	var card := Ui.gear_card(item, "slot_weapon", tone, "12", 118, upgrade)
	card.size = Vector2(118, 118)
	var panel: PanelContainer = card.get_child(0)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var face := TextureRect.new()
	face.texture = _texture(palette, tone)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_SCALE
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(face)
	card.move_child(face, 0)
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.position = at
	card.scale = Vector2.ONE * (display / 118.0)
	add_child(card)

func _texture(palette: String, tone: String) -> Texture2D:
	var key := palette + "-" + tone
	if not _textures.has(key):
		var img := Image.new()
		var error := img.load_svg_from_string(FileAccess.get_file_as_string(OUT.path_join("svg/" + key + ".svg")), 3.0)
		assert(error == OK)
		_textures[key] = ImageTexture.create_from_image(img)
	return _textures[key]

func _text(value: String, at: Vector2, bounds: Vector2, font_size: int) -> void:
	var label := Ui.label(value, "", font_size)
	label.position = at
	label.size = bounds
	label.add_theme_color_override("font_color", Color("583f21"))
	label.add_theme_constant_override("outline_size", 0)
	add_child(label)
