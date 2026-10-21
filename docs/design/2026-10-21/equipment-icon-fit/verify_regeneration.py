"""Check icon-only idempotence and full installer output without touching held art."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ART = ROOT / "game/ui/art"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


before = {p.name: digest(p) for p in ART.glob("*.png")}
manifest_before = digest(ART / "equipment-sources.json")
subprocess.run([sys.executable, "-B", str(ROOT / "tools/ui/install_equipment_art.py"), "--icons-only"], check=True)
after = {p.name: digest(p) for p in ART.glob("*.png")}
idempotent = before == after and manifest_before == digest(ART / "equipment-sources.json")

spec = importlib.util.spec_from_file_location("equipment_installer", ROOT / "tools/ui/install_equipment_art.py")
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)
scratch_parent = (ROOT / "output").resolve()
scratch_parent.mkdir(exist_ok=True)
# TemporaryDirectory cleanup is constrained to this verified workspace subtree.
with tempfile.TemporaryDirectory(prefix="equipment-icon-regeneration-", dir=scratch_parent) as temporary:
    temporary_path = Path(temporary).resolve()
    assert temporary_path.is_relative_to(scratch_parent) and scratch_parent.is_relative_to(ROOT)
    installer.OUT = temporary_path
    installer.install_all_art()
    installer.install_equipment_icons()
    regenerated = {p.name: digest(p) for p in temporary_path.glob("*.png")}
    differences = sorted(name for name in before.keys() | regenerated.keys()
                         if before.get(name) != regenerated.get(name))

baseline = json.loads((HERE / "baseline-hashes.json").read_text("utf-8"))
held_names = sorted(name for name in baseline if name.startswith(("unit_", "hero_cat_", "cat_hero")))
held_changed = sorted(name for name in held_names if baseline[name] != after[name])
report = {"icon_only_png_and_manifest_idempotent": idempotent,
          "production_png_count": len(before), "isolated_full_regeneration_png_count": len(regenerated),
          "full_regeneration_sha256_differences": differences,
          "held_and_soldier_png_count": len(held_names), "held_and_soldier_changed_from_baseline": held_changed}
(HERE / "regeneration-check.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report, indent=2))
if not idempotent or differences or held_changed:
    raise SystemExit(1)
