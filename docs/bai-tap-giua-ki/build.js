// Builds the midterm design report (bao_cao.html -> PDF), the one-page overview slide and
// the 50-level progression table (CSV) from the game's real numbers (design_data.json,
// exported by tests/ExportDesignData.tscn). Run: node build.js
const fs = require('fs');
const path = require('path');
const DIR = __dirname;
const data = JSON.parse(fs.readFileSync(path.join(DIR, 'design_data.json'), 'utf8'));

const RARITY = ['Thường', 'Hiếm', 'Sử thi', 'Huyền thoại'];
const RARITY_COLOR = ['#8a96a3', '#3b8fd6', '#9b5de5', '#e59400'];
const ROLE = ['Cận chiến', 'Bắn xa', 'Hồi máu', 'Hỗ trợ'];
const troopName = Object.fromEntries(data.troops.map(t => [t.id, t.name]));
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;');
const fmt = n => Math.round(n).toLocaleString('vi-VN');
const dec = (n, d = 2) => Number(n).toFixed(d).replace('.', ',');

// ---------------------------------------------------------------------------------------
// Levels 1-10: real data. Levels 11-50: planned roadmap.
const PHASES = [
  { n: 1, from: 1, to: 10, name: 'Làm quen', color: '#4caf50', goal: 'Học cơ chế cốt lõi: mua gear, đặt cạnh trục, ghép gear, xích truyền động, kinh tế lãi.' },
  { n: 2, from: 11, to: 20, name: 'Mở rộng cơ chế', color: '#2196f3', goal: 'Mỗi màn thêm một biến thể của lưới gear hoặc một kiểu địch mới.' },
  { n: 3, from: 21, to: 30, name: 'Tăng thử thách', color: '#ff9800', goal: 'Siết tài nguyên (thịt, máu thành, tốc độ trục) để buộc người chơi tối ưu.' },
  { n: 4, from: 31, to: 40, name: 'Biến thể phức tạp', color: '#f44336', goal: 'Lưới gear nhiều trục, bánh răng đảo chiều, địch tấn công hai hướng.' },
  { n: 5, from: 41, to: 50, name: 'Thử thách cao', color: '#9c27b0', goal: 'Tổng hợp mọi cơ chế, trùm nhiều giai đoạn, màn 50 là trùm cuối.' },
];
const phaseOf = l => PHASES.find(p => l >= p.from && l <= p.to);

