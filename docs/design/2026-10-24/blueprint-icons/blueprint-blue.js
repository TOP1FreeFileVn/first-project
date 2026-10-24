// Blueprint (bản vẽ) icons, one per equipment slot. 256 x 256 frame.
// A blueprint sheet: blue paper with a rolled top edge, a faint grid, and the slot's item
// drawn as white construction lines with a few dimension ticks. Flat cat style: one even
// #583f21 outline around the sheet, no gradients or shine. The item lines are white
// strokes (the blueprint's ink), not filled, so the four read as plans, not as items.
(function () {
  const INK = '#583f21', PAPER = '#4f86c6', PAPER_DARK = '#3d6ea8', GRID = '#6c9bd2',
    LINE = '#f4f8ff', ROLL = '#d9e8f7', ROLL_SHADE = '#a9c3e2', PIN = '#e46a5a';
  const MAIN = 12, PLAN = 11, THIN = 3;
  const C = Pen.circle;

  function sheet(P) {
    // Sheet slightly tilted, a curl at the top-right corner, a pin top-left.
    const body = [['M', 46, 58], ['L', 206, 50], ['Q', 214, 50, 214, 58], ['L', 222, 206], ['Q', 222, 214, 214, 214],
      ['L', 50, 222], ['Q', 42, 222, 42, 214], ['L', 38, 66], ['Q', 38, 58, 46, 58], ['Z']];
    P.shape(body, { fill: PAPER });
    // Bottom shade band, then the grid (clipped by hand: only inside the paper rectangle).
    P.shape([['M', 42, 196], ['L', 221, 188], ['L', 222, 206], ['Q', 222, 214, 214, 214], ['L', 50, 222], ['Q', 42, 222, 42, 214], ['Z']], { fill: PAPER_DARK });
    for (let x = 70; x <= 190; x += 30) P.shape([['M', x, 62], ['L', x + 6, 208]], { stroke: GRID, width: THIN });
    for (let y = 90; y <= 180; y += 30) P.shape([['M', 44, y + 2], ['L', 216, y - 6]], { stroke: GRID, width: THIN });
    P.shape(body, { stroke: INK, width: MAIN });
    // Rolled top edge: a paper tube along the top.
    const roll = [['M', 34, 46], ['L', 212, 36], ['Q', 230, 36, 230, 54], ['Q', 230, 72, 212, 72], ['L', 36, 82], ['Q', 18, 82, 18, 64], ['Q', 18, 46, 34, 46], ['Z']];
    P.shape(roll, { fill: ROLL });
    P.shape([['M', 22, 72], ['L', 214, 62], ['Q', 226, 62, 229, 58], ['Q', 228, 72, 212, 72], ['L', 36, 82], ['Q', 22, 82, 20, 74], ['Z']], { fill: ROLL_SHADE });
    P.shape(roll, { stroke: INK, width: MAIN });
    P.shape(C(40, 64, 8), { fill: PIN, stroke: INK, width: 5 });
  }

  // A dimension mark: a short line with end ticks, in the plan ink.
  function dim(P, x1, y1, x2, y2) {
    P.shape([['M', x1, y1], ['L', x2, y2]], { stroke: LINE, width: THIN + 1 });
    const dx = y2 - y1, dy = x1 - x2, k = 6 / Math.hypot(dx, dy);
    for (const [x, y] of [[x1, y1], [x2, y2]]) P.shape([['M', x - dx * k, y - dy * k], ['L', x + dx * k, y + dy * k]], { stroke: LINE, width: THIN + 1 });
  }
  const plan = (P, d) => P.shape(d, { stroke: LINE, width: PLAN });

  const ITEMS = {
    weapon(P) {   // a sword, point up-right
      plan(P, [['M', 104, 184], ['L', 180, 108], ['L', 194, 78], ['L', 164, 92], ['L', 88, 168], ['Z']]);
      plan(P, [['M', 104, 160], ['L', 170, 94]]);            // fuller
      plan(P, [['M', 74, 158], ['L', 112, 196]]);            // guard
      plan(P, [['M', 88, 184], ['L', 70, 202]]);             // grip
    },
    helmet(P) {   // a kettle hat with a brim
      plan(P, [['M', 78, 160], ['Q', 78, 98, 130, 96], ['Q', 182, 98, 182, 160]]);
      plan(P, [['M', 56, 162], ['Q', 130, 144, 204, 162], ['Q', 208, 178, 194, 178], ['Q', 130, 162, 66, 178], ['Q', 52, 178, 56, 162], ['Z']]);
    },
    armor(P) {    // a breastplate with shoulders
      plan(P, [['M', 92, 96], ['L', 168, 94], ['L', 196, 116], ['L', 182, 136], ['L', 172, 130], ['L', 172, 182],
        ['Q', 132, 194, 92, 184], ['L', 92, 132], ['L', 82, 138], ['L', 66, 118], ['Z']]);
      plan(P, [['M', 112, 98], ['Q', 132, 118, 150, 96]]);   // neckline
      plan(P, [['M', 94, 160], ['Q', 132, 170, 170, 158]]);  // belt
    },
    boots(P) {    // a pair of boots
      for (const ox of [0, 64]) {
        plan(P, [['M', 66 + ox, 100], ['L', 104 + ox, 98], ['L', 106 + ox, 158], ['L', 130 + ox, 168], ['Q', 140 + ox, 178, 130 + ox, 188],
          ['L', 64 + ox, 190], ['Q', 58 + ox, 190, 60 + ox, 180], ['Z']]);
      }
    },
  };

  globalThis.Blueprint = {
    SLOTS: ['weapon', 'helmet', 'armor', 'boots'],
    draw(slot, size) {
      const P = new Pen(); P.scale(size / 256);
      sheet(P);
      ITEMS[slot](P);
      return P.ops;
    },
  };
})();
