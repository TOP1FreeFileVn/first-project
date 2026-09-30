# Thiết kế: Bảng Admin (chỉnh cân bằng, công thức, dữ liệu)

## Cách dùng (đã làm xong A → G)

1. Chạy game bản debug (F5 trong editor, hoặc APK "Export With Debug").
2. Ở sảnh, bấm nút đỏ **ADMIN** trên thanh trên cùng (cạnh nút cài đặt). Không cần PIN. *(Trước đây là chạm avatar 7 lần + PIN; đã bỏ theo yêu cầu.)*
3. Sửa gì cũng **có hiệu lực ngay** trong bộ nhớ. Bấm **LƯU** (kèm ghi chú) để giữ lại trên máy; đóng khi chưa lưu sẽ được hỏi.
4. **JSON**: copy/dán để chuyển cấu hình sang máy khác; **GHI VÀO BẢN BUILD** (chỉ khi chạy từ editor) ghi thẳng vào
   `game/data/balance.json` và các file `.tres`, sau đó build lại là người chơi nhận số mới.
5. **L.SỬ**: 20 lần lưu gần nhất, khôi phục được.

Kiểm thử: `tests/BalanceTest.tscn` (13 công thức khớp code cũ trên toàn dải + kiểm tra chặn công thức sai, hoàn tác, xuất/nhập),
`tests/AdminShots.tscn` (chụp mọi tab).

> **Lưu ý kỹ thuật:** `Expression` của Godot **âm thầm bỏ qua phần thừa** ở cuối công thức (`level * 2 level` = `level * 2`)
> và **không hỗ trợ `a if điều_kiện else b`** (luôn trả về `a`). `FormulaEngine.gd` có bộ phân tích cú pháp riêng để chặn cả hai;
> điều kiện viết dạng `int(điều_kiện)`, ví dụ số sao: `1 + int(hp_ratio >= 0.45) + int(hp_ratio >= 0.8)`.

---

> Mục tiêu: người thiết kế game chỉnh **mọi con số và công thức** ngay trong game, thấy kết quả tức thì
> (bảng giá trị, biểu đồ, chơi thử), rồi lưu lại hoặc xuất ra để đưa vào bản build.

---

## 0. Hiện trạng: con số đang nằm ở đâu

Hiện mọi thứ là **hằng số viết cứng trong code**, muốn đổi phải sửa file `.gd` và chạy lại.

### 0.1 Công thức (có biến đầu vào)

| # | Công thức | Hiện tại | File |
|---|---|---|---|
| F1 | Giá lên cấp lính | `round(50 × 1.35^(cấp−1))` | `Economy.level_cost` |
| F2 | Hệ số sức mạnh lính (cấp, sao) | `(1 + 0.08×(cấp−1)) × 1.2^(sao−1)` | `PlayerData.troop_multiplier` |
| F3 | Hệ số bậc gear trong trận | `1.75^(bậc−1)` | `Battle.TIER_POWER` |
| F4 | Thời gian sinh lính của gear | `gốc × 0.92^(bậc−1) ÷ (1 + %bánh_răng_tổng)` | `Gear.spawn_interval` |
| F5 | Giá triệu hồi trong trận | `min(2 + floor(số_lần ÷ 3), 9)` | `Core.summon_cost` |
| F6 | Sức mạnh quân địch | `power_màn × (1 + 0.2 × đợt)` | `Battle._spawn_enemy` |
| F7 | Tinh nhuệ | máu ×5, sát thương ×1.8 | `Battle._spawn_enemy` |
| F8 | Sát thương vào tường | `sát_thương × 0.35` | `Battle.SIEGE_DAMAGE` |
| F9 | Thời gian hồi thịt | `1.6 × (1 − %lò_thịt)` | `PlayerData.meat_regen_time` |
| F10 | Giá xưởng | `base × growth^cấp` | `Economy.workshop_cost` |
| F11 | Vàng thắng trận | `60 + 40×(màn) + 20×sao`, lần đầu ×2 | `Economy.win_gold` |
| F12 | Vàng thua trận | `15 × số_đợt_đã_qua` | `Economy.loss_gold` |
| F13 | Vàng tuần tra mỗi giờ | `60 + 60 × số_màn_đã_qua` | `Economy.patrol_rate` |
| F14 | Số sao cuối trận | ≥80% máu → 3★, ≥45% → 2★, còn lại 1★ | `Battle._on_all_waves_cleared` |

