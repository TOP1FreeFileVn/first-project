// Cat soldier (sword infantry, tabby) redrawn for a skeletal rig. 256 x 240 frame, y down.
// Built from separate parts so nothing is cut out of another part:
// - The body is one closed, rounded shape with a flat-ish bottom. Its stripes are clipped
//   to it, so moving a leg never slices a stripe.
// - Each leg is its own short stub drawn BEHIND the body: only the foot pokes out below.
// - Paws are the hook strokes at the chest; the right paw is drawn again over the sword grip.
// Cat.parts() -> { name: ops } for every layer; Cat.PIVOTS give each part's joint.
(function () {
  const INK = '#583f21', FUR = '#f9d27b', STRIPE = '#d89f4c', EYE = '#3b2a1a', PINKISH = '#f6b8b0',
    STEEL = '#c9d3dd', STEEL_SEAM = '#9aa8b6', TRIM = '#b98a5a';
  const W = 9, S = 5;   // main line (the accepted 9 px), stripe/trim strokes
  const C = Pen.circle;

  // Bottom at y206, so the legs below get ~28 px of visible foot.
  const BODY = [['M', 80, 118], ['L', 176, 118], ['Q', 204, 118, 206, 150], ['L', 207, 182],
    ['Q', 208, 206, 180, 206], ['L', 76, 206], ['Q', 48, 206, 49, 182], ['L', 50, 150], ['Q', 52, 118, 80, 118], ['Z']];
  const HEAD = [['M', 128, 34], ['C', 196, 34, 214, 58, 214, 92], ['C', 214, 128, 186, 144, 128, 144],
    ['C', 70, 144, 42, 128, 42, 92], ['C', 42, 58, 60, 34, 128, 34], ['Z']];

  // Stripes are drawn only where they fall inside `clip` (a convex-ish blob): we trim each
  // stroke to the clip's horizontal extent at its height, so no SVG clipPath is needed.
  function bodySpan(y) { // x range of BODY at height y (piecewise, matches the path closely)
    if (y < 118) return null;
    const t = Math.min(1, (y - 118) / 32);
    const left = y < 150 ? 80 - 30 * Math.sin(t * Math.PI / 2) : 50 - 2 * (y - 150) / 42;
    return [left + 6, 256 - left - 6];
  }
  function stripes(P) {
    for (const y of [150, 168, 186]) {
      const [l, r] = bodySpan(y);
      P.shape([['M', l, y], ['Q', l + 18, y + 6, l + 36, y]], { stroke: STRIPE, width: 8 });
      P.shape([['M', r - 36, y], ['Q', r - 18, y + 6, r, y]], { stroke: STRIPE, width: 8 });
    }
  }
  function headStripes(P) {
    for (const [a, b, y] of [[50, 70, 100], [50, 68, 116], [186, 206, 100], [188, 206, 116]])
      P.shape([['M', a, y], ['Q', (a + b) / 2, y + 4, b, y]], { stroke: STRIPE, width: 7 });
  }

  const parts = {
    tail(P) {
      const d = [['M', 186, 198], ['Q', 236, 204, 232, 158], ['Q', 230, 142, 218, 142]];
      P.shape(d, { stroke: INK, width: 13 + 2 * W });
      P.shape(d, { stroke: FUR, width: 13 });
    },
    // A leg: a short rounded stub; the top hides behind the body, the foot shows below.
    leg_l(P) { leg(P, 90); },
    leg_r(P) { leg(P, 166); },
    body(P) {
      P.shape(BODY, { fill: FUR });
      stripes(P);
      // Breastplate and belt, inside the body.
      const plate = [['M', 86, 130], ['L', 170, 130], ['Q', 182, 160, 170, 188], ['L', 86, 188], ['Q', 74, 160, 86, 130], ['Z']];
      P.shape(plate, { fill: STEEL, stroke: INK, width: 7 });
      P.shape([['M', 128, 138], ['L', 128, 176]], { stroke: STEEL_SEAM, width: 5 });
      P.shape([['M', 88, 181], ['L', 168, 181]], { stroke: TRIM, width: 9 });
      P.shape(BODY, { stroke: INK, width: W });
    },
    paw_l(P) { P.shape([['M', 104, 150], ['Q', 114, 164, 106, 172], ['Q', 97, 179, 84, 170]], { stroke: INK, width: 13 }); },
    paw_r(P) { P.shape([['M', 152, 150], ['Q', 142, 164, 150, 172], ['Q', 159, 179, 172, 170]], { stroke: INK, width: 13 }); },
    head(P) {
      P.shape(HEAD, { fill: FUR });
      headStripes(P);
      P.shape(HEAD, { stroke: INK, width: W });
      P.shape(C(104, 96, 9), { fill: EYE }); P.shape(C(152, 96, 9), { fill: EYE });
      P.shape([['M', 110, 110], ['Q', 119, 124, 128, 112], ['Q', 137, 124, 146, 110]], { stroke: EYE, width: 7.5 });
      // Kettle hat: dome, brim, trim band.
      P.shape([['M', 62, 70], ['Q', 62, 18, 128, 16], ['Q', 194, 18, 194, 70], ['Z']], { fill: STEEL, stroke: INK, width: W });
      P.shape([['M', 36, 72], ['Q', 128, 50, 220, 72], ['Q', 224, 86, 208, 86], ['Q', 128, 66, 48, 86], ['Q', 32, 86, 36, 72], ['Z']], { fill: STEEL, stroke: INK, width: 8 });
      P.shape([['M', 68, 62], ['Q', 128, 46, 188, 62]], { stroke: TRIM, width: 8 });
    },
  };
  function leg(P, x) {
    // Top at y178 (well inside the body), rounded foot bottom at y232.
    const d = [['M', x - 20, 176], ['L', x - 21, 218], ['Q', x - 21, 235, x, 235], ['Q', x + 21, 235, x + 21, 218], ['L', x + 20, 176], ['Z']];
    P.shape(d, { fill: FUR, stroke: INK, width: W });
    // Two toe lines on the foot.
    P.shape([['M', x - 7, 226], ['L', x - 7, 233]], { stroke: INK, width: 4 });
    P.shape([['M', x + 7, 226], ['L', x + 7, 233]], { stroke: INK, width: 4 });
  }

  const ORDER = ['tail', 'leg_l', 'leg_r', 'body', 'paw_l', 'head', 'weapon', 'paw_r'];
  const PIVOTS = { tail: [186, 200], leg_l: [90, 190], leg_r: [166, 190], body: [128, 200], paw_l: [104, 150],
    head: [128, 140], weapon: [156, 168], paw_r: [152, 150] };

  globalThis.Cat = {
    ORDER, PIVOTS,
    part(name, k = 1) { const P = new Pen(); P.scale(k); parts[name](P); return P.ops; },
    names: () => Object.keys(parts),
  };
})();
