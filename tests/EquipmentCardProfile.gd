extends Node

# Times the pieces of one bag card (RAM only):
#   Godot --path . res://tests/EquipmentCardProfile.tscn

const Ui = preload("res://game/ui/Ui.gd")
const EquipmentCard = preload("res://game/ui/EquipmentCard.gd")

func _ready() -> void:
	var n := 200
	for label in ["gear_card", "no_apply", "apply", "icon", "panel", "label", "paperboard"]:
		var t := Time.get_ticks_usec()
		for i in n:
			var c: Control
			match label:
				"gear_card": c = Ui.gear_card("hero_w_kiem", "slot_weapon", "green", "1", 116.0)
				"no_apply": c = Ui.gear_card("hero_w_kiem", "slot_x", "green", "1", 116.0)
				"apply":
					c = Ui.gear_card("hero_w_kiem", "slot_x", "green", "1", 116.0)
					EquipmentCard.apply(c, "slot_weapon", "green", 116.0)
				"icon": c = Ui.icon("hero_w_kiem", 80)
				"panel": c = Ui.panel("CardEquipmentGreen")
				"label": c = Ui.label("Lv.1", "LabelTiny", 17)
				"paperboard":
					c = load("res://game/ui/PaperboardFrame.gd").new()
			c.free()
		print("PROFILE %s: %.3f ms each" % [label, (Time.get_ticks_usec() - t) / 1000.0 / n])
	get_tree().quit()
