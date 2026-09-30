extends RefCounted

# Who may open the admin panel: debug builds, or exports with the "admin" feature tag.
# Release builds without that tag never show the ADMIN button.


static func available() -> bool:
	return OS.is_debug_build() or OS.has_feature("admin")