// Planned levels: name, new mechanic / focus.
const PLAN = {
  11: ['Bến Cảng', 'Ô đá chắn cạnh trục cam: phải nối xích đi vòng'],
  12: ['Rừng Sương', 'Nhiều Hiệp sĩ khiên địch + ô đá: cần sát thương dồn'],
  13: ['Đồi Cừu', 'Ô vàng: gear đặt lên sinh lính nhanh hơn 50%'],
  14: ['Mỏ Vàng', 'Ô rỉ sét: gear chỉ truyền động, không sinh lính; kỵ thương dồn dập'],
  15: ['Cầu Đá', 'Ô băng: gear chỉ quay khi chạm trục; trùm nhỏ Thợ rèn + khiên tinh nhuệ'],
  16: ['Trại Lính', 'Đầu bếp địch đi theo nhóm, hồi máu liên tục'],
  17: ['Bãi Lau', 'Sương mù: không xem trước đợt địch kế tiếp'],
  18: ['Tháp Canh', 'Shop chỉ còn 4 ô: chọn lọc kỹ hơn'],
  19: ['Thung Lũng Gió', 'Hai tinh nhuệ mỗi đợt'],
  20: ['Pháo Đài Đen', 'TRÙM: Tướng quân Đen + cận vệ khiên'],
  21: ['Làng Cháy', 'Thành bắt đầu với 70% máu'],
  22: ['Cối Xay Gỉ', 'Trục cam quay chậm hơn 20%'],
  23: ['Doanh Trại Pháo', 'Pháo thủ địch bắn vào bàn gear: gear trúng bom ngừng quay 3 giây'],
  24: ['Mê Cung Đá', 'Ô lưới khoá luân phiên mỗi đợt'],
  25: ['Đèo Hiểm', 'Trùm nhỏ: Sát thủ Bóng Đêm địch săn lính bắn xa'],
  26: ['Chiến Hào', 'Đợt đôi: hai đợt liền nhau không có lượt nghỉ'],
  27: ['Kho Lương Trống', 'Thịt khởi đầu thấp, lãi tiết kiệm tăng'],
  28: ['Tu Viện Đen', 'Tu sĩ địch hồi sinh đồng đội một lần'],
  29: ['Tường Thành Cổ', 'Tổng hợp giai đoạn 3'],
  30: ['Vua Đỏ Trở Lại', 'TRÙM 2 giai đoạn: khi còn 50% máu gọi thêm quân'],
  31: ['Nhà Máy Bánh Răng', 'Hai trục cam: hai chuỗi truyền động riêng'],
  32: ['Xưởng Đảo Chiều', 'Ô đảo chiều: gear quay ngược thì không sinh lính'],
  33: ['Sông Băng', 'Địch làm chậm lính ta khi đánh trúng'],
  34: ['Ngã Ba', 'Địch tấn công hai hướng: trái và phải'],
  35: ['Cổng Sắt', 'Trùm nhỏ: Hiệp sĩ Thép miễn tên'],
  36: ['Chợ Đen', 'Giới hạn 3 lần đổi shop cả màn'],
  37: ['Tháp Cung', 'Địch miễn sát thương tên trong 2 đợt'],
  38: ['Hẻm Chật', 'Số lính tối đa trên sân giảm còn 40'],
  39: ['Thành Lũy Kép', 'Tổng hợp giai đoạn 4'],
  40: ['Quân Đoàn Đen', 'TRÙM: 3 tinh nhuệ + Tướng quân Đen cùng lúc'],
  41: ['Vực Thẳm', 'Mọi đợt có tinh nhuệ'],
  42: ['Rừng Chết', 'Sương mù + đợt đôi'],
  43: ['Pháo Đài Lửa', 'Cung lửa và Pháo thủ địch số đông'],
  44: ['Đại Lộ Máu', 'Thành 60% máu + trục chậm'],
  45: ['Cổng Địa Ngục', 'Trùm nhỏ: hai Tướng quân địch'],
  46: ['Tháp Đồng Hồ', 'Hai trục cam + ô khoá luân phiên'],
  47: ['Hầm Mộ', 'Địch hồi sinh + hồi máu'],
  48: ['Lâu Đài Gió', 'Tấn công hai hướng + shop 4 ô'],
  49: ['Ngai Vàng', 'Tổng hợp mọi cơ chế'],
  50: ['Vua Đen', 'TRÙM CUỐI 3 giai đoạn'],
};
const LEVEL_FOCUS_1_10 = {
  1: 'Mua gear, đặt cạnh trục cam, bánh răng quay thì sinh lính',
  2: 'Ghép 2 gear giống nhau lên bậc 2; Kỵ thương địch xuất hiện',
  3: 'Xích truyền động qua gear khác; Tu sĩ địch hồi máu',
  4: 'Kinh tế: để dành thịt để nhận lãi (tối đa +3/đợt)',
  5: 'Thợ mỏ địch chịu tên: cần cận chiến; mở khoá Hiệp sĩ khiên',
  6: 'Cung lửa địch đốt lính; khoá shop giữ gear hiếm',
  7: 'Sát thủ địch săn lính bắn xa; Hiệp sĩ khiên địch',
  8: 'Đầu bếp, Thợ rèn, Pháo thủ địch: dàn lính tản ra',
  9: 'Kiểm tra tổng hợp: 8 đợt, 4 tinh nhuệ, gear bậc 3',
  10: 'TRÙM: Tướng quân địch (Huyền thoại)',
};
// Perceived difficulty 1-5: a sawtooth that rises by phase, peaks at bosses (x0) and
// mini-bosses (x5) and eases right after each boss.
const FELT = [
  1, 2, 1, 2, 2, 2, 3, 3, 3, 4,
  2, 2, 3, 3, 4, 3, 3, 3, 4, 4,
  3, 3, 3, 4, 4, 3, 4, 4, 4, 5,
  3, 4, 4, 4, 5, 4, 4, 4, 5, 5,
  4, 4, 5, 4, 5, 4, 5, 5, 5, 5,
];
// Recommended castle level (grid cells) per phase for the planned levels.
const CASTLE_FOR = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5];
const GIFTS_PLAN = { 12: 'Mở khoá Thợ rèn', 15: 'Rương Bạc', 20: '50 kim cương + Pháo thủ', 25: 'Rương Vàng', 30: '80 kim cương + 10 mảnh tướng',
  35: 'Rương Vàng', 40: '100 kim cương + Tướng Sử thi', 45: 'Rương Vàng x2', 50: '200 kim cương + Tướng Huyền thoại' };

const levels = [];
for (let l = 1; l <= 50; l++) {
  let row;
  if (l <= data.levels.length) {
    const d = data.levels[l - 1];
    const gift = d.gift ? `Mở khoá ${troopName[d.gift]}` : '';
    row = {
      l, name: d.name.split(' · ')[1], waves: d.waves.length, enemies: d.enemies, elites: d.elites, power: d.enemy_power,
      core: d.core_hp, meat: d.start_meat, focus: LEVEL_FOCUS_1_10[l] || PLAN[l][1], gold: d.gold_3star, gift, real: true, kinds: d.kinds,
    };
  } else {
    const k = l - 10;
    const waves = Math.min(12, 8 + Math.floor(k / 8));
    let power = 3.0 * Math.pow(1.07, k);
    if (l % 10 === 1) power *= 0.9;
    if (l % 10 === 0) power *= 1.12;
    if (l % 10 === 5) power *= 1.06;
    const enemies = Math.round(waves * (24 + k * 0.55));
    row = {
      l, name: PLAN[l][0], waves, enemies, elites: Math.min(waves, 4 + Math.floor(k / 5)), power: +power.toFixed(2),
      core: 150 + Math.floor(k / 2) * 5, meat: Math.min(30, 15 + Math.floor(k / 3)), focus: PLAN[l][1],
      gold: 160 + 40 * (l - 1), gift: GIFTS_PLAN[l] || '', real: false,
    };
  }
  row.phase = phaseOf(l);
  row.pressure = row.enemies * row.power / row.core;
  row.felt = FELT[l - 1];
  row.boss = l % 10 === 0 ? 'boss' : (l % 10 === 5 && l > 10 ? 'mini' : '');
  row.castle = l <= 10 ? CASTLE_FOR[l - 1] : Math.min(10, 5 + Math.ceil((l - 10) / 8));
  row.cells = data.castle[row.castle - 1].cells;
  levels.push(row);
}

