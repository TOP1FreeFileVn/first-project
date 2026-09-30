# Thiết kế: thêm lính · hoạt ảnh mở rương · đội hình

**Trạng thái: ĐÃ LÀM XONG A → D**, kèm thêm lính **Huyền thoại: Tướng quân** (mục 1.2b). Xem "Kết quả" ở cuối tài liệu.

---

## 0. Admin bấm một lần (ĐÃ LÀM)

- Thanh trên cùng của sảnh có nút đỏ **ADMIN**, nằm cạnh nút cài đặt. Bấm là mở ngay, không cần PIN hay chạm nhiều lần.
- Nút chỉ xuất hiện ở bản **debug** (chạy từ editor, hoặc export có tick *Export With Debug*) và ở bản export có feature `admin`. Bản phát hành bình thường không có nút này, nên người chơi thật không mở được.
- Đã bỏ: chạm avatar 7 lần, ô nhập PIN, file `user://admin.cfg`, phần đổi PIN trong tab Người chơi.

---

## 1. Thêm lính

### 1.1 Giới hạn của bộ asset

Tiny Swords Free có đúng **5 loại lính**: Warrior, Archer, Lancer, Monk, Pawn. Mỗi loại có 5 màu. Màu đã được dùng để thể hiện **bậc của bánh răng** (bậc 1 xanh → bậc cao tím), nên không thể lấy màu để phân biệt loại lính.

Có thể phân biệt lính mới bằng những thứ có sẵn:

| Nguồn | Có gì | Dùng cho |
|---|---|---|
| Pawn có 7 món đồ cầm tay | Axe (đang dùng), Hammer, Knife, Pickaxe (có hoạt ảnh đánh), Meat, Gold, Wood (chỉ có đứng yên và chạy) | 5 lính mới dạng Pawn |
| Warrior_Guard | Hoạt ảnh giơ khiên | Lính đỡ đòn |
| Lancer 5 hướng + Defence | Đâm và thủ | Lính xung phong |
| Particle FX | Fire 1–3, Explosion 1–2, Dust, Water Splash | Hiệu ứng kỹ năng: cháy, nổ, lan |
| Vẽ bằng code | Vòng sáng, hào quang, chữ nổi | Đánh dấu lính có kỹ năng |

Mỗi lính mới được nhận ra nhờ **món đồ cầm tay, hiệu ứng kỹ năng, khung thẻ theo độ hiếm và icon kỹ năng** ở góc thẻ.

### 1.2 Danh sách đề xuất: 7 lính mới (tổng 12)

