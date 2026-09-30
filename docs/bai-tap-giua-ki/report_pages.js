// Page builders for the rubric-shaped report: gear-grid maps, one-page level design
// documents (course template), the mechanic library and bot playtest metrics.
const fs = require('fs');
const path = require('path');
const { BRIEFS, MECHANICS } = require('./content.js');

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;');
const fmt = n => Math.round(n).toLocaleString('vi-VN');
const dec = (n, d = 1) => Number(n).toFixed(d).replace('.', ',');

// The board: 6x4 cells, the drive at (2,1). Cells open outward from the drive as the
// castle levels up (same order as GearBoard.open_order()).
const COLS = 6, ROWS = 4, MASTER = [2, 1];
function openOrder() {
  const cells = [];
  for (let y = 0; y < ROWS; y++) for (let x = 0; x < COLS; x++) if (!(x === MASTER[0] && y === MASTER[1])) cells.push([x, y]);
  const d = c => Math.abs(c[0] - MASTER[0]) + Math.abs(c[1] - MASTER[1]);
  return cells.sort((a, b) => d(a) - d(b) || a[1] - b[1] || a[0] - b[0]);
}
const UNIT = { W: ['Chiến binh', '#3f7fd9'], A: ['Cung thủ', '#2e9e5b'], P: ['Nông dân', '#8a6d3b'], L: ['Kỵ thương', '#d9534f'],
  M: ['Tu sĩ', '#9b5de5'], G: ['Hiệp sĩ khiên', '#607d8b'], F: ['Cung lửa', '#ef6c00'], N: ['Thợ mỏ', '#795548'] };
const TILE = { rock: ['#6d6a66', 'Đá'], gold: ['#f2c14e', 'Vàng'], rust: ['#b5652b', 'Rỉ sét'], ice: ['#bfe9ff', 'Băng'] };

function gridMap(cellsOpen, layout = [], tiles = {}) {
  const s = 46, pad = 10, top = 30;
  const w = COLS * s + pad * 2, h = ROWS * s + top + pad;
  const open = new Set(openOrder().slice(0, cellsOpen).map(c => c.join(',')));
  let g = `<svg viewBox="0 0 ${w} ${h}" width="100%" xmlns="http://www.w3.org/2000/svg" font-family="Segoe UI, Arial">`;
  // The wall the enemies march at, above the grid.
  g += `<rect x="${pad}" y="4" width="${COLS * s}" height="14" rx="4" fill="#b0bec5"/>`;
  g += `<text x="${w / 2}" y="15" text-anchor="middle" font-size="9" font-weight="700" fill="#263238">TƯỜNG THÀNH · địch tràn xuống từ phía trên</text>`;
  for (let y = 0; y < ROWS; y++) for (let x = 0; x < COLS; x++) {
    const px = pad + x * s, py = top + y * s, key = `${x},${y}`;
    const isMaster = x === MASTER[0] && y === MASTER[1];
    const tile = Object.entries(tiles).find(([, cells]) => cells.some(c => c[0] === x && c[1] === y));
    let fill = open.has(key) || isMaster ? '#e8f0e0' : '#37474f';
    if (tile && open.has(key)) fill = TILE[tile[0]][0];
    g += `<rect x="${px + 2}" y="${py + 2}" width="${s - 4}" height="${s - 4}" rx="6" fill="${fill}" stroke="#90a4ae"/>`;
    if (isMaster) {
      g += `<circle cx="${px + s / 2}" cy="${py + s / 2}" r="14" fill="#f08a24" stroke="#5b3a1e" stroke-width="2"/><rect x="${px + s / 2}" y="${py + s / 2 - 3}" width="16" height="6" rx="2" fill="#f08a24" stroke="#5b3a1e"/>`;
    } else if (!open.has(key)) {
      g += `<rect x="${px + s / 2 - 6}" y="${py + s / 2 - 2}" width="12" height="9" rx="2" fill="#cfd8dc"/><path d="M${px + s / 2 - 4} ${py + s / 2 - 2} v-3 a4 4 0 0 1 8 0 v3" fill="none" stroke="#cfd8dc" stroke-width="2"/>`;
    }
  }
  for (const [u, x, y] of layout) {
    const px = pad + x * s + s / 2, py = top + y * s + s / 2;
    g += `<circle cx="${px}" cy="${py}" r="15" fill="${UNIT[u][1]}" stroke="#263238" stroke-width="2"/><text x="${px}" y="${py + 4}" text-anchor="middle" font-size="12" font-weight="800" fill="#fff">${u}</text>`;
  }
  return g + '</svg>';
}

function legend(layout) {
  const used = [...new Set(layout.map(l => l[0]))];
  return `<div class="legend"><span><i style="background:#f08a24"></i>Trục cam</span><span><i style="background:#e8f0e0;border:1px solid #90a4ae"></i>Ô mở</span><span><i style="background:#37474f"></i>Ô khoá</span>${used.map(u => `<span><i style="background:${UNIT[u][1]}"></i>${u} = ${UNIT[u][0]}</span>`).join('')}</div>`;
}