// ---------------------------------------------------------------------------------------
// Charts (inline SVG).
function levelCurve(width = 900, height = 330) {
  const pad = { l: 48, r: 56, t: 34, b: 40 };
  const w = width - pad.l - pad.r, h = height - pad.t - pad.b;
  const x = l => pad.l + (l - 0.5) / 50 * w;
  const y = v => pad.t + h - (v / 5) * h;
  const maxP = Math.max(...levels.map(r => Math.log(r.pressure)));
  const minP = Math.min(...levels.map(r => Math.log(r.pressure)));
  const yp = p => pad.t + h - (Math.log(p) - minP) / (maxP - minP) * h;
  let s = `<svg viewBox="0 0 ${width} ${height}" width="100%" xmlns="http://www.w3.org/2000/svg" font-family="Segoe UI, Arial" font-size="11">`;
  for (const p of PHASES) {
    const x0 = x(p.from) - w / 100, x1 = x(p.to) + w / 100;
    s += `<rect x="${x0}" y="${pad.t}" width="${x1 - x0}" height="${h}" fill="${p.color}" opacity="0.08"/>`;
    s += `<text x="${(x0 + x1) / 2}" y="${pad.t - 10}" text-anchor="middle" font-weight="700" fill="${p.color}">GĐ${p.n} · ${p.name}</text>`;
  }
  for (let v = 1; v <= 5; v++) {
    s += `<line x1="${pad.l}" x2="${pad.l + w}" y1="${y(v)}" y2="${y(v)}" stroke="#ddd"/>`;
    s += `<text x="${pad.l - 8}" y="${y(v) + 4}" text-anchor="end" fill="#555">${v}</text>`;
  }
  for (const r of levels) {
    const bw = w / 50 * 0.7;
    s += `<rect x="${x(r.l) - bw / 2}" y="${y(r.felt)}" width="${bw}" height="${y(0) - y(r.felt)}" rx="2" fill="${r.phase.color}" opacity="${r.real ? 0.95 : 0.6}"/>`;
    if (r.boss) s += `<text x="${x(r.l)}" y="${y(r.felt) - 5}" text-anchor="middle" font-size="12">${r.boss === 'boss' ? '👑' : '★'}</text>`;
  }
  const pts = levels.map(r => `${x(r.l)},${yp(r.pressure)}`).join(' ');
  s += `<polyline points="${pts}" fill="none" stroke="#263238" stroke-width="2"/>`;
  for (const r of levels) s += `<circle cx="${x(r.l)}" cy="${yp(r.pressure)}" r="${r.real ? 3 : 2}" fill="${r.real ? '#263238' : '#fff'}" stroke="#263238"/>`;
  for (const l of [1, 10, 20, 30, 40, 50]) s += `<text x="${x(l)}" y="${pad.t + h + 16}" text-anchor="middle" fill="#555">${l}</text>`;
  s += `<text x="${pad.l + w / 2}" y="${height - 4}" text-anchor="middle" fill="#333">Level</text>`;
  s += `<text transform="translate(14 ${pad.t + h / 2}) rotate(-90)" text-anchor="middle" fill="#333">Độ khó cảm nhận (cột, 1–5)</text>`;
  s += `<text transform="translate(${width - 12} ${pad.t + h / 2}) rotate(90)" text-anchor="middle" fill="#263238">Chỉ số sức ép địch (đường, thang log)</text>`;
  s += `</svg>`;
  return s;
}

function coreLoop() {
  const box = (x, y, w, h, title, sub, color) => `<g><rect x="${x}" y="${y}" width="${w}" height="${h}" rx="14" fill="${color}" stroke="#263238" stroke-width="2"/>
    <text x="${x + w / 2}" y="${y + 26}" text-anchor="middle" font-weight="800" font-size="15" fill="#fff">${title}</text>
    <text x="${x + w / 2}" y="${y + 46}" text-anchor="middle" font-size="11.5" fill="#fff">${sub}</text></g>`;
  const arrow = (x1, y1, x2, y2) => `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="#263238" stroke-width="3" marker-end="url(#a)"/>`;
  return `<svg viewBox="0 0 900 250" width="100%" xmlns="http://www.w3.org/2000/svg" font-family="Segoe UI, Arial">
  <defs><marker id="a" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#263238"/></marker></defs>
  ${box(20, 20, 200, 62, 'LƯỢT NGHỈ (SHOP)', 'Mua gear · đổi shop · khoá shop', '#2196f3')}
  ${box(350, 20, 200, 62, 'XẾP & GHÉP GEAR', 'Nối xích tới trục cam · ghép lên bậc', '#9c27b0')}
  ${box(680, 20, 200, 62, 'ĐỢT ĐỊCH (FIGHT)', 'Gear quay → sinh lính tự đánh', '#f44336')}
  ${box(680, 168, 200, 62, 'HẾT ĐỢT', 'Thu nhập 5 + đợt + lãi (≤3)', '#ff9800')}
  ${box(350, 168, 200, 62, 'THẮNG / THUA', 'Sao theo % máu thành', '#4caf50')}
  ${box(20, 168, 200, 62, 'SẢNH (META)', 'Rương · nâng lính · thành · tướng', '#607d8b')}
  ${arrow(222, 51, 346, 51)}${arrow(552, 51, 676, 51)}${arrow(780, 84, 780, 164)}
  <path d="M676 199 C 600 140, 300 140, 222 60" fill="none" stroke="#263238" stroke-width="2.5" stroke-dasharray="6 5" marker-end="url(#a)"/>
  <text x="450" y="128" text-anchor="middle" font-size="12" fill="#263238">còn đợt → quay lại lượt nghỉ</text>
  ${arrow(676, 199, 554, 199)}${arrow(346, 199, 224, 199)}
  <path d="M120 166 L120 86" stroke="#263238" stroke-width="3" marker-end="url(#a)"/>
  <text x="128" y="130" font-size="12" fill="#263238">chơi màn tiếp</text>
  </svg>`;
}

