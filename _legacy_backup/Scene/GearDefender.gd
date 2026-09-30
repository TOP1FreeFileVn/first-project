extends Node2D

# A self-contained, five-wave tower defense demo using the project's Tiny Swords art.
const ART = "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/"
const SCREEN_SIZE = Vector2(1280, 720)
const CASTLE_X = 154.0
const LANES = [298.0, 405.0, 512.0]
const PADS = [
	Vector2(380, 230), Vector2(585, 230), Vector2(790, 230), Vector2(995, 230),
	Vector2(380, 614), Vector2(585, 614), Vector2(790, 614), Vector2(995, 614),
]
const MAX_WAVES = 5
const ARCHER_COST = 60
const GEAR_COST = 85
const UPGRADE_COST = 55

var castle_texture: Texture2D
var tower_texture: Texture2D
var archery_texture: Texture2D
var red_run_texture: Texture2D
var black_run_texture: Texture2D
var blue_archer_texture: Texture2D
var tree_texture: Texture2D
var bush_texture: Texture2D
var rock_texture: Texture2D
var font: Font

var towers: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var float_texts: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var selected_type := 0 # 0 = archer, 1 = gear cannon
var gold := 130
var castle_hp := 10
var wave := 0
var score := 0
var phase := "ready"
var spawn_left := 0
var spawn_clock := 0.0
var wave_clock := 0.0
var animation_clock := 0.0
var message := "Xây tháp rồi bấm BẮT ĐẦU để phòng thủ!"
var message_clock := 5.0

func _ready() -> void:
	rng.randomize()
	castle_texture = load(ART + "Buildings/Blue Buildings/Castle.png")
	tower_texture = load(ART + "Buildings/Blue Buildings/Tower.png")
	archery_texture = load(ART + "Buildings/Blue Buildings/Archery.png")
	red_run_texture = load(ART + "Units/Red Units/Warrior/Warrior_Run.png")
	black_run_texture = load(ART + "Units/Black Units/Warrior/Warrior_Run.png")
	blue_archer_texture = load(ART + "Units/Blue Units/Archer/Archer_Idle.png")
	tree_texture = load(ART + "Terrain/Resources/Wood/Trees/Tree1.png")
	bush_texture = load(ART + "Terrain/Decorations/Bushes/Bushe1.png")
	rock_texture = load(ART + "Terrain/Decorations/Rocks/Rock1.png")
	font = ThemeDB.fallback_font
	queue_redraw()

func _process(delta: float) -> void:
	animation_clock += delta
	message_clock = maxf(0.0, message_clock - delta)
	if phase == "wave":
		_update_spawning(delta)
		_update_enemies(delta)
		_update_towers(delta)
		_update_shots(delta)
		if spawn_left == 0 and enemies.is_empty() and shots.is_empty() and phase == "wave":
			_finish_wave()
	for item in float_texts.duplicate():
		item["time"] -= delta
		item["position"] += Vector2(0, -30 * delta)
		if item["time"] <= 0.0:
			float_texts.erase(item)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				selected_type = 0
			KEY_2:
				selected_type = 1
			KEY_SPACE:
				if phase == "ready":
					_start_wave()
			KEY_R:
				if phase == "won" or phase == "lost":
					_reset_game()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click := get_global_mouse_position()
		if Rect2(1070, 651, 175, 51).has_point(click):
			if phase == "ready":
				_start_wave()
			elif phase == "won" or phase == "lost":
				_reset_game()
			return
		if Rect2(23, 651, 164, 51).has_point(click):
			selected_type = 0
			return
		if Rect2(195, 651, 164, 51).has_point(click):
			selected_type = 1
			return
		if phase == "won" or phase == "lost":
			return
		for i in PADS.size():
			if click.distance_to(PADS[i]) <= 48.0:
				_handle_pad_click(i)
				return

func _handle_pad_click(index: int) -> void:
	for tower in towers:
		if tower["pad"] == index:
			if tower["level"] >= 3:
				_say("Tháp đã đạt cấp tối đa.")
			elif gold >= UPGRADE_COST:
				gold -= UPGRADE_COST
				tower["level"] += 1
				_add_float(PADS[index] + Vector2(0, -100), "CẤP %d" % tower["level"], Color("ffdf8a"))
			else:
				_say("Thiếu vàng để nâng cấp (%d)." % UPGRADE_COST)
			return
	var cost := ARCHER_COST if selected_type == 0 else GEAR_COST
	if gold < cost:
		_say("Thiếu vàng! Cần %d vàng." % cost)
		return
	gold -= cost
	towers.append({"pad": index, "type": selected_type, "level": 1, "cooldown": 0.0})
	_add_float(PADS[index] + Vector2(0, -100), "ĐÃ XÂY", Color("d8f5a2"))

