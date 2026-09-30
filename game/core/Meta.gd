extends RefCounted

# Retention features: the 7-day login gift, daily quests with activity milestones, and
# the avatars / frames for the player profile. Rewards are dictionaries that
# PlayerData.grant() understands: {"gold": n}, {"gems": n}, {"cards": n} (random troop
# cards), {"shards": [hero id or "featured", n]}, {"hero": id}.

const LOGIN_REWARDS := [
	{"gold": 300},
	{"gems": 20},
	{"cards": 8},
	{"shards": ["featured", 10]},
	{"gems": 50},
	{"gold": 1500},
	{"hero": "sage"},
]

## Quests reset every day. "login" completes itself.
const QUESTS := [
	{"id": "login", "text": "Đăng nhập trò chơi", "goal": 1, "reward": {"gold": 100}},
	{"id": "win", "text": "Thắng 2 trận", "goal": 2, "reward": {"gold": 300}},
	{"id": "chest", "text": "Mở 1 rương", "goal": 1, "reward": {"gems": 5}},
	{"id": "upgrade", "text": "Nâng cấp lính hoặc tướng 2 lần", "goal": 2, "reward": {"gold": 200}},
	{"id": "patrol", "text": "Thu hoạch tuần tra 1 lần", "goal": 1, "reward": {"gold": 150}},
	{"id": "summon", "text": "Triệu hồi tướng 1 lần", "goal": 1, "reward": {"gems": 10}},
]
const QUEST_POINTS := 20
const QUEST_MILESTONES := [
	{"points": 40, "reward": {"gold": 400}},
	{"points": 80, "reward": {"gems": 20}},
	{"points": 120, "reward": {"shards": ["featured", 5]}},
]

const AVATAR_COUNT := 25
## Levels cleared to unlock each row of five avatars.
const AVATAR_ROW_NEEDS := [0, 0, 3, 6, 9]

const FRAME_ORDER := ["wood", "silver", "gold", "royal"]
const FRAMES := {
	"wood": {"name": "Gỗ", "color": Color("9a6a3a"), "need": "Mặc định"},
	"silver": {"name": "Bạc", "color": Color("d6dee6"), "need": "Qua 3 màn"},
	"gold": {"name": "Vàng", "color": Color("f2c14e"), "need": "Nhận đủ quà 7 ngày"},
	"royal": {"name": "Hoàng gia", "color": Color("c28bff"), "need": "Có tướng Huyền thoại"},
}


static func avatar_path(index: int) -> String:
	return "UI Elements/UI Elements/Human Avatars/Avatars_%02d.png" % index


static func avatar_need(index: int) -> int:
	return AVATAR_ROW_NEEDS[(index - 1) / 5]


static func quest(id: String) -> Dictionary:
	for q in QUESTS:
		if q["id"] == id:
			return q
	return {}