// ---------------------------------------------------------------------------------------
const img = n => `img/${n}.png`;
const stars = n => '<span class="dots">' + '●'.repeat(n) + '<span class="off">' + '●'.repeat(5 - n) + '</span></span>';

function levelTable50(from, to) {
  let rows = '';
  for (const r of levels.slice(from - 1, to)) {
    rows += `<tr class="${r.boss ? 'b-' + r.boss : ''}"><td style="border-left:5px solid ${r.phase.color}">${r.l}</td><td class="${r.real ? '' : 'planned'}">${esc(r.name)}</td>
      <td>${r.waves}</td><td>${r.enemies}</td><td>${r.elites}</td><td>${dec(r.power)}</td><td>${r.cells}</td>
      <td>${esc(r.focus)}</td><td>${stars(r.felt)}</td><td>${fmt(r.gold)}${r.gift ? '<br><small>' + esc(r.gift) + '</small>' : ''}</td></tr>`;
  }
  return `<table class="t50"><thead><tr><th>Lv</th><th>Tên màn</th><th>Đợt</th><th>Quân</th><th>Tinh nhuệ</th><th>Sức mạnh địch</th><th>Ô gear</th><th>Cơ chế / trọng tâm</th><th>Độ khó</th><th>Thưởng 3★</th></tr></thead><tbody>${rows}</tbody></table>`;
}

function brief10Table() {
  let rows = '';
  for (const r of levels.slice(0, 10)) {
    rows += `<tr><td>${r.l}</td><td>${esc(r.name)}</td><td>${esc(r.focus)}</td><td>${r.cells} ô (thành ${r.castle})</td><td>${r.waves}</td><td>${r.enemies}</td>
    <td>${r.felt}</td><td>${fmt(r.gold)}${r.gift ? '<br><small>' + esc(r.gift) + '</small>' : ''}</td></tr>`;
  }
  return `<table><thead><tr><th>Lv</th><th>Tên</th><th>Mục tiêu &amp; cơ chế chính</th><th>Không gian</th><th>Số đợt</th><th>Số quân</th><th>Độ khó (1–5)</th><th>Thưởng</th></tr></thead><tbody>${rows}</tbody></table>`;
}

