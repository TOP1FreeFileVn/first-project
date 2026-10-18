extends Control

# Lobby rebuilt on the full-screen layout of the real games (Figma "Bố cục toàn màn"):
# HUD → title + stage island (one centre subject) with side rails → wave progress + chest →
# one big CTA → callout + bottom nav. Each motivating element is tagged with the effect it
# leans on; see docs/ui/PhanTich_KichThich_UI.md.
# Run: Godot --path . res://tests/ui/HomePreview.tscn [-- --shot=C:/some/folder/home.png]

const Ui = preload("res://game/ui/Ui.gd")

const TABS := [["tab_shop", "Cửa hàng"], ["tab_cat", "Anh hùng"], ["tab_battle", "Chiến"], ["tab_army", "Lính"], ["tab_summon", "Triệu hồi"]]

var _limited_left := 23 * 3600 + 58 * 60 + 6
var _limited_label: Label


func _ready() -> void:
	Ui.setup_root(self)
	var sky := ColorRect.new()
	sky.color = Color("6fa3e0")
	add_child(sky)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var col := Ui.vbox(0)
	add_child(col)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_child(Ui.hud(12, "28/30", "02:41", "12.450", "860", 0.86))  # goal gradient: EXP bar near full
	var middle := Control.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(middle)
	col.add_child(Ui.bottom_nav(TABS, 2, [0, 4]))  # red dots: unfinished business (Zeigarnik)

	_build_center(middle)
	_build_rails(middle)

	# Callout over the summon tab: free pull waiting (variable reward cue).
	var tip := Ui.callout("Triệu hồi miễn phí!")
	Ui.pin(self, tip, Vector2(-216, -186), Control.PRESET_BOTTOM_RIGHT)
	tip.offset_right = tip.offset_left + 210
	tip.offset_bottom = tip.offset_top + 60
	Ui.bob(tip, 6.0, 1.1)

	var tick := Timer.new()
	tick.wait_time = 1.0
	tick.autostart = true
	tick.timeout.connect(_tick)
	add_child(tick)
	_shot_if_asked()


