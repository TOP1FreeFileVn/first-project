"""Add a "hammer" clip to the lobby cat rigs (game/assets/units/lobby_<coat>/lobby_<coat>.json)
for the castle-building scene: the right paw lifts high and slams down twice a second, the
body bobs with each blow and the tail flicks. A "bang" event marks each blow, so the game
plays a knock and puffs dust there. The hammer is a sprite the game pins to the paw.

    python -I tools/ui/add_lobby_hammer_clip.py

Re-run after make_lobby_cat_rigs.py (which writes the rigs without this clip).
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from make_soldier_spine import keys

ROOT = Path(__file__).resolve().parents[2]
COATS = ["tabby", "cream", "calico", "grey"]


def hammer():
    # One blow = 0.5 s: wind up (paw high and back), slam (paw down at 0.3), recoil.
    T = [0, 0.18, 0.3, 0.38, 0.5]
    return {
        "bones": {
            "paw_r": {"rotate": keys(T, value=[0, 110, -30, -10, 0]),
                      "translate": keys(T, x=[0, -6, 8, 4, 0], y=[0, 46, -6, 0, 0])},
            "paw_l": {"rotate": keys(T, value=[0, -10, 6, 0, 0])},
            "body": {"rotate": keys(T, value=[0, 6, -8, -4, 0])},
            "hip": {"translate": keys(T, x=[0, 0, 0, 0, 0], y=[0, 4, -5, -2, 0]),
                    "scale": keys(T, x=[1, 0.98, 1.06, 1.02, 1], y=[1, 1.04, 0.92, 0.98, 1])},
            "head": {"rotate": keys(T, value=[0, -6, 8, 4, 0])},
            "ear_l": {"rotate": keys(T, value=[0, 0, 10, 4, 0])},
            "ear_r": {"rotate": keys(T, value=[0, 0, -10, -4, 0])},
            "tail": {"rotate": keys(T, value=[0, 18, -14, -6, 0])},
        },
        "events": [{"time": 0.3, "name": "bang"}],
    }


def main():
    for coat in COATS:
        path = ROOT / "game/assets/units" / f"lobby_{coat}" / f"lobby_{coat}.json"
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        data.setdefault("events", {})["bang"] = {}
        names = {b["name"] for b in data["bones"]}
        clip = hammer()
        clip["bones"] = {b: tl for b, tl in clip["bones"].items() if b in names}
        data["animations"]["hammer"] = clip
        path.write_text(json.dumps(data, indent=1), encoding="utf-8")
        print(path.name, sorted(data["animations"]))


if __name__ == "__main__":
    main()