func _start_wave() -> void:
	wave += 1
	phase = "wave"
	spawn_left = 5 + wave * 3
	spawn_clock = 0.2
	wave_clock = 0.0
	_say("ĐỢT %d ĐANG TỚI!" % wave)

func _update_spawning(delta: float) -> void:
	wave_clock += delta
	if spawn_left <= 0:
		return
	spawn_clock -= delta
	if spawn_clock > 0.0:
		return
	spawn_clock = maxf(0.46, 1.05 - wave * 0.10)
	spawn_left -= 1
	var heavy := wave >= 2 and spawn_left % 4 == 0
	var lane := rng.randi_range(0, 2)
	var hp := (6.0 + wave * 2.4) * (2.2 if heavy else 1.0)
	enemies.append({
		"position": Vector2(1308 + rng.randf_range(0, 38), LANES[lane]),
		"hp": hp, "max_hp": hp,
		"speed": (49.0 + wave * 6.0) * (0.72 if heavy else 1.0),
		"heavy": heavy, "reward": 18 if heavy else 10,
		"damage": 2 if heavy else 1,
		"frame": rng.randf_range(0, 6),
	})

func _update_enemies(delta: float) -> void:
	for enemy in enemies.duplicate():
		enemy["position"].x -= enemy["speed"] * delta
		enemy["frame"] += 7.0 * delta
		if enemy["position"].x <= CASTLE_X + 68.0:
			castle_hp -= enemy["damage"]
			_add_float(Vector2(CASTLE_X + 65, 352), "-%d ♥" % enemy["damage"], Color("ff7777"))
			enemies.erase(enemy)
			if castle_hp <= 0:
				castle_hp = 0
				phase = "lost"
				_say("THÀNH ĐÃ THẤT THỦ!")
				return

func _update_towers(delta: float) -> void:
	for tower in towers:
		tower["cooldown"] -= delta
		if tower["cooldown"] > 0.0:
			continue
		var origin: Vector2 = PADS[tower["pad"]] + Vector2(0, -75)
		var target: Dictionary = {}
		var best_x := 99999.0
		var range_radius := 285.0 if tower["type"] == 0 else 245.0
		for enemy in enemies:
			if origin.distance_to(enemy["position"]) <= range_radius and enemy["position"].x < best_x:
				target = enemy
				best_x = enemy["position"].x
		if target.is_empty():
			continue
		var level: int = tower["level"]
		var is_gear: bool = tower["type"] == 1
		shots.append({
			"position": origin, "target": target,
			"damage": (6.0 if is_gear else 3.0) + (level - 1) * (3.0 if is_gear else 1.5),
			"gear": is_gear,
		})
		tower["cooldown"] = (1.8 if is_gear else 0.75) / (1.0 + (level - 1) * 0.18)

func _update_shots(delta: float) -> void:
	for shot in shots.duplicate():
		var target: Dictionary = shot["target"]
		if not enemies.has(target):
			shots.erase(shot)
			continue
		var direction: Vector2 = target["position"] - shot["position"]
		var travel := (310.0 if shot["gear"] else 480.0) * delta
		if direction.length() <= travel + 8.0:
			_hit_enemy(target, shot["damage"])
			if shot["gear"]:
				for other in enemies.duplicate():
					if other != target and other["position"].distance_to(target["position"]) < 76.0:
						_hit_enemy(other, shot["damage"] * 0.55)
			shots.erase(shot)
		else:
			shot["position"] += direction.normalized() * travel

func _hit_enemy(enemy: Dictionary, damage: float) -> void:
	if not enemies.has(enemy):
		return
	enemy["hp"] -= damage
	if enemy["hp"] <= 0.0:
		gold += enemy["reward"]
		score += 10 if enemy["heavy"] else 5
		_add_float(enemy["position"] + Vector2(0, -35), "+%d" % enemy["reward"], Color("ffe083"))
		enemies.erase(enemy)

func _finish_wave() -> void:
	gold += 35 + wave * 5
	if wave >= MAX_WAVES:
		phase = "won"
		_say("CHIẾN THẮNG! THÀNH ĐÃ ĐƯỢC BẢO VỆ.")
	else:
		phase = "ready"
		_say("Qua đợt %d! Thưởng %d vàng. Nâng cấp rồi tiếp tục." % [wave, 35 + wave * 5])

