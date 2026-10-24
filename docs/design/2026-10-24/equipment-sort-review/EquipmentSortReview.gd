extends "res://docs/design/2026-10-23/equipment-ui-integration/ReviewEquipmentIntegration.gd"

## Focused review of the production funnel menu, without visual overrides.
## Reuses the real inventory fixture and native input helpers from integration.


func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	_out = "res://docs/design/2026-10-24/equipment-sort-review/native"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	_original_state = PlayerData.to_dict().duplicate(true)
	_original_persist = PlayerData.persist
	_original_tab = HOME_SCRIPT.last_tab
	PlayerData.persist = false
	_save_before = _save_hash()
	for requested in SIZES:
		_size = requested
		_fixture("full")
		await _mount()
		_audit_grid(HeroCat.ITEMS.size() - WORN.size())
		await _capture("equipment-before-sort")
		await _filters_sort()
		_check_native_nav("after_sort")
		await _unmount()
	_check(not PlayerData.persist and _save_before == _save_hash(), "no_player_save_write_during_review")
	PlayerData.from_dict(_original_state)
	HOME_SCRIPT.last_tab = _original_tab
	_check(PlayerData.to_dict() == _original_state, "original_in_memory_profile_restored")
	_check(_save_before == _save_hash(), "profile_restore_never_writes_save")
	PlayerData.persist = _original_persist
	_finish()


func _finish() -> void:
	var report := {
		"scope": "Actual production Home/Hero funnel dropdown at 360x640 and 450x800. Native mouse taps select rarity/level and ascending/descending order, retain sort through category filters and dismiss by tapping outside. Full inventory fixture includes levels 1 through 10. No visual overrides or persistent inventory writes.",
		"profile": OS.get_user_data_dir(),
		"original_persist_restored": PlayerData.persist == _original_persist,
		"save_before": _save_before,
		"save_after": _save_hash(),
		"checks": _checks,
		"captures": _captures,
		"geometry": _geometry,
		"failures": _failures,
	}
	var file := FileAccess.open(_out.path_join("review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("EQUIPMENT_SORT_REVIEW_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
