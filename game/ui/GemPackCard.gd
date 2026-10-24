extends PanelContainer

## Presentation only: the shop decides what happens after a pack is selected.
## In particular, this card never grants gems or starts a payment.
signal selected(pack_id: String)

const Ui = preload("res://game/ui/Ui.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const Catalog = preload("res://game/core/ShopCatalog.gd")
const BROWN := Color("583f21")

var pack_id := ""
var purchase_button: Button
var _pack: Dictionary = {}
var _amount: Label
var _art: Control


func _init(pack: Dictionary = {}) -> void:
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_meta("purchase_integrated", false)
	var face := StyleBoxFlat.new()
	face.bg_color = Color("eee2f3")
	face.border_color = BROWN
	face.set_border_width_all(5)
	face.set_corner_radius_all(22)
	face.content_margin_left = 14
	face.content_margin_right = 14
	face.content_margin_top = 12
	face.content_margin_bottom = 12
	face.anti_aliasing = true
	add_theme_stylebox_override("panel", face)
	var box := Ui.vbox(4)
	add_child(box)
	var amount_row := Ui.hbox(7)
	amount_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(amount_row)
	amount_row.add_child(Ui.icon("gem", 34))
	_amount = Ui.label("", "", 33)
	_amount.add_theme_font_override("font", UiKit.game_font())
	_amount.add_theme_color_override("font_color", BROWN)
	_amount.add_theme_constant_override("outline_size", 0)
	amount_row.add_child(_amount)
	var art_center := CenterContainer.new()
	art_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art_center)
	_art = Control.new()
	_art.name = "GemCluster"
	_art.custom_minimum_size = Vector2(238, 118)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_center.add_child(_art)
	purchase_button = Ui.button("", "Yellow", Vector2(0, 78), 28)
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
	purchase_button.name = "GemPackBuy_" + pack_id
	purchase_button.text = Catalog.format_vnd(int(pack.get("price_vnd", 0)))
	purchase_button.tooltip_text = "%s · %s" % [pack.get("name", "Kim cương"), purchase_button.text]
	purchase_button.disabled = pack_id.is_empty()
	_build_cluster(clampi(int(pack.get("art_level", 1)), 1, 6))


func get_pack() -> Dictionary:
	return _pack.duplicate(true)


func _build_cluster(level: int) -> void:
	for child in _art.get_children():
		_art.remove_child(child)
		child.queue_free()
	# Reuse the approved wide diamond. Each tier adds gems to the same stable
	# composition; no unrelated bags, boxes or promotional symbols are introduced.
	var pieces: Array = []
	match level:
		1:
			pieces = [Vector3(55, -2, 128)]
		2:
			pieces = [Vector3(27, 7, 112), Vector3(100, 7, 112)]
		3:
			pieces = [Vector3(8, 27, 94), Vector3(135, 27, 94), Vector3(55, -2, 128)]
		4:
			pieces = [Vector3(45, -8, 98), Vector3(108, -8, 98), Vector3(8, 31, 101), Vector3(123, 31, 101)]
		5:
			pieces = [Vector3(23, -5, 93), Vector3(123, -5, 93), Vector3(-1, 31, 101), Vector3(138, 31, 101), Vector3(60, 15, 118)]
		6:
			pieces = [Vector3(54, -13, 94), Vector3(95, -13, 94), Vector3(13, 3, 100), Vector3(125, 3, 100), Vector3(26, 23, 105), Vector3(109, 23, 105)]
	for piece in pieces:
		var gem := Ui.image("icon_gem", Vector2.ZERO)
		gem.position = Vector2(piece.x, piece.y)
		gem.size = Vector2(piece.z, piece.z)
		_art.add_child(gem)