func _reset_game() -> void:
	towers.clear()
	enemies.clear()
	shots.clear()
	float_texts.clear()
	gold = 130
	castle_hp = 10
	wave = 0
	score = 0
	phase = "ready"
	selected_type = 0
	_say("Xây tháp rồi bấm BẮT ĐẦU để phòng thủ!")

func _say(value: String) -> void:
	message = value
	message_clock = 4.0

func _add_float(position: Vector2, value: String, color: Color) -> void:
	float_texts.append({"position": position, "text": value, "color": color, "time": 1.1})

func _draw() -> void:
	_draw_ground()
	_draw_scenery()
	_draw_castle()
	_draw_pads_and_towers()
	_draw_enemies()
	_draw_shots()
	_draw_hud()
	for item in float_texts:
		_label(item["text"], item["position"], 18, item["color"])

func _draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color("779f55"))
	# Wide lanes keep the three enemy routes easy to read.
	for lane_y in LANES:
		draw_rect(Rect2(0, lane_y - 37, 1280, 74), Color("b59e70"))
		draw_line(Vector2(0, lane_y - 37), Vector2(1280, lane_y - 37), Color("8b825e"), 4)
		draw_line(Vector2(0, lane_y + 37), Vector2(1280, lane_y + 37), Color("8b825e"), 4)
		for x in range(260, 1280, 84):
			draw_line(Vector2(x, lane_y), Vector2(x + 30, lane_y), Color("d1bd8a", 0.7), 2)
	draw_rect(Rect2(0, 0, 1280, 91), Color("152a38"))
	draw_rect(Rect2(0, 633, 1280, 87), Color("152a38"))
	draw_line(Vector2(0, 91), Vector2(1280, 91), Color("5d9d8d"), 3)
	draw_line(Vector2(0, 633), Vector2(1280, 633), Color("5d9d8d"), 3)

func _draw_scenery() -> void:
	for position in [Vector2(58, 211), Vector2(1178, 218), Vector2(255, 210), Vector2(1125, 608)]:
		_draw_atlas(tree_texture, Rect2(0, 0, 256, 256), position, Vector2(92, 92))
	for position in [Vector2(330, 126), Vector2(710, 142), Vector2(1200, 566), Vector2(200, 573)]:
		_draw_atlas(bush_texture, Rect2(0, 0, 128, 128), position, Vector2(55, 55))
	for position in [Vector2(510, 128), Vector2(1110, 143), Vector2(740, 570)]:
		_draw_atlas(rock_texture, Rect2(0, 0, 64, 64), position, Vector2(42, 42))

func _draw_castle() -> void:
	draw_circle(Vector2(CASTLE_X, 402), 97, Color("233e40", 0.25))
	_draw_atlas(castle_texture, Rect2(0, 0, 320, 256), Vector2(CASTLE_X, 411), Vector2(222, 178))
	_label("LÕI THÀNH", Vector2(104, 438), 16, Color("ffffff"))

func _draw_pads_and_towers() -> void:
	for i in PADS.size():
		var pad: Vector2 = PADS[i]
		var tower: Dictionary = {}
		for candidate in towers:
			if candidate["pad"] == i:
				tower = candidate
				break
		draw_circle(pad + Vector2(0, 3), 44, Color("314b40", 0.45))
		draw_arc(pad, 40, 0, TAU, 40, Color("d5e7a7", 0.8) if tower.is_empty() else Color("8de0ed"), 3)
		if tower.is_empty():
			_label("+", pad + Vector2(-9, 12), 34, Color("f5e8a5"))
		else:
			var texture: Texture2D = archery_texture if tower["type"] == 0 else tower_texture
			var width := 91.0 if tower["type"] == 0 else 65.0
			_draw_atlas(texture, Rect2(0, 0, texture.get_width(), texture.get_height()), pad + Vector2(0, 27), Vector2(width, 120))
			for star in tower["level"]:
				_label("★", pad + Vector2(-18 + star * 18, -97), 17, Color("ffe384"))
			if tower["type"] == 0:
				_draw_atlas(blue_archer_texture, Rect2(0, 0, 192, 192), pad + Vector2(0, 5), Vector2(56, 56))

