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


# SoundLib builds on a worker thread at startup; wait for it.
func _process(_delta: float) -> void:
	if SoundLib._streams.is_empty():
		return
	set_process(false)
	var out := _out
	print("background synthesis ready after %d ms (%d sounds)" % [Time.get_ticks_msec() - _start, SoundLib._streams.size()])
	var failed := 0
	for name in SoundLib._streams:
		var stream: AudioStreamWAV = SoundLib._streams[name]
		var data := stream.data
		var peak := 0
		for i in range(0, data.size(), 2):
			peak = maxi(peak, absi(data.decode_s16(i)))
		var seconds := data.size() / 2.0 / SoundLib.RATE
		var ok := peak > 3000 and peak < 32767 and seconds > 0.02 and seconds < 3.0
		if not ok:
			failed += 1
		print("  %-12s %.2fs peak %5.1f%% %s" % [name, seconds, peak * 100.0 / 32767.0, "" if ok else "<-- CHECK"])
		if out != "":
			stream.save_to_wav("%s/%s.wav" % [out, name])
	print("SoundCheck: %d sounds, %d to check" % [SoundLib._streams.size(), failed])
	get_tree().quit(1 if failed > 0 else 0)
