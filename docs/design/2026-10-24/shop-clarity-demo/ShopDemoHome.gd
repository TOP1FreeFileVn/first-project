extends "res://game/menu/Home.gd"

# Isolated preview backdrop. The regular Home scene and its palette stay intact.
const DEMO_PATTERN = preload("res://docs/design/2026-10-24/shop-clarity-demo/quiet_pattern.gdshader")
var proposed := true
var palette_mode := 1
var _original_pattern: Material
var _quiet_pattern: ShaderMaterial


func _update_backdrop() -> void:
	if _original_pattern != null:
		_pattern_backdrop.material = _original_pattern
	super._update_backdrop()
	if _original_pattern == null:
		_original_pattern = _pattern_backdrop.material
		_quiet_pattern = ShaderMaterial.new()
		_quiet_pattern.shader = DEMO_PATTERN
		_quiet_pattern.set_shader_parameter("tile", Ui.tex("bg_tile"))
	if proposed and active_menu_context() == "shop":
		_pattern_backdrop.material = _quiet_pattern
		var paint := Color("345873") if palette_mode != 2 else Color("355e65")
		_pattern_backdrop.color = paint
		_quiet_pattern.set_shader_parameter("sky", paint)
	else:
		_pattern_backdrop.material = _original_pattern
		_original_pattern.set_shader_parameter("sky", Ui.menu_pattern_color(active_menu_context()))