| # | Tên | Hình | Độ hiếm | Vai trò | Kỹ năng |
|---|---|---|---|---|---|
| 1 | Nông dân *(có sẵn)* | Pawn + rìu | Thường | Cận chiến | — |
| 2 | Chiến binh *(có sẵn)* | Warrior | Thường | Cận chiến | — |
| 3 | Cung thủ *(có sẵn)* | Archer | Thường | Tầm xa | — |
| 4 | **Thợ mỏ** | Pawn + cuốc | Thường | Cận chiến, trâu | **Đào hầm**: nhận ít hơn 30% sát thương từ tên |
| 5 | **Thợ rèn** | Pawn + búa | Thường | Hỗ trợ cận chiến | **Rèn giáp**: đồng đội đứng gần nhận thêm 10% máu tối đa |
| 6 | Kỵ thương *(có sẵn)* | Lancer | Hiếm | Cận chiến | — (đổi sang **Xung phong** nếu cần, xem #9) |
| 7 | **Sát thủ** | Pawn + dao | Hiếm | Cận chiến nhanh | **Ám sát**: bỏ qua quân tuyến đầu, lao thẳng vào cung thủ hoặc tu sĩ địch; đòn đầu gây x2 sát thương |
| 8 | **Hiệp sĩ khiên** | Warrior_Guard | Hiếm | Đỡ đòn | **Giơ khiên**: 4 giây một lần, chặn toàn bộ sát thương trong 1 giây, hiện khiên sáng |
| 9 | **Cung lửa** | Archer + Fire | Hiếm | Tầm xa | **Tên lửa**: đốt mục tiêu, mất 3 máu/giây trong 3 giây; hiện hiệu ứng lửa trên người |
| 10 | Tu sĩ *(có sẵn)* | Monk | Sử thi | Hồi máu | — |
| 11 | **Đầu bếp** | Pawn + thịt | Sử thi | Kinh tế | Không đánh. **Nấu thịt**: khi còn sống, 6 giây cộng 1 thịt cho bánh răng tổng, có thịt bay về |
| 12 | **Pháo thủ** | Pawn + búa, đạn nổ | Sử thi | Tầm xa diện rộng | **Bom**: ném chậm, nổ (Explosion_01) gây sát thương cho mọi địch trong bán kính 60 |

Tỉ lệ độ hiếm sau khi thêm: **5 Thường · 4 Hiếm · 3 Sử thi**, khớp với trọng số rương hiện tại 64/32/4.

### 1.2b Huyền thoại: Tướng quân (thêm theo yêu cầu)

| | |
|---|---|
| Độ hiếm | **Huyền thoại** (bậc 4, màu vàng cam). Tỉ lệ thẻ 0.4% (trọng số `rarity_weights` = [64, 32, 3.6, 0.4]) |
| Hình | Warrior với đòn chém thứ hai (Attack2), to hơn 1.4 lần, **vương miện vẽ bằng code** trên đầu, vòng hào quang vàng dưới chân, gear có quầng vàng |
| Chỉ số gốc | 260 máu, 20 sát thương, sinh 10 giây/lính, tối đa 1 con mỗi gear, tỉ lệ triệu hồi 0.45 |
| Hiệu lệnh | Đồng đội trong bán kính 160 gây **+30% sát thương** (chấm vàng trên đầu lính được buff) |
| Chém lan | Mỗi nhát chém trúng thêm mọi địch sát mục tiêu (50% sát thương) |
| Xoay kiếm | 5 giây một lần, gây **x1.5 sát thương** cho mọi địch quanh mình (vòng sóng vàng) |
| Xuất trận | Nổ sáng + thông báo "Tướng quân xuất trận!" |
| Phía địch | Là **trùm cuối màn 10** |

Chỉnh mọi con số ở **Admin → Lính → Tướng quân** (4 ô kỹ năng).

### 1.3 Hệ thống kỹ năng (code)

- `TroopData` thêm:
  - `ability` (enum: NONE, TUNNEL, FORGE, ASSASSIN, SHIELD, BURN, COOK, BOMB),
  - `ability_value`, `ability_duration`, `ability_cooldown`, `ability_radius`: 4 số dùng chung cho mọi kỹ năng, mỗi kỹ năng hiểu theo cách riêng,
  - `projectile` ("arrow", "fire_arrow", "bomb").
- `Unit.gd` gọi các hook theo kỹ năng: `_on_spawn`, `_on_hit(target)`, `_on_damaged(amount)`, `_tick(delta)`, `_pick_target()`. Mỗi kỹ năng chỉ là một đoạn nhỏ trong `match`, không cần class riêng.
- **Địch cũng dùng được lính mới**, tự có đủ kỹ năng. Đợt quân ở màn 6–10 sẽ thêm Sát thủ, Hiệp sĩ khiên, Pháo thủ để có độ khó mới.
- **Admin**:
  - Tab Lính tự hiện thêm 4 ô kỹ năng và mô tả kỹ năng.
  - Biểu đồ so sánh có thêm "giá trị kỹ năng quy đổi" (ví dụ Đầu bếp = thịt/giây).
  - Trình sửa đợt quân tự có 12 lính trong danh sách chọn.
- **Test**: BalanceTest kiểm tra mỗi kỹ năng. AutoPlay chạy 1 trận với mỗi lính để bắt lỗi.

### 1.4 Cách người chơi có lính mới

- Thẻ lính rơi từ rương như hiện nay: lính **chưa mở khoá** rơi ra thì thẻ đầu tiên mở khoá luôn lính đó (hiện "MỚI!").
- Quà khi qua màn lần đầu (`FIRST_CLEAR_GIFT`), đề xuất:

  | Qua màn | Nhận |
  |---|---|
  | 1 | Kỵ thương |
  | 2 | Tu sĩ |
  | 3 | Thợ mỏ |
  | 5 | Hiệp sĩ khiên |
  | 7 | Cung lửa |

  Các lính còn lại (Thợ rèn, Sát thủ, Đầu bếp, Pháo thủ) chỉ có từ rương, để rương có giá trị.

---

## 2. Hoạt ảnh mở rương + BỎ QUA

### 2.1 Nguyên tắc

- **Phần thưởng được cộng ngay khi bấm mở**, trước khi chạy hoạt ảnh (đúng như code hiện tại). Bỏ qua, tắt game hay mất mạng giữa chừng đều không mất đồ.
- Hoạt ảnh chạy trên một lớp phủ toàn màn hình (`ChestOpening.gd`, CanvasLayer riêng), dùng lại được cho: mua ở Cửa hàng, rương thắng trận, rương tuần tra.

### 2.2 Các cảnh (tổng khoảng 4–7 giây nếu không bỏ qua)

| Cảnh | Thời gian | Nội dung |
|---|---|---|
| 1. Rơi xuống | 0.5 s | Nền tối lại. Rương rơi từ trên xuống giữa màn hình, nảy 2 lần, bụi (Dust_01) bay hai bên, màn hình rung nhẹ. |
| 2. Chờ chạm | tuỳ người chơi | Rương thở (phóng to/nhỏ nhẹ), khe nắp lộ ánh sáng theo **độ hiếm cao nhất** trong rương: trắng, xanh hoặc tím. Chữ "Chạm để mở". Rương có thẻ Sử thi thì rung mạnh hơn và có tia lửa tím. |
| 3. Bật nắp | 0.6 s | Nắp bật lên và xoay bay ra. Nổ ánh sáng (Explosion_02 tô màu độ hiếm), tia sáng xoay sau rương, xu vàng bắn ra bay về góc vàng trên thanh trên cùng. |
| 4. Lật thẻ | 0.35 s mỗi thẻ | Từng thẻ bay ra từ rương, úp mặt, rồi lật (thu nhỏ theo chiều ngang về 0, đổi mặt, phóng lại). Khung thẻ phát sáng theo độ hiếm. Có tên lính, "x3 thẻ", và thanh tiến độ tới sao tiếp theo chạy lên. |
| 4b. Thẻ Sử thi | +1 s | Dừng lại, tia sáng tím, rung màn hình, chữ lớn "SỬ THI!". |
| 4c. Lính mới | +1 s | Chữ "MỚI!" đỏ, lính chạy ra và đứng cạnh thẻ (dùng sprite thật đang chạy). |
| 5. Tổng kết | — | Lưới mọi thẻ đã nhận, tổng vàng, nút **XONG**. Nếu có lính đủ điều kiện nâng sao thì thêm nút **XEM LÍNH** (sang tab Lính). |

Mọi hình đều dùng asset có sẵn hoặc vẽ bằng code:
- **Rương**: vẽ lại bằng code, tách **thân và nắp** thành 2 node để nắp bay ra được. Có viền kim loại và màu theo loại rương.
- **Tia sáng**: vẽ polygon xoay.
- **Hạt**: CPUParticles2D dùng texture sao và xu.

### 2.3 Bỏ qua

- **Nút "BỎ QUA ≫"** ở góc trên phải, hiện từ cảnh 1. Bấm là nhảy thẳng tới cảnh 5 (tổng kết).
- **Chạm vào màn hình** ở cảnh 4: lật ngay thẻ hiện tại và chuyển sang thẻ kế tiếp. Chạm liên tục sẽ đi rất nhanh nhưng vẫn thấy từng thẻ.
- **Cài đặt → "Mở rương nhanh"** (bật/tắt, lưu trong save): khi bật, bỏ cảnh 1–4 và chỉ hiện tổng kết có hiệu ứng nảy nhẹ.
- Cảnh Sử thi và lính mới **vẫn hiện khi chạm nhanh**, nhưng rút xuống 0.4 giây, để khoảnh khắc đáng giá nhất không bị bỏ lỡ. Chỉ nút BỎ QUA mới bỏ luôn cả hai.

### 2.4 Kiểm tra

- `tests/ChestShots.tscn` chụp mỗi cảnh cho 3 loại rương, trên hồ sơ tạm (không ghi save).
- Kiểm tra: bấm BỎ QUA ở mỗi cảnh thì số thẻ và vàng trong save không đổi so với khi không bỏ qua.

---

## 3. Đội hình (đưa lính vào team)

### 3.1 Luật chơi

- Người chơi chọn **đội hình** gồm các lính mang vào trận. Trong trận, **triệu hồi chỉ ra lính trong đội** (theo `summon_weight`).
  - Hiện tại trận lấy mọi lính đã mở khoá mà màn cho phép (`level.troop_pool`).
  - Sẽ bỏ `troop_pool` phía người chơi: màn không còn giới hạn lính của bạn nữa.
- **Số ô đội hình theo cấp thành**: cấp 1 có 3 ô, cấp 3 có 4 ô, cấp 6 có 5 ô. Có thể sửa trong admin, cột "Ô đội" ở bảng thành.
- Lý do đội nhỏ là tốt hơn: đội càng ít lính thì càng dễ ra 2 bánh răng giống nhau để ghép. Người chơi phải đánh đổi giữa **đa dạng** và **dễ ghép**. Đây là lựa chọn chiến thuật chính.
- Phải có ít nhất 1 lính trong đội. Ô trống là được, không bắt buộc đủ.
- Save cũ: đội được tự tạo từ các lính đã mở khoá mạnh nhất, theo số ô hiện có.

### 3.2 Giao diện

**Tab Lính** (chia 2 phần):

```
┌─────────── ĐỘI HÌNH  (sức mạnh 1.240) ───────────┐
│ [Chiến binh] [Cung thủ] [Tu sĩ] [ + ] [🔒 thành 6] │
└───────────────────────────────────────────────────┘
  Bộ sưu tập (12)      Lọc: Tất cả · Thường · Hiếm · Sử thi
  [thẻ] [thẻ]
  [thẻ] [thẻ]   ← thẻ đang trong đội có nhãn "TRONG ĐỘI"
```

- **Chạm thẻ trong bộ sưu tập** → mở chi tiết như hiện nay, thêm nút **VÀO ĐỘI** hoặc **RA KHỎI ĐỘI**.
- **Đội đầy mà bấm VÀO ĐỘI** → các ô đội nhấp nháy, chữ "Chọn lính để thay". Chạm một ô là đổi (lính mới bay vào ô, lính cũ bay ra).
- **Kéo thả**: kéo thẻ từ bộ sưu tập thả vào ô đội. Làm sau cùng, vì cách chạm ở trên đã đủ dùng.
- **Sức mạnh đội** = tổng DPS × máu quy đổi của các lính trong đội, dùng cùng công thức "sức mạnh" của tab Lính trong admin.

**Tab Chiến đấu**:
- Phần "Lính của bạn" hiện đội hình hiện tại, kèm nút **ĐỔI ĐỘI** (chuyển sang tab Lính).
- Bấm CHƠI với đội trống sẽ bị chặn, có thông báo.

### 3.3 Dữ liệu

- `PlayerData.team: Array[String]` (lưu trong save), cùng các hàm `team_slots()`, `set_team_slot(i, id)`, `add_to_team(id)`, `remove_from_team(id)`, `team_power()`.
- `balance.json`: thêm `team_slots` vào mỗi cấp thành.
- `Battle._pool` lấy từ `PlayerData.team`. Bot mô phỏng dùng đội gợi ý tốt nhất; bảng Mô phỏng thêm lựa chọn "đội: tự chọn / hồ sơ hiện tại".
- Admin tab Người chơi: thêm cheat "đặt đội" và "mở khoá tất cả lính" (đã có).

---

## 4. Thứ tự làm đề xuất

| Bước | Việc | Vì sao đi trước |
|---|---|---|
| A | Đội hình (dữ liệu, trận, tab Lính, tab Chiến đấu) | Không cần asset mới. Khi có 12 lính thì bắt buộc phải có đội. |
| B | Hệ thống kỹ năng + 7 lính mới + admin | Lớn nhất. Cần đội hình để test từng lính riêng. |
| C | Hoạt ảnh mở rương + bỏ qua + mở nhanh | Độc lập. Làm sau để hiện được lính mới, chữ "MỚI!" và Sử thi. |
| D | Cân bằng lại bằng admin: đợt quân màn 6–10 dùng lính mới, chạy mô phỏng | Cần A–C xong. |

Mỗi bước có test headless và ảnh chụp như các lần trước. Không ghi vào save thật.

## 5. Kết quả (đã làm)

**Đã chốt theo mặc định:** giữ đủ 7 lính trong mục 1.2; ô đội 3 → 4 → 5 ở thành cấp 1 / 3 / 6; "Mở rương nhanh" mặc định tắt.

| Phần | File chính |
|---|---|
| Dữ liệu lính + kỹ năng | `game/data/TroopData.gd`, `game/data/troops/*.tres` (13 lính), `game/core/Content.gd` |
| Hình lính mới | `game/core/SpriteLib.gd` (Pawn cầm cuốc/búa/dao/thịt/túi, Guard, General; hiệu ứng lửa, nổ; bom vẽ bằng code) |
| Kỹ năng trong trận | `game/battle/Unit.gd`, `Projectile.gd` (tên lửa, bom ném vòng cung), `Battle.gd` (thịt bay về gear tổng) |
| Đội hình | `PlayerData.gd` (team, battle_team, auto_team, set_team_slot…), `TroopsPage.gd`, `BattlePage.gd`, cột "Ô đội" trong bảng thành |
| Mở rương | `game/ui/ChestOpening.gd` (Cửa hàng + rương chiến thắng sau trận), cài đặt "Mở rương nhanh" |
| Admin | Tab Lính có 4 ô kỹ năng; tab Thành có cột Ô đội; tab Cửa hàng có tỉ lệ Huyền thoại; tab Người chơi có "Đội mạnh nhất" |
| Quân địch | Màn 5–10 có Thợ mỏ, Cung lửa, Sát thủ, Hiệp sĩ khiên, Thợ rèn, Pháo thủ, Đầu bếp; Tướng quân là trùm màn 10 |

**Kiểm tra:**
- BalanceTest 498/498.
- Bot có đủ 13 lính thắng màn 5–10.
- Bot với đội thực tế (lính khởi đầu + quà): thắng 7, 8, 9; màn 6 và 10 lúc thắng lúc thua (màn 10 là trùm, dự kiến khó).
- Ảnh chụp mọi cảnh mở rương và tab Lính: `tests/MenuShots.tscn`.

**Save cũ:** tự tạo đội từ các lính mạnh nhất đang có. Lính mới ở trạng thái khoá, nhận bằng rương hoặc quà qua màn.