// Per-level brief cards for 1-10 (real waves).
const BRIEF = {
  1: { goal: 'Người chơi hiểu vòng lặp: mua gear → đặt cạnh trục cam → bánh răng quay → lính ra trận.', tip: 'Chỉ cần 2–3 gear Chiến binh/Cung thủ đặt sát trục là thắng. Đợt 4 có tinh nhuệ đầu tiên để dạy khái niệm "địch mạnh".', risk: 'Người chơi đặt gear xa trục (không quay) → hướng dẫn chữ nổi khi gear đứng yên.' },
  2: { goal: 'Dạy ghép gear: 2 gear cùng lính, cùng bậc thả lên nhau → bậc 2 mạnh gấp đôi.', tip: 'Shop gắn nhãn "GHÉP ĐƯỢC" khi món đó ghép với gear trên bàn.', risk: 'Sức mạnh địch 2,0 cao hơn màn 3 (1,5): gai độ khó, xem mục 6.' },
  3: { goal: 'Dạy xích truyền động: gear chạm gear đang quay cũng quay theo; một chuỗi dài nuôi nhiều gear.', tip: 'Tu sĩ địch hồi máu cho đồng đội: nên có lính bắn xa hạ trước.', risk: '3 tinh nhuệ dồn cuối: cần gear bậc 2 trở lên.' },
  4: { goal: 'Dạy kinh tế: thịt để dành sinh lãi (mỗi 5 thịt +1, tối đa +3 mỗi đợt).', tip: 'Không cần mua hết shop; khoá shop khi có món tốt.', risk: 'Người chơi tiêu hết mỗi lượt → thiếu thịt cho đợt 5–6.' },
  5: { goal: 'Thợ mỏ địch giảm 50% sát thương tên/bom → buộc có lính cận chiến.', tip: 'Thắng lần đầu mở khoá Hiệp sĩ khiên.', risk: 'Đội toàn cung thủ bị chặn.' },
  6: { goal: 'Cung lửa địch đốt lính; màn dài 7 đợt 138 quân — kiểm tra quản lý shop.', tip: 'Dùng "Đổi shop" (lần đầu miễn phí) tìm gear Hiếm.', risk: 'Lính ít máu cháy nhanh.' },
  7: { goal: 'Sát thủ địch bỏ qua tuyến đầu, săn lính bắn xa/hồi máu phía sau.', tip: 'Đặt Hiệp sĩ khiên, lính cận chiến dày. Thắng lần đầu mở khoá Cung lửa.', risk: 'Hậu tuyến bị cắt → mất Tu sĩ.' },
  8: { goal: 'Ba kiểu địch hỗ trợ: Đầu bếp (hồi máu), Thợ rèn (giáp), Pháo thủ (bom diện rộng).', tip: 'Ưu tiên hạ hỗ trợ; lính tản ra để tránh bom.', risk: 'Bom diện rộng quét cả cụm lính.' },
  9: { goal: 'Bài kiểm tra tổng hợp trước trùm: 8 đợt, 171 quân, 4 tinh nhuệ.', tip: 'Cần gear bậc 3; nâng thành để có 20 ô lưới.', risk: 'Hết chỗ trên lưới → phải bán/ghép hợp lý.' },
  10: { goal: 'TRÙM: Tướng quân địch (Huyền thoại) — chém lan, xoay kiếm, tăng 30% sát thương đồng đội.', tip: 'Dồn sát thương đơn (Kỵ thương, Sát thủ) vào trùm; tướng dẫn đội hỗ trợ.', risk: 'Đợt trùm kèm lính đông: cần tường máu cao (nâng thành).' },
};
function waveSummary(d) {
  return d.waves.map((w, i) => {
    const parts = w.groups.map(g => `${g.count} ${troopName[g.troop]}${g.elite ? ' (tinh nhuệ)' : ''}`);
    return `<li><b>Đợt ${i + 1}</b> (${w.count}): ${parts.join(', ')}</li>`;
  }).join('');
}
function briefCards() {
  return levels.slice(0, 10).map(r => {
    const d = data.levels[r.l - 1];
    const b = BRIEF[r.l];
    return `<div class="brief">
      <div class="bhead" style="background:${r.phase.color}">LEVEL ${r.l} · ${esc(r.name.toUpperCase())}${r.boss === 'boss' ? ' 👑' : ''}<span>Độ khó ${stars(r.felt)}</span></div>
      <div class="bbody">
        <img src="${img('level_' + String(r.l).padStart(2, '0'))}">
        <div class="bcol">
          <p><b>Mục tiêu thiết kế:</b> ${esc(b.goal)}</p>
          <p class="kv"><span>Máu thành <b>${d.core_hp}</b></span><span>Thịt đầu <b>${d.start_meat}</b></span><span>Sức mạnh địch <b>${dec(d.enemy_power, 1)}</b></span><span>Lưới <b>${r.cells} ô</b></span><span>Thưởng <b>${fmt(r.gold)}</b> vàng${r.gift ? ' · ' + esc(r.gift) : ''}</span></p>
          <ul class="waves">${waveSummary(d)}</ul>
          <p><b>Gợi ý / hướng dẫn:</b> ${esc(b.tip)}</p>
          <p><b>Rủi ro &amp; cách xử lý:</b> ${esc(b.risk)}</p>
        </div>
      </div></div>`;
  });
}

function troopTable() {
  return `<table><thead><tr><th>Lính</th><th>Độ hiếm</th><th>Vai trò</th><th>Máu</th><th>Sát thương</th><th>Kỹ năng</th></tr></thead><tbody>${
    data.troops.map(t => `<tr><td><b>${esc(t.name)}</b></td><td style="color:${RARITY_COLOR[t.rarity]};font-weight:700">${RARITY[t.rarity]}</td><td>${ROLE[t.role]}</td><td>${t.hp}</td><td>${t.damage || '—'}</td><td>${esc(t.ability || '—')}</td></tr>`).join('')
  }</tbody></table>`;
}
function castleTable() {
  return `<table class="small"><thead><tr><th>Cấp thành</th>${data.castle.map((c, i) => `<th>${i + 1}</th>`).join('')}</tr></thead><tbody>
    <tr><td>Ô lưới gear</td>${data.castle.map(c => `<td>${c.cells}</td>`).join('')}</tr>
    <tr><td>Ô đội hình</td>${data.castle.map(c => `<td>${c.team}</td>`).join('')}</tr>
    <tr><td>Máu thành x</td>${data.castle.map(c => `<td>${c.hp}</td>`).join('')}</tr>
    <tr><td>Giá nâng (vàng)</td>${data.castle.map(c => `<td>${fmt(c.cost)}</td>`).join('')}</tr></tbody></table>`;
}
function oddsTable() {
  const shop = data.battle_shop;
  return `<table class="small"><thead><tr><th>Từ đợt</th>${RARITY.map((n, i) => `<th style="color:${RARITY_COLOR[i]}">${n}</th>`).join('')}</tr></thead><tbody>${
    shop.odds.map(o => `<tr><td>${o.from}</td>${o.weights.map(w => `<td>${w}%</td>`).join('')}</tr>`).join('')}
    <tr><td>Giá (thịt)</td>${shop.prices.map(p => `<td>${p}</td>`).join('')}</tr></tbody></table>`;
}

