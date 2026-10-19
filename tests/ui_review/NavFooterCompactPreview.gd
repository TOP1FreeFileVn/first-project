extends "res://tests/ui_review/NavFocusPreview.gd"

# Adds icon/holder geometry to the shared real-pointer, native-render fixture.
# It writes only to nav-footer-compact and never replaces the earlier nav-focus review.
func _control_geometry(control: Control, render_scale: Vector2) -> Dictionary:
	var result := super._control_geometry(control, render_scale)
	if control.theme_type_variation == &"NavSelected":
		var body := control.get_child(0)
		var holder := body.get_child(0) as Control
		result["icon_holder"] = super._control_geometry(holder, render_scale)
		for child in holder.get_children():
			if child is TextureRect:
				result["icon"] = super._control_geometry(child, render_scale)
				break
	return result
