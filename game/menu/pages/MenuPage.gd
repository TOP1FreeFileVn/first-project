extends Control

# Base for the five lobby pages. A page fills `body` in build(); refresh() rebuilds it
# after PlayerData changes. Live values (timers, patrol gold) update in tick() instead,
# so buttons aren't rebuilt under the player's finger every second.

const UiKit = preload("res://game/ui/UiKit.gd")
const Economy = preload("res://game/core/Economy.gd")

var home: Control
var body: VBoxContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 70)
	scroll.add_child(margin)
	body = UiKit.vbox(14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(body)


func refresh() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	build()


func build() -> void:
	pass


func tick() -> void:
	pass


func has_alert() -> bool:
	return false


# Helpers shared by pages.
## Opt in when a short page should fill the viewport. The scroll container still
## grows past the viewport when its content needs more room.
func fill_available_height(bottom_padding := 24) -> void:
	var margin := body.get_parent() as MarginContainer
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_bottom", bottom_padding)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL


func title(text: String, color := UiKit.Ribbon.BLUE) -> void:
	body.add_child(UiKit.ribbon(text, 26, color))


func panel(separation := 10) -> VBoxContainer:
	var context: String = get_script().resource_path.get_file().get_basename().trim_suffix("Page").to_snake_case()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel_style(context))
	p.set_meta("menu_panel_context", context)
	p.set_meta("menu_panel_kind", "Board")
	body.add_child(p)
	var box := UiKit.vbox(separation)
	p.add_child(box)
	return box


func section(heading: String, separation := 12) -> VBoxContainer:
	var context: String = get_script().resource_path.get_file().get_basename().trim_suffix("Page").to_snake_case()
	var box := UiKit.vbox(separation)
	body.add_child(UiKit.Ui.menu_section(context, heading, box))
	return box
