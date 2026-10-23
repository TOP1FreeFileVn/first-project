# Lobby regional title panoramas

Regional panorama art for all 15 stages, cropped to 476×90 without the carton border.
Bound through `LevelData.lobby_banner` and shown by `BattlePage` at (122,136).
Corners use a 10px rounded alpha mask with a 3px brown (#583f21) inside contour, without a shadow.
The stage name remains a separate centered white Label with a brown 3px outline.
The courtyard, cats and castle remain the same persistent lobby scene.

`manifest.json` records source and output hashes. The original art was generated
with GPT Image 2.5 through the user-selected local 9Router API. Rebuild from the
untouched originals with:

```powershell
python tools/ui/install_lobby_map_titles.py
```
