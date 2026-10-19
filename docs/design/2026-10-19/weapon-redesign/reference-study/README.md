# Nghiên cứu chi tiết vũ khí từ Figma

Nguồn bổ sung người dùng chỉ định sau đó: [nhân vật cầm vũ khí — trang 3443:2](held-characters/README.md). Đã xem biến thể đầu/cuối của 21 nhóm Hero và sáu ví dụ kiếm, rìu, giáo, gậy, nỏ, sách. Nguồn này cung cấp mẫu trực tiếp cho tư thế cầm và cách phối vũ khí với nhân vật.

Nguồn người dùng chỉ định: [Asset bổ sung · Kho PNG](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3470-2), Cat Gunner 1.1.64. Ngày xem: 2026-10-19.

Đã xem các bảng sprite 01–06 và 08; lưu ảnh tổng quan trong `sheet-*.png`. Các PNG `ref-*.png` là phần sprite đã xuất riêng từ node Figma, giữ nền trong suốt. Không dùng các ảnh tham khảo này làm tài sản runtime.

| Tệp | Node ảnh | Chi tiết đáng học |
| --- | --- | --- |
| [Pistol](ref-pistol.png) | [3471:289](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3471-289) | Thân thép lớn, báng riêng, khe mở ít và rõ |
| [Súng nhiều nòng](ref-minigun.png) | [3471:437](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3471-437) | Nòng và đai lặp có khoảng cách, chi tiết theo cấu tạo |
| [Shotgun](ref-shotgun.png) | [3471:578](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3471-578) | Mảng thép/gỗ dài, ít đường chia có chủ đích |
| [Súng có ống ngắm](ref-sniper.png) | [3471:1053](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3471-1053) | Ống ngắm, thân, nòng, báng và tay cầm đọc được riêng |
| [Mèo](ref-cat.png) | [3471:252](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3471-252) | Viền bo nâu ấm, mảng màu lớn |
| [Mèo cùng súng](ref-cat-gun.png) | [3471:2283](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3471-2283) | Súng rõ các bộ phận, nét nhỏ nhẹ hơn nét chính; mặt mèo vẫn nổi bật |
| [Icon súng menu](ref-menu-gun.png) | [3471:3011](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3471-3011) | Ít chi tiết, viền rất dày: khác mục đích với sprite vũ khí |

## Kết luận áp dụng

- Thiết kế từ khối chính → mảng vật liệu → bộ phận chức năng → vài chi tiết nhỏ.
- Chi tiết có ích là ống ngắm, báng, hộp tiếp đạn, đai nòng, khoảng cò; không phải nhiều vân gỗ và vít vụn.
- Phân cấp nét ngoài, đường chia bộ phận và nét phụ. Chừa diện tích màu, khe và lỗ đủ rộng ngay lúc dựng hình.
- Bộ vũ khí phát triển theo cùng họ cấu tạo, với vật liệu/phụ kiện có hệ thống. Đây là nhận xét về hình ảnh, không suy ra luật nâng cấp.
- Không lấy độ dày viền của `Icon_Gun` menu áp vào mọi chi tiết của sprite súng.
- Không áp nét bóng của cá/đá quý/tiền tệ trong cùng trang lên vũ khí cầm của mèo.

## Vì sao bản thử V3 chưa đạt

V3 giữ nhiều nét vân gỗ, dây quấn và vít mảnh; khi thêm viền dày, lỗ cò và vòng đầu gậy bị lấp, cán và đốc kiếm thành khối nâu. Cần thiết kế lại tỷ lệ bộ phận và khoảng hở. Không tiếp tục bồi stroke đồng loạt. Bản đó là thử nghiệm bị loại, chưa được đưa vào game hoặc trang duyệt Figma.

Chuẩn này đã ghi vào skill dự án: [figma-weapon-study.md](../../../../../tools/skills/casual-weapon-design/references/figma-weapon-study.md). Tham khảo chủ yếu là súng; áp dụng sang kiếm, rìu và gậy là diễn giải theo cách tổ chức chi tiết, không sao chép hình dáng súng.
