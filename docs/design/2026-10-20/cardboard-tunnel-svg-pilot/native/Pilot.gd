extends Node2D

# Isolated, original vector interaction pilot. No game autoloads or player save.
const INK := Color("583f21")
const PROP_ORIGIN := Vector2(128, 224)
const CAT_ORIGIN := Vector2(128, 238)
const PROP_SCALE := 1.18
const CAT_SCALE := 0.5
const CYCLE := 23.0

var folder: String
var project_folder: String
var font: FontFile
var body_font: FontFile
var depth: Node2D
var prop: Node2D
var slot: Node2D
var cat: Node2D
var shadow: Polygon2D
var front_pose: Node2D
var foot_pivots: Array[Node2D] = []
var prop_parts: Dictionary = {}
var part_home: Dictionary = {}
var state_label: Label
var detail_label: Label
var parent_label: Label
var progress: ProgressBar
var pause_button: Button
var clock := 0.0
var paused := false
var exploded := false
var mode := "all"
var capture := false
var latest_state := ""
var state_proofs: Dictionary = {}
var texture_cache: Dictionary = {}
var prop_kind := "tunnel"
var title_label: Label
var rows_labels: Array[Label] = []


func _ready() -> void:
	folder = ProjectSettings.globalize_path("res://..").simplify_path()
	project_folder = folder.path_join("../../../..").simplify_path()
	font = FontFile.new()
	assert(font.load_dynamic_font(project_folder.path_join("game/ui/fonts/PaytoneOne-Regular.ttf")) == OK)
	body_font = FontFile.new()
	assert(body_font.load_dynamic_font(project_folder.path_join("game/ui/fonts/DejaVuSans.ttf")) == OK)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for arg in OS.get_cmdline_user_args():
		if arg == "--bed":
			prop_kind = "bed"
	_build_world()
	_build_ui()
	for arg in OS.get_cmdline_user_args():
		if arg == "--capture":
			capture = true
	_pose(0.0)
	if capture:
		set_process(false)
		_capture_demo.call_deferred()
	queue_redraw()


func _texture(path: String) -> Texture2D:
	if texture_cache.has(path):
		return texture_cache[path]
	var image := Image.new()
	assert(image.load_svg_from_string(FileAccess.get_file_as_string(path)) == OK, path)
	var texture := ImageTexture.create_from_image(image)
	texture_cache[path] = texture
	return texture


