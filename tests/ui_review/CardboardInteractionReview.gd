extends Node

# Deterministic production-world review; no game save mutations or battle routing.
const WORLD = preload("res://game/menu/lobby/CardboardLobby.gd")
const OUT := "res://docs/ui_review/2026-10-20/approved-integration/interactions"
const PHASES := [0.0, 6.5, 7.95, 8.0, 8.05, 10.0, 22.95, 23.0, 23.05, 24.0, 25.0]

var _lobby
var _failures: Array = []
var _timeline: Array = []
var _captures: Array = []
var _handoffs: Array = []
var _max_step := 0.0
var _samples := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	get_window().size = Vector2i(720, 1280)
	_lobby = WORLD.new()
	add_child(_lobby)
	_lobby.set_active(true)
	_lobby.set_process(false)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_check_textures(_lobby)
	_review_cycle()
	await _capture_phases()
	var result := {
		"sample_rate_hz": 20, "duration_seconds": 28, "samples": _samples,
		"failures": _failures, "max_logical_step_pixels": _max_step,
		"handoffs": _handoffs, "captures": _captures, "timeline": _timeline,
	}
	var file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("CARDBOARD_INTERACTION_REVIEW samples=", _samples, " handoffs=", _handoffs.size(), " failures=", _failures.size(), " max_step=", _max_step)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _review_cycle() -> void:
	var previous: Dictionary = {}
	var ids: Dictionary = {}
	var actors: Dictionary = _lobby.get("_actors")
	var props: Dictionary = _lobby.get("_props")
	var world: Node2D = _lobby.get("_world")
	var depth: Node2D = _lobby.get("_depth")
	for kind in props:
		var root: Node2D = props[kind].root
		var slot: Node2D = props[kind].slot
		_check(not root.y_sort_enabled, "fixed_prop_internal_depth", 0, kind)
		_check(root.get_child_count() == 5 and root.get_child(3) == slot, "rear_interior_slot_front_order", 0, kind)
	for i in 561:
		var clock := float(i) / 20.0
		_lobby.set("_clock", clock)
		_lobby.call("_pose")
		_samples += 1
		var sample := {"clock": clock, "actors": [], "reservations": {}}
		for key in actors:
			var data: Dictionary = actors[key]
			var actor: Node2D = data.root
			var pose: Node2D = data.pose
			var p: Vector2 = data.position
			var parent: Node2D = actor.get_parent()
			if not ids.has(key):
				ids[key] = actor.get_instance_id()
			_check(ids[key] == actor.get_instance_id(), "stable_actor_identity", clock, key)
			_check(actor.global_scale.is_equal_approx(world.global_scale), "constant_global_actor_scale", clock, key)
			_check(pose.scale.is_equal_approx(Vector2.ONE * 0.37), "constant_positive_front_pose_scale", clock, key)
			_check(is_zero_approx(actor.rotation) and is_zero_approx(pose.rotation), "no_front_pose_flip_or_rotation", clock, key)
			_check(actor.is_visible_in_tree() and is_equal_approx(actor.modulate.a, 1.0) and is_equal_approx(pose.modulate.a, 1.0), "no_actor_hiding_or_fading", clock, key)
			_check(actor.global_position.distance_to(world.to_global(p)) < 0.001, "position_matches_logical_world_after_reparent", clock, key)
			_check(pose.get_child_count() == 7, "seven_front_parts_preserved", clock, key)
			if previous.has(key):
				var distance: float = p.distance_to(previous[key].position)
				_max_step = maxf(_max_step, distance)
				_check(distance <= 1.3, "continuous_position_20hz", clock, key)
				if previous[key].parent != parent.get_instance_id():
					_handoffs.append({"clock": clock, "actor": key, "distance_px": distance, "parent": str(parent.name)})
					_check(distance <= 1.3, "handoff_has_no_position_pop", clock, key)
			previous[key] = {"position": p, "parent": parent.get_instance_id()}
			sample.actors.append({"name": key, "position": [p.x, p.y], "state": data.state, "parent": str(parent.name), "scale": [actor.global_scale.x, actor.global_scale.y]})
		for kind in props:
			var prop: Dictionary = props[kind]
			var expected: String = "cream" if kind == "tunnel" else "calico"
			_check(prop.reservation == expected, "stable_exclusive_reservation", clock, kind)
			_check(prop.occupant == "" or prop.occupant == expected, "occupant_owns_reservation", clock, kind)
			var actual: Array = []
			for key in actors:
				if actors[key].root.get_parent() == prop.slot:
					actual.append(key)
			_check(actual.size() <= 1, "one_actor_per_prop_slot", clock, kind)
			_check((actual.is_empty() and prop.occupant == "") or (actual.size() == 1 and prop.occupant == actual[0]), "occupancy_matches_scene_parent", clock, kind)
			sample.reservations[kind] = {"reserved_by": prop.reservation, "occupant": prop.occupant}
		_check(actors.tabby.root.get_parent() == depth, "tabby_never_steals_prop", clock, "tabby")
		_timeline.append(sample)
	_check(_handoffs.size() == 4, "two_handoffs_per_resident_cycle", 28, "all")


func _capture_phases() -> void:
	for kind in ["tunnel", "bed"]:
		for phase: float in PHASES:
			var clock := phase if kind == "tunnel" else fposmod(phase - 2.0, 28.0)
			_lobby.set("_clock", clock)
			_lobby.call("_pose")
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			_check(img.get_size() == Vector2i(720, 1280), "native_capture_size", clock, kind)
			var region := Rect2i(15, 620, 300, 300) if kind == "tunnel" else Rect2i(380, 700, 300, 300)
			var crop := img.get_region(region)
			var filename := "%s_phase_%05.2f.png" % [kind, phase]
			var err := crop.save_png(OUT + "/" + filename)
			_check(err == OK, "capture_saved", clock, kind)
			_captures.append({"kind": kind, "clock": clock, "local_phase": phase, "file": filename})


func _check(ok: bool, label: String, clock: float, subject: String) -> void:
	if not ok:
		var item := {"label": label, "clock": clock, "subject": subject}
		_failures.append(item)
		push_error("CARDBOARD_INTERACTION_FAILURE " + JSON.stringify(item))


func _check_textures(node: Node) -> void:
	if node is Sprite2D:
		_check(node.texture != null, "all_production_sprite_textures_loaded", 0, str(node.get_path()))
	for child in node.get_children():
		_check_textures(child)