### 0.2 Bảng và hằng số (không có biến)

- Bảng 10 cấp thành (máu, thịt, số ô, giá) · thẻ cần để lên sao `[10, 30]` · số cấp mỗi sao `10`.
- Rương: số thẻ, giá, vàng thưởng, bảo hiểm `10`, tỉ lệ `64/32/4`, hồi rương gỗ `4 giờ`.
- Đổi kim cương `20 → 500` · thịt khi giết `0.35` / tinh nhuệ `3` · thịt tối đa · kho tuần tra `8 giờ`...

### 0.3 Dữ liệu

- **5 lính** (`game/data/troops/*.tres`): máu, sát thương, tầm, hồi chiêu, tốc chạy, tầm phát hiện, thời gian sinh, số lính tối đa, tỉ lệ ra khi triệu hồi, độ hiếm.
- **10 màn** (`game/data/levels/*.tres`): tên, sức mạnh, máu thành, thịt đầu, thời gian chuẩn bị, **các đợt và nhóm quân**.

---

## 1. Hướng giải quyết: lớp "Balance" ở giữa

```
          ┌──────────── mặc định ────────────┐
          │ res://game/data/balance.json      │  ← đi theo bản build
          └──────────────┬───────────────────┘
                         │ ghép
          ┌──────────────▼───────────────────┐
          │ user://balance_override.json      │  ← thay đổi của admin trên máy này
          └──────────────┬───────────────────┘
                         ▼
   Balance (autoload) ── value("siege_damage")
                      ── formula("level_cost", {"level": 5})
                      ── troop_stat("warrior", "max_hp") / level_override(...)
                         ▲
     Economy · PlayerData · Battle · Core · Gear  (đọc qua Balance, không còn hằng số cứng)
```

- **Mọi con số** chuyển vào `balance.json`. Code đọc qua `Balance`, không còn `const` cho số cân bằng.
- **Công thức lưu dạng chuỗi**, ví dụ `"round(50 * pow(1.35, level - 1))"`, và tính bằng lớp **`Expression`** có sẵn của Godot.
  Mỗi công thức khai báo rõ **biến được dùng** (`level`, `stars`, `tier`...).
- Admin sửa thì ghi vào **file override** trên máy. Nút **"Về mặc định"** chỉ cần xoá override.
- **Xuất ra bản build**: ghi đè `res://game/data/balance.json` (chỉ khi chạy từ editor hoặc PC), rồi build lại là người chơi nhận số mới.

> Game hiện **không có server**, nên chỉnh ở admin chỉ có tác dụng **trên máy đó**. Muốn đẩy số mới cho mọi người chơi
> mà không build lại thì cần "remote config" (tải `balance.json` từ server). Việc này để giai đoạn sau; cấu trúc ở đây đã sẵn cho nó.

### 1.1 Cấu trúc `balance.json` (rút gọn)

