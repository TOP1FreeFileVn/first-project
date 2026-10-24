extends Node

# Checks every synthesised sound: not silent, not clipping, sensible length; prints how
# long synthesis took. With --out=C:/folder it also writes each sound as a .wav to listen to.
# Run: Godot --headless --path . res://tests/SoundCheck.tscn -- --out=C:/some/folder

var _start := 0
var _out := ""


func _ready() -> void:
	_start = Time.get_ticks_msec()
	var out := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.get_slice("=", 1)
	_out = out


# Every effect is a WAV now (SoundLib.SOUNDS + UI_TAPS); checks each one's level and length.
func _process(_delta: float) -> void:
	if not SoundLib.has_sound("legend"):
		return
	set_process(false)
	var out := _out
	var sounds: Dictionary = SoundLib.SOUNDS.duplicate()
	sounds["click"] = SoundLib.UI_TAPS[0]
	for i in range(1, SoundLib.UI_TAPS.size()):
		sounds["click_variant_%d" % (i + 1)] = SoundLib.UI_TAPS[i]
	print("%d sounds / variants loaded after %d ms" % [sounds.size(), Time.get_ticks_msec() - _start])
	var failed := 0
	for name in sounds:
		# Imported streams are QOA-compressed, so measure the source WAV's PCM instead.
		var stream: AudioStream = sounds[name]
		var pcm := _source_pcm(stream.resource_path)
		var peak := 0
		for i in range(0, pcm["data"].size(), 2):
			peak = maxi(peak, absi(pcm["data"].decode_s16(i)))
		var seconds: float = pcm["data"].size() / 2.0 / maxf(pcm["rate"] * pcm["channels"], 1.0)
		var ok: bool = peak > 3000 and peak < 32767 and seconds > 0.02 and seconds < 4.0
		if not ok:
			failed += 1
		print("  %-12s %.2fs peak %5.1f%% %s" % [name, seconds, peak * 100.0 / 32767.0, "" if ok else "<-- CHECK"])
		if out != "":
			DirAccess.copy_absolute(ProjectSettings.globalize_path(stream.resource_path), "%s/%s.wav" % [out, name])
	print("SoundCheck: %d sounds / variants, %d to check" % [sounds.size(), failed])
	get_tree().quit(1 if failed > 0 else 0)

# The 16-bit PCM data of a source .wav (RIFF): {"data", "rate", "channels"}.
func _source_pcm(path: String) -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(path)
	var out := {"data": PackedByteArray(), "rate": 22050, "channels": 1}
	var at := 12
	while at + 8 <= bytes.size():
		var id := bytes.slice(at, at + 4).get_string_from_ascii()
		var size := bytes.decode_u32(at + 4)
		if id == "fmt ":
			out["channels"] = bytes.decode_u16(at + 10)
			out["rate"] = bytes.decode_u32(at + 12)
		elif id == "data":
			out["data"] = bytes.slice(at + 8, at + 8 + size)
		at += 8 + size + (size % 2)
	return out
