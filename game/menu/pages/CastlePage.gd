extends "res://game/menu/pages/MenuPage.gd"

# Castle level (HP, max meat, open gear cells, team slots) and the three workshop upgrades.

const GridPreview = preload("res://game/menu/widgets/GridPreview.gd")
const CastleTiers = preload("res://game/menu/lobby/CastleTiers.gd")
const CastleBuild = preload("res://game/menu/lobby/CastleBuild.gd")
## The castle picture: the live tiered castle (waving flags), scaled into the stage.
const STAGE_HEIGHT := 250.0
const STAGE_SCALE := 0.6

## The building scene plays in the stage; the page waits to rebuild until it ends.
var _building := false
var _castle_root: Node2D
var _castle_tiers: Node2D


func build() -> void:
	body.add_theme_constant_override("separation", 22)
	var level := PlayerData.castle_level
	var max_level := PlayerData.castle_max_level()
	var now: Dictionary = PlayerData.castle_stats()
	var next: Dictionary = Economy.CASTLE[level] if level < max_level else now

	var art_stage := Control.new()
	art_stage.name = "CastleStage"
	art_stage.custom_minimum_size.y = STAGE_HEIGHT
	art_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(art_stage)
	# Gate foot at the stage's bottom middle; the build scene uses the same space.
	var root := Node2D.new()
	root.name = "CastleStageRoot"
	root.scale = Vector2.ONE * STAGE_SCALE
	art_stage.add_child(root)
	art_stage.resized.connect(func(): root.position = Vector2(art_stage.size.x * 0.5, art_stage.size.y - 4.0))
	_castle_root = Node2D.new()
	_castle_root.name = "CastleStageCastle"
	root.add_child(_castle_root)
	_castle_tiers = CastleTiers.new()
	_castle_tiers.position = -CastleTiers.GATE_FOOT
	_castle_tiers.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_castle_root.add_child(_castle_tiers)
	_castle_tiers.set_level(level)
	var castle := section("Thành cấp %d / %d" % [level, max_level], 10)

	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 30)
	stats.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stat_row(stats, "Máu thành", "x%.2f" % now["hp"], "x%.2f" % next["hp"], level < max_level)
	_stat_row(stats, "Túi xu tối đa", str(now["meat"]), str(next["meat"]), level < max_level)
	_stat_row(stats, "Ô đặt gear", str(now["cells"]), str(next["cells"]), level < max_level)
	_stat_row(stats, "Ô đội hình", str(Economy.team_slots(level)), str(Economy.team_slots(mini(level + 1, max_level))), level < max_level)
	castle.add_child(stats)

	var preview := GridPreview.new()
	preview.open_now = now["cells"]
	preview.open_next = next["cells"]
	castle.add_child(preview)
	var legend := UiKit.ink("Xanh: ô đang mở · Vàng: ô mở thêm ở cấp sau", 16)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	castle.add_child(legend)

	var cost := PlayerData.castle_upgrade_cost()
	var upgrade := UiKit.button("", Vector2(360, 80), _upgrade)
	upgrade.name = "CastleDetailsUpgrade"
	upgrade.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	upgrade.add_theme_font_size_override("font_size", 24)
	if cost < 0:
		upgrade.text = "THÀNH ĐÃ TỐI ĐA"
		upgrade.disabled = true
	else:
		upgrade.text = "NÂNG THÀNH  %s" % UiKit.format_number(cost)
		upgrade.icon = UiKit.coin_texture()
		upgrade.add_theme_constant_override("icon_max_width", 34)
		upgrade.disabled = PlayerData.gold < cost
	castle.add_child(upgrade)

	var workshop := section("Xưởng", 18)
	for id in Economy.WORKSHOP_ORDER:
		if workshop.get_child_count() > 0:
			var rule := HSeparator.new()
			var line := StyleBoxFlat.new()
			line.bg_color = Color(0.345, 0.247, 0.129, 0.2)
			line.content_margin_top = 1
			line.content_margin_bottom = 1
			rule.add_theme_stylebox_override("separator", line)
			workshop.add_child(rule)
		_workshop_row(workshop, id)


func has_alert() -> bool:
	return PlayerData.can_improve_castle()


func _stat_row(grid: GridContainer, name: String, now: String, next: String, has_next: bool) -> void:
	grid.add_child(UiKit.ink(name, 19))
	grid.add_child(UiKit.ink(now + ("  →  " + next if has_next and next != now else ""), 19))


func _workshop_row(box: VBoxContainer, id: String) -> void:
	var spec: Dictionary = Economy.WORKSHOP[id]
	var level := PlayerData.workshop_level(id)
	var row := UiKit.hbox(12)
	box.add_child(row)
	var info := UiKit.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.ink("%s  (%d/%d)" % [spec["name"], level, spec["max"]], 21))
	var effect: String = spec["desc"] % PlayerData.workshop_value(id)
	if level < spec["max"]:
		effect += "  →  " + spec["desc"] % PlayerData.workshop_value(id, level + 1)
	var effect_label := UiKit.ink(effect, 18)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(effect_label)
	row.add_child(info)
	var cost := PlayerData.workshop_cost(id)
	var b := UiKit.button("", Vector2(170, 64), func(): PlayerData.upgrade_workshop(id))
	if cost < 0:
		b.text = "TỐI ĐA"
		b.disabled = true
	else:
		b.text = UiKit.format_number(cost)
		b.icon = UiKit.coin_texture()
		b.add_theme_constant_override("icon_max_width", 28)
		b.disabled = PlayerData.gold < cost
	row.add_child(b)


## Buys the next level and plays the building scene over the castle picture: cats hammer
## at it, then it stands at its new tier. The page rebuilds (new numbers) when it ends.
func _upgrade() -> void:
	if _building or not is_instance_valid(_castle_root):
		return
	_building = true
	if not PlayerData.upgrade_castle():
		_building = false
		return
	var build := CastleBuild.new()
	build.name = "CastleBuild"
	_castle_root.get_parent().add_child(build)
	build.start(_castle_root, func(): _castle_tiers.set_level(PlayerData.castle_level), func():
		_building = false
		refresh())


func refresh() -> void:
	if _building:
		return
	super()