```json
{
  "version": 1,
  "formulas": {
    "level_cost": {
      "expr": "round(50 * pow(1.35, level - 1))",
      "vars": ["level"],
      "preview": {"level": [1, 30]},
      "label": "Giá lên cấp lính (vàng)",
      "used_in": "Lính → Nâng cấp"
    },
    "troop_multiplier": {"expr": "(1 + 0.08 * (level - 1)) * pow(1.2, stars - 1)", "vars": ["level", "stars"], "...": "..."},
    "tier_multiplier":  {"expr": "pow(1.75, tier - 1)", "vars": ["tier"]},
    "spawn_interval":   {"expr": "base * pow(0.92, tier - 1) / (1 + master_bonus)", "vars": ["base", "tier", "master_bonus"]},
    "summon_cost":      {"expr": "min(2 + floor(count / 3), 9)", "vars": ["count"]},
    "enemy_multiplier": {"expr": "power * (1 + 0.2 * wave)", "vars": ["power", "wave"]},
    "siege_damage":     {"expr": "damage * 0.35", "vars": ["damage"]},
    "meat_regen_time":  {"expr": "1.6 * (1 - regen_pct / 100)", "vars": ["regen_pct"]},
    "workshop_cost":    {"expr": "round(base * pow(growth, level))", "vars": ["base", "growth", "level"]},
    "win_gold":         {"expr": "60 + 40 * (level + 1) + 20 * stars", "vars": ["level", "stars"]},
    "loss_gold":        {"expr": "15 * waves", "vars": ["waves"]},
    "patrol_rate":      {"expr": "60 + 60 * cleared", "vars": ["cleared"]},
    "battle_stars":     {"expr": "3 if hp_ratio >= 0.8 else (2 if hp_ratio >= 0.45 else 1)", "vars": ["hp_ratio"]}
  },
  "values": {
    "elite_hp_mult": 5.0, "elite_damage_mult": 1.8, "kill_meat": 0.35, "elite_kill_meat": 3.0,
    "first_clear_gold_mult": 2, "first_three_star_gems": 10, "levels_per_star": 10,
    "star_card_cost": [10, 30], "rarity_weights": [64, 32, 4], "free_chest_cooldown": 14400,
    "gold_chest_pity": 10, "exchange": {"gems": 20, "gold": 500}, "patrol_max_hours": 8
  },
  "castle": [{"hp": 1.0, "meat": 10, "cells": 12, "cost": 0}, "..."],
  "workshop": {"meat_regen": {"base": 120, "growth": 1.6, "step": 6, "max": 5}, "...": "..."},
  "chests": {"wood": {"cards": 3, "gold": 0, "gems": 0, "bonus_gold": [50, 100], "min_rare": 0}, "...": "..."},
  "troops": {"warrior": {"max_hp": 85, "damage": 8, "...": "..."}},
  "levels": {"3": {"enemy_power": 1.5, "waves": ["..."]}}
}
```

`troops` và `levels` trong override **chỉ ghi phần khác mặc định**, để file override nhỏ và dễ đọc.

### 1.2 An toàn khi tính công thức

- `Expression` chạy **không có đối tượng gốc** (`execute(inputs, null)`), nên công thức không gọi được hàm game, chỉ dùng được toán.
- **Danh sách hàm cho phép**: `pow, sqrt, floor, ceil, round, min, max, clamp, abs, lerp, log, exp`. Tên nào ngoài danh sách hoặc ngoài `vars` đều bị từ chối lúc lưu.
- **Kiểm tra trước khi áp dụng**: chạy thử trên toàn dải `preview`. Kết quả phải là số, không NaN hay vô cực, và nằm trong **giới hạn an toàn** của công thức đó (ví dụ giá > 0, hệ số > 0, thời gian ≥ 0.1 giây). Không đạt thì không cho lưu và báo rõ lỗi ở dòng nào.
- **Công thức lỗi lúc chạy**: tự quay về công thức mặc định, ghi cảnh báo, và gắn huy hiệu đỏ trong admin.

### 1.3 Hiệu năng

- Công thức được **dịch sẵn một lần** (`Expression.parse`) và lưu cache.
- Công thức gọi liên tục trong trận (F3, F4, F6) được **tính sẵn thành bảng lúc vào trận**. Bậc 1–5 chỉ có 5 giá trị, đợt 1–8 chỉ có 8 giá trị. Trong trận chỉ tra bảng, không tính `Expression` mỗi khung hình.

---

## 2. Vào admin như thế nào

| Bản | Cách vào |
|---|---|
| **Debug / editor** | Nút **ADMIN** trên thanh trên cùng của sảnh, bấm là mở (đã bỏ 7 chạm + PIN) |
| **Release (bản phát hành)** | **Tắt hẳn**: code admin nằm sau `OS.has_feature("admin")`; preset export phát hành không bật feature này |

Thêm một preset export "Android (Admin)" có bật feature `admin`, để cài lên điện thoại riêng cho người test cân bằng.

---

## 3. Giao diện admin

Mở ra như một lớp phủ toàn màn hình, trên cùng là **thanh 7 tab** cuộn ngang:

