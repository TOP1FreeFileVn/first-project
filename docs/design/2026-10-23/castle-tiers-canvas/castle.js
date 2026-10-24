// Cardboard cat castle, 5 upgrade tiers. Local frame 440 x 380, ground y = 330.
// Castle.draw(tier, size) returns Pen ops for a size-wide image.
//
// Construction rules (from review of round 3):
// - The cat ears are the keep's side walls cut taller, not pieces stuck on top.
// - Every flag pole stands behind a merlon (or through a roof tip): its base is hidden.
// - Roofs sit inside a tower's battlements, behind the front merlons.
// - Tape runs straight along seams and edges, as on a real box.
// - Everything stays cardboard and cat things; no paint, no soldiers.
(function () {
  const INK = '#583f21', CARD = '#e8bb7c', SHADE = '#d4a065', DEEP = '#b07c45', TAPE = '#f3dfae',
    HOLE = '#6b4a2b', FLAG = '#6aa9a8', FLAGS = '#4f8b8a', CREAM = '#fbf1dc', GOLD = '#f0c457',
    GOLDS = '#cf9a35', GLOW = '#ffd77a', SISAL = '#d9c39a', SISALS = '#b89d6d', FELT = '#6aa9a8',
    FELTS = '#4f8b8a', PINK = '#f2b6a8', YARN = '#e07a6b';
  const W = 6, S = 3;   // main / secondary stroke widths (local units, 440 wide)
  const C = Pen.circle, R = Pen.rrect;

  // Merlon row from x0 to x1: tops at y, crenel floors at y + 12, odd count of segments.
  function battlements(x0, x1, y, n) {
    const out = [], step = (x1 - x0) / n;
    for (let i = 0; i < n; i++) {
      const a = x0 + i * step, b = a + step, top = i % 2 === 0 ? y : y + 12;
      out.push(['L', a, top], ['L', b, top]);
    }
    return out;
  }

  // Side tower: front-facing box with a battlemented top.
  function towerShape(x, top, w) {
    return [['M', x, 330], ['L', x, top], ...battlements(x, x + w, top, 5), ['L', x + w, 330], ['Z']];
  }

  // Flag pole + finial; the cloth is drawn separately so the game can wave it.
  // Anchors (where each cloth hangs) are recorded for the game.
  let ANCHORS = [], CLOTH = true;
  function flag(P, x, base, top, big) {
    P.shape([['M', x, base], ['L', x, top]], { stroke: INK, width: W - 1 });
    P.shape(C(x, top - 4, 4.5), { fill: GOLD, stroke: INK, width: S });
    ANCHORS.push({ x: x + 2, y: top + 2, big });
    if (CLOTH) cloth(P, x + 2, top + 2, big);
  }
  // Cloth with its hoist (pole side) top corner at (x, y).
  function cloth(P, x, y, big) {
    const fw = big ? 60 : 36, fh = big ? 34 : 22;
    const d = [['M', x, y], ['Q', x + fw * 0.5, y - 7, x + fw, y + 3], ['L', x + fw - 9, y + fh / 2 + 1],
      ['L', x + fw, y + fh], ['Q', x + fw * 0.5, y + fh - 8, x, y + fh], ['Z']];
    P.shape(d, { fill: FLAG });
    P.shape([['M', x, y + fh * 0.62], ['Q', x + fw * 0.5, y + fh * 0.5, x + fw - 4, y + fh * 0.75], ['L', x + fw, y + fh],
      ['Q', x + fw * 0.5, y + fh - 8, x, y + fh], ['Z']], { fill: FLAGS });
    if (big) {
      const fx = x + 12, fy = y + fh / 2 - 1;
      P.shape([['M', fx, fy], ['Q', fx + 12, fy - 9, fx + 24, fy], ['Q', fx + 12, fy + 9, fx, fy], ['Z'],
        ['M', fx + 24, fy], ['L', fx + 31, fy - 6], ['L', fx + 31, fy + 6], ['Z']], { fill: CREAM, stroke: INK, width: 2.2 });
    }
    P.shape(d, { stroke: INK, width: S + 0.5 });
  }

  // Straight tape strip with torn (zigzag) ends; dir 'h' or 'v'.
  function tape(P, x, y, len, th, dir) {
    const d = dir === 'h'
      ? [['M', x, y], ['L', x + len, y], ['L', x + len - 3, y + th / 3], ['L', x + len, y + th * 2 / 3], ['L', x + len - 2, y + th],
        ['L', x, y + th], ['L', x + 3, y + th * 2 / 3], ['L', x, y + th / 3], ['Z']]
      : [['M', x, y], ['L', x + th / 3, y + 3], ['L', x + th * 2 / 3, y], ['L', x + th, y + 2], ['L', x + th, y + len],
        ['L', x + th * 2 / 3, y + len - 3], ['L', x + th / 3, y + len], ['L', x, y + len - 2], ['Z']];
    P.shape(d, { fill: TAPE, stroke: DEEP, width: 1.8 });
  }

  // Cone roof sitting inside a tower's battlements (drawn before the tower).
  function cone(P, cx, base, w, h, fill, shade, stitch) {
    const d = [['M', cx - w / 2, base], ['Q', cx - w * 0.18, base - h * 0.55, cx, base - h], ['Q', cx + w * 0.18, base - h * 0.55, cx + w / 2, base], ['Z']];
    P.shape(d, { fill });
    P.shape([['M', cx, base - h], ['Q', cx + w * 0.18, base - h * 0.55, cx + w / 2, base], ['L', cx + w * 0.16, base], ['Z']], { fill: shade });
    if (stitch) P.shape([['M', cx - w * 0.3, base - 10], ['Q', cx, base - 2, cx + w * 0.3, base - 10]], { stroke: CREAM, width: 2.2 });
    P.shape(d, { stroke: INK, width: W });
  }

  const pawPrint = (P, x, y, k, col) => {
    P.shape(C(x, y + 4 * k, 7 * k), { fill: col });
    for (const [dx, dy] of [[-8, -6], [-3, -10], [3, -10], [8, -6]]) P.shape(C(x + dx * k, y + dy * k, 2.8 * k), { fill: col });
  };

  function castle(P, t) {
    const gx = 220, ground = 330;
    const tall = t >= 4 ? 28 : 0;           // tier 4+: a second box stacked on the keep
    const ky = 112 - tall;                  // keep merlon tops
    const kx0 = 132, kx1 = 308;
    const towerTop = t >= 3 ? 168 : 190;    // tier 3+: taller side towers
    const towers = [[38, 98], [304, 98]];

    // ---- Keep flag (behind the middle merlon)
    flag(P, gx, ky + 10, ky - 96, true);

    // ---- Keep: side walls continue up into the cat ears.
    const earTip = ky - 46, earIn = 54;     // inner base of each ear, from the wall
    const keep = [['M', kx0, ground], ['L', kx0, ky + 6], ['Q', kx0 - 2, earTip + 8, kx0 + 16, earTip],
      ['Q', kx0 + 40, earTip + 10, kx0 + earIn, ky],
      ...battlements(kx0 + earIn, kx1 - earIn, ky, 5),
      ['L', kx1 - earIn, ky], ['Q', kx1 - 40, earTip + 10, kx1 - 16, earTip], ['Q', kx1 + 2, earTip + 8, kx1, ky + 6],
      ['L', kx1, ground], ['Z']];
    P.shape(keep, { fill: CARD });
    // Cardboard edge shade: a thin even band on both side walls, starting below the ears'
    // roots, so the two ears match and nothing pokes up past the outline.
    for (const [a, b] of [[kx0, kx0 + 10], [kx1 - 10, kx1]])
      P.shape([['M', a, ky + 30], ['L', b, ky + 30], ['L', b, ground], ['L', a, ground], ['Z']], { fill: SHADE });
    for (const s of [-1, 1]) {   // inner ear
      const wx = s < 0 ? kx0 : kx1, k = -s;
      const inner = [['M', wx + k * 12, ky + 4], ['Q', wx + k * 12, earTip + 20, wx + k * 19, earTip + 14], ['Q', wx + k * 34, earTip + 18, wx + k * 38, ky + 4], ['Z']];
      P.shape(inner, { fill: t >= 5 ? GOLD : PINK });
    }
    P.shape([['M', kx0 + 6, ky + 26], ['L', kx1 - 6, ky + 26]], { stroke: DEEP, width: S });   // top flap fold
    if (tall) P.shape([['M', kx0 + 4, ky + tall + 40], ['L', kx1 - 4, ky + tall + 40]], { stroke: DEEP, width: S });
    P.shape(keep, { stroke: INK, width: W });

    // ---- Side towers (in front of the keep's lower corners)
    towers.forEach(([x, w], i) => {
      const s = i === 0 ? -1 : 1, cx = x + w / 2;
      const poleX = s < 0 ? x + w / 10 : x + w - w / 10;   // behind an outer merlon
      if (t < 3) flag(P, poleX, towerTop + 8, towerTop - 56, false);
      // A roofed tower has a plain wall top: the roof sits on it, not inside battlements.
      const shape = t >= 3 ? [['M', x, 330], ['L', x, towerTop + 6], ['L', x + w, towerTop + 6], ['L', x + w, 330], ['Z']] : towerShape(x, towerTop, w);
      P.shape(shape, { fill: CARD });
      const fold = towerTop + (t >= 3 ? 30 : 24);
      for (const [a, b] of [[x, x + 8], [x + w - 8, x + w]])
        P.shape([['M', a, fold], ['L', b, fold], ['L', b, ground], ['L', a, ground], ['Z']], { fill: SHADE });
      P.shape([['M', x + 5, towerTop + (t >= 3 ? 30 : 24)], ['L', x + w - 5, towerTop + (t >= 3 ? 30 : 24)]], { stroke: DEEP, width: S });
      if (t >= 4) sisal(P, x, w, towerTop + 120, ground - 2);
      // window + paw print
      const wy = towerTop + 38;
      P.shape([['M', cx - 12, wy + 34], ['L', cx - 12, wy + 12], ['Q', cx - 12, wy, cx, wy], ['Q', cx + 12, wy, cx + 12, wy + 12], ['L', cx + 12, wy + 34], ['Z']],
        { fill: t >= 3 ? GLOW : HOLE, stroke: INK, width: S + 1 });
      if (t >= 3) P.shape([['M', cx, wy + 2], ['L', cx, wy + 33], ['M', cx - 11, wy + 18], ['L', cx + 11, wy + 18]], { stroke: INK, width: 2.2 });
      if (t < 4) pawPrint(P, cx, wy + 66, 1.05, DEEP);
      P.shape(shape, { stroke: INK, width: W });
      if (t >= 3) {
        const roofH = t >= 4 ? 88 : 80, eave = towerTop + 14;
        flag(P, cx, eave - roofH + 8, eave - roofH - 54, false);   // pole rises out of the roof tip
        if (t >= 4) cone(P, cx, eave, w + 22, roofH, FELT, FELTS, false);
        else cone(P, cx, eave, w + 22, roofH, '#cf9b5c', DEEP, false);
        if (t >= 5) { P.shape(C(cx, eave - roofH - 2, 9), { fill: YARN, stroke: INK, width: S }); P.shape([['M', cx - 6, eave - roofH - 6], ['Q', cx, eave - roofH + 2, cx + 7, eave - roofH - 4]], { stroke: '#b85a4d', width: 2 }); }
      }
    });

    // ---- Tape (tier 2+): along seams and over edges, all straight.
    if (t >= 2) {
      tape(P, kx0 + 6, ky + 21, kx1 - kx0 - 12, 11, 'h');                 // keep top flap seam
      for (const [x, w] of towers) {
        if (t < 3) { tape(P, x + 10, towerTop + 14, 13, 26, 'v'); tape(P, x + w - 30, towerTop + 14, 13, 26, 'v'); }  // across the box seam
      }
    }
    if (t >= 4) tape(P, kx0 + 6, ky + tall + 35, kx1 - kx0 - 12, 11, 'h');  // seam of the stacked box

    // ---- Gate: cat-head arch with a fold-down ramp.
    const gw = 92, gy = 214;
    const gate = [['M', gx - gw / 2, ground], ['L', gx - gw / 2, gy + 24], ['L', gx - gw / 2 + 4, gy - 8], ['L', gx - 24, gy + 8],
      ['Q', gx, gy, gx + 24, gy + 8], ['L', gx + gw / 2 - 4, gy - 8], ['L', gx + gw / 2, gy + 24], ['L', gx + gw / 2, ground], ['Z']];
    P.shape(gate, { fill: HOLE, stroke: INK, width: W });
    if (t >= 5) banner(P, gx, ky + 30);
    P.shape([['M', gx - gw / 2, ground], ['L', gx + gw / 2, ground], ['L', gx + gw / 2 + 12, ground + 24], ['L', gx - gw / 2 - 12, ground + 24], ['Z']],
      { fill: CARD, stroke: INK, width: W });
  }

  // Sisal rope wrapped round the lower tower: a cat scratching post.
  function sisal(P, x, w, y0, y1) {
    P.shape(R(x + 2, y0, w - 4, y1 - y0, 3), { fill: SISAL });
    for (let y = y0 + 7; y < y1; y += 9) P.shape([['M', x + 4, y], ['Q', x + w / 2, y + 3, x + w - 4, y]], { stroke: SISALS, width: 2 });
    P.shape([['M', x + 2, y0], ['L', x + w - 2, y0]], { stroke: INK, width: S });
  }

  // A felt cushion on the ramp (tier 4+).
  function cushion(P, x, y) {
    const d = R(x - 34, y - 9, 68, 18, 9);
    P.shape(d, { fill: FELT, stroke: INK, width: S + 0.5 });
    P.shape([['M', x - 26, y], ['L', x + 26, y]], { stroke: CREAM, width: 2 });
  }

  // Gold paper crown sitting in the keep's battlements (tier 5).
  function crown(P, x, y) {
    const d = [['M', x - 30, y + 14], ['L', x - 32, y - 14], ['L', x - 16, y - 2], ['L', x, y - 22], ['L', x + 16, y - 2], ['L', x + 32, y - 14], ['L', x + 30, y + 14], ['Z']];
    P.shape(d, { fill: GOLD });
    P.shape([['M', x + 6, y - 14], ['L', x + 16, y - 2], ['L', x + 32, y - 14], ['L', x + 30, y + 14], ['L', x + 8, y + 14], ['Z']], { fill: GOLDS });
    P.shape(d, { stroke: INK, width: S + 1 });
    P.shape(C(x, y + 4, 4), { fill: FLAG, stroke: INK, width: 2 });
  }

  // Fish banner hanging from the keep's merlons (tier 5).
  function banner(P, x, y) {
    const d = [['M', x - 30, y], ['L', x + 30, y], ['L', x + 30, y + 70], ['L', x, y + 58], ['L', x - 30, y + 70], ['Z']];
    P.shape(d, { fill: FLAG, stroke: INK, width: S + 1 });
    P.shape([['M', x - 16, y + 30], ['Q', x - 2, y + 18, x + 12, y + 30], ['Q', x - 2, y + 42, x - 16, y + 30], ['Z'],
      ['M', x + 12, y + 30], ['L', x + 20, y + 23], ['L', x + 20, y + 37], ['Z']], { fill: CREAM, stroke: INK, width: 2.2 });
    P.shape([['M', x - 34, y], ['L', x + 34, y]], { stroke: INK, width: W - 1 });
  }

  // Paw-print bunting strung from each tower's inner merlon to the keep (tier 5).
  function bunting(P, towers, towerTop, kx0, kx1, ky) {
    const lines = [[towers[0][0] + towers[0][1] - 10, towerTop, kx0 + 8, ky + 48], [towers[1][0] + 10, towerTop, kx1 - 8, ky + 48]];
    for (const [ax, ay, bx, by] of lines) {
      const mx = (ax + bx) / 2, my = Math.max(ay, by) + 16;
      P.shape([['M', ax, ay], ['Q', mx, my, bx, by]], { stroke: INK, width: 2 });
      for (const k of [0.3, 0.6]) {
        const px = (1 - k) * (1 - k) * ax + 2 * (1 - k) * k * mx + k * k * bx, py = (1 - k) * (1 - k) * ay + 2 * (1 - k) * k * my + k * k * by;
        P.shape([['M', px - 7, py], ['L', px + 7, py], ['L', px, py + 13], ['Z']], { fill: k < 0.5 ? GOLD : FLAG, stroke: INK, width: 2 });
      }
    }
  }

  globalThis.Castle = {
    TIERS: ['Hộp carton', 'Thùng gia cố', 'Tháp mái giấy', 'Tháp cào móng', 'Cung điện mèo'],
    // opts.cloth = false leaves the poles bare and returns the cloth anchors (local units).
    draw(tier, size, opts = {}) {
      ANCHORS = []; CLOTH = opts.cloth !== false;
      const P = new Pen(); P.scale(size / 440); castle(P, tier);
      const k = size / 440;
      P.anchors = ANCHORS.map((a) => ({ x: +(a.x * k).toFixed(2), y: +(a.y * k).toFixed(2), big: a.big }));
      return P.ops.anchors = P.anchors, P.ops;
    },
    // A lone cloth, hoist corner at (pad, pad).
    cloth(big, size, pad) {
      const P = new Pen(); P.scale(size / 440); cloth(P, pad * 440 / size, pad * 440 / size, big); return P.ops;
    },
  };
})();