func _part(parent: Node2D, path: String, origin: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _texture(path)
	sprite.centered = false
	sprite.position = -origin
	parent.add_child(sprite)
	return sprite


func _build_world() -> void:
	depth = Node2D.new()
	depth.name = "DepthWorld"
	depth.y_sort_enabled = true
	add_child(depth)
	_build_prop()
	cat = Node2D.new()
	cat.name = "CatFloorRoot"
	depth.add_child(cat)
	shadow = Polygon2D.new()
	shadow.name = "ContactShadow"
	var points := PackedVector2Array()
	for i in 32:
		var angle := TAU * float(i) / 32.0
		points.append(Vector2(cos(angle)*43.0, sin(angle)*9.0-2.0))
	shadow.polygon = points
	shadow.color = Color(0.34, 0.43, 0.22, 0.22)
	cat.add_child(shadow)
	front_pose = _cat_pose()


func _build_prop() -> void:
	prop = Node2D.new()
	prop.name = "BedDepthRoot" if prop_kind == "bed" else "TunnelDepthRoot"
	prop.position = Vector2(380, 470)
	prop.scale = Vector2.ONE * PROP_SCALE
	prop.y_sort_enabled = false
	depth.add_child(prop)
	var art_folder := "bed-art" if prop_kind == "bed" else "art"
	for key in ["shadow", "rear", "interior"]:
		var sprite := _part(prop, folder.path_join(art_folder + "/" + key + ".svg"), PROP_ORIGIN)
		sprite.name = key
		prop_parts[key] = sprite
		part_home[key] = sprite.position
	slot = Node2D.new()
	slot.name = "OccupantSlot"
	# Compensate the prop scale so reparenting does not scale the cat.
	slot.scale = Vector2.ONE / PROP_SCALE
	prop.add_child(slot)
	var front := _part(prop, folder.path_join(art_folder + "/front.svg"), PROP_ORIGIN)
	front.name = "front"
	prop_parts["front"] = front
	part_home["front"] = front.position


func _cat_pose() -> Node2D:
	var visual := Node2D.new()
	visual.name = "FrontVisual"
	visual.scale = Vector2.ONE * CAT_SCALE
	cat.add_child(visual)
	# Art direction: the cat always presents its original front face.
	var source := project_folder.path_join("docs/design/2026-10-20/cat-spine-parts/svg/cat_tabby")
	var layers := ["tail", "foot_L_image", "foot_R_image", "body", "paw_L_image", "paw_R_image", "head"]
	for layer: String in layers:
		if layer.begins_with("foot_"):
			var pivot := Node2D.new()
			pivot.name = layer
			var at := Vector2(82,203) if layer == "foot_L_image" else Vector2(174,203)
			pivot.position = at - CAT_ORIGIN
			visual.add_child(pivot)
			_part(pivot, source.path_join(layer + ".svg"), at)
			foot_pivots.append(pivot)
		else:
			_part(visual, source.path_join(layer + ".svg"), CAT_ORIGIN)
	return visual


func _label(text: String, position_px: Vector2, width: float, size_px: int, heading := false) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position_px
	label.size.x = width
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", font if heading else body_font)
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _button(text: String, at: Vector2, width: float, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = Vector2(width, 42)
	button.add_theme_font_override("font", body_font)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", INK)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f8e1ab")
	style.border_color = INK
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("ffe9b6")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("e4c78d")
	button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(callback)
	add_child(button)
	return button


func _build_ui() -> void:
	title_label = _label("", Vector2(32,22), 710, 30, true)
	_label("Bản thử SVG · mèo luôn hiện mặt trước khi di chuyển", Vector2(34,76), 1000, 18)
	_button("Ống chui", Vector2(780,28), 134, func(): _select_prop("tunnel"))
	_button("Khay nghỉ", Vector2(928,28), 140, func(): _select_prop("bed"))
	_label("01 · THỬ TRONG CẢNH", Vector2(50,139), 650, 17, true)
	_label("Các lớp tách riêng", Vector2(780,148), 285, 23, true)
	var rows := [["Vỏ trước", "Vòm cửa và hai bên hộp", "edc98c"], ["Mèo", "Giữ nguyên cỡ khi vào ống", "f9d27b"], ["Lòng ống", "Sàn và mặt trong phía sau", "b78751"], ["Bóng", "Nằm dưới điểm tiếp đất", "a8b877"]]
	for i in rows.size():
		var item: Array = rows[i]
		var color := ColorRect.new()
		color.position = Vector2(782, 203+i*57)
		color.size = Vector2(12,39)
		color.color = Color(item[2])
		color.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(color)
		rows_labels.append(_label(item[0], Vector2(808,199+i*57), 250, 18, true))
		rows_labels.append(_label(item[1], Vector2(808,225+i*57), 250, 13))
	state_label = _label("", Vector2(780,455), 270, 23, true)
	detail_label = _label("", Vector2(780,498), 270, 16)
	parent_label = _label("", Vector2(50,612), 650, 15)
	_label("Chỉ dùng dáng mặt trước.\nBước chân còn ở mức thử\nchuyển động, chưa phải Spine.", Vector2(780,603), 270, 13)
	progress = ProgressBar.new()
	progress.position = Vector2(50,652)
	progress.size = Vector2(660,7)
	progress.show_percentage = false
	progress.max_value = CYCLE
	add_child(progress)
	_button("Tự chạy", Vector2(32,704), 138, func(): mode="all"; clock=0.0; paused=false; _reset_exploded())
	_button("Đi trước / sau", Vector2(184,704), 180, func(): mode="depth"; clock=0.0; paused=false; _reset_exploded())
	_button("Vào / ra", Vector2(378,704), 150, func(): mode="portal"; clock=14.0; paused=false; _reset_exploded())
	_button("Tách lớp", Vector2(542,704), 150, func(): exploded=not exploded; queue_redraw())
	pause_button = _button("Tạm dừng", Vector2(706,704), 170, func(): paused=not paused; pause_button.text="Tiếp tục" if paused else "Tạm dừng")
	_button("Từ đầu", Vector2(890,704), 178, func(): clock=0.0; mode="all"; paused=false; _reset_exploded())
	_update_prop_labels()


func _select_prop(kind: String) -> void:
	if kind != prop_kind:
		# Move the actor out before freeing its previous occupant slot.
		if cat.get_parent() != depth:
			cat.reparent(depth, true)
		prop.free()
		prop_parts.clear()
		part_home.clear()
		prop_kind = kind
		_build_prop()
	clock = 14.0
	mode = "portal"
	paused = false
	_reset_exploded()
	_update_prop_labels()
	_pose(clock)


func _update_prop_labels() -> void:
	var bed := prop_kind == "bed"
	title_label.text = "KHAY NGHỈ HỘP GIẤY" if bed else "ỐNG CHUI HỘP GIẤY"
	rows_labels[0].text = "Thành trước" if bed else "Vỏ trước"
	rows_labels[1].text = "Hai góc khay, lối giữa mở" if bed else "Vòm cửa và hai bên hộp"
	rows_labels[3].text = "Luôn hiện mặt trước, cùng cỡ"
	rows_labels[4].text = "Lòng khay" if bed else "Lòng ống"
	rows_labels[5].text = "Đệm và mặt trong phía sau" if bed else "Sàn và mặt trong phía sau"


func _reset_exploded() -> void:
	exploded = false
	pause_button.text = "Tạm dừng"
	queue_redraw()


func _process(delta: float) -> void:
	if not paused and not exploded:
		clock += minf(delta, 0.05)
		if mode == "depth" and clock >= 11.0:
			clock = 0.0
		elif mode == "portal" and clock >= 22.3:
			clock = 14.0
		elif clock >= CYCLE:
			clock = 0.0
	_pose(clock)


func _interpolate(a: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(b, clampf(t, 0.0, 1.0))


func _pose(time: float) -> void:
	var p := Vector2(160,560)
	var inside := false
	var walking := true
	var state := "Đi phía trước"
	var detail := "Mèo đứng trước mặt hộp."
	if time < 4.0:
		p = _interpolate(Vector2(160,560), Vector2(600,560), time/4.0)
	elif time < 5.5:
		p = _interpolate(Vector2(600,560), Vector2(600,423), (time-4.0)/1.5)
		state = "Vòng ra phía sau"
		detail = "Đi vòng bên phải, không xuyên hộp."
	elif time < 9.5:
		p = _interpolate(Vector2(600,423), Vector2(160,423), (time-5.5)/4.0)
		state = "Đi phía sau"
		detail = "Hộp che mèo theo vị trí chân."
	elif time < 11.0:
		p = _interpolate(Vector2(160,423), Vector2(160,560), (time-9.5)/1.5)
		state = "Vòng về phía trước"
		detail = "Giữ một lối đi bên ngoài vật thể."
	elif time < 14.0:
		p = _interpolate(Vector2(160,560), Vector2(380,560), (time-11.0)/3.0)
		state = "Tới trước cửa"
		detail = "Canh giữa cửa trước khi đi vào."
	elif time < 15.5:
		p = _interpolate(Vector2(380,560), Vector2(380,484), (time-14.0)/1.5)
		state = "Tới ngưỡng cửa"
		detail = "Luôn hiện mặt trước; giữ nguyên kích thước."
	elif time < 17.0:
		p = _interpolate(Vector2(380,484), Vector2(380,454), (time-15.5)/1.5)
		inside = true
		state = "Đang chui vào"
		detail = "Mèo nằm giữa lòng ống và vỏ trước."
	elif time < 19.0:
		p = Vector2(380,454)
		walking = false
		inside = true
		state = "Ngồi trong ống"
		detail = "Nhìn ra cửa; vòm trước bao quanh mèo."
	elif time < 20.8:
		p = _interpolate(Vector2(380,454), Vector2(380,528), (time-19.0)/1.8)
		inside = p.y < 484.0
		state = "Đi ra ngoài"
		detail = "Qua cửa rồi trở lại lớp ngoài sân."
	else:
		p = _interpolate(Vector2(380,528), Vector2(600,560), (time-20.8)/2.2)
		state = "Trở lại sân"
		detail = "Có thể tiếp tục đi ngang trước hộp."
	if prop_kind == "bed":
		if time >= 14.0 and time < 15.5:
			state = "Tới lối vào khay"
			detail = "Lối giữa mở, không bước xuyên thành."
		elif time >= 15.5 and time < 17.0:
			state = "Bước vào khay"
			detail = "Giữ mặt trước, chân tiến lên đệm."
		elif time >= 17.0 and time < 19.0:
			state = "Nghỉ trên đệm"
			detail = "Mèo ngồi giữa khay; hai góc ở phía trước."
		elif time >= 19.0 and time < 20.8:
			state = "Rời khay"
			detail = "Ra cùng lối giữa, luôn hiện mặt trước."
	var parent: Node2D = slot if inside else depth
	if cat.get_parent() != parent:
		cat.reparent(parent, true)
	cat.global_position = p
	# Reparenting must preserve the world scale as well as the position.
	cat.global_scale = Vector2.ONE
	front_pose.visible = true
	var phase := time * TAU * 2.0
	var amount := 1.0 if walking else 0.0
	for i in foot_pivots.size():
		var pivot: Node2D = foot_pivots[i]
		var side := 1.0 if i%2 == 0 else -1.0
		pivot.rotation = sin(phase)*0.11*side*amount
		var at := Vector2(82,203) if i%2 == 0 else Vector2(174,203)
		pivot.position = at - CAT_ORIGIN + Vector2(0,-maxf(0.0,sin(phase)*side)*3.0*amount)
	front_pose.position.y = -absf(sin(phase))*1.3*amount
	for key: String in prop_parts:
		var sprite: Sprite2D = prop_parts[key]
		var offset := Vector2.ZERO
		if exploded:
			offset = {"shadow":Vector2(0,65),"rear":Vector2(-135,-35),"interior":Vector2(-70,-5),"front":Vector2(135,25)}[key]
		sprite.position = part_home[key] + offset
	if exploded:
		if cat.get_parent() != slot:
			cat.reparent(slot,true)
		cat.global_position = Vector2(380,454)
		cat.global_scale = Vector2.ONE
		front_pose.visible = true
		state = "Các lớp rời"
		detail = "Lòng ở sau · mèo ở giữa · vỏ ở trước."
	state_label.text = state
	detail_label.text = detail
	var object_name := "khay" if prop_kind == "bed" else "ống"
	parent_label.text = "Mèo luôn hiện mặt trước · " + ("Đang trong " + object_name if cat.get_parent()==slot else "Đang ngoài sân")
	progress.value = time
	latest_state = state
	state_proofs[state] = true


func _draw() -> void:
	draw_rect(Rect2(0,0,1100,760), Color("e9efdf"))
	var stage_style := StyleBoxFlat.new()
	stage_style.bg_color = Color("cbd79b")
	stage_style.set_corner_radius_all(22)
	draw_style_box(stage_style, Rect2(28,122,704,560))
	var sky_style := StyleBoxFlat.new()
	sky_style.bg_color = Color("c5dfda")
	sky_style.corner_radius_top_left = 22
	sky_style.corner_radius_top_right = 22
	draw_style_box(sky_style, Rect2(28,122,704,150))
	draw_colored_polygon(PackedVector2Array([Vector2(28,275),Vector2(28,234),Vector2(120,215),Vector2(230,244),Vector2(370,224),Vector2(510,246),Vector2(640,214),Vector2(732,230),Vector2(732,282)]),Color("afc596"))
	draw_colored_polygon(PackedVector2Array([Vector2(295,682),Vector2(510,682),Vector2(455,587),Vector2(428,520),Vector2(336,520),Vector2(342,584)]),Color("e9d4a0"))
	for at in [Vector2(80,374),Vector2(670,390),Vector2(101,585),Vector2(647,581)]:
		_grass_ellipse(at, Vector2(5,10),Color("a6ba76"))
		_grass_ellipse(at+Vector2(9,2),Vector2(4,7),Color("a6ba76"))
		_grass_ellipse(at+Vector2(-8,4),Vector2(4,6),Color("a6ba76"))
	var side_style := StyleBoxFlat.new()
	side_style.bg_color = Color("f4edda")
	side_style.set_corner_radius_all(22)
	draw_style_box(side_style, Rect2(752,122,320,560))


func _grass_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var polygon := PackedVector2Array()
	for i in 32:
		var angle := TAU*float(i)/32.0
		polygon.append(center + Vector2(cos(angle)*radius.x, sin(angle)*radius.y))
	draw_colored_polygon(polygon, color)


func _capture_demo() -> void:
	var capture_folder := folder.path_join("bed-preview") if prop_kind == "bed" else folder
	var output := capture_folder.path_join("capture")
	DirAccess.make_dir_recursive_absolute(output)
	var checkpoints := {0:"01-front",72:"02-behind",160:"03-entering",180:"04-inside",200:"05-exiting"}
	for frame in 230:
		_pose(float(frame)/10.0)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		assert(image.save_png(output.path_join("frame_%03d.png" % frame)) == OK)
		if checkpoints.has(frame):
			assert(image.save_png(capture_folder.path_join(checkpoints[frame]+".png")) == OK)
	var captured_kind := prop_kind
	var captured_states := state_proofs.keys()
	for kind: String in ["tunnel" if prop_kind == "bed" else "bed", captured_kind]:
		_select_prop(kind)
		_pose(18.0)
		assert(is_instance_valid(cat) and cat.get_parent() == slot)
		assert(cat.global_scale.is_equal_approx(Vector2.ONE) and front_pose.visible)
		assert(front_pose.get_node_or_null("RearVisual") == null)
	exploded = true
	_pose(18.0)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(capture_folder.path_join("06-layers.png")) == OK)
	var validation := {"isolated_project":true,"production_code_modified":false,"prop":prop_kind,"resolution":[1100,760],"frames":230,"fps":10,"duration_seconds":23,"states":captured_states,"cat_alpha":cat.modulate.a,"cat_global_scale":[cat.global_scale.x,cat.global_scale.y],"depth_sort_enabled":depth.y_sort_enabled,"same_z_index":depth.z_index==prop.z_index and prop.z_index==cat.z_index,"front_pose_source":"cat-spine-parts/svg/cat_tabby","pose_policy":"front_only_all_states","rear_pose_loaded":false,"switch_props_while_occupied_checked":true,"exploded_view_checked":true,"scope":"Vector occlusion pilot; front-facing cat by design, simple foot motion, no Spine runtime."}
	var file := FileAccess.open(capture_folder.path_join("demo-validation.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(validation,"\t"))
	print("TUNNEL_PILOT_CAPTURE_COMPLETE ",JSON.stringify(validation))
	get_tree().quit()