```
┌────────────────────────────────────────┐
│ ADMIN   [Hoàn tác] [Lưu] [Xuất] [✕]    │  thanh trên, có chấm vàng khi có thay đổi chưa lưu
│ Công thức│Lính│Thành│Cửa hàng│Màn│Người chơi│Mô phỏng │
├────────────────────────────────────────┤
│               nội dung tab              │
└────────────────────────────────────────┘
```

### 3.1 Tab Công thức (trọng tâm)

Danh sách 14 công thức (F1–F14). Mỗi dòng: tên, công thức rút gọn, huy hiệu **"đã sửa"** hoặc **"lỗi"**. Bấm vào để mở trình sửa:

```
┌ Giá lên cấp lính (vàng) ─────────── Dùng ở: Lính → Nâng cấp ┐
│ Biến: level (1–30)                                          │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ round(50 * pow(1.35, level - 1))                        │ │ ← ô sửa chữ, tô màu cú pháp đơn giản
│ └─────────────────────────────────────────────────────────┘ │
│ [pow] [floor] [round] [min] [max] [clamp] [level]  ← chèn nhanh │
│ ✔ Hợp lệ                                                     │
│                                                               │
│ Thử nhanh:  level = [ 7 ]  →  303  (cũ: 303)                  │ ← nhập giá trị bất kỳ
│                                                               │
│ Biểu đồ:  ── mới   ┄┄ cũ                                      │
│   ▁▁▂▂▃▃▄▅▆▇█                                                 │
│                                                               │
│ Bảng:  level │  1 │  2 │  3 │ ... │ 10 │ 20 │ 30             │
│        cũ    │ 50 │ 68 │ 91 │ ... │552 │... │...              │
│        mới   │ 50 │ 68 │ 91 │ ... │552 │... │...   (+/−%)     │
│        Tổng vàng lên cấp 1→10: 1.577  (cũ 1.577)              │ ← chỉ số tổng hợp theo từng công thức
│                                                               │
│ [Về mặc định]   [Huỷ]   [ÁP DỤNG]                             │
└───────────────────────────────────────────────────────────────┘
```

- **Thử nhanh**: nhập giá trị cho từng biến và xem kết quả ngay, cả mới lẫn cũ.
- **Biểu đồ và bảng** chạy theo dải `preview`. Công thức 2 biến (như F2 cấp × sao) hiện **bảng 2 chiều**, và biểu đồ vẽ mỗi mức sao một đường.
- **Chỉ số tổng hợp** giúp thấy tác động thật. Ví dụ: F1 xem tổng vàng để lên cấp 10; F11 xem tổng vàng qua 10 màn; F6 xem sức mạnh đợt cuối từng màn.
- **ÁP DỤNG** có hiệu lực ngay: sảnh và trận tiếp theo dùng công thức mới.

### 3.2 Tab Lính

Chọn lính → bảng các chỉ số với **thanh trượt kèm ô nhập số**. Cạnh mỗi chỉ số hiện:
- **DPS** (sát thương ÷ hồi chiêu), **"sức mạnh"** (máu × DPS), và **lính/phút** của một gear.
- So sánh nhanh 5 lính trên **một biểu đồ cột** để thấy lính nào đang quá mạnh hoặc quá yếu.

### 3.3 Tab Thành & Xưởng

- Bảng 10 cấp thành **sửa trực tiếp từng ô** (máu, thịt, số ô, giá), kèm cột "tổng vàng tới cấp này".
- Xưởng: base, growth, step, max. Công thức F10 liên kết sang tab Công thức.

### 3.4 Tab Cửa hàng

- Rương: số thẻ, giá, vàng thưởng, bảo đảm Hiếm, bảo hiểm, thời gian hồi.
- Tỉ lệ độ hiếm: 3 thanh trượt, **tự chuẩn hoá về 100%**.
- Nút **"Mở thử 1.000 rương"**: chạy ngay trong máy, hiện phân bố thực tế và số thẻ trung bình mỗi lính.

### 3.5 Tab Màn chơi

- Chọn màn → sửa tên, sức mạnh, máu thành, thịt đầu, thời gian chuẩn bị.
- **Trình sửa đợt**: danh sách đợt, mỗi đợt có danh sách nhóm `[loại lính ▼] [số lượng] [giãn cách] [bắt đầu] [☐ tinh nhuệ] [🗑]`, cùng nút **+ nhóm** và **+ đợt**. Có **dòng thời gian** nhỏ cho biết mỗi đợt ra quân lúc nào.
- Nút **"Chơi thử màn này"** (xem 3.7).