// ---------------------------------------------------------------------------------------
const css = `
@font-face { font-family: Paytone; src: url('../../game/ui/fonts/PaytoneOne-Regular.ttf'); }
@page { size: A4; margin: 14mm 13mm 16mm 13mm; }
* { box-sizing: border-box; }
body { font-family: 'Segoe UI', Arial, sans-serif; color: #1f2a33; font-size: 10.6pt; line-height: 1.45; margin: 0; }
h1, h2, h3, .title { font-family: Paytone, 'Segoe UI', sans-serif; font-weight: 400; }
h2 { font-size: 20pt; color: #0d47a1; margin: 0 0 8px; display: flex; align-items: center; gap: 10px; }
h2 .num { display: inline-grid; place-items: center; width: 34px; height: 34px; border-radius: 50%; background: #e53935; color: #fff; font-size: 17pt; }
h3 { font-size: 13pt; color: #263238; margin: 14px 0 6px; }
.page { page-break-after: always; }
.page:last-child { page-break-after: auto; }
p { margin: 5px 0; }
table { width: 100%; border-collapse: collapse; margin: 6px 0 10px; font-size: 9.2pt; }
th { background: #0d47a1; color: #fff; padding: 5px 6px; text-align: left; font-weight: 600; }
td { border-bottom: 1px solid #e0e6eb; padding: 4px 6px; vertical-align: top; }
tr:nth-child(even) td { background: #f6f9fb; }
table.small { font-size: 8.8pt; }
table.small td, table.small th { text-align: center; } table.small td:first-child { text-align: left; font-weight: 600; }
.t50 { font-size: 7.6pt; } .t50 td, .t50 th { padding: 2.5px 4px; }
.t50 tr.b-boss td { background: #fff3e0; font-weight: 600; } .t50 tr.b-mini td { background: #fffde7; }
.planned { font-style: italic; color: #607d8b; }
.dots { color: #e53935; letter-spacing: 1px; white-space: nowrap; } .dots .off { color: #d7dde2; }
.grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.grid3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }
.shot { width: 100%; border-radius: 10px; border: 2px solid #263238; }
/* Phone screenshots: shrink to fit, never crop. */
.short .shot { height: 330px; width: auto; max-width: 100%; display: block; margin: 0 auto; object-fit: contain; }
.grid2 .shot { max-height: 470px; width: auto; max-width: 100%; display: block; margin: 0 auto; }
/* On screen, show the report as A4 sheets like the PDF. */
@media screen {
  html { background: #dfe6ec; }
  body { width: 210mm; margin: 16px auto; }
  section.page { background: #fff; padding: 14mm 13mm 16mm; margin-bottom: 16px; min-height: 297mm; box-shadow: 0 2px 12px rgba(0,0,0,.18); }
}
figure { margin: 0; } figcaption { font-size: 8.6pt; color: #546e7a; text-align: center; margin-top: 3px; }
.card { border: 1px solid #cfd8dc; border-radius: 12px; padding: 10px 12px; background: #fafcfd; }
.card h4 { margin: 0 0 4px; font-size: 11pt; color: #0d47a1; }
.tag { display: inline-block; background: #e3f2fd; color: #0d47a1; border-radius: 10px; padding: 1px 8px; margin: 2px 3px 2px 0; font-size: 9pt; font-weight: 600; }
.note { background: #fff8e1; border-left: 5px solid #ffb300; padding: 8px 12px; border-radius: 6px; margin: 8px 0; }
.warn { background: #ffebee; border-left: 5px solid #e53935; padding: 8px 12px; border-radius: 6px; margin: 8px 0; }
.cover { height: 265mm; border: 4px double #111; padding: 14mm 12mm 10mm; display: flex; flex-direction: column; align-items: center;
  text-align: center; font-family: 'Times New Roman', Times, serif; color: #111; }
.cover .school { font-weight: 700; font-size: 13pt; line-height: 1.35; }
.cover .logo { width: 150px; margin: 34px 0 44px; }
.cover .kind { font-weight: 700; font-size: 26pt; letter-spacing: .5px; }
.cover .topic { color: #e00000; font-weight: 700; font-size: 20pt; line-height: 1.3; margin: 18px 0 30px; }
.cover .info { font-size: 13pt; line-height: 1.75; text-align: left; border-collapse: collapse; width: auto; margin: 0; }
.cover .info td { border: 0; padding: 0 0 0 0; background: none !important; }
.cover .info td:first-child { font-weight: 700; padding-right: 60px; }
.cover .place { margin-top: auto; font-weight: 700; font-size: 13pt; }
.brief { border: 1px solid #cfd8dc; border-radius: 12px; overflow: hidden; margin-bottom: 10px; page-break-inside: avoid; }
.bhead { color: #fff; font-family: Paytone, sans-serif; font-size: 12pt; padding: 5px 12px; display: flex; justify-content: space-between; align-items: center; }
.bhead .dots { color: #fff; } .bhead .dots .off { color: rgba(255,255,255,.35); }
.bhead span { font-family: 'Segoe UI', sans-serif; font-size: 9pt; }
.bbody { display: grid; grid-template-columns: 190px 1fr; gap: 10px; padding: 8px 10px; font-size: 8.8pt; }
.bbody img { width: 190px; border-radius: 8px; border: 1px solid #90a4ae; }
.bbody p { margin: 2px 0; }
.kv span { display: inline-block; background: #eceff1; border-radius: 8px; padding: 0 6px; margin: 1px 3px 1px 0; }
.waves { margin: 3px 0 3px 16px; padding: 0; } .waves li { margin: 0; }
.toc li { margin: 4px 0; font-size: 11.5pt; }
.phase { border-radius: 12px; padding: 8px 10px; color: #fff; font-size: 9pt; }
.phase b { font-size: 11pt; display: block; }
`;

