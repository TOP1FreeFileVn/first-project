# Pipeline SVG cho sảnh lâu đài giấy và mèo tương tác

Ngày: 2026-10-20. Cập nhật 2026-10-21: ống chui, khay nghỉ SVG và ba mèo mặt trước đã ghép vào sảnh game thật. Xem [bản triển khai và giới hạn hiện tại](../../../ui_review/2026-10-21/approved-art-rollout.md).
Mục tiêu: vẽ lại bản V4 thành SVG sạch, mèo đi trước/sau và vào/ra đồ vật có tiếp đất,
che khuất đúng; lâu đài thay được các nấc nâng cấp.

Tham chiếu: [V4](../cardboard-castle-lobby-v4/README.md),
[nghiên cứu Cat Gunner](../cat-shooter-background-study/README.md),
[mèo tách chân](../cat-spine-parts/README.md).

Kết quả bước đầu: [pilot hai vật thể](../cardboard-tunnel-svg-pilot/README.md) đã có
SVG tách lớp, lối vào mở xuống mặt đất, mèo đi trước/sau và vào/ra trên đường đi
cố định. Mèo luôn hiện mặt trước trong mọi trạng thái, theo hướng đã chốt.
Có GIF, ảnh trạng thái, demo đổi vật thể và Figma
[ống chui](https://www.figma.com/design/2uKzqvXeOSPQqfaow6s7TU?node-id=77-2) /
[khay nghỉ](https://www.figma.com/design/2uKzqvXeOSPQqfaow6s7TU?node-id=82-2) để duyệt.
Đã kiểm tra chuyển lớp hai chiều, đổi vật thể khi mèo đang bên trong và chế độ
tách lớp. Chuyển động chân còn đơn giản, chưa có Spine runtime; phần đề xuất
sản xuất bên dưới vẫn là các việc cần triển khai tiếp.

## 1. Quyết định chính

Chia tranh theo **vai trò trong không gian và tương tác**, không theo từng màu tô.
Một tấm nền và một lớp che phía trước đủ cho ảnh tĩnh V4 nhưng không đủ khi mèo đi lại.

- Ngoài vật thể: mèo và vật thể xếp trước/sau theo điểm chạm đất.
- Khi vào: mèo nằm giữa lòng vật thể và vỏ phía trước, nhìn qua lỗ cửa trong suốt thật.
- Trong vật thể: có chỗ ngồi/nằm riêng; không phải vật thể nào cũng cần làm mèo biến mất.
- Khi ra: đi ngược qua cùng cửa rồi trở lại lớp đi ngoài sân.
- Mèo và đồ vật giữ kích thước ổn định. Không thu nhỏ/fade để giả thao tác chui vào.
- **Quy tắc đã chốt: mèo luôn hiện mặt trước** trong mọi trạng thái đi ngang,
  vào/ra, ngồi nghỉ. Không tạo hoặc đổi sang pose mặt sau/chéo/ngang; không lật
  mặt theo hướng di chuyển. Hướng đi thể hiện bằng đường đi và nhịp chân.

**Làm ống chui thử trước → khay ngủ → lâu đài → đệm/cột cào → cảnh xa và các cấp thành.**
Chốt được hình và chuyển động của một vật thể trước khi nhân ra toàn cảnh.

## 2. Khóa chuẩn trước khi vẽ

- Bố cục tham chiếu là canvas 720×1280 của V4. Giữ đất liền, cây hai mép,
  khoảng trời cho tên màn, khoảng trống nút hai bên và cụm Trận chiến bên dưới.
- Đặt một mèo gốc cạnh vật thể trong suốt quá trình vẽ. Đo nét tại kích thước hiển thị.
  Không áp một con số 9 px cho mọi SVG có viewBox/kích thước khác nhau.
- Nét chính vật thể gần: khởi điểm khoảng 4–5 px ở khổ 720; nét gấp/vật liệu khoảng
  2–2,5 px, nhẹ hơn và thiên màu vật liệu; nét cảnh xa khoảng 1–2 px, ít tương phản.
  Đây là mức thử để so cạnh mèo, chưa phải token đã duyệt.
- Màu viền chính nâu ấm `#583F21`; seam bìa có thể bắt đầu từ `#A57A48`.
  Mảng sáng vừa, vài mặt bên/bóng lớn; giữ rõ bìa, nắp gấp và băng keo.
- Mèo cream/tabby/calico hiện có nét nguồn 12 px trên canvas 256×240;
  bản hero neutral riêng là 9 px. Ví dụ 12×96/256 = 4,5 px khi hiển thị rộng 96.
  Không âm thầm sửa mèo để khớp một thông số môi trường.

Vẽ lại bằng đường cong có chủ đích, ít điểm neo và khối màu lớn. Không auto-trace
toàn ảnh AI: cách đó giữ lại đường méo, nhiều điểm và vết bóng của bản nháp.

## 3. Các lớp cần có

| Nhóm | Lớp xuất | Vai trò |
|---|---|---|
| Cảnh xa | sky, clouds_far/near, hills, distant_bushes | Luôn sau world; mây có thể chuyển động riêng về sau |
| Mặt đất | lawn, path, ground_decals | Nền dưới mọi mèo; không gộp chân tường vào cỏ |
| Lâu đài | contact_shadow, ramp_floor, interior_back, facade_front, flags, upgrade_modules | Cổng có alpha thật; ramp dưới mèo; facade che hai bên và phía trên |
| Ống/nhà chui | contact_shadow, interior_floor, rear_shell, front_shell | Mặt trước có lỗ thật; không tô giả màu nền vào lỗ |
| Khay ngủ | contact_shadow, floor_back, rear_walls, front_rim | Mèo lọt trong khay, chân/thân dưới sau thành trước |
| Đệm | contact_shadow, cushion_body, front_lip nếu cần | Điểm leo lên/ngồi, không có portal kiểu cửa |
| Cột cào | contact_shadow, post_body, fish_string, fish_toy | Chân đứng trước cột; móng chạm marker; không có inside |
| Mèo | floor_root, shadow, visual/rig | Root dùng di chuyển/sort; visual dùng bước chân, ngồi, nhún |

Chỉ tách thêm một lớp nếu nó cần đổi trước/sau, chuyển động, đổi màu hoặc thay theo cấp.
Giữ mỗi vật thể thành một cụm; không làm hàng trăm mảnh không có mục đích.
Cây/bụi ở vùng mèo đi được phải có chân và footprint; cây trang trí xa không cần collider.

## 4. Hợp đồng asset SVG

Mỗi vật thể có `source.svg` với nhóm semantic và các SVG từng phần xuất từ chính nguồn đó.
Các phần của **cùng vật thể** giữ nguyên viewBox, registration và tỉ lệ; không crop từng
phần rồi căn lại bằng mắt. Vật thể khác nhau có thể có viewBox riêng.

```text
<prop_id>/
  source.svg               # bản ghép vector có các nhóm tên rõ
  parts/rear.svg
  parts/interior.svg
  parts/front.svg
  parts/shadow.svg
  interaction.json         # tọa độ, vùng cửa và hành vi
  review/assembled.png
  review/layers.png
```

- Lỗ cửa là compound path/alpha thật, không phải một miếng màu tối đặc.
  Bóng tối trong phòng nằm ở `interior`; vỏ trước phải cho thấy mèo qua cửa.
- Phần bị che vẫn vẽ đủ hình và thêm vùng chồng kín dưới lớp trên để tránh khe antialias.
  Không thêm stroke mới dọc đường cắt layer; một mép nhìn thấy chỉ có một nét viền.
- Để lề đủ cho stroke; không cắt mất nửa nét ở biên viewBox.
- Giữ path/fill/stroke đơn giản; tránh filter/phông chữ/ảnh nhúng trong asset vật thể.
  Tên màn vẫn là text UI, không đóng vào SVG nền.
- Ghép các SVG từng phần phải khôi phục đúng `source.svg` ở pose nghỉ.
- **Godot nhập SVG thành texture.** Group trong một SVG không tự thành node, bone hay
  layer chạy độc lập. Muốn điều khiển phần nào phải xuất phần đó thành asset/node riêng.
- Figma giữ cây nhóm vector có tên và một bản ghép; marker debug nằm ở nhóm riêng,
  không xuất vào asset hiển thị.

## 5. Tọa độ và dữ liệu tương tác

Mỗi vật thể cần: `id`, `tier`, viewBox, registration/ground anchor, depth anchor,
footprint, cửa/threshold, route vào/ra, vị trí nghỉ, sức chứa và hành vi hỗ trợ.
[interaction-template.json](interaction-template.json) là bản mẫu chuẩn bị, chưa được loader nào sử dụng.

Phân biệt ba hệ tọa độ: SVG local, world 720×1280 và màn hình sau stretch.
Không lấy x/y/width của hộp ảnh trong V4 làm vị trí chân.

Mèo dùng floor-root ở mặt dưới hai bàn chân; pivot khớp chân trong rig là điểm khác.
Mốc đề xuất cho canvas mèo 256×240: `(128,238)` với viền 12 px,
`(128,236.5)` với neutral 9 px. Kiểm tra lại silhouette/pose khi sản xuất.
Nhún người/Spine nằm dưới `Visual`, không nhún floor-root để khỏi đổi thứ tự Y liên tục.

Các mốc world đọc từ V4 dưới đây **chỉ là bản nháp**. Phải đặt lại trên SVG sau khi
kiểm tra kích thước cửa so với đầu/bụng mèo và khoảng tiếp đất.

| Vật thể | Tiếp cận | Ngưỡng/cửa | Vị trí bên trong/tương tác |
|---|---|---|---|
| Lâu đài | (340,662), qua ramp (350,625) | (365,595) | (365,570) |
| Ống chui | (165,800) | (164,770) | (164,747) |
| Khay ngủ | (515,900) | (515,858) | (526,828) |
| Đệm | (650,905) | không có cửa | (635,870) |
| Cột cào | tùy đường đến | không có cửa | chân (580,786), móng (579,716) |

Ống V4 chỉ rõ một cửa: làm mèo vào nghỉ và ra cùng cửa trước. Muốn chui xuyên qua
phải vẽ cửa thứ hai và đường nối bên trong; không teleport sang một mặt kín.

## 6. Render và portal trong Godot

```text
Home
  LobbyWorldHolder (Control, full rect, không chặn input UI)
    LobbyWorld (Node2D)
      DistantLayers
      GroundAndFloors
      DepthWorld (Node2D, y_sort_enabled = true)
        CatFloorRoot
          Shadow
          Visual / rig
        PropDepthRoot (y_sort_enabled = false)
          InteriorBack
          OccupantSlot
          FrontShell
      FixedForeground (chỉ vùng đã cấm mèo đi)
  UI: tên màn, thưởng, CTA, rail, header, bottom bar
```

Các root dưới `DepthWorld` cùng canvas và cùng z-index; sắp theo điểm tiếp đất.
Một prop có chiều dài lớn có thể cần nhiều đoạn depth-root, không lấy tâm toàn bbox làm khóa sort.
Ramp/floor ở dưới actor, không đặt trong facade phủ lên chân mèo.

Khi mèo ngoài sân, Y-sort quyết định trước/sau toàn prop. Khi vào cửa, controller
chuyển floor-root của mèo vào `OccupantSlot`, giữ global transform để không nhảy hình.
Thứ tự cục bộ là `InteriorBack → mèo → FrontShell`. Chọn điểm handoff trong vùng
cửa mà thứ tự cũ/mới cho hình giống nhau; không đợi mèo đã xuyên tường mới đổi lớp.
Ra cửa làm ngược lại. Y-sort đơn thuần không giải quyết được trường hợp bên trong hộp.

Nếu vào lâu đài cần khuất hẳn, route phải đi tới vùng bị vỏ/cửa sau che hoàn toàn rồi
mới dừng vẽ actor. Với ống/khay, mèo có thể vẫn lộ đầu khi nghỉ.
Không mặc định mọi front-shell luôn nằm trên mọi mèo ngoài sân.

Ưu tiên vỏ alpha đơn giản; chỉ dùng shader/mask riêng khi hình vỏ không diễn đạt được.
`Control.clip_contents` chỉ cắt chữ nhật; `LightOccluder2D` phục vụ ánh sáng,
không thay thế mask hình mèo. Kiểm tra khả năng runtime trước khi chọn giải pháp mask phức tạp.

## 7. Đi lại và chuyển động tự nhiên

State đề xuất: `roam → reserve → approach → align → enter → rest/action → exit → release`.
Mỗi slot chỉ nhận số mèo đã định; mèo khác chọn hoạt động khác thay vì đứng chồng nhau.
Khi hủy hành vi/đổi tab/phá prop phải giải phóng reservation và đưa mèo về trạng thái hợp lệ.

- Bước thử dùng waypoint và đường cong đã đặt, chưa cần roaming tự do toàn sân.
  Chặn footprint chân tường/cột, mở corridor cửa; không lấy toàn bbox làm vùng cấm.
- Tính clearance theo vùng chân mèo và kiểm tra thêm đầu/thân khi qua cửa.
  Không ép mèo co lại chỉ vì họa sĩ vẽ cửa quá nhỏ; sửa cửa hoặc tạo pose cúi phù hợp.
- Tốc độ dịch chuyển phải khớp nhịp chân; chân chạm đất có quãng đứng, không trượt.
  Giữ mặt trước khi đổi hướng, giảm tốc khi tới cửa, dừng một nhịp khi ngồi.
- Khay có thành kín cần động tác bước/nhảy qua thành trước; bản thử dùng lối
  giữa mở xuống mặt đất để mèo đi vào. Đệm cần leo lên rồi ngồi;
  cột cào cần đứng đúng chân và móng chạm điểm đánh dấu. Không dùng chung animation chui cửa.
- Bóng tiếp đất riêng, biến đổi theo tư thế/độ cao; không trôi độc lập hoặc đè lên thành hộp.
- Mèo dùng duy nhất pose trước đã tách chân, giữ các nét mặt và silhouette gốc.
  Tiếp tục làm idle/walk/sit với nhịp chân và chuyển trọng tâm trong dáng mặt
  trước; không cần pose sau hay ngang. Chỉ tween mèo đứng sẽ trông như trượt
  dù layer đúng.
- Có thể làm pilot bằng các phần vector đã tách. Chưa coi đó là rig/animation Spine;
  chốt runtime Spine trước khi lên kế hoạch tích hợp skeleton.

Nếu mở roaming tự do: bổ sung NavigationRegion2D/NavigationAgent2D và navigation
polygon có clearance thật. Radius avoidance không tự khoét khoảng cách khỏi tường.

## 8. Tích hợp đúng nơi và giữ các cấp lâu đài ổn định

`game/battle/Background.gd` hiện vẽ nền chiến đấu, không phải cảnh sảnh cần thay.
Sảnh nằm ở `Home.gd` và `menu/pages/BattlePage.gd`. BattlePage đang dựng đảo bằng
Control/TextureRect; chưa có world tương tác. Vẽ SVG xong chưa đồng nghĩa tính năng đi lại đã có.

Đề xuất tạo một `LobbyWorld` tồn tại riêng dưới Home, hiện ở tab Chiến;
BattlePage giữ title/reward/CTA dạng Control phủ phía trên. Home hiện dùng vùng content
y112..1120 có clip; world full-screen không đặt bên trong `_column` bị dựng lại mỗi refresh.
`PlayerData.changed` hiện gọi refresh: cập nhật thông tin UI thay vì hủy toàn world,
nếu không mèo sẽ bị reset vị trí và reservation mỗi lần tài nguyên đổi.
Nền shop vẫn có lifecycle riêng theo cấu trúc Home hiện có.

Mỗi nấc lâu đài giữ ID cửa, ground anchor và điểm nối ramp; tăng bằng module tháp,
tầng, cầu và đồ trang trí. Không phóng to nguyên tòa làm cổng đổi cỡ/vị trí.
Nếu footprint bắt buộc đổi, cập nhật route/nav và xử lý mèo đang trong thành trước khi thay.

## 9. Các mốc kiểm tra trước khi làm toàn cảnh

1. **Ống chui vector:** chốt silhouette, nét và màu cạnh mèo gốc ở khổ 720 và cửa sổ game 450×800.
2. **Lớp và tiếp đất:** ảnh ghép nghỉ khớp nguồn; cửa alpha thật; không khe/nét đôi;
   mèo đi trước và sau vật thể đúng thứ tự.
3. **Pilot chuyển động:** clip ngắn vào một nửa → vào nghỉ → ra; không pop layer,
   xuyên tường, co/fade, trượt chân hoặc biến mất quá sớm.
4. **Nhân ra khay/lâu đài:** mỗi đồ vật có route, pose và vị trí nghỉ riêng;
   thử hai mèo tranh một chỗ và một mèo đi ngang phía trước.
5. **Cảnh hoàn chỉnh:** kiểm tra vật thể với rail/CTA, mây riêng, các tỉ lệ cửa sổ;
   UI vẫn nhận input, đổi tab/refresh không reset sai world.
6. **Nâng cấp:** cùng một clip chạy ở từng tier, cửa và chân mèo không nhảy vị trí.

Đầu ra mỗi mốc gồm SVG nguồn, các phần SVG, metadata, ảnh ghép và clip chuyển động.
Chỉ sau khi pilot đạt mới sản xuất cả bộ và thay cảnh sảnh trong game.
