extends RefCounted

# Retention features: the 7-day login gift, daily quests with activity milestones, and
# the avatars / frames for the player profile. Rewards are dictionaries that
# PlayerData.grant() understands: {"gold": n}, {"gems": n}, {"cards": n} (random troop
# cards), {"blueprints": n} (random-slot Blueprints),
# {"item": rarity} (a random hero-cat item).

const LOGIN_REWARDS := [
	{"gold": 300},
	{"gems": 20},
	{"cards": 8},
	{"blueprints": 12},
	{"gems": 50},
	{"gold": 1500},
	{"item": 2},
]

## Quests reset every day. "login" completes itself.
const QUESTS := [
	{"id": "login", "text": "Đăng nhập trò chơi", "goal": 1, "reward": {"gold": 100}},
	{"id": "win", "text": "Thắng 2 trận", "goal": 2, "reward": {"gold": 300}},
	{"id": "chest", "text": "Mở 1 rương", "goal": 1, "reward": {"gems": 5}},
	{"id": "upgrade", "text": "Nâng cấp lính hoặc trang bị 2 lần", "goal": 2, "reward": {"gold": 200}},
	{"id": "patrol", "text": "Thu hoạch tuần tra 1 lần", "goal": 1, "reward": {"gold": 150}},
	{"id": "summon", "text": "Triệu hồi lính 1 lần", "goal": 1, "reward": {"gems": 10}},
]
const QUEST_POINTS := 20
const QUEST_MILESTONES := [
	{"points": 40, "reward": {"gold": 400}},
	{"points": 80, "reward": {"gems": 20, "blueprints": 2}},
	{"points": 120, "reward": {"blueprints": 8}},
]

## Profile pictures, all cats: the five cat faces, then the sixteen cat soldiers.
const AVATARS := [
	"head:tabby", "head:grey", "head:calico", "head:cream", "head:hero",
	"kiem", "cung", "gay_phep", "giao", "riu", "no", "thuoc", "cu_kiem",
	"dao", "sung", "sach_phep", "chuy", "katana", "dai_bac", "dua_phep", "bua",
]
const AVATAR_COUNT := 21
## Levels cleared to unlock each row of five avatars (the last row holds one).
const AVATAR_ROW_NEEDS := [0, 0, 3, 6, 9]

const FRAME_ORDER := ["wood", "silver", "gold", "royal"]
const FRAMES := {
	"wood": {"name": "Gỗ", "color": Color("9a6a3a"), "need": "Mặc định"},
	"silver": {"name": "Bạc", "color": Color("d6dee6"), "need": "Qua 3 màn"},
	"gold": {"name": "Vàng", "color": Color("f2c14e"), "need": "Nhận đủ quà 7 ngày"},
	"royal": {"name": "Hoàng gia", "color": Color("c28bff"), "need": "Có trang bị Huyền thoại"},
}


## Skin image name of avatar `index` (1-based): a cat head or a cat soldier.
static func avatar_image(index: int) -> String:
	var key: String = AVATARS[clampi(index, 1, AVATAR_COUNT) - 1]
	return "cat_head_" + key.substr(5) if key.begins_with("head:") else "unit_" + key


static func avatar_need(index: int) -> int:
	return AVATAR_ROW_NEEDS[(index - 1) / 5]


static func quest(id: String) -> Dictionary:
	for q in QUESTS:
		if q["id"] == id:
			return q
	return {}