const shots = (items, cols = 3, cls = '') => `<div class="grid${cols} ${cls}">${items.map(([n, c]) => `<figure><img class="shot" src="${img(n)}"><figcaption>${esc(c)}</figcaption></figure>`).join('')}</div>`;
const heroRows = data.heroes.map(h => `<tr><td><b>${esc(h.name)}</b></td><td style="color:${RARITY_COLOR[h.rarity]};font-weight:700">${RARITY[h.rarity]}</td><td>${esc(troopName[h.troop])}</td><td>${esc(h.buff)}</td></tr>`).join('');
const totalReal = levels.slice(0, 10).reduce((a, r) => a + r.enemies, 0);

// The report pages live in html_block.js (rubric order); metrics come from bot playtests.
const P = require('./report_pages.js');
const metrics = P.loadMetrics(DIR);
const before = fs.existsSync(path.join(DIR, 'metrics_before.csv'))
  ? (() => { const tmp = path.join(DIR, '_build', 'before'); fs.mkdirSync(tmp, { recursive: true }); fs.copyFileSync(path.join(DIR, 'metrics_before.csv'), path.join(tmp, 'metrics.csv')); return P.loadMetrics(tmp); })()
  : {};
const html = require('./html_block.js')({ data, levels, css, img, esc, fmt, dec, PHASES, coreLoop, levelCurve, levelTable50, brief10Table, shots, troopName, P, metrics, before });
fs.writeFileSync(path.join(DIR, 'bao_cao.html'), html);

