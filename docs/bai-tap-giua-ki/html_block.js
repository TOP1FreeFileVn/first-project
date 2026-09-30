// The report's HTML, shaped by the course rubric: 1. game intro (2 pages), 2. 50-level
// progression (4 pages), 3. level briefs (overview + one page per level), 4. summary.
module.exports = (ctx) => {
  const { data, levels, css, img, esc, fmt, dec, PHASES, coreLoop, levelCurve, levelTable50, brief10Table, shots, troopName, P, metrics, before } = ctx;
  const pctd = x => Math.round(x * 100) + '%';
  const tuned = [2, 8, 9, 10];
  const beforeAfter = tuned.map(l => {
    const b = before[l], a = metrics[l];
    return `<tr><td>${l}</td><td style="text-align:left">${esc(levels[l - 1].name)}</td><td>${b ? pctd(b.rate) + ` (${b.wins}/${b.runs})` : '—'}</td><td>${a ? pctd(a.rate) + ` (${a.wins}/${a.runs})` : '—'}</td><td>${a ? P.mmss(a.avgTime) : '—'}</td></tr>`;
  }).join('');
  const oldPower = { 2: '2,0', 8: '2,8', 9: '3,0', 10: '3,0' };

  return `<!doctype html><html lang="vi"><head><meta charset="utf-8"><title>Báo cáo thiết kế màn chơi – Gear Defenders</title><style>${css}${P.CSS}</style></head><body>

<section class="page"><div class="cover">
  <div class="school">HỌC VIỆN CÔNG NGHỆ BƯU CHÍNH VIỄN THÔNG<br>VIỆN CÔNG NGHỆ THÔNG TIN VÀ TRUYỀN THÔNG CDIT</div>
  <img class="logo" src="${img('ptit_logo')}">
  <div class="kind">BÁO CÁO BÀI TẬP GIỮA KÌ</div>
  <div class="topic">Thiết kế màn chơi và cơ chế game<br>Gear Defenders</div>
  <table class="info">
    <tr><td>Giảng viên hướng dẫn:</td><td>ThS. Trần Duy Hiếu</td></tr>
    <tr><td>Sinh viên thực hiện:</td><td>Nguyễn Đình Cường Quốc</td></tr>
    <tr><td>Mã sinh viên:</td><td>B24DCGA124</td></tr>
    <tr><td>Lớp:</td><td>D24CQGA04-B</td></tr>
  </table>
  <div class="place">HÀ NỘI - 2026</div>
</div></section>

<section class="page">
  <h2>Mục lục</h2>
  <ol class="toc">
    <li>Giới thiệu game: tổng quan, USP, gameplay cơ bản, đối tượng và thị trường</li>
    <li>Tiến trình 50 level: giai đoạn, level curve, bảng tiến trình, thư viện cơ chế</li>
    <li>Level brief chi tiết level 1–10: chỉ số playtest và One-page Level Design Document cho từng level</li>
    <li>Tổng kết và hướng phát triển</li>
  </ol>
  <h3>Tóm tắt</h3>
  <p><b>Gear Defenders</b> là game thủ thành kết hợp ghép đồ (merge) trên điện thoại, màn hình dọc. Người chơi không điều khiển lính mà điều khiển <b>bộ máy bánh răng</b>: mỗi bánh răng (gear) là một doanh trại lính; gear chỉ sinh lính khi đang <b>quay</b>, và chỉ quay khi được trục cam trung tâm đẩy trực tiếp hoặc qua một chuỗi bánh răng ăn khớp. Giữa các đợt địch có <b>lượt nghỉ</b> để mua gear, xếp lại lưới và ghép hai gear giống nhau lên bậc cao hơn.</p>
  <p>Bản demo có <b>${data.levels.length} level chơi được</b>, 13 loại lính, 6 tướng, làm bằng Godot 4 với bộ hình Tiny Swords. Tài liệu trình bày thiết kế cho <b>50 level</b>: ${data.levels.length} level đầu dùng số liệu thật từ dữ liệu game, các level sau là lộ trình dự kiến. Mỗi level trong 10 level đầu được viết theo khung <b>Purpose → Player/Mechanic → Dominant Feature → Goal → Challenge → Space → Encounter → Support → Outcome → Reward</b> của môn học, và được kiểm chứng bằng bot tự chơi (win rate, thời gian chơi).</p>
  <div class="grid3" style="margin-top:12px">
    <div class="card"><h4>Thể loại</h4>Tower defense + merge + auto-battler</div>
    <div class="card"><h4>Nền tảng</h4>Android / iOS · dọc 720×1280 · bản web</div>
    <div class="card"><h4>Phiên chơi</h4>1–5 phút mỗi màn · 4–8 đợt địch</div>
  </div>
  <h3>Điểm khác biệt (USP)</h3>
  <p><span class="tag">Sinh lính bằng chuyển động bánh răng</span><span class="tag">Xếp xích truyền động như giải đố</span><span class="tag">Ghép gear lên bậc</span><span class="tag">Shop giữa đợt có chiến thuật kinh tế</span><span class="tag">Ô đặc biệt trên lưới</span></p>
</section>

<section class="page compact">
  <h2><span class="num">1</span>Giới thiệu game</h2>
  <div class="grid2">
    <div>
      <table>
        <tr><td><b>Tên game</b></td><td>Gear Defenders</td></tr>
        <tr><td><b>Thể loại</b></td><td>Thủ thành + ghép đồ (merge) + lính tự đánh</td></tr>
        <tr><td><b>Bối cảnh</b></td><td>Vương quốc trung cổ bị Quân Đỏ và Quân Đen xâm lược; người chơi là kỹ sư vận hành cỗ máy bánh răng cổ giữ thành</td></tr>
        <tr><td><b>Trải nghiệm cốt lõi</b></td><td>Cảm giác "lắp máy cho khéo": bánh răng ăn khớp và lính tuôn ra</td></tr>
        <tr><td><b>Nền tảng</b></td><td>Mobile, màn hình dọc, chơi một tay; có bản chạy trên trình duyệt</td></tr>
        <tr><td><b>Engine / đồ hoạ</b></td><td>Godot 4.7 · pixel art Tiny Swords · font Paytone One</td></tr>
      </table>
      <h3>Đối tượng người chơi</h3>
      <table>
        <tr><td><b>Casual–midcore, 13–35 tuổi</b></td><td>Học sinh, sinh viên, nhân viên văn phòng; chơi lúc rảnh 3–10 phút</td></tr>
        <tr><td><b>Mobile first</b></td><td>Dọc, một tay, không cần phản xạ nhanh</td></tr>
        <tr><td><b>Thích xếp cho khéo</b></td><td>Thích merge, giải đố không gian, tối ưu</td></tr>
        <tr><td><b>Thích sưu tầm</b></td><td>13 lính, 6 tướng, rương, nâng cấp giữa các trận</td></tr>
      </table>
      <h3>Key values</h3>
      <p><span class="tag">Dễ học – khó giỏi</span><span class="tag">Cảm giác cơ khí thỏa mãn</span><span class="tag">Nhiều level, nhiều cơ chế mới</span><span class="tag">Thưởng thường xuyên</span><span class="tag">Phiên ngắn</span></p>
      <h3>Tham khảo thị trường</h3>
      <table class="small" style="text-align:left">
        <tr><th>Nhóm game</th><th>Học hỏi</th><th>Khác biệt</th></tr>
        <tr><td>Merge TD (kiểu Rush Royale)</td><td>Ghép cùng loại, shop ngẫu nhiên</td><td>Vị trí có ý nghĩa nhờ xích bánh răng</td></tr>
        <tr><td>Auto-battler (kiểu TFT)</td><td>Lượt nghỉ mua sắm, lãi</td><td>1 người, phiên ngắn</td></tr>
      </table>
    </div>
    <div>${shots([['battle_shop', 'Lượt nghỉ: shop 5 món, lưới gear, trục cam ở giữa'], ['battle_fight', 'Đợt địch: gear quay sinh lính, tướng dẫn đội']], 2)}</div>
  </div>
</section>

<section class="page compact">
  <h2><span class="num">1</span>Gameplay cơ bản</h2>
  ${coreLoop()}
  <div class="grid2">
    <div>
      <h3>Điều khiển</h3>
      <table>
        <tr><td><b>Mua</b></td><td>Chạm món trong shop (tốn thịt) → gear vào ô trống</td></tr>
        <tr><td><b>Di chuyển</b></td><td>Kéo gear sang ô khác; thả lên gear khác để đổi chỗ</td></tr>
        <tr><td><b>Ghép</b></td><td>Thả gear lên gear <i>cùng lính, cùng bậc</i> → lên bậc (tối đa 5)</td></tr>
        <tr><td><b>Bán</b></td><td>Kéo gear vào nút BÁN → hoàn 75% giá</td></tr>
        <tr><td><b>Shop</b></td><td>Đổi 5 món (lần đầu miễn phí), khoá để giữ món</td></tr>
      </table>
      <h3>Thắng / thua / sao</h3>
      <p><b>Thắng:</b> sống qua mọi đợt. <b>Thua:</b> thành hết máu. <b>Sao:</b> theo % máu thành còn lại.</p>
    </div>
    <div>
      <h3>Cơ chế truyền động</h3>
      <p>Trục cam ở giữa lưới quay liên tục; cần gạt của nó đẩy từng răng của gear kề bên. Gear chạm gear đang quay sẽ quay theo, tạo <b>chuỗi truyền động</b>. <b>Chỉ gear đang quay mới sinh lính</b>, mỗi răng quay là 3 giây sản xuất.</p>
      <h3>Kinh tế trong trận</h3>
      <p>Thu nhập mỗi đợt = <b>5 + số đợt</b>, cộng <b>lãi</b> 1 thịt cho mỗi 5 thịt để dành (tối đa 3). Giá: Thường 2 · Hiếm 3 · Sử thi 4 · Huyền thoại 6.</p>
      <h3>Ngoài trận</h3>
      <p>Vàng và thẻ lính nâng cấp lính (cấp +8%, sao ×1,2), nâng thành (thêm ô lưới, ô đội hình), mở tướng; quà 7 ngày, nhiệm vụ, sự kiện.</p>
    </div>
  </div>
  <h3>Lính (13 loại)</h3>
  <table class="small" style="text-align:left">${[['Thường', ['pawn', 'warrior', 'archer', 'miner', 'smith']], ['Hiếm', ['lancer', 'assassin', 'guard', 'fire_archer']], ['Sử thi', ['monk', 'cook', 'bomber']], ['Huyền thoại', ['general']]]
    .map(([r, ids]) => `<tr><td style="font-weight:700">${r}</td><td>${ids.map(id => troopName[id]).join(' · ')}</td></tr>`).join('')}</table>
</section>

<section class="page">
  <h2><span class="num">2</span>Tiến trình 50 level</h2>
  <div class="grid3" style="grid-template-columns:repeat(5,1fr);gap:8px">
    ${PHASES.map(p => `<div class="phase" style="background:${p.color}"><b>GĐ${p.n} (${p.from}–${p.to})</b>${esc(p.name)}<br><span style="opacity:.92">${esc(p.goal)}</span></div>`).join('')}
  </div>
  <h3>Đường cong độ khó (level curve)</h3>
  ${levelCurve()}
  <p><b>Cột</b>: độ khó cảm nhận 1–5 theo thiết kế, dạng răng cưa (theo Scott Kim): tăng trong mỗi giai đoạn, đỉnh ở <b>trùm nhỏ</b> (★, level x5) và <b>trùm lớn</b> (👑, level x0), rồi <b>hạ ngay sau trùm</b> để người chơi thở. <b>Đường</b>: chỉ số sức ép địch = số quân × sức mạnh địch ÷ máu thành, tính từ dữ liệu. Chấm đặc: level có trong demo.</p>
  <h3>Nguyên tắc tiến trình</h3>
  <ul>
    <li><b>Một level, một ý tưởng chính</b>; 2–3 level sau kết hợp ý đó với ý cũ (giới thiệu → luyện → kết hợp → áp lực → thành thạo).</li>
    <li>Tăng khó bằng <b>Context / Combination / Constraint</b>: ô đặc biệt, tổ hợp địch, giới hạn thịt, không chỉ tăng máu địch.</li>
    <li>Sức ép địch tăng ~7%/level từ level 11; người chơi bù bằng nâng cấp và ô lưới.</li>
    <li>Cơ chế mở khoá: quà lần đầu (lính mới ở level 1, 2, 3, 5, 7, 12, 15), kim cương và tướng ở trùm.</li>
  </ul>
</section>

<section class="page">
  <h2><span class="num">2</span>Bảng tiến trình 50 level (1–25)</h2>
  ${levelTable50(1, 25)}
</section>

<section class="page">
  <h2><span class="num">2</span>Bảng tiến trình 50 level (26–50)</h2>
  ${levelTable50(26, 50)}
  <p style="font-size:8pt;color:#546e7a">Tên in nghiêng xám: level dự kiến. Sức mạnh địch: hệ số nhân máu và sát thương quân địch. Ô gear: số ô lưới ở cấp thành khuyến nghị. Nền cam: trùm lớn; nền vàng: trùm nhỏ. Bảng dạng Excel: <b>bang_tien_trinh_50_level.xlsx</b>.</p>
</section>

<section class="page">
  <h2><span class="num">2</span>Thư viện cơ chế</h2>
  <p>Mỗi cơ chế ghi rõ level mở, luật, ràng buộc khi thiết kế và các sai lầm thường gặp, để level designer và lập trình viên hiểu giống nhau (theo mẫu Block Library của các file level design).</p>
  ${P.mechanicTable()}
</section>

<section class="page compact">
  <h2><span class="num">3</span>Level brief level 1–10: tổng quan và chỉ số</h2>
  <div class="tight">${brief10Table()}</div>
  <h3>Chỉ số playtest (bot tự chơi)</h3>
  <p>Mỗi level chơi 4 lượt bằng bot dùng đúng thao tác kéo thả thật, với hồ sơ người chơi hợp lý khi tới level đó (cấp thành theo gợi ý, lính cấp 1→10, đội hình chỉ gồm lính đã mở). Win rate mục tiêu theo độ khó: Normal 75–100%, Hard 45–80%, Super Hard 30–50%.</p>
  ${P.metricsTable(levels, metrics)}
</section>

${levels.slice(0, 10).map(r => P.lddPage(r, data.levels[r.l - 1], metrics, img, troopName)).join('\n')}

<section class="page compact">
  <h2><span class="num">4</span>Tổng kết và hướng phát triển</h2>
  <h3>Điều đã kiểm chứng</h3>
  <ul>
    <li>Vòng lặp mua → xếp → quay → sinh lính dễ hiểu: level 1–7 đạt win rate 100% với bot, level 1 xong trong khoảng 1 phút rưỡi.</li>
    <li>Cơ chế bánh răng tạo được bài toán không gian: các level 11–15 dùng ô đá, ô vàng, ô rỉ sét, ô băng mà không cần hình mới.</li>
    <li>Số liệu giúp tìm và sửa gai độ khó (level 2, level 8–10) trước khi có người chơi thật.</li>
  </ul>
  <h3>Vòng chỉnh sửa theo số liệu</h3>
  <p>Chỉ số playtest ở mục 3 cho thấy tác dụng của vòng này. Lần đo đầu cho thấy <b>gai độ khó ở level 8–10</b>: level 7 thắng 4/4 nhưng level 8 chỉ 1/4, level 9–10 thua cả 4 lượt, có lượt thua ngay ở đợt 1 sau 27 giây. <b>Giả thuyết:</b> sức mạnh địch tăng nhanh hơn sức mạnh người chơi ở mức nâng cấp vừa phải. <b>Chỉnh:</b> hạ sức mạnh địch level 8/9/10 và level 2 (gai đã thấy từ trước). <b>Đo lại:</b></p>
  <table class="small metrics"><thead><tr><th>Lv</th><th>Tên</th><th>Win rate trước</th><th>Win rate sau</th><th>Thời gian TB sau</th></tr></thead><tbody>${beforeAfter}</tbody></table>
  <p style="font-size:8.5pt;color:#546e7a">Sức mạnh địch đã chỉnh: level 2: ${oldPower[2]} → ${dec(levels[1].power, 1)}; level 8: ${oldPower[8]} → ${dec(levels[7].power, 1)}; level 9: ${oldPower[9]} → ${dec(levels[8].power, 1)}; level 10: ${oldPower[10]} → ${dec(levels[9].power, 1)}. Bot chơi đều tay hơn người thật, nên số liệu dùng để so sánh giữa các level; Reach Rate và Churn Rate sẽ đo khi có người chơi thật.</p>
  <h3>Hạn chế</h3>
  <ul>
    <li>Win rate đo bằng bot, chưa có Reach / Churn thật; cần playtest với người chơi.</li>
    <li>Level 7–10 dài 4–5 phút, hơi quá mục tiêu 2–4 phút; có thể bớt một đợt.</li>
    <li>Bộ hình miễn phí có ít loại lính; kẻ địch mới dựa vào đổi màu và cơ chế.</li>
  </ul>
  <h3>Hướng phát triển</h3>
  <table>
    <tr><td><b>Giai đoạn 2 (11–20)</b></td><td>Đã làm 11–15 với ô đặc biệt; tiếp theo là địch hồi máu theo nhóm, sương mù, shop 4 ô, trùm level 20</td></tr>
    <tr><td><b>Chọn buff giữa đợt</b></td><td>Hết mỗi đợt chọn 1 trong 3 thẻ buff: tăng tính chơi lại</td></tr>
    <tr><td><b>Hệ phái lính</b></td><td>Thợ / Kỵ sĩ / Xạ thủ / Bóng tối: có 2–3 lính cùng hệ thì được buff</td></tr>
    <tr><td><b>Kỹ năng tướng</b></td><td>Nút kỹ năng trong trận, hồi chiêu 20–30 giây</td></tr>
    <tr><td><b>Chế độ và sự kiện</b></td><td>Vô tận, thử thách ngày, Boss Rush, tháp thử thách dạng giải đố</td></tr>
    <tr><td><b>Đo lường</b></td><td>Ghi Level Start, Win/Lose, Play Time, thịt để dành mỗi lượt để tính Reach, Churn, Deep Metric</td></tr>
  </table>
  <h3>Sản phẩm nộp</h3>
  <table>
    <tr><td>Báo cáo PDF</td><td>bao_cao_thiet_ke_level.pdf (tài liệu này)</td></tr>
    <tr><td>Slide tổng quan 1 trang</td><td>tong_quan_1_trang.png / .pdf</td></tr>
    <tr><td>Bảng tiến trình 50 level</td><td>bang_tien_trinh_50_level.xlsx</td></tr>
    <tr><td>Bản demo chơi được</td><td>GearDefenders_Demo_Windows.zip; bản web chạy trên trình duyệt</td></tr>
    <tr><td>Video gameplay</td><td>GearDefenders_gameplay.mp4 (3 phút 27 giây)</td></tr>
  </table>
</section>

</body></html>`;
};
