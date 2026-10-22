extends Control

const Ui = preload("res://game/ui/Ui.gd")
const OUT := "res://docs/design/2026-10-23/weapon-frame-options"
const TILE := Vector2(430, 338)
const OPTIONS := [
	["", "Hiện tại", "Viền sáng kép · nền phủ kín"],
	["A", "Khay carton", "Carton ấm · mặt lót theo độ hiếm"],
	["B", "Nẹp thép", "Góc vát · nẹp thép liền khối"],
	["C", "Tem kho", "Hai cạnh khoét · một nét bao gọn"],
	["D", "Nẹp bốn góc", "Bốn nẹp rời · mặt thoáng"],
	["E", "Dải Lv riêng", "Tách thông tin · vũ khí ở giữa"],
]
const ITEMS := [["hero_w_kiem","green"],["hero_w_cung","blue"],["hero_w_gay_phep","purple"],["hero_w_riu","purple"],["hero_w_katana","orange"]]
var _textures := {}

func _ready() -> void:
	get_window().content_scale_size = Vector2i(900, 1188)
	get_window().size = Vector2i(900, 1188)
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var bg := ColorRect.new()
	bg.color = Color("b6cbc3")
	bg.size = Vector2(900,1188)
	add_child(bg)
	_text("KHUNG VŨ KHÍ · 5 PHƯƠNG ÁN", Vector2(22,17), Vector2(856,42),30)
	_text("Cùng cỡ vũ khí · hàng nhỏ = 5 ô ở màn 360px · khung phẳng, không bóng",Vector2(22,61),Vector2(856,28),17)
	for i in OPTIONS.size():
		_option(OPTIONS[i],Vector2(14+(i%2)*442,104+(i/2)*346))
	_text("Bản thử để duyệt · Có thể dùng chung cho mũ, giáp và giày",Vector2(20,1146),Vector2(860,28),17)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT.path_join("preview.png")))
	print("Frame proposals rendered: ",image.get_size())
	get_tree().quit()

func _option(data: Array, at: Vector2) -> void:
	var tile := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("dbe5da") if data[0] != "" else Color("cfdad1")
	style.set_corner_radius_all(18)
	tile.add_theme_stylebox_override("panel",style)
	tile.position=at
	tile.size=TILE
	add_child(tile)
	var title: String = data[1] if data[0] == "" else data[0]+" · "+data[1]
	_text(title,at+Vector2(16,11),Vector2(398,33),25)
	_text(data[2],at+Vector2(12,48),Vector2(406,26),17)
	_place_card(data[0],"hero_w_kiem","green","12",true,at+Vector2(137,84),156)
	for j in ITEMS.size():
		_place_card(data[0],ITEMS[j][0],ITEMS[j][1],"12",j==0,at+Vector2(48+j*67,264),59)

func _place_card(key: String, item: String, tone: String, level: String, upgrade: bool, at: Vector2, display: float) -> void:
	var card := Ui.gear_card(item,"slot_weapon",tone,level,118,upgrade)
	card.size=Vector2(118,118)
	if key != "":
		var panel: PanelContainer = card.get_child(0)
		panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
		var face := TextureRect.new()
		face.texture = _texture(key,tone)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_SCALE
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(face)
		card.move_child(face,0)
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.position=at
	card.scale=Vector2.ONE*(display/118.0)
	add_child(card)

func _texture(key: String, tone: String) -> Texture2D:
	var id := key+"-"+tone
	if not _textures.has(id):
		var image := Image.new()
		var error := image.load_svg_from_string(FileAccess.get_file_as_string(OUT.path_join("svg/"+id+".svg")),3.0)
		assert(error == OK)
		_textures[id] = ImageTexture.create_from_image(image)
	return _textures[id]

func _text(value: String, at: Vector2, bounds: Vector2, font_size: int) -> void:
	var label := Ui.label(value,"",font_size)
	label.position=at
	label.size=bounds
	label.add_theme_color_override("font_color",Color("583f21"))
	label.add_theme_constant_override("outline_size",0)
	add_child(label)
