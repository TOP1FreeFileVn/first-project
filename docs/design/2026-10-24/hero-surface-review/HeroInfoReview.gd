extends "res://docs/design/2026-10-24/hero-surface-review/HeroOpenReview.gd"

## Framed information on the open hero composition, for user review.
const INFO_FILL := Color("2c414e")
const INFO_INK := Color("202e38")
const POWER_FILL := Color("f1d6a3")
const POWER_INK := Color("57432d")


func _init() -> void:
	design_slug = "framed"


func _apply_surface(variant: int) -> void:
	super(variant)
	var stage: Control = _page.find_child("HeroPreviewStage", true, false)
	# The thicker information plaque gets its own clearance under the idle sweep.
	stage.custom_minimum_size.y = 304
	var power: PanelContainer = stage.find_child("HeroCombatPower", true, false)
	power.custom_minimum_size = Vector2(240, 64)
	(power.get_parent() as Control).offset_top = -64
	power.add_theme_stylebox_override("panel", _frame(POWER_FILL, POWER_INK, Vector4(16, 4, 16, 4)))
	for label: Label in power.find_children("*", "Label", true, false):
		label.add_theme_color_override("font_color", POWER_INK)
		label.add_theme_constant_override("outline_size", 0)
	var surface: PanelContainer = _page.find_child("HeroPaperboardFolder", true, false)
	var column: VBoxContainer = surface.get_child(0)
	column.add_theme_constant_override("separation", 10)
	var stat_panel: PanelContainer = _page.find_child("EquipmentStat_hp", true, false).get_parent().get_parent()
	stat_panel.name = "HeroInfoStats"
	stat_panel.add_theme_stylebox_override("panel", _frame(INFO_FILL, INFO_INK, Vector4(16, 8, 16, 8)))
	var strip: HBoxContainer = column.get_child(2)
	strip.name = "HeroInfoAbilities"
	strip.add_theme_constant_override("separation", 10)
	var original := strip.get_children()
	var skill := Ui.hbox(8)
	var synergy := Ui.hbox(8)
	for index in original.size():
		var child: Node = original[index]
		strip.remove_child(child)
		if index == 2:
			child.queue_free()
		elif index < 2:
			skill.add_child(child)
		else:
			synergy.add_child(child)
	var skill_frame := _info_chip("HeroInfoSkill", skill)
	skill_frame.size_flags_stretch_ratio = 1.45
	strip.add_child(skill_frame)
	strip.add_child(_info_chip("HeroInfoSynergy", synergy))


func _info_chip(node_name: String, content: HBoxContainer) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.name = node_name
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.custom_minimum_size.y = 64
	frame.add_theme_stylebox_override("panel", _frame(INFO_FILL, INFO_INK, Vector4(14, 8, 14, 8)))
	frame.add_child(content)
	return frame


func _frame(fill: Color, ink: Color, margins: Vector4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = ink
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.anti_aliasing = true
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, margins[side])
	return style


func _audit_open() -> void:
	super()
	for name in ["HeroCombatPower", "HeroInfoStats", "HeroInfoSkill", "HeroInfoSynergy"]:
		var panel: PanelContainer = _page.find_child(name, true, false)
		var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
		_check(style != null and style.bg_color.a == 1.0 and style.border_width_left == 3, name + "_opaque_background_and_outline")
		var rect := panel.get_global_rect()
		_check(_page.get_global_rect().encloses(rect), name + "_fits_page")
		for label: Label in panel.find_children("*", "Label", true, false):
			_check(rect.grow(1).encloses(label.get_global_rect()), name + "_text_inside_frame")
