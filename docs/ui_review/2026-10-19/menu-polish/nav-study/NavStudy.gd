extends Node

const OUT := "res://docs/ui_review/2026-10-19/menu-polish/nav-study"
var home: Control
var block: PanelContainer
var footer: PanelContainer

func _ready() -> void:
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	get_window().size = Vector2i(450, 800)
	home = load("res://game/menu/Home.tscn").instantiate()
	add_child(home)
	home.select_tab(2, false)
	await get_tree().create_timer(0.2).timeout
	for tween: Tween in get_tree().get_processed_tweens():
		tween.pause()
	block = home._nav_holder.get_child(0).get_child(2)
	footer = block.find_child("SelectedNavFooter", true, false)
	print("NAV_STUDY_TRANSFORMS ", get_viewport().get_stretch_transform(), " global=", block.get_global_transform_with_canvas(), " rect=", block.get_global_rect())
	await _capture("default")
	block.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	await _capture("nearest")
	block.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE
	_snap_style(block, 0.0)
	_snap_style(footer, 0.0)
	await _capture("snap-whole")
	_snap_style(block, 0.5)
	_snap_style(footer, 0.5)
	await _capture("snap-half")
	_snap_style(block, 0.0)
	_snap_style(footer, 0.0)
	block.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	await _capture("snap-nearest")
	block.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE
	for window_size in [Vector2i(720, 1280), Vector2i(360, 640)]:
		block.remove_theme_stylebox_override("panel")
		footer.remove_theme_stylebox_override("panel")
		get_window().size = window_size
		await get_tree().process_frame
		await get_tree().process_frame
		await _capture("default-" + str(window_size.x))
		_snap_style(block, 0.0)
		_snap_style(footer, 0.0)
		await _capture("snap-whole-" + str(window_size.x))
	print("NAV_STUDY_COMPLETE")
	get_tree().quit()

func _snap_style(control: PanelContainer, phase: float) -> void:
	var sb := control.get_theme_stylebox("panel").duplicate() as StyleBoxTexture
	var rect := control.get_global_rect()
	var scale_factor := get_viewport().get_stretch_transform().x.x
	var left := (roundf(rect.position.x * scale_factor - phase) + phase) / scale_factor
	var right := (roundf(rect.end.x * scale_factor - phase) + phase) / scale_factor
	sb.expand_margin_left = rect.position.x - left
	sb.expand_margin_right = right - rect.end.x
	control.add_theme_stylebox_override("panel", sb)
	print("NAV_STUDY_SNAP ", control.name, " phase=", phase, " margins=", sb.expand_margin_left, ",", sb.expand_margin_right)

func _capture(key: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + "/" + key + ".png")