// ---------------------------------------------------------------------------------------
// One-page overview slide (1920x1080), same six panels as the assignment's example.
const miniCurve = levelCurve(760, 300);
const slide = `<!doctype html><html lang="vi"><head><meta charset="utf-8"><title>Tổng quan Gear Defenders</title><style>
@font-face { font-family: Paytone; src: url('../../game/ui/fonts/PaytoneOne-Regular.ttf'); }
@page { size: 1920px 1080px; margin: 0; }
body { margin: 0; width: 1920px; height: 1080px; font-family: 'Segoe UI', Arial; color: #1f2a33; background: #fff; }
.wrap { padding: 26px 34px; height: 100%; box-sizing: border-box; display: flex; flex-direction: column; }
.head { font-family: Paytone; font-size: 54px; color: #0d47a1; text-align: center; margin-bottom: 14px; }
.head small { display: block; font-family: 'Segoe UI'; font-size: 20px; color: #546e7a; }
.row { display: grid; gap: 16px; flex: 1; min-height: 0; }
.r1 { grid-template-columns: 1.05fr 1fr 1fr; margin-bottom: 16px; }
.r2 { grid-template-columns: 1.25fr 1.35fr 0.8fr; }
.p { border-radius: 16px; padding: 12px 16px; overflow: hidden; }
.p h3 { font-family: Paytone; font-weight: 400; font-size: 25px; margin: 0 0 8px; display: flex; gap: 10px; align-items: center; }
.n { display: inline-grid; place-items: center; width: 40px; height: 40px; border-radius: 50%; color: #fff; font-size: 22px; }
.b1 { background: #fdecec; } .b1 .n { background: #e53935; } .b1 h3 { color: #b71c1c; }
.b2 { background: #e8f5e9; } .b2 .n { background: #43a047; } .b2 h3 { color: #1b5e20; }
.b3 { background: #fff3e0; } .b3 .n { background: #fb8c00; } .b3 h3 { color: #e65100; }
.b4 { background: #e3f2fd; } .b4 .n { background: #1e88e5; } .b4 h3 { color: #0d47a1; }
.b5 { background: #ede7f6; } .b5 .n { background: #7e57c2; } .b5 h3 { color: #4527a0; }
.b6 { background: #e0f7fa; } .b6 .n { background: #00acc1; } .b6 h3 { color: #006064; }
.flex { display: flex; gap: 16px; } .shot { height: 360px; border-radius: 12px; border: 3px solid #263238; }
ul { margin: 0; padding-left: 22px; font-size: 21px; line-height: 1.5; } li b { color: #263238; }
table { border-collapse: collapse; width: 100%; font-size: 16px; } th { background: #5e35b1; color: #fff; padding: 3px 5px; } td { padding: 2px 5px; border-bottom: 1px solid #d1c4e9; }
.dots { color: #e53935; } .dots .off { color: #d7dde2; }
</style></head><body><div class="wrap">
<div class="head">BÀI TẬP GIỮA KÌ · GEAR DEFENDERS<small>Thiết kế màn chơi &amp; cơ chế · Tower defense + merge bánh răng · Mobile dọc</small></div>
<div class="row r1">
  <div class="p b1"><h3><span class="n">1</span>GIỚI THIỆU GAME</h3><div class="flex"><img class="shot" src="img/battle_fight.png"><ul>
    <li><b>Thể loại:</b> Tower defense + merge</li><li><b>Đối tượng:</b> casual–midcore 13–35</li><li><b>USP:</b> gear chỉ sinh lính khi đang quay — vị trí trên lưới là chiến thuật</li><li><b>Nền tảng:</b> Android / iOS</li><li><b>Engine:</b> Godot 4 · Tiny Swords</li></ul></div></div>
  <div class="p b2"><h3><span class="n">2</span>GAMEPLAY CƠ BẢN</h3><div class="flex"><img class="shot" src="img/battle_shop.png"><ul>
    <li><b>Mua:</b> shop 5 món giữa đợt</li><li><b>Xếp:</b> nối xích tới trục cam</li><li><b>Ghép:</b> 2 gear giống → lên bậc</li><li><b>Chiến đấu:</b> lính tự đánh</li><li><b>Thắng:</b> giữ thành qua mọi đợt; sao theo % máu</li></ul></div></div>
  <div class="p b3"><h3><span class="n">3</span>ĐỐI TƯỢNG &amp; THỊ TRƯỜNG</h3><ul style="font-size:22px;line-height:1.7">
    <li><b>Casual players:</b> học sinh, sinh viên, dân văn phòng</li><li><b>Mobile first:</b> dọc, một tay, 2–4 phút/màn</li><li><b>Thích xếp cho khéo:</b> merge + giải đố không gian</li><li><b>Thích sưu tầm:</b> 13 lính, 6 tướng, rương, gacha</li>
    <li style="margin-top:6px"><b>Key value:</b> dễ học – khó giỏi · cảm giác cơ khí thỏa mãn · nhiều cơ chế mới · thưởng thường xuyên</li></ul></div>
</div>
<div class="row r2">
  <div class="p b4"><h3><span class="n">4</span>LỘ TRÌNH 50 LEVEL</h3>${miniCurve}
    <div style="display:flex;gap:6px;font-size:13px">${PHASES.map(p => `<div style="flex:1;background:${p.color};color:#fff;border-radius:8px;padding:4px 6px"><b>GĐ${p.n} (${p.from}–${p.to})</b><br>${esc(p.name)}</div>`).join('')}</div></div>
  <div class="p b5"><h3><span class="n">5</span>CHI TIẾT 10 LEVEL ĐẦU</h3><table><tr><th>Lv</th><th>Mục tiêu &amp; cơ chế</th><th>Ô</th><th>Đợt</th><th>Quân</th><th>Khó</th><th>Thưởng</th></tr>
    ${levels.slice(0, 10).map(r => `<tr><td>${r.l}</td><td>${esc(r.focus)}</td><td>${r.cells}</td><td>${r.waves}</td><td>${r.enemies}</td><td>${stars(r.felt)}</td><td>${fmt(r.gold)}${r.gift ? ' · ' + esc(r.gift.replace('Mở khoá ', '')) : ''}</td></tr>`).join('')}</table></div>
  <div class="p b6"><h3><span class="n">6</span>SẢN PHẨM NỘP BÀI</h3><ul>
    <li><b>Báo cáo PDF</b> (${process.env.PAGES || '17'} trang)</li><li><b>Hình ảnh, sơ đồ</b> vòng lặp, ảnh game</li><li><b>Bảng 50 level</b> + level curve</li><li><b>Level brief</b> 10 level đầu</li><li><b>Bản demo</b> ${data.levels.length} level chơi được</li></ul></div>
</div></div></body></html>`;
fs.writeFileSync(path.join(DIR, 'tong_quan_1_trang.html'), slide);

// ---------------------------------------------------------------------------------------
// CSV for Excel (UTF-8 with BOM so Vietnamese shows correctly).
const csvRows = [['Level', 'Giai đoạn', 'Tên màn', 'Trạng thái', 'Số đợt', 'Số quân', 'Tinh nhuệ', 'Sức mạnh địch', 'Máu thành', 'Thịt đầu', 'Ô gear', 'Cơ chế / trọng tâm', 'Độ khó (1-5)', 'Chỉ số sức ép', 'Thưởng vàng 3 sao', 'Thưởng thêm']];
for (const r of levels) csvRows.push([r.l, `GĐ${r.phase.n} ${r.phase.name}`, r.name, r.real ? 'Có trong demo' : 'Dự kiến', r.waves, r.enemies, r.elites, r.power, r.core, r.meat, r.cells, r.focus, r.felt, r.pressure.toFixed(2), r.gold, r.gift]);
const csv = '﻿' + csvRows.map(row => row.map(v => /[",\n;]/.test(String(v)) ? `"${String(v).replace(/"/g, '""')}"` : v).join(',')).join('\r\n');
// A staging copy that no spreadsheet has open; print.sh turns it into the .xlsx.
fs.mkdirSync(path.join(DIR, '_build'), { recursive: true });
fs.writeFileSync(path.join(DIR, '_build', 'bang_tien_trinh_50_level.csv'), csv);
try {
  fs.writeFileSync(path.join(DIR, 'bang_tien_trinh_50_level.csv'), csv);
} catch (e) {
  console.log('CSV is open in another program, not rewritten:', e.code);
}
console.log('built: bao_cao.html, tong_quan_1_trang.html, bang_tien_trinh_50_level.csv');
