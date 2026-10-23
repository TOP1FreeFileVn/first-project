"""Install generated regional title and battlefield art for stages 11–15.

Run with --check while image generation is still in progress. Installation waits
for every source, uses the existing lobby builder, and verifies stages 1–10 stay
byte-for-byte unchanged. The original generated artwork is never modified.
"""
from pathlib import Path
import argparse
import copy
import hashlib
import json
import re
import shutil
import subprocess
import sys

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
LOBBY = ROOT / "game/assets/lobby/map-titles"
BATTLE = ROOT / "game/assets/battle/regions"
REGIONS = [
    (11, "ben-cang", "Bến Cảng"),
    (12, "rung-suong", "Rừng Sương"),
    (13, "doi-cuu", "Đồi Cừu"),
    (14, "mo-vang", "Mỏ Vàng"),
    (15, "cau-da", "Cầu Đá"),
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def level_binding(stage: int, filename: str) -> tuple[Path, str]:
    path = ROOT / f"game/data/levels/level_{stage:02d}.tres"
    text = path.read_text(encoding="utf-8")
    for field, directory in [("battlefield", BATTLE), ("lobby_banner", LOBBY)]:
        asset_path = "res://" + (directory / filename).relative_to(ROOT).as_posix()
        declaration = f'[ext_resource type="Texture2D" path="{asset_path}" id="{field}"]'
        assignment = f'{field} = ExtResource("{field}")'
        if f'id="{field}"' in text:
            if declaration not in text or assignment not in text:
                raise ValueError(f"Unexpected existing {field} binding: {path}")
            continue
        text, count = re.subn(r"load_steps=(\d+)", lambda match: f"load_steps={int(match[1]) + 1}", text, count=1)
        if count != 1 or "\n[resource]" not in text or 'script = ExtResource("1_level")' not in text:
            raise ValueError(f"Unexpected resource format: {path}")
        text = text.replace("\n[resource]", f"\n{declaration}\n\n[resource]", 1)
        text = text.replace('script = ExtResource("1_level")', f'script = ExtResource("1_level")\n{assignment}', 1)
    if "load_steps=4" not in text:
        raise ValueError(f"Expected exactly three dependencies for new stage: {path}")
    return path, text


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check all ten generated sources without writing files.")
    args = parser.parse_args()
    sources = []
    missing = []
    for stage, slug, name in REGIONS:
        folder = f"{stage:02d}-{slug}"
        title = ROOT / f"output/imagegen/map-titles-11-15/{folder}/landscape-raw.png"
        ground = ROOT / f"output/imagegen/battle-regions/{folder}/battlefield.png"
        for path in [title, ground]:
            if not path.is_file():
                missing.append(path.relative_to(ROOT).as_posix())
        sources.append((stage, name, folder + ".png", title, ground))
    if missing:
        print(json.dumps({"ready": False, "missing": missing}, ensure_ascii=False, indent=2))
        raise SystemExit(2)
    for _, _, _, title, ground in sources:
        with Image.open(title) as image:
            image.verify()
        with Image.open(ground) as image:
            if image.size != (720, 740):
                raise ValueError(f"Ground must be 720x740: {ground}")
            image.load()
            if image.mode == "RGBA" and image.getchannel("A").getextrema() != (255, 255):
                raise ValueError(f"Ground must be opaque: {ground}")
    if args.check:
        print(json.dumps({"ready": True, "regions": len(sources), "sources": len(sources) * 2}))
        return

    lobby_manifest = read_json(LOBBY / "manifest.json")
    battle_manifest = read_json(BATTLE / "manifest.json")
    old_records = {
        directory: copy.deepcopy([entry for entry in manifest["maps"] if entry["stage"] <= 10])
        for directory, manifest in [(LOBBY, lobby_manifest), (BATTLE, battle_manifest)]
    }
    preserved = {}
    for directory, records in old_records.items():
        if len(records) != 10 or {entry["stage"] for entry in records} != set(range(1, 11)):
            raise ValueError(f"Expected ten existing region records: {directory}")
        for entry in records:
            target = directory / entry["file"]
            if sha256(target) != entry["sha256"]:
                raise ValueError(f"Existing art does not match its manifest: {target}")
            if directory == LOBBY and not (ROOT / entry["source"]).with_name("landscape-raw.png").is_file():
                raise ValueError(f"Missing original for existing lobby art: {entry['source']}")
            preserved[target] = entry["sha256"]
    for stage in range(1, 11):
        path = ROOT / f"game/data/levels/level_{stage:02d}.tres"
        preserved[path] = sha256(path)

    bindings = []
    for stage, name, filename, title, ground in sources:
        bindings.append(level_binding(stage, filename))
        target = BATTLE / filename
        if target.exists() and sha256(target) != sha256(ground):
            raise ValueError(f"Refusing to replace different existing ground: {target}")
        for manifest, record in [
            (lobby_manifest, {"stage": stage, "name": name, "file": filename,
                              "source": title.relative_to(ROOT).as_posix()}),
            (battle_manifest, {"stage": stage, "name": name, "file": filename,
                               "size": [720, 740], "sha256": sha256(ground),
                               "source": ground.relative_to(ROOT).as_posix()}),
        ]:
            existing = [item for item in manifest["maps"] if item["stage"] == stage]
            if len(existing) > 1:
                raise ValueError(f"Duplicate manifest stage: {stage}")
            if existing:
                if any(existing[0].get(key) != value for key, value in record.items()):
                    raise ValueError(f"Unexpected existing manifest record: {stage}")
            else:
                manifest["maps"].append(record)

    # All source files, current hashes, targets and resource edits have passed
    # preflight before any production file is touched.
    for _, _, filename, _, ground in sources:
        target = BATTLE / filename
        if not target.exists():
            shutil.copyfile(ground, target)
    lobby_manifest["maps"].sort(key=lambda entry: entry["stage"])
    battle_manifest["maps"].sort(key=lambda entry: entry["stage"])
    lobby_manifest["scope"] = "Regional title panoramas for all 15 playable stages; live stage names remain separate."
    battle_manifest["scope"] = "Regional ground art for all 15 playable stages; castles, flags, actors and board remain separate."
    write_json(LOBBY / "manifest.json", lobby_manifest)
    write_json(BATTLE / "manifest.json", battle_manifest)
    subprocess.run([sys.executable, str(ROOT / "tools/ui/install_lobby_map_titles.py")], check=True, cwd=ROOT)
    for path, text in bindings:
        if path.read_text(encoding="utf-8") != text:
            path.write_text(text, encoding="utf-8", newline="\n")

    (LOBBY / "README.md").write_text("""# Lobby regional title panoramas

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
""", encoding="utf-8")
    (BATTLE / "README.md").write_text("""# Regional battle ground

Ground-only PNGs for all 15 stages, bound through `LevelData.battlefield`.
Each bitmap is 720×740 and draws at (0,0) on the 720×1280 battle canvas.
Castle rear/foreground, flags, units and the gear table stay separate.
Levels with no `battlefield` resource use the original woodland fallback.

Generated with `gpt-image-2.5-sunburst` via the user-selected local 9Router API.
Originals, per-region prompts and review images: `output/imagegen/battle-regions/`.
`manifest.json` records original byte hashes; these production PNGs are unchanged copies.
""", encoding="utf-8")

    for path, expected in preserved.items():
        if sha256(path) != expected:
            raise RuntimeError(f"Existing stage 1–10 file changed: {path}")
    for directory, records in old_records.items():
        current = [entry for entry in read_json(directory / "manifest.json")["maps"] if entry["stage"] <= 10]
        if current != records:
            raise RuntimeError(f"Existing stage 1–10 manifest records changed: {directory}")
    print(json.dumps({"installed_stages": [entry[0] for entry in sources],
                      "existing_assets_and_bindings_unchanged": len(preserved),
                      "lobby_size": [476, 90], "battle_size": [720, 740]}, ensure_ascii=False))


if __name__ == "__main__":
    main()
