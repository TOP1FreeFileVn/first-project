extends PanelContainer

## Presentation only: the shop decides what happens after a pack is selected.
## In particular, this card never grants gems or starts a payment.
signal selected(pack_id: String)

const Ui = preload("res://game/ui/Ui.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const Catalog = preload("res://game/core/ShopCatalog.gd")
const BACKDROP = preload("res://game/ui/gem_pack_backdrop.gdshader")
const BROWN := Color("583f21")

var pack_id := ""
var purchase_button: Button
var _pack: Dictionary = {}
var _amount: Label
var _art: TextureRect


func _init(pack: Dictionary = {}) -> void:
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_meta("purchase_integrated", false)
	var face := StyleBoxFlat.new()
	face.bg_color = Color("faefd9")
	face.border_color = BROWN
	face.set_border_width_all(5)
	face.set_corner_radius_all(22)
	face.content_margin_left = 10
	face.content_margin_right = 10
	face.content_margin_top = 12
	face.content_margin_bottom = 12
	face.anti_aliasing = true
	add_theme_stylebox_override("panel", face)
	var backdrop := ColorRect.new()
	backdrop.name = "GemPackBackdrop"
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop_material := ShaderMaterial.new()
	backdrop_material.shader = BACKDROP
	backdrop.material = backdrop_material
	backdrop.resized.connect(func(): backdrop_material.set_shader_parameter("rect_size", backdrop.size))
	add_child(backdrop)
	var box := Ui.vbox(4)
	add_child(box)
	var amount_row := Ui.hbox(6)
	amount_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(amount_row)
	amount_row.add_child(Ui.icon("gem", 26))
	_amount = Ui.label("", "", 29)
	_amount.add_theme_font_override("font", UiKit.game_font())
	_amount.add_theme_color_override("font_color", BROWN)
	_amount.add_theme_constant_override("outline_size", 0)
	amount_row.add_child(_amount)
	_art = TextureRect.new()
	_art.custom_minimum_size = Vector2(0, 180)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_art)
	purchase_button = Ui.button("", "Yellow", Vector2(0, 70), 22)
	purchase_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	purchase_button.add_theme_font_override("font", UiKit.game_font())
	purchase_button.add_theme_constant_override("outline_size", 4)
	purchase_button.add_theme_color_override("font_outline_color", Color("352719"))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		purchase_button.add_theme_color_override(state, Color.WHITE)
	purchase_button.pressed.connect(func(): selected.emit(pack_id))
	box.add_child(purchase_button)
	configure(pack)


func configure(pack: Dictionary) -> void:
	_pack = pack.duplicate(true)
	pack_id = str(pack.get("id", ""))
	name = "GemPack_" + pack_id
	set_meta("shop_pack_id", pack_id)
	set_meta("shop_pack_gems", int(pack.get("gems", 0)))
	set_meta("shop_pack_price_vnd", int(pack.get("price_vnd", 0)))
	_amount.name = "GemPackAmount_" + pack_id
	_amount.text = UiKit.format_number(int(pack.get("gems", 0)))
	_art.name = "GemPackIllustration_" + pack_id
	var illustration_path := str(pack.get("illustration", ""))
	_art.texture = null
	if not illustration_path.is_empty() and ResourceLoader.exists(illustration_path):
		_art.texture = load(illustration_path) as Texture2D
	set_meta("shop_pack_illustration", illustration_path)
	purchase_button.name = "GemPackBuy_" + pack_id
	purchase_button.text = Catalog.format_vnd(int(pack.get("price_vnd", 0)))
	purchase_button.tooltip_text = "%s · %s" % [pack.get("name", "Kim cương"), purchase_button.text]
	purchase_button.disabled = pack_id.is_empty()


func get_pack() -> Dictionary:
	return _pack.duplicate(true)
