extends SceneTree

const KEYS := ["hero-tail", "hero-cape", "hero-torso", "hero-body", "hero-head", "hero-head-noears", "hero-paws", "hero-base", "hero-neutral"]

func _initialize() -> void:
    var folder := ProjectSettings.globalize_path("res://docs/design/2026-10-19/hero-equipment/sources")
    for key in KEYS:
        var stem := folder.path_join(key)
        var image := Image.new()
        assert(image.load_svg_from_string(FileAccess.get_file_as_string(stem + ".svg"), 3.0) == OK, key)
        assert(image.get_size() == Vector2i(768, 720), key)
        assert(image.save_png(stem + ".png") == OK, key)
        print("HERO_BASE_NATIVE_RENDERED ", key, " ", image.get_size())
    print("HERO_BASE_NATIVE_COMPLETE ", KEYS.size())
    quit()
