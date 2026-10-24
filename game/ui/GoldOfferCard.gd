extends PanelContainer

## A gold offer uses its generated pack illustration, original buttons and game font.
## Spending and daily eligibility belong to PlayerData, never this presentation.
signal selected(offer_id: String)

const Ui = preload("res://game/ui/Ui.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const BACKDROP = preload("res://game/ui/gem_pack_backdrop.gdshader")
const BROWN := Color("583f21")

var offer_id := ""
var purchase_button: Button
var _status: Label
var _amount: Label
var _art: TextureRect
var _offer: Dictionary


func _init(offer: Dictionary) -> void:
	_offer = offer.duplicate(true)
	offer_id = str(offer["id"])
	name = "GoldOffer_" + offer_id
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_meta("shop_gold_offer", offer_id)
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
	backdrop.name = "GoldOfferBackdrop"
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = BACKDROP
	material.set_shader_parameter("top_color", Color("fff0ba"))
	material.set_shader_parameter("bottom_color", Color("edc370"))
	material.set_shader_parameter("light_color", Color("fff8d8"))
	material.set_shader_parameter("pedestal_color", Color("c18a3b"))
	backdrop.material = material
	backdrop.resized.connect(func(): material.set_shader_parameter("rect_size", backdrop.size))
	add_child(backdrop)
	var box := Ui.vbox(4)
	add_child(box)
	var amount_row := Ui.hbox(6)
	amount_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(amount_row)
	amount_row.add_child(Ui.icon("coin", 26))
	_amount = _copy(UiKit.format_number(int(offer["gold"])), 29)
	_amount.name = "GoldOfferAmount_" + offer_id
	amount_row.add_child(_amount)
	_art = TextureRect.new()
	_art.name = "GoldOfferIllustration_" + offer_id
	_art.custom_minimum_size = Vector2(0, 166)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_art)
	_set_illustration(int(offer["art_level"]))
	_status = _copy("Mỗi ngày 1 lần" if offer_id == "daily_gold" else "Đổi kim cương", 21)
	_status.name = "DailyGoldStatus" if offer_id == "daily_gold" else "GoldOfferStatus_" + offer_id
	box.add_child(_status)
	purchase_button = Ui.button("", "Green" if offer_id == "daily_gold" else "Yellow", Vector2(0, 70), 24)
	purchase_button.name = "DailyGoldClaim" if offer_id == "daily_gold" else "GoldExchangeBuy_" + offer_id
	purchase_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	purchase_button.add_theme_font_override("font", UiKit.game_font())
	purchase_button.add_theme_constant_override("outline_size", 4)
	purchase_button.add_theme_color_override("font_outline_color", Color("352719"))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		purchase_button.add_theme_color_override(state, Color.WHITE)
	if offer_id != "daily_gold":
		purchase_button.icon = Ui.icon_tex("gem", 26)
		purchase_button.add_theme_constant_override("icon_max_width", 26)
		purchase_button.add_theme_constant_override("h_separation", 6)
	purchase_button.pressed.connect(func(): selected.emit(offer_id))
	box.add_child(purchase_button)
	set_available(true)


func set_available(available: bool, claimed := false) -> void:
	purchase_button.disabled = not available
	if offer_id == "daily_gold":
		purchase_button.text = "ĐÃ NHẬN" if claimed else "MIỄN PHÍ"
		_status.text = "Mai nhận tiếp" if claimed else "Mỗi ngày 1 lần"
		purchase_button.tooltip_text = "%s vàng miễn phí mỗi ngày · Làm mới lúc 00:00" % UiKit.format_number(int(_offer["gold"]))
	else:
		purchase_button.text = UiKit.format_number(int(_offer["gems"]))
		purchase_button.tooltip_text = "Đổi %s kim cương lấy %s vàng" % [UiKit.format_number(int(_offer["gems"])), UiKit.format_number(int(_offer["gold"]))]
		_status.text = "Đổi kim cương" if available else "Thiếu kim cương"


func update_offer(offer: Dictionary) -> void:
	# Keep displayed prices aligned with live balance edits as well as eligibility.
	_offer = offer.duplicate(true)
	_amount.text = UiKit.format_number(int(_offer["gold"]))
	_set_illustration(int(_offer["art_level"]))


func _set_illustration(level: int) -> void:
	var illustration_path := "res://game/ui/art/shop_gold_packs/%02d.png" % clampi(level, 1, 6)
	if str(get_meta("shop_gold_illustration", "")) == illustration_path:
		return
	_art.texture = null
	if ResourceLoader.exists(illustration_path):
		_art.texture = load(illustration_path) as Texture2D
	set_meta("shop_gold_illustration", illustration_path)


func _copy(text: String, font_size: int) -> Label:
	var label := Ui.label(text, "", font_size)
	label.add_theme_font_override("font", UiKit.game_font())
	label.add_theme_color_override("font_color", BROWN)
	label.add_theme_constant_override("outline_size", 0)
	return label
