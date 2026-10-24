// Blueprint (bản vẽ) icons, one per equipment slot. 256 x 256 frame.
// A torn piece of cardboard, like the castle and the menu cartons: tan board with a
// darker torn edge, the corrugation showing along the torn side, two strips of tape
// holding it, and the slot's item drawn on it in brown marker. Flat cat style: one even
// #583f21 outline, no gradients or shine. The item is outline strokes (marker), not
// filled, so the four read as plans, not as items. (Blue version: blueprint-blue.js.)
(function () {
  const INK = '#583f21', CARD = '#e8bb7c', CARD_SHADE = '#d4a065', FLUTE = '#b07c45',
    TAPE = '#f3dfae', TAPE_EDGE = '#c9a56a', LINE = '#583f21';
  // A marker swatch behind each item tells the slots apart at a glance.
  const SWATCH = { weapon: '#f2a65a', helmet: '#8fc1e3', armor: '#a8d58a', boots: '#e6a3c8' };
  const MAIN = 12, PLAN = 12, THIN = 3;
  const C = Pen.circle;

  function sheet(P) {
    // A slightly tilted board; the bottom edge is torn (zigzag), the rest cut straight.
    const torn = [];
    for (let i = 0; i <= 10; i++) torn.push(['L', 220 - i * 17.6, 210 + (i % 2 ? 10 : 0) - i * 0.8]);
    const body = [['M', 42, 56], ['L', 208, 48], ['Q', 216, 48, 216, 56], ['L', 220, 210], ...torn, ['L', 40, 64], ['Q', 40, 56, 42, 56], ['Z']];
    P.shape(body, { fill: CARD });
    // Torn strip: the inner corrugated layer shows along the tear.
    const strip = [['M', 42, 196], ['L', 219, 188], ['L', 220, 210], ...torn, ['Z']];
    P.shape(strip, { fill: CARD_SHADE });
    for (let x = 52; x <= 208; x += 13) P.shape([['M', x, 196 - (x - 42) * 0.045], ['L', x - 2, 214 - (x - 42) * 0.045]], { stroke: FLUTE, width: THIN + 1 });
    P.shape(body, { stroke: INK, width: MAIN });
    // Two strips of tape over the top corners.
    for (const [x, y, a] of [[56, 58, -38], [204, 50, 38]]) {
      P.save(); P.translate(x, y); P.rotate(a);
      const t = [['M', -30, -11], ['L', 30, -11], ['L', 27, -4], ['L', 30, 3], ['L', 27, 11], ['L', -30, 11], ['L', -27, 4], ['L', -30, -3], ['Z']];
      P.shape(t, { fill: TAPE, stroke: TAPE_EDGE, width: 3 });
      P.restore();
    }
  }

  // A dimension mark: a short line with end ticks, in the plan ink.
  function dim(P, x1, y1, x2, y2) {
    P.shape([['M', x1, y1], ['L', x2, y2]], { stroke: LINE, width: THIN + 1 });
    const dx = y2 - y1, dy = x1 - x2, k = 6 / Math.hypot(dx, dy);
    for (const [x, y] of [[x1, y1], [x2, y2]]) P.shape([['M', x - dx * k, y - dy * k], ['L', x + dx * k, y + dy * k]], { stroke: LINE, width: THIN + 1 });
  }
  const plan = (P, d) => P.shape(d, { stroke: LINE, width: PLAN });
  // A soft round marker scribble behind the drawing.
  function swatch(P, slot) {
    P.shape([['M', 74, 104], ['Q', 130, 86, 188, 102], ['Q', 206, 146, 186, 184], ['Q', 128, 198, 76, 184], ['Q', 56, 146, 74, 104], ['Z']], { fill: SWATCH[slot] });
  }

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
      swatch(P, slot);
      ITEMS[slot](P);
      return P.ops;
    },
  };
})();
