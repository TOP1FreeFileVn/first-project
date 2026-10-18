# UI taps

Three original variations of one short, soft idle-game button tap: a rounded
wood-like body and a muted contact sound, without a sustained electronic beep.
They are generated from damped sine resonances and seeded filtered noise by
`tools/audio/make_ui_taps.py`; no third-party recordings or samples are used.

Format: mono PCM16, 22050 Hz, 72–76 ms, peak −11.06 dBFS. `SoundLib` cycles the
variants with slight pitch variation. Existing buttons, tabs, popup controls and
the saved **Âm thanh** toggle continue to use the same `play("click")` API.

Regenerate from the repository root:

```powershell
python tools/audio/make_ui_taps.py
```
