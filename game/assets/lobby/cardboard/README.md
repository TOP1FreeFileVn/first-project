# Asset sảnh lâu đài giấy đã duyệt

## Cập nhật đồ vật theo thành — 2026-10-23

Runtime hiện dùng `terrain-props-clean.png` và bộ SVG phẳng đồng bộ với
`castle-tier-2-body.svg`: màu bìa `#e8bb7c`, mảng tối `#d4a065`, viền `#583f21`.
Nét chính khoảng 6px, nét phụ 3px ở canvas game 720px; số đo local của nhà/khay
đã bù scale 0.82/0.86. Không sửa hình mèo hoặc đường đi.

- `tunnel/` và `bed/`: SVG tách lớp hiện tại, giữ nguyên cửa và mốc đặt chân.
- `props/scratching-post.svg`: origin (80,176), ground (590,780).
- `props/yarn.svg`: origin (40,74), ground (214,854).
- `props/pillow.svg`: origin (75,80), ground (630,903).

Cả ba đồ tĩnh đã tách khỏi bitmap và được Y-sort theo điểm chạm đất. Bản nền
cũ `terrain-clean.png` được giữ để truy nguồn; `terrain-props-clean.png` xóa
đúng ba đồ cũ và bóng của chúng trong các mask đã lưu. Pixel ngoài mask giữ nguyên.
`props/manifest.json` ghi hash, palette và vị trí. Tái tạo ba SVG tĩnh và nền sạch:

```powershell
python tools/ui/restyle_lobby_props.py
```

Phần dưới mô tả bộ V4 lịch sử. `prepare_assets.py` là bước nhập V4 ban đầu;
các SVG nhà/khay hiện tại là bản thiết kế mới hơn và phải được giữ khi tái nhập.

Ngày: **2026-10-20**. Bộ này đưa art V4, ống chui, khay nghỉ và mèo gốc vào vùng
asset production. Không thiết kế lại hoặc sửa hình mèo. Các quyết định nguồn,
tọa độ và SHA-256 được ghi trong [integration-manifest.json](integration-manifest.json).

## Dùng trong cảnh 720×1280

| Asset | Cách đặt |
| --- | --- |
| `terrain-clean.png` | RGB 720×1280, top-left (0,0) |
| `castle-layer.png` | RGBA 720×1280, top-left (0,0); alpha bounds (156,290)–(591,647) |
| `castle-crop.png` | Bản crop RGBA 435×357 để dùng trong CastlePage; nếu ráp lại cảnh, đặt tại (156,290) |
| `tunnel/*.svg` | Canvas 256×240, ground local (128,224), world (165,790), scale 0.82 |
| `bed/*.svg` | Canvas 256×240, ground local (128,224), world (530,866), scale 0.86 |
| `cats/{cat_cream,cat_tabby,cat_calico}/*.svg` | Canvas 256×240, floor local (128,238), visual scale gợi ý 0.37 |
| `pillow-foreground.png` | RGBA 720×1280, top-left (0,0), đặt trên khay để giữ đúng gối xanh phía trước như V4 |
| `yarn-foreground.png` | RGBA 720×1280, top-left (0,0), Y-sort tại ground (214,854) để len che mèo đi phía sau |

Mốc cửa lâu đài là **(365,595)**; đầu ramp dưới gần **(337,644)**. Lâu đài giữ
nguyên bitmap đã duyệt, chưa tách cổng để mèo đi vào. Sky/cây/đồi/cỏ/đường và
post/ball/pillow trang trí vẫn là bitmap. Ống, khay và mèo là SVG tách phần.

Mỗi đồ giấy có `source.svg` và các lớp `shadow`, `rear`, `interior`, `front`.
Giữ cùng viewBox/registration. Thứ tự khi có mèo: **shadow → rear → interior →
mèo → front**. Ngoài đồ vật, sort cả cụm theo điểm chạm đất. Lối trước mở xuống
ground, không có thanh chắn ngang. Mèo luôn giữ mặt trước ở mọi trạng thái.

Bộ mèo có thứ tự **tail → foot_L_image → foot_R_image → body → paw_L_image →
paw_R_image → head**. Pivot chân là (82,203), (174,203); `assembled.svg` là pose
ghép nguyên bản. Không copy hoặc dùng pose quay lưng thử nghiệm.

## Nguồn và xử lý

- [V4 đã duyệt](../../../../docs/design/2026-10-20/cardboard-castle-lobby-v4/README.md):
  `castle-layer.png`, `castle-crop.png` được copy đúng byte; terrain gốc được giữ
  tại `source/terrain-approved-v4.png` để truy nguồn, không dùng làm nền runtime.
- [Ống chui](../../../../docs/design/2026-10-20/cardboard-tunnel-svg-pilot/art/README.md)
  và [khay nghỉ](../../../../docs/design/2026-10-20/cardboard-tunnel-svg-pilot/bed-art/README.md):
  copy đúng SVG và geometry đã duyệt.
- [Bộ mèo gốc tách phần](../../../../docs/design/2026-10-20/cat-spine-parts/README.md):
  copy đúng ba bộ cream/tabby/calico, giữ nguyên nét, màu và gương mặt.

Terrain V4 đã loại castle/cats nhưng còn ống và khay vẽ sẵn. `terrain-clean.png`
chỉ phục hồi cỏ ở hai vị trí này cùng bóng của chúng để tránh xuất hiện hai lần
khi đặt entity sống. Cỏ được fit từ chính các pixel cỏ lân cận, loại đường mòn,
đồ vật, bóng và nét tuft khỏi mẫu. Mask có viền mềm, bảo vệ bóng chân lâu đài,
post, quả len và gối. Không thay sky/cây/đường hay phát sinh art mới.

`pillow-foreground.png` và `yarn-foreground.png` lấy đúng pixel gối và len cũ để
phục hồi thứ tự che lên khay hoặc mèo. RGB giữ nguyên nguồn, chỉ trích alpha;
đây là các lớp trang trí tĩnh, không phải thêm vật thể sống. Đặt ảnh fullcanvas
ở (0,0); với node Y-sort tại điểm chạm đất, sprite cần offset âm ground tương ứng.
Không dùng ảnh V4
`courtyard-background.png` cùng castle layer vì ảnh đó đã ghép lâu đài.

## Tái tạo và kiểm tra

Chạy từ gốc repository:

```powershell
python game/assets/lobby/cardboard/prepare_assets.py
```

Script kiểm tra SHA của **39 file copy**, pixel ngoài mask không đổi và các vùng
bảo vệ vẫn khớp nguồn tuyệt đối. [review/scene-proof.png](review/scene-proof.png)
ghép terrain sạch, lâu đài và hai đồ giấy đúng tọa độ trên, chưa ghép mèo/UI.
Các mask và terrain riêng nằm trong `review/`; `source/` và `review/` có
`.gdignore` để không nhập ảnh tham chiếu thành tài nguyên runtime.
