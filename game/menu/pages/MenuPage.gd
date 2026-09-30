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
func title(text: String, color := UiKit.Ribbon.BLUE) -> void:
	body.add_child(UiKit.ribbon(text, 26, color))


func panel(separation := 10) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel_style())
	body.add_child(p)
	var box := UiKit.vbox(separation)
	p.add_child(box)
	return box