func _draw_enemies() -> void:
	for enemy in enemies:
		var position: Vector2 = enemy["position"]
		var heavy: bool = enemy["heavy"]
		var size := Vector2(99, 99) if heavy else Vector2(81, 81)
		draw_ellipse_shadow(position, size.x * 0.30)
		var texture: Texture2D = black_run_texture if heavy else red_run_texture
		var frame: int = int(enemy["frame"]) % 6
		_draw_atlas(texture, Rect2(frame * 192, 0, 192, 192), position + Vector2(0, -16), size)
		var ratio: float = clampf(enemy["hp"] / enemy["max_hp"], 0.0, 1.0)
		draw_rect(Rect2(position.x - 27, position.y - 58, 54, 6), Color("26313d"))
		draw_rect(Rect2(position.x - 26, position.y - 57, 52 * ratio, 4), Color("f36d68"))

func draw_ellipse_shadow(position: Vector2, radius: float) -> void:
	draw_set_transform(position + Vector2(0, 16), 0.0, Vector2(1.0, 0.33))
	draw_circle(Vector2.ZERO, radius, Color("243b3e", 0.42))
	draw_set_transform(Vector2.ZERO)

func _draw_shots() -> void:
	for shot in shots:
		var position: Vector2 = shot["position"]
		if shot["gear"]:
			draw_circle(position, 10, Color("e9a846"))
			draw_arc(position, 10, 0, TAU, 8, Color("fff0ae"), 2)
		else:
			draw_circle(position, 5, Color("e8f8e3"))

func _draw_hud() -> void:
	_label("GEAR DEFENDER", Vector2(23, 39), 27, Color("f3e1a7"))
	_label("BẢO VỆ LÕI THÀNH", Vector2(25, 68), 14, Color("aad5cf"))
	_label("♥  %d / 10" % castle_hp, Vector2(380, 52), 25, Color("ff9691"))
	_label("◈  %d" % gold, Vector2(575, 52), 25, Color("ffdc7c"))
	_label("ĐỢT  %d / %d" % [wave, MAX_WAVES], Vector2(755, 52), 23, Color("e3f1dc"))
	_label("ĐIỂM  %d" % score, Vector2(1015, 52), 21, Color("bbdfde"))
	_draw_button(Rect2(23, 651, 164, 51), "1  CUNG  %d◈" % ARCHER_COST, selected_type == 0)
	_draw_button(Rect2(195, 651, 164, 51), "2  PHÁO  %d◈" % GEAR_COST, selected_type == 1)
	_label("Click ô tròn để xây  •  Click tháp để nâng cấp %d◈" % UPGRADE_COST, Vector2(382, 673), 15, Color("c4d8d3"))
	_label("R: chơi lại", Vector2(382, 694), 13, Color("8ea8aa"))
	var action_text := "BẮT ĐẦU" if phase == "ready" else ("CHƠI LẠI" if phase == "won" or phase == "lost" else "ĐANG ĐÁNH")
	_draw_button(Rect2(1070, 651, 175, 51), action_text, phase == "ready" or phase == "won" or phase == "lost")
	if message_clock > 0.0 or phase == "won" or phase == "lost":
		var text_width := minf(760.0, maxf(300.0, message.length() * 10.0))
		draw_rect(Rect2(640 - text_width / 2, 104, text_width, 41), Color("152a38", 0.88))
		_label(message, Vector2(640 - text_width / 2 + 17, 131), 17, Color("fff0bf"))
	if phase == "won" or phase == "lost":
		draw_rect(Rect2(350, 258, 580, 175), Color("152a38", 0.94))
		draw_rect(Rect2(350, 258, 580, 175), Color("7cbdb3"), false, 3)
		_label("CHIẾN THẮNG!" if phase == "won" else "THẤT THỦ!", Vector2(490, 319), 37, Color("f5e4a6" if phase == "won" else "ffaaa2"))
		_label("Điểm: %d    •    Nhấn R hoặc CHƠI LẠI" % score, Vector2(458, 378), 20, Color("d9efed"))

func _draw_button(rect: Rect2, title: String, active: bool) -> void:
	draw_rect(rect, Color("317b72") if active else Color("304653"))
	draw_rect(rect, Color("a9e1c5") if active else Color("567782"), false, 2)
	_label(title, rect.position + Vector2(13, 33), 18, Color("ffffff" if active else "c7d7d8"))

func _draw_atlas(texture: Texture2D, source: Rect2, center: Vector2, size: Vector2) -> void:
	if texture == null:
		return
	draw_texture_rect_region(texture, Rect2(center - size / 2.0, size), source)

func _label(value: String, position: Vector2, size: int, color: Color) -> void:
	draw_string(font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
