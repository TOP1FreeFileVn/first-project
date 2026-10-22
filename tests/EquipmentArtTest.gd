extends Node

# Production routing/regression check: accepted PNGs must reach both UI and
# soldiers, and stat-only equipment must never replace the hero's costume.
const Ui = preload("res://game/ui/Ui.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const IDS := ["kiem", "riu", "dao", "katana", "cung", "no", "sung", "dai_bac",
	"gay_phep", "thuoc", "sach_phep", "dua_phep", "giao", "cu_kiem", "chuy", "bua"]
const WEAPONS := ["kiem_go", "cung_san", "gay_sao", "riu_lua", "katana_nguyet"]
const STAT_ITEMS := ["mu_hiep_si", "giap_rong", "giay_gio"]
const OUT := "res://docs/ui_review/2026-10-22/hero-four-slots/art-routing"
var _checks := 0
var _failed := 0


func _ready() -> void:
	PlayerData.persist = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for id in IDS:
		var texture := SpriteLib.cat_texture("art:" + id)
		_check(texture != null and texture.get_size() == Vector2(128, 120), id + " production soldier loads at native size")
		for size in [32, 48, 64, 96]:
			var icon := Ui.icon_tex("w_" + id, size)
			_check(icon != null and icon.resource_path == "res://game/ui/art/icon_w_%s_%d.png" % [id, size], id + " UI uses final raster at " + str(size))
		texture.get_image().save_png(OUT + "/soldier-" + id + ".png")
	_check(Ui.tex("platform").resource_path == "res://game/ui/skin/platform.svg", "unchanged UI still falls back to generated SVG")
	for name in ["helmet", "armor", "boots"]:
		_check(Ui.icon_tex("eq_" + name, 64).resource_path == "res://game/ui/art/icon_eq_%s_64.png" % name, name + " uses final stat-only icon")
	var state := HeroCat.new_state()
	var appearances := {}
	for id in WEAPONS:
		var uid := HeroCat.add_item(state, id)
		state.equipped.weapon = uid
		var before := SpriteLib.hero_cat_texture(state)
		_check(before != null and before.get_size() == Vector2(768, 720), id + " final front hero loads")
		appearances[before.resource_path] = true
		var original_stats := HeroCat.total_stats(state)
		var geared := state.duplicate(true)
		for stat_id in STAT_ITEMS:
			var stat_uid := HeroCat.add_item(geared, stat_id)
			geared.equipped[HeroCat.ITEMS[stat_id].slot] = stat_uid
		_check(HeroCat.total_stats(geared) != original_stats, "three stat-only gear slots still add stats for " + id)
		_check(SpriteLib.hero_cat_texture(geared) == before, "three stat-only items do not change " + id + " appearance")
		var picture := before.get_image()
		picture.resize(128, 120, Image.INTERPOLATE_LANCZOS)
		picture.save_png(OUT + "/hero-" + id + ".png")
	_check(appearances.size() == WEAPONS.size(), "all five equipped weapon types have distinct hero artwork")
	state.equipped.erase("weapon")
	_check(SpriteLib.hero_cat_texture(state).resource_path == "res://game/ui/art/hero_cat_bare.png", "empty weapon shows bare unchanged hero")
	var report := {"checks": _checks, "failed": _failed, "persist": PlayerData.persist,
		"soldier_art_count": IDS.size(), "hero_weapon_looks": appearances.size(),
		"stat_only_gear_slots": STAT_ITEMS.size(), "production_png_routing": true}
	var file := FileAccess.open(OUT + "/runtime.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("EquipmentArtTest: %d checks, %d failed" % [_checks, _failed])
	get_tree().quit(1 if _failed else 0)


func _check(value: bool, description: String) -> void:
	_checks += 1
	if not value:
		_failed += 1
		push_error(description)