### 3.6 Tab Người chơi (cheat để test)

- Cộng hoặc trừ vàng và kim cương · đặt cấp thành, cấp xưởng.
- Từng lính: mở khoá, cấp, sao, số thẻ.
- Mở hoặc khoá màn, đặt sao từng màn.
- **Tua thời gian** +1h / +4h / +8h, để thử tuần tra và rương gỗ mà không phải chờ.
- **Lưu và nạp hồ sơ mẫu** ("Người mới", "Giữa game", "Cuối game") để test nhanh từng giai đoạn.
- **Xoá save**.

Cheat **chỉ tác động lên save của máy đó** và có ghi nhật ký ("đã cộng 5.000 vàng lúc 14:03") để khỏi nhầm khi đánh giá độ khó.

### 3.7 Tab Mô phỏng

Mang bot `tests/AutoPlay` vào trong game:
- Chọn **màn** và **mức nâng cấp** (thành / cấp lính / sao), hoặc dùng "hồ sơ hiện tại".
- **Chạy N trận bằng bot** ở tốc độ x8, trên nền, có thanh tiến độ. Kết quả gồm **tỉ lệ thắng, máu thành còn lại trung bình, đợt thua nhiều nhất**.
- **Chơi thử có bot**: xem bot chơi trực tiếp, bật/tắt bất tử cho thành.
- **Bảng đường cong kinh tế**: với công thức hiện tại, tính **vàng kiếm được** (thắng lần đầu + tuần tra theo giờ) so với **vàng cần** để đạt mức nâng cấp dự kiến ở mỗi màn. Vẽ 2 đường; chỗ đường "cần" vượt quá đường "có" là chỗ người chơi sẽ bị kẹt.

---

## 4. Lưu, hoàn tác, xuất

| Thao tác | Tác dụng |
|---|---|
| **Áp dụng** (trong từng trình sửa) | Đổi trong bộ nhớ, có hiệu lực ngay, chấm vàng "chưa lưu" |
| **Hoàn tác** | Quay lại từng bước (lưu tối đa 50 bước) |
| **Lưu** | Ghi `user://balance_override.json` |
| **Về mặc định** (từng mục hoặc tất cả) | Xoá phần override tương ứng |
| **Xuất JSON** | Copy toàn bộ cấu hình vào clipboard, hoặc lưu file để gửi người khác |
| **Nhập JSON** | Dán hoặc chọn file → kiểm tra hợp lệ → xem trước khác biệt → áp dụng |
| **Ghi vào bản build** (chỉ PC/editor) | Ghi `res://game/data/balance.json` và các `.tres` lính/màn đã sửa |

Mỗi lần lưu có **dấu thời gian và ghi chú** ("tăng giá cấp 8–10"), hiện trong **lịch sử** để so sánh và quay về bản cũ.

---

## 5. Kiến trúc code

```
game/
  core/
    Balance.gd            autoload: nạp mặc định + override, value(), formula(), bảng tính sẵn,
                          validate(), apply(), undo(), save/export/import; signal changed
    FormulaEngine.gd      bọc Expression: parse có cache, danh sách hàm cho phép, kiểm tra biến,
                          tính trên dải, trả lỗi có vị trí
  data/
    balance.json          mặc định (sinh từ số hiện tại, đảm bảo game chạy y như cũ)
  admin/
    AdminGate.gd          chỉ kiểm tra bản debug / feature "admin" (nút ADMIN chỉ hiện khi đúng)
    AdminPanel.tscn/.gd   lớp phủ, thanh tab, lưu/hoàn tác/xuất
    tabs/FormulaTab.gd, TroopTab.gd, CastleTab.gd, ShopTab.gd, LevelTab.gd, PlayerTab.gd, SimTab.gd
    widgets/FormulaEditor.gd   ô sửa + thử nhanh + bảng + biểu đồ
    widgets/LineChart.gd       vẽ đường cũ/mới (Control._draw)
    widgets/NumberField.gd     thanh trượt + ô số, có min/max/bước
    widgets/WaveEditor.gd      danh sách đợt/nhóm, dòng thời gian
    SimRunner.gd               chạy Battle + bot trong SubViewport ẩn, tốc độ cao, gom kết quả
```

