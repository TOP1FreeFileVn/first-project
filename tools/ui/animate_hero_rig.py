"""Add the hero cat's own animations to its rigs (game/assets/hero/<family>/<family>.json).

build_hero_preview_rig.py makes the rigs with only "idle". This adds, without touching the
art or the bones:
  battle  - "run", "attack" (slash / shoot / cast by weapon, with a "hit" event);
  lobby   - "walk"  : a proud march, the cape swaying behind;
            "train" : two practice strikes then a breath (a "swipe" event per strike);
            "pose"  : chest out, weapon raised high, cape blowing in the wind;
            "look"  : stands guard, looks left and right over the courtyard;
            "cheer" : tapped: a hop with the weapon thrown up.
The cape and the weapon move in every clip, which ordinary cats do not have.

    python -I tools/ui/animate_hero_rig.py
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from make_soldier_spine import attack_animation, cast_animation, keys, run_animation, shoot_animation

ROOT = Path(__file__).resolve().parents[2]
HERO = ROOT / "game/assets/hero"
## Which paw holds the weapon, and how the family attacks.
FAMILIES = {
    "bare": ("paw_r", "slash"), "melee": ("paw_r", "slash"), "heavy": ("paw_r", "slash"),
    "katana": ("paw_r", "slash"), "magic": ("paw_r", "cast"), "ranged": ("paw_l", "shoot"),
}
ATTACKS = {"slash": attack_animation, "shoot": shoot_animation, "cast": cast_animation}


def loop(period, n=4):
    return [round(period * i / n, 4) for i in range(n + 1)]


def swap_paws(anim, hand):
    """The clips are written for a right-handed weapon; a left hand mirrors the paw tracks."""
    if hand == "paw_r":
        return anim
    bones = anim["bones"]
    r, l = bones.pop("paw_r", None), bones.pop("paw_l", None)
    for name, track in (("paw_l", r), ("paw_r", l)):
        if track is None:
            continue
        for k in track.get("rotate", []):
            k["value"] = -k["value"]
        for k in track.get("translate", []):
            k["x"] = -k.get("x", 0)
        bones[name] = track
    return anim


def cape(times, values):
    return {"rotate": keys(times, value=values)}


def walk():
    anim = run_animation()
    # A march, not a dash: slower, lower bounce, the weapon held steady.
    for tl in anim["bones"].values():
        for ch, ks in tl.items():
            for k in ks:
                if "time" in k:
                    k["time"] = round(k["time"] * 1.6, 4)
                for c in ("x", "y", "value"):
                    if c in k and ch != "scale":
                        k[c] = round(k[c] * 0.65, 3)
    T = loop(0.704)
    anim["bones"]["cape"] = cape(T, [0, 6, 0, 6, 0])
    anim["bones"]["head"]["rotate"] = keys([0], value=[-2])
    return anim


def run():
    anim = run_animation()
    anim["bones"]["cape"] = cape(loop(0.44), [4, 12, 4, 12, 4])
    return anim


def attack(style):
    anim, events = ATTACKS[style]()
    anim["bones"]["cape"] = cape([0, 0.14, 0.22, 0.5], [0, -6, 10, 0])
    anim["events"] = events
    return anim


def train(style):
    """Two strikes 0.5 s apart, then a 0.8 s breath with the weapon lowered."""
    one, _ = ATTACKS[style]()
    out = {"bones": {}}
    for bone, tl in one["bones"].items():
        out["bones"][bone] = {}
        for ch, ks in tl.items():
            track = []
            for rep in (0.0, 0.5):
                for k in ks:
                    t = round(float(k.get("time", 0.0)) + rep, 4)
                    if rep > 0 and t == rep:
                        continue
                    nk = dict(k)
                    nk.pop("time", None)
                    if t:
                        nk["time"] = t
                    track.append(nk)
            rest = dict(ks[0])
            rest.pop("time", None)
            rest["time"] = 1.8
            track.append(rest)
            out["bones"][bone][ch] = track
    out["bones"]["cape"] = cape([0, 0.22, 0.5, 0.72, 1.0, 1.8], [0, 10, 0, 10, 0, 0])
    out["events"] = [{"time": 0.22, "name": "swipe"}, {"time": 0.72, "name": "swipe"}]
    return out


def pose():
    """Proud stance: chest out, weapon high over the head, cape blowing."""
    T = loop(1.6)
    return {"bones": {
        "hip": {"scale": keys(loop(1.6, 2), x=[0.98, 1.0, 0.98], y=[1.06, 1.08, 1.06])},
        "body": {"rotate": keys([0], value=[-3])},
        "head": {"rotate": keys(T, value=[-6, -8, -6, -8, -6]), "translate": keys([0], x=[0], y=[4])},
        # The weapon already points up in the setup pose: lift the paw, tilt it back a little.
        "paw_r": {"rotate": keys([0], value=[18]), "translate": keys([0], x=[-4], y=[36])},
        "weapon": {"rotate": keys(T, value=[0, 3, 0, -3, 0])},
        "paw_l": {"rotate": keys([0], value=[-30]), "translate": keys([0], x=[6], y=[6])},
        "cape": cape(loop(0.8), [10, 20, 12, 22, 10]),
        "tail": {"rotate": keys(T, value=[20, 28, 20, 14, 20])},
    }}


def look():
    """On guard: turns its head (and a little body) to one side, then the other."""
    T = [0, 0.6, 1.4, 2.0, 2.8, 3.4]
    return {"bones": {
        "hip": {"scale": keys(loop(3.4, 2), x=[1, 1.02, 1], y=[1, 1.03, 1])},
        "body": {"rotate": keys(T, value=[0, 3, 3, 0, -3, 0])},
        "head": {"rotate": keys(T, value=[0, 12, 12, 0, -12, 0]),
                 "translate": keys(T, x=[0, 4, 4, 0, -4, 0], y=[0, 0, 0, 0, 0, 0])},
        "cape": cape(loop(3.4), [0, 4, 0, -4, 0]),
        "tail": {"rotate": keys(loop(3.4), value=[0, 10, 0, -10, 0])},
    }}


def cheer():
    """Tapped: a hop with the weapon thrown up, tail high. 0.9 s."""
    H = [0, 0.15, 0.4, 0.9]
    return {"bones": {
        "hip": {"translate": keys(H, x=[0, 0, 0, 0], y=[0, -6, 24, 0]),
                "scale": keys(H, x=[1, 1.08, 0.94, 1], y=[1, 0.9, 1.08, 1])},
        "head": {"rotate": keys(H, value=[0, 4, -10, 0])},
        "paw_r": {"rotate": keys(H, value=[0, -8, 22, 0]), "translate": keys(H, x=[0, 0, -4, 0], y=[0, -4, 38, 0])},
        "paw_l": {"rotate": keys(H, value=[0, -10, -60, 0]), "translate": keys(H, x=[0, 0, 4, 0], y=[0, 0, 22, 0])},
        "cape": cape(H, [0, -6, 24, 0]),
        "tail": {"rotate": keys(H, value=[0, -10, -34, 0])},
        # The feet hang from root, not the hip: they leave the ground with the body.
        "leg_l": {"translate": keys(H, x=[0, 0, 0, 0], y=[0, 0, 22, 0])},
        "leg_r": {"translate": keys(H, x=[0, 0, 0, 0], y=[0, 0, 22, 0])},
    }}


def main():
    for family, (hand, style) in FAMILIES.items():
        path = HERO / family / f"{family}.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        idle = data["animations"]["idle"]
        idle["bones"]["cape"] = cape(loop(1.2), [0, 3, 0, -3, 0])
        data["animations"] = {
            "idle": idle,
            "walk": swap_paws(walk(), hand),
            "run": swap_paws(run(), hand),
            "attack": swap_paws(attack(style), hand),
            "train": swap_paws(train(style), hand),
            "pose": swap_paws(pose(), hand),
            "look": look(),
            "cheer": swap_paws(cheer(), hand),
        }
        path.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        print(family, sorted(data["animations"]))


if __name__ == "__main__":
    main()
