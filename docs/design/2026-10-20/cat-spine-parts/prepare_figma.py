"""Build the editable-layer payload consumed by the Figma publishing step."""
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
PROJECT = BASE.parents[3]


def main():
    manifest = json.loads((BASE / "manifest.json").read_text(encoding="utf-8"))
    cats = []
    for key, spec in manifest["cats"].items():
        folder = BASE / spec["directory"]
        cats.append({
            "key": key,
            "stroke": spec["source_body_stroke_px"],
            "source": (PROJECT / spec["source"]).read_text(encoding="utf-8"),
            "layers": [
                {"name": name, "svg": (folder / f"{name}.svg").read_text(encoding="utf-8")}
                for name in spec["layer_order_back_to_front"]
            ],
        })
    output = BASE / "figma-payload.json"
    output.write_text(json.dumps(cats, ensure_ascii=True), encoding="utf-8")
    print(output)


if __name__ == "__main__":
    main()
