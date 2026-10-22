extends Control

## A prominent upgrade prompt whose animation never changes the parent's hitbox.
## The host owns availability and clicks; hide this control when no upgrade is ready.
const ARROW := preload("res://game/ui/skin/icon_badge_up_96.svg")
const PULSE_SECONDS := 1.10
const BOB_PIXELS := 6.0

var _elapsed := 0.0
var _bob := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(48, 48)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)


func _ready() -> void:
	resized.connect(_update_pivot)
	_update_pivot()
	_sync_visibility()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree():
		_sync_visibility()


func _exit_tree() -> void:
	_reset_motion()
	set_process(false)


func _sync_visibility() -> void:
	_reset_motion()
	set_process(is_visible_in_tree())


func _reset_motion() -> void:
	_elapsed = 0.0
	_bob = 0.0
	queue_redraw()


func _update_pivot() -> void:
	pivot_offset = size * 0.5
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed = fmod(_elapsed + delta, PULSE_SECONDS)
	var rise := 0.5 - 0.5 * cos(TAU * _elapsed / PULSE_SECONDS)
	_bob = -BOB_PIXELS * rise
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5 + Vector2(0, _bob)
	draw_set_transform(center)
	draw_texture_rect(ARROW, Rect2(-size * 0.5, size), false)


func get_review_state() -> Dictionary:
	var visual_rect := Rect2(Vector2(0, _bob), size)
	return {
		"size": size,
		"visual_scale": 1.0,
		"bob": _bob,
		"visible": is_visible_in_tree(),
		"animating": is_processing(),
		"ink_rect": get_global_transform() * visual_rect,
		"hit_rect": get_global_rect(),
		"pulse_seconds": PULSE_SECONDS,
	}