## The middle column, laid out like both reference lobbies so it fills any screen height:
## [flex] stage (title plaque on top of the island, cat in the middle) → progress track →
## caption → [flex] CTA row (locked stage | CTA | locked stage) → room for the callout.
func _build_center(middle: Control) -> void:
	var col := Ui.vbox(6)
	middle.add_child(col)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_child(_flex(0.15))

	# Title plaque + recommended power on top of the stage.
	var title := Ui.vbox(2)
	title.add_child(Ui.center(Ui.title_plaque("1-3 · Rừng Mèo", "(2/3)", 26)))
	var power := Ui.hbox(6)
	power.add_child(Ui.label("Sức mạnh gợi ý", "LabelSmall", 17))
	power.add_child(Ui.icon("star", 26))
	power.add_child(Ui.label("1.000", "", 22))
	title.add_child(power)
	col.add_child(title)

	# Stage: the island grows to fill the height that is left (kept at its aspect ratio and
	# between the side rails), so taller or shorter screens never leave a gap. The cat is
	# anchored in fractions of the island, so it stays on the grass at any size.
	var side := Ui.margin(84, 0, 84, 0)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var fit := AspectRatioContainer.new()
	fit.ratio = 560.0 / 400.0
	side.add_child(fit)
	var stage := Control.new()
	fit.add_child(stage)
	var island := Ui.image("stage_island", Vector2.ZERO)
	stage.add_child(island)
	island.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cat := Ui.image("cat_hero", Vector2.ZERO)
	stage.add_child(cat)
	cat.anchor_left = 0.34
	cat.anchor_right = 0.66
	cat.anchor_top = 0.02
	cat.anchor_bottom = 0.47
	col.add_child(side)

	# One centred progress track: wave 1 ✓ — wave 2 ✓ — wave 3 — chest, then the caption
	# (goal gradient + endowed progress; the reward sits at the end of the track).
	var track := Ui.hbox(0)
	for i in 4:
		if i > 0:
			var link := ColorRect.new()
			link.custom_minimum_size = Vector2(34, 8)
			link.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			link.color = Color("ffd23f") if i < 3 else Color("3d5a8a")
			track.add_child(link)
		if i < 3:
			var mark := Ui.icon("badge_shield_blue" if i < 2 else "badge_shield_orange", 50)
			var l := Ui.label(str(i + 1), "LabelSmall", 20)
			mark.add_child(l)
			l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			l.offset_bottom = -8
			if i < 2:
				Ui.pin(mark, Ui.icon("badge_check", 26), Vector2(-16, -16), Control.PRESET_BOTTOM_RIGHT)
			track.add_child(mark)
		else:
			track.add_child(Ui.icon("chest", 60))
	col.add_child(track)
	col.add_child(Ui.label("Còn 1 sóng mở rương!", "LabelSmall", 19))
	col.add_child(_flex(0.12))

	# CTA row: one big breathing call to action (salience), locked neighbour stages beside it
	# so the next goal is always in sight. All in the row, so nothing drifts with screen size.
	var row := Ui.hbox(14)
	row.add_child(_locked_stage("Ải 1-2"))
	var cta := Ui.cost_button("Trận chiến", "x5", "bolt", "Yellow", Vector2(330, 108))
	row.add_child(cta)
	row.add_child(_locked_stage("Ải 1-4"))
	col.add_child(row)
	cta.ready.connect(func(): Ui.pulse(cta, 0.04, 1.4))
	var foot := Control.new()
	foot.custom_minimum_size.y = 62  # room for the callout above the nav
	col.add_child(foot)

	# Lower side items between the track and the CTA, like "Vĩnh viễn" / "Triệu hồi" in the
	# references, so the sides are not empty.
	var boost := Ui.rail([Ui.rail_item("bolt", "Tăng tốc x2", "15:00")])
	Ui.pin(middle, boost, Vector2(8, -350), Control.PRESET_BOTTOM_LEFT)
	var summon := Ui.rail([Ui.rail_item("tab_summon", "Triệu hồi", "", true)])
	Ui.pin(middle, summon, Vector2(-128, -350), Control.PRESET_BOTTOM_RIGHT)


func _flex(ratio: float) -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.size_flags_stretch_ratio = ratio
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _locked_stage(text: String) -> Button:
	var locked := Ui.button("", "Tab", Vector2(110, 92))
	Ui.lock(locked)
	var l := Ui.label(text, "LabelTiny", 15)
	locked.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.offset_bottom = -12
	return locked


func _build_rails(middle: Control) -> void:
	_limited_label = null
	var limited := Ui.rail_item("rail_limited", "Gói giới hạn", _clock(_limited_left), true)  # scarcity / time pressure
	_limited_label = limited.get_child(limited.get_child_count() - 1)
	var left := Ui.rail([
		Ui.rail_item("rail_pass", "Thông hành", "", true),  # season pass: sunk progress
		Ui.rail_item("rail_vip", "VIP"),
		limited,
	])
	Ui.pin(middle, left, Vector2(8, 120))
	var right := Ui.rail([
		Ui.rail_item("rail_quest", "Nhiệm vụ", "3/5", true),  # Zeigarnik: open tasks
		Ui.rail_item("rail_online", "Quà online", "04:12"),  # appointment / return trigger
		Ui.rail_item("rail_checkin", "Điểm danh", "Ngày 6/7", true),  # streak: loss aversion
	])
	Ui.pin(middle, right, Vector2(-128, 120), Control.PRESET_TOP_RIGHT)


func _tick() -> void:
	_limited_left = maxi(0, _limited_left - 1)
	if _limited_label:
		_limited_label.text = _clock(_limited_left)


static func _clock(s: int) -> String:
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


func _shot_if_asked() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			await get_tree().create_timer(0.6).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.get_slice("=", 1))
			get_tree().quit()