// Bot playtest metrics per level from metrics.csv.
function loadMetrics(dir) {
  const file = path.join(dir, 'metrics.csv');
  const out = {};
  if (!fs.existsSync(file)) return out;
  const lines = fs.readFileSync(file, 'utf8').trim().split(/\r?\n/).slice(1);
  for (const line of lines) {
    const [level, , phase, left, max, secs] = line.split(',');
    if (!level || !phase) continue;
    const m = out[level] || (out[level] = { runs: 0, wins: 0, time: 0, hp: 0 });
    m.runs++;
    m.time += Number(secs);
    if (phase === 'won') { m.wins++; m.hp += Number(left) / Number(max); }
  }
  for (const m of Object.values(out)) {
    m.rate = m.wins / m.runs;
    m.avgTime = m.time / m.runs;
    m.avgHp = m.wins ? m.hp / m.wins : 0;
  }
  return out;
}
// Target win-rate band by designed difficulty (course, lecture 3: easy 70-90%, medium 40-60%).
const TARGET = { 1: [0.9, 1.0], 2: [0.75, 0.95], 3: [0.6, 0.8], 4: [0.45, 0.65], 5: [0.3, 0.5] };
const TAG = f => (f <= 2 ? 'Normal' : f <= 4 ? 'Hard' : 'Super Hard');
function verdict(m, felt) {
  if (!m) return '—';
  const [lo, hi] = TARGET[felt];
  if (m.rate > hi) return '<span class="ok-hi">Dễ hơn mục tiêu</span>';
  if (m.rate < lo) return '<span class="bad">Khó hơn mục tiêu</span>';
  return '<span class="ok">Trong mục tiêu</span>';
}
const pct = x => Math.round(x * 100) + '%';
const mmss = s => `${Math.floor(s / 60)}:${String(Math.round(s % 60)).padStart(2, '0')}`;

function metricsTable(levels, metrics) {
  return `<table class="small metrics"><thead><tr><th>Lv</th><th>Tên</th><th>Tag</th><th>Win rate mục tiêu</th><th>Win rate (bot)</th><th>Máu thành còn</th><th>Thời gian TB</th><th>Đánh giá</th></tr></thead><tbody>${
    levels.slice(0, 10).map(r => {
      const m = metrics[r.l];
      const [lo, hi] = TARGET[r.felt];
      return `<tr><td>${r.l}</td><td style="text-align:left">${esc(r.name)}</td><td>${TAG(r.felt)}</td><td>${pct(lo)}–${pct(hi)}</td><td>${m ? `${pct(m.rate)} (${m.wins}/${m.runs})` : '—'}</td><td>${m && m.wins ? pct(m.avgHp) : '—'}</td><td>${m ? mmss(m.avgTime) : '—'}</td><td>${verdict(m, r.felt)}</td></tr>`;
    }).join('')}</tbody></table>`;
}

function mechanicTable() {
  return `<table class="mech"><thead><tr><th>Cơ chế</th><th>Mở ở</th><th>Luật</th><th>Ràng buộc thiết kế</th><th>Sai lầm người chơi</th><th>Sai lầm designer cần tránh</th></tr></thead><tbody>${
    MECHANICS.map(r => `<tr><td><b>${esc(r[0])}</b></td>${r.slice(1).map(c => `<td>${esc(c)}</td>`).join('')}</tr>`).join('')}</tbody></table>`;
}