**Đổi code hiện có (không đổi cách chơi):**

| File | Thay đổi |
|---|---|
| `Economy.gd` | Hằng số và hàm tĩnh thành **lớp mỏng gọi `Balance`**. Tên hàm giữ nguyên, nên PlayerData và các trang không phải sửa nhiều |
| `PlayerData.gd` | `troop_multiplier`, `meat_regen_time` gọi công thức F2, F9 |
| `Battle.gd` | F3, F6, F7, F8, F14, thịt khi giết: lấy từ Balance, **tính bảng lúc `_ready`** |
| `Core.gd`, `Gear.gd` | F5, F4 |
| `troops/*.tres`, `levels/*.tres` | Giữ làm mặc định. Balance áp phần override lên bản sao trong bộ nhớ lúc nạp |
| `tests/AutoPlay.gd` | Tách logic bot ra `game/admin/Bot.gd` để dùng chung cho test headless và tab Mô phỏng |

---

## 6. Lộ trình & tiêu chí xong

| Bước | Nội dung | Xong khi |
|---|---|---|
| **A. Lớp Balance** | `balance.json` mặc định, `Balance` + `FormulaEngine`, chuyển 14 công thức và mọi hằng số sang | **Bot cho ra kết quả y hệt trước** (cùng seed); test so sánh công thức cũ và mới trên toàn dải khớp 100% |
| **B. Cổng admin + tab Người chơi** | 7 chạm + PIN + feature flag; cheat, tua giờ, hồ sơ mẫu | Build release không mở được admin; bản admin mở được |
| **C. Tab Công thức** | Trình sửa, kiểm tra hợp lệ, thử nhanh, bảng, biểu đồ, áp dụng, hoàn tác | Sửa F1 thì giá ở trang Lính đổi ngay; công thức sai bị chặn kèm thông báo rõ |
| **D. Tab Lính / Thành / Cửa hàng** | Sửa bảng và số, mở thử 1.000 rương | Đổi tỉ lệ 64/32/4 thì mô phỏng rương khớp ±2% |
| **E. Tab Màn chơi** | Trình sửa đợt + dòng thời gian | Thêm được một nhóm quân mới rồi chơi thử thấy xuất hiện |
| **F. Tab Mô phỏng** | Bot trong game, chạy N trận, đường cong kinh tế | Chạy 5 trận màn 6 cho ra tỉ lệ thắng giống bot headless |
| **G. Lưu / xuất / nhập / lịch sử** | Override, JSON clipboard/file, ghi vào build | Xuất trên máy A, nhập trên máy B cho ra số y hệt |

---

## 7. Rủi ro & cách xử lý

| Rủi ro | Xử lý |
|---|---|
| Công thức sai làm hỏng game | Kiểm tra trước khi lưu, tự quay về mặc định khi lỗi, luôn có "Về mặc định" |
| Admin lọt vào bản phát hành | Feature flag + preset export riêng; kiểm tra thủ công mỗi lần phát hành |
| Chậm vì tính `Expression` trong trận | Dịch sẵn và tính thành bảng lúc vào trận |
| Override cũ không khớp khi game cập nhật | `version` trong JSON; khoá không còn tồn tại thì bỏ qua và báo |
| Người test quên đang bật cheat | Nhật ký cheat + dải cảnh báo "ĐANG DÙNG CHEAT" ở sảnh |

---

## 8. Câu hỏi cần chốt

1. Cách vào admin: **7 chạm + PIN** như trên, hay chỉ dùng được trong editor/PC?
2. Có cần **remote config** (chỉnh số từ xa cho mọi người chơi) không, hay chỉ chỉnh trên máy rồi build lại?
3. Tab Mô phỏng: chạy bot **trên điện thoại** (chậm hơn, pin) hay chỉ trên PC là đủ?
4. Thứ tự ưu tiên: đề xuất **A → C → B → F → D → E → G** (công thức và mô phỏng trước, vì giá trị cao nhất).
