"""Writes the 16 cat soldiers (game/data/troops/<weapon>.tres) from the design sheet's
"Solider (sửa)" tab, and tags the old human troops (now the enemy roster) with a class.

Sheet units -> game units, chosen so the sheet's baseline (Kiếm) matches the old Warrior
the levels were tuned for:
  damage = Tấn công x 0.4, max_hp = Máu x 1.4, attack_cooldown = 1 / Tốc độ đánh,
  spawn_interval = 0.72 / Tốc độ sx, move_speed = Tốc độ d/c x 15.7,
  attack_range = Tầm x 18 (melee) or x 25.5 (ranged).
Run: python -I tools/data/make_cat_troops.py   (re-run after editing the sheet numbers)
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TROOPS = ROOT / "game" / "data" / "troops"

INFANTRY, RANGED, MAGE, CAVALRY = range(4)
KLASS = {INFANTRY: "tabby", RANGED: "grey", MAGE: "calico", CAVALRY: "cream"}  # cat coat per class
MELEE_ROLE, RANGED_ROLE = 0, 1
BOMB = 7

# id, name, rarity, klass, atk, hp, crit, critdmg, prod/s, move, atk/s, range, note
SHEET = [
    ("kiem", "Mèo Kiếm", 0, INFANTRY, 20, 60, 0.12, 1.5, 0.16, 3.5, 1.0, 2.1, "Kiếm sĩ cân bằng, giữ hàng đầu."),
    ("riu", "Mèo Rìu", 1, INFANTRY, 43, 90, 0.24, 1.5, 0.14, 3.5, 0.67, 2.1, "Bổ rìu nặng, chí mạng cao."),
    ("dao", "Mèo Đao", 2, INFANTRY, 56, 140, 0.16, 1.5, 0.12, 3.5, 0.83, 2.1, "Đao dài, vừa trâu vừa đau."),
    ("katana", "Mèo Katana", 3, INFANTRY, 70, 285, 0.30, 1.5, 0.08, 3.5, 1.25, 2.1, "Kiếm khách huyền thoại, chém liên hồi."),
    ("cung", "Mèo Cung", 0, RANGED, 10, 30, 0.12, 1.5, 0.16, 3.5, 1.0, 9, "Bắn xa từ phía sau, máu giấy."),
    ("no", "Mèo Nỏ", 1, RANGED, 19, 42, 0.21, 1.5, 0.14, 3.5, 0.75, 9, "Tên nỏ xuyên giáp, bắn chắc tay."),
    ("sung", "Mèo Súng", 2, RANGED, 27, 64, 0.24, 1.5, 0.12, 3.5, 0.83, 9, "Súng hoả mai, mỗi phát một nhát đau."),
    ("dai_bac", "Mèo Đại Bác", 3, RANGED, 130, 128, 0.30, 1.5, 0.08, 3.0, 0.33, 9, "Đại bác chậm nhưng nổ lan cả đám."),
    ("gay_phep", "Mèo Gậy Phép", 0, MAGE, 19, 36, 0.20, 1.5, 0.16, 3.5, 0.83, 10, "Phép thuật cơ bản, sát thương cao máu thấp."),
    ("thuoc", "Mèo Bình Thuốc", 1, MAGE, 29, 55, 0.10, 1.5, 0.14, 3.5, 0.83, 10, "Ném bình thuốc nổ phép."),
    ("sach_phep", "Mèo Sách Phép", 2, MAGE, 55, 85, 0.20, 1.5, 0.12, 3.5, 0.67, 10, "Đọc chú từ sách cổ, phép rất mạnh."),
    ("dua_phep", "Mèo Đũa Phép", 3, MAGE, 71, 170, 0.25, 1.5, 0.08, 3.5, 1.0, 10, "Pháp sư huyền thoại, phép liên tục."),
    ("giao", "Mèo Giáo", 0, CAVALRY, 20, 72, 0.08, 1.5, 0.16, 6.0, 0.77, 2.4, "Kỵ binh máu trâu, lao lên rất nhanh."),
    ("cu_kiem", "Mèo Cự Kiếm", 1, CAVALRY, 34, 109, 0.10, 1.5, 0.14, 6.0, 0.67, 2.4, "Vác cự kiếm xông thẳng vào địch."),
    ("chuy", "Mèo Chuỳ", 2, CAVALRY, 54, 170, 0.10, 1.5, 0.12, 6.0, 0.67, 2.4, "Chuỳ gai nặng, đập choáng tiền tuyến."),
    ("bua", "Mèo Búa", 3, CAVALRY, 116, 340, 0.30, 1.5, 0.08, 6.0, 0.56, 2.4, "Búa chiến huyền thoại, trâu nhất đội."),
]
MAX_ALIVE = [3, 2, 2, 1]

# Old human troops: now the dungeon monsters (art from tools/ui/make_units.py). Name, class.
ENEMY_NAMES = {"pawn": "Slime", "warrior": "Goblin Kiếm", "archer": "Goblin Cung", "miner": "Chuột Chũi",
               "smith": "Goblin Thợ Rèn", "lancer": "Kỵ Sĩ Xương", "assassin": "Dơi Đêm", "guard": "Lính Xương Khiên",
               "fire_archer": "Xương Nỏ Lửa", "monk": "Nấm Thầy Thuốc", "cook": "Orc Đầu Bếp", "bomber": "Goblin Bom",
               "general": "Vua Orc"}
ENEMY_KLASS = {"pawn": INFANTRY, "warrior": INFANTRY, "miner": INFANTRY, "guard": INFANTRY, "general": INFANTRY,
               "archer": RANGED, "fire_archer": RANGED, "bomber": RANGED,
               "smith": MAGE, "monk": MAGE, "cook": MAGE,
               "lancer": CAVALRY, "assassin": CAVALRY}


def num(v):
    return f"{float(v):.3f}".rstrip("0").rstrip(".") + ("" if "." in f"{float(v):.3f}".rstrip("0").rstrip(".") else ".0")


def write_cat(row):
    tid, name, rarity, klass, atk, hp, crit, cdmg, prod, move, aspd, rng, note = row
    melee = klass in (INFANTRY, CAVALRY)
    attack_range = rng * (18 if melee else 25.5)
    lines = [
        '[gd_resource type="Resource" format=3]',
        "",
        '[ext_resource type="Script" path="res://game/data/TroopData.gd" id="1_troop"]',
        "",
        "[resource]",
        'script = ExtResource("1_troop")',
        f'id = "{tid}"',
        f'display_name = "{name}"',
        f'description = "{note}"',
        f"rarity = {rarity}",
        f'unit_key = "art:{tid}"',
        f"role = {MELEE_ROLE if melee else RANGED_ROLE}",
        f"klass = {klass}",
        f"max_hp = {num(round(hp * 1.4))}",
        f"damage = {num(round(atk * 0.4, 1))}",
        f"attack_range = {num(round(attack_range))}",
        f"attack_cooldown = {num(round(1.0 / aspd, 2))}",
        f"move_speed = {num(round(move * 15.7))}",
        f"aggro_range = {num(max(220, round(attack_range) + 60))}",
        f"crit_chance = {num(crit)}",
        f"crit_mult = {num(cdmg)}",
        f"spawn_interval = {num(round(0.72 / prod, 2))}",
        f"max_alive = {MAX_ALIVE[rarity]}",
    ]
    if tid == "dai_bac":
        lines += [f"ability = {BOMB}", 'ability_text = "Đạn nổ trúng mọi địch quanh điểm rơi."', "ability_radius = 70.0"]
    (TROOPS / f"{tid}.tres").write_text("\n".join(lines) + "\n", encoding="utf-8")


def tag_enemy(tid, klass):
    path = TROOPS / f"{tid}.tres"
    text = path.read_text(encoding="utf-8")
    lines = [l for l in text.splitlines() if not l.startswith(("klass = ", "unit_key = ", "tint = ", "display_name = "))]
    at = next(i for i, l in enumerate(lines) if l.startswith("id = "))
    lines[at + 1:at + 1] = [f'display_name = "{ENEMY_NAMES[tid]}"', f'unit_key = "art:{tid}"'] + ([f"klass = {klass}"] if klass else [])
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    for row in SHEET:
        write_cat(row)
    for tid, klass in ENEMY_KLASS.items():
        tag_enemy(tid, klass)
    print(f"{len(SHEET)} cat soldiers written, {len(ENEMY_KLASS)} enemies tagged")