// One page per level, in the course's One-page Level Design Document layout.
function lddPage(r, d, metrics, img, troopName) {
  const b = BRIEFS[r.l];
  const m = metrics[r.l];
  const [lo, hi] = TARGET[r.felt];
  const waves = d.waves.map((w, i) => `<li><b>Đợt ${i + 1}</b> (${w.count}): ${w.groups.map(g => `${g.count} ${troopName[g.troop]}${g.elite ? ' <em>tinh nhuệ</em>' : ''}`).join(', ')}</li>`).join('');
  const core = [
    ['Player / Mechanic', b.mechanic], ['Dominant Feature', b.dominant], ['Goal', b.goal], ['Challenge', b.challenge],
    ['Space', b.space], ['Support', b.support], ['Outcome', b.outcome],
    ['Reward', `${fmt(r.gold)} vàng (x2 lần đầu)${r.gift ? ' · ' + r.gift : ''} · rương chiến thắng`],
  ];
  return `<section class="page ldd">
  <div class="lhead" style="background:${r.phase.color}"><span>LEVEL ${r.l} · ${esc(r.name.toUpperCase())}${r.boss === 'boss' ? ' 👑' : ''}</span><span class="tagbox">${TAG(r.felt)} · độ khó ${r.felt}/5</span></div>
  <div class="facts"><span>Loại: Tower defense + merge</span><span>${r.waves} đợt · ${r.enemies} quân · ${r.elites} tinh nhuệ</span><span>Sức mạnh địch ${dec(r.power)}</span><span>Máu thành ${d.core_hp} · thịt đầu ${d.start_meat}</span><span>Lưới ${r.cells} ô (thành cấp ${r.castle})</span><span>Thời gian dự kiến ${m ? mmss(m.avgTime) : '2–4 phút'}</span></div>
  <div class="lrow">
    <div>
      <div class="statement">“${esc(b.statement)}”</div>
      <h4>Purpose &amp; context</h4><ul>${b.purpose.map(p => `<li>${esc(p)}</li>`).join('')}</ul>
    </div>
    <img class="art" src="${img('level_' + String(r.l).padStart(2, '0'))}">
  </div>
  <div class="lrow">
    <table class="core">${core.map(([k, v]) => `<tr><th>${k}</th><td>${esc(v)}</td></tr>`).join('')}</table>
    <div class="mapbox"><h4>Level map (lưới gear, bố trí gợi ý)</h4>${gridMap(r.cells, b.layout)}${legend(b.layout)}</div>
  </div>
  <h4>Flow</h4>
  <div class="flow">${b.flow.map((f, i) => `<div><b>${i + 1}</b>${esc(f)}</div>`).join('<span class="arrow">➜</span>')}</div>
  <div class="lrow">
    <div><h4>Challenges &amp; encounters (các đợt)</h4><ul class="waves">${waves}</ul></div>
    <div>
      <h4>Chỉ số &amp; khoảnh khắc chính</h4>
      <table class="kv2">
        <tr><th>Win rate mục tiêu</th><td>${pct(lo)}–${pct(hi)} (${TAG(r.felt)})</td></tr>
        <tr><th>Win rate bot</th><td>${m ? `${pct(m.rate)} (${m.wins}/${m.runs} lượt)` : 'chưa đo'}</td></tr>
        <tr><th>Máu thành còn (khi thắng)</th><td>${m && m.wins ? pct(m.avgHp) : '—'}</td></tr>
        <tr><th>Điểm tắc</th><td>${esc(b.chokepoint)}</td></tr>
        <tr><th>Khoảnh khắc Aha</th><td>${esc(b.aha)}</td></tr>
      </table>
    </div>
  </div>
  <div class="lrow">
    <div><h4>Walkthrough (lời giải gợi ý)</h4><ol>${b.walkthrough.map(w => `<li>${esc(w)}</li>`).join('')}</ol></div>
    <div><h4>Notes / TBD</h4><ul>${b.notes.map(n => `<li>${esc(n)}</li>`).join('')}</ul></div>
  </div>
</section>`;
}

const CSS = `
.ldd { font-size: 8.7pt; }
.ldd h4 { margin: 6px 0 3px; font-size: 10pt; color: #0d47a1; }
.ldd ul, .ldd ol { margin: 0 0 0 16px; padding: 0; } .ldd li { margin: 1px 0; }
.lhead { color: #fff; font-family: Paytone, sans-serif; font-size: 15pt; padding: 6px 12px; border-radius: 10px; display: flex; justify-content: space-between; align-items: center; }
.lhead .tagbox { font-family: 'Segoe UI', sans-serif; font-size: 9.5pt; font-weight: 700; background: rgba(255,255,255,.2); border-radius: 8px; padding: 2px 8px; }
.facts { display: flex; flex-wrap: wrap; gap: 4px; margin: 6px 0; }
.facts span { background: #eceff1; border-radius: 8px; padding: 1px 7px; font-size: 8.2pt; }
.lrow { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; align-items: start; }
.statement { font-style: italic; font-size: 10.5pt; background: #fff8e1; border-left: 4px solid #ffb300; padding: 6px 10px; border-radius: 6px; }
.ldd .art { width: 100%; height: 170px; object-fit: cover; border-radius: 8px; border: 1px solid #90a4ae; }
table.core, table.kv2 { font-size: 8.3pt; margin: 0; }
table.core th, table.kv2 th { background: #e3f2fd; color: #0d47a1; width: 34%; text-align: left; font-weight: 700; }
.mapbox svg { max-height: 190px; }
.legend { display: flex; flex-wrap: wrap; gap: 3px 10px; font-size: 7.6pt; color: #455a64; }
.legend i { display: inline-block; width: 10px; height: 10px; border-radius: 3px; margin-right: 3px; vertical-align: -1px; }
.flow { display: flex; align-items: center; gap: 4px; }
.flow div { flex: 1; background: #f1f8e9; border: 1px solid #c5e1a5; border-radius: 8px; padding: 3px 6px; font-size: 8pt; text-align: center; }
.flow div b { display: block; color: #33691e; }
.flow .arrow { color: #90a4ae; }
.ldd .waves { font-size: 8pt; }
.tight table { font-size: 8pt; } .tight td, .tight th { padding: 2px 5px; }
table.mech { font-size: 7.9pt; } table.mech td { padding: 3px 5px; }
table.metrics td { text-align: center; }
.ok { color: #2e7d32; font-weight: 700; } .ok-hi { color: #f57c00; font-weight: 700; } .bad { color: #c62828; font-weight: 700; }
.compact h3 { margin: 8px 0 4px; } .compact p { margin: 3px 0; } .compact table { margin: 4px 0 6px; }
`;

module.exports = { gridMap, legend, loadMetrics, metricsTable, mechanicTable, lddPage, CSS, TARGET, TAG, pct, mmss };
