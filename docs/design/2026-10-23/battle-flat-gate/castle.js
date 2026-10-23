// Front-facing 2D cardboard battle castle, 5 upgrade tiers, using shared Pen paths.
// Every exported layer keeps the complete 720 x 240 registration. The gate aperture,
// baseline (y218) and wall footprint never change between tiers; only dressing grows,
// following the lobby tiers in docs/design/2026-10-23/castle-tiers-canvas:
//   1 box  2 taped seams  3 felt-less paper cone roofs + lit windows
//   4 teal felt roofs, sisal scratching rope  5 yarn-ball finials, gold inner ears, fish banner
// Flags have bare poles here; the game draws each cloth from `anchors` and waves it.
(function () {
  const C = {
    ink: '#583f21', seam: '#a57a48', board: '#e0b878', top: '#e8c080',
    side: '#cfa466', tape: '#f7dfad', dark: '#604820', inner: '#c09559',
    teal: '#77b3b3', tealDark: '#568f91', stamp: '#ac854b',
    pink: '#f2b6a8', gold: '#f0c457', glow: '#ffd77a', hole: '#6b4a2b',
    roof: '#cf9b5c', roofShade: '#b07c45', felt: '#6aa9a8', feltShade: '#4f8b8a',
    sisal: '#d9c39a', sisalShade: '#b89d6d', yarn: '#e07a6b', cream: '#fbf1dc',
  };
  const MAIN = 4.6, SECONDARY = 2.6;
  const path = (P, d, fill, stroke = C.ink, width = MAIN) => P.shape(d, { fill, stroke, width });
  let ANCHORS = [];

  // Bare pole + finial; records where the cloth's hoist corner hangs.
  function pole(P, x, base, top, big) {
    path(P, [['M', x, base], ['L', x, top]], null, C.ink, MAIN);
    path(P, Pen.circle(x, top - 3, 3.4), C.gold, C.ink, 2.6);
    ANCHORS.push({ x: x + 2, y: top + 1, big });
  }

  function tape(P, x, y, w, h) {
    path(P, [['M',x,y],['L',x+w,y],['L',x+w-1,y+h],['L',x+w-5,y+h-2],['L',x+w-9,y+h],['L',x+w-13,y+h-2],['L',x,y+h],['Z']], C.tape, C.seam, 1.6);
  }

  function paw(P, x, y, s = 1) {
    P.save(); P.translate(x,y); P.scale(s);
    path(P, [['M',-9,7],['Q',-10,2,-4,-2],['Q',0,-7,4,-2],['Q',10,2,9,7],['Q',7,11,2,8],['Q',0,7,-2,8],['Q',-7,11,-9,7],['Z']], C.stamp, null, 0);
    for (const [cx,cy,angle] of [[-10,-6,-25],[-3.5,-11,-10],[4,-11,10],[10,-6,25]]) {
      P.save(); P.translate(cx,cy); P.rotate(angle); P.transform(1,0,0,1.3,0,0);
      path(P,Pen.circle(0,0,3),C.stamp,null,0); P.restore();
    }
    P.restore();
  }

  // Cone roof resting on a flat wall top, eave overhanging both sides.
  function cone(P, cx, base, w, h, fill, shade) {
    const d = [['M', cx - w / 2, base], ['Q', cx - w * 0.18, base - h * 0.55, cx, base - h], ['Q', cx + w * 0.18, base - h * 0.55, cx + w / 2, base], ['Z']];
    path(P, d, fill, null, 0);
    path(P, [['M', cx, base - h], ['Q', cx + w * 0.18, base - h * 0.55, cx + w / 2, base], ['L', cx + w * 0.16, base], ['Z']], shade, null, 0);
    path(P, d, null);
  }

  function window_(P, cx, y, lit) {
    path(P, [['M', cx - 10, y + 28], ['L', cx - 10, y + 10], ['Q', cx - 10, y, cx, y], ['Q', cx + 10, y, cx + 10, y + 10], ['L', cx + 10, y + 28], ['Z']], lit ? C.glow : C.hole, C.ink, 3);
    if (lit) path(P, [['M', cx, y + 2], ['L', cx, y + 27], ['M', cx - 9, y + 15], ['L', cx + 9, y + 15]], null, C.ink, 2);
  }

  // A side tower (141 wide) at x. Roofed tiers drop the battlements for a flat top.
  function tower(P, x, t, mirrored) {
    const w = 141, cx = x + w / 2;
    if (t < 3) {
      path(P,[['M',x,130],['L',x,116],['L',x+20,116],['L',x+20,130],['L',x+42,130],['L',x+42,116],['L',x+62,116],['L',x+62,130],['L',x+84,130],['L',x+84,116],['L',x+104,116],['L',x+104,130],['L',x+123,130],['L',x+123,116],['L',x+w,116],['L',x+w,218],['L',x,218],['Z']],C.board);
      path(P,[['M',x+3,133],['L',x+w-3,133],['L',x+w-3,143],['L',x+3,143],['Z']],C.top,null,0);
    } else {
      path(P,[['M',x,124],['L',x+w,124],['L',x+w,218],['L',x,218],['Z']],C.board);
      path(P,[['M',x+3,127],['L',x+w-3,127],['L',x+w-3,137],['L',x+3,137],['Z']],C.top,null,0);
    }
    if (t >= 4) {   // sisal rope round the foot: a scratching post
      path(P, [['M', x + 2, 186], ['L', x + w - 2, 186], ['L', x + w - 2, 216], ['L', x + 2, 216], ['Z']], C.sisal, null, 0);
      for (let y = 192; y < 216; y += 7) path(P, [['M', x + 4, y], ['Q', cx, y + 3, x + w - 4, y]], null, C.sisalShade, 1.8);
      path(P, [['M', x + 2, 186], ['L', x + w - 2, 186]], null, C.ink, SECONDARY);
      path(P,[['M',x,124],['L',x+w,124],['L',x+w,218],['L',x,218],['Z']],null);
    }
    if (t >= 3) window_(P, cx, 146, true);
    else paw(P, cx, 196, .9);
    if (t >= 3 && t < 4) paw(P, cx, 196, .9);
    if (t === 2) tape(P, mirrored ? x + 15 : x + 106, 135, 22, 14);
    if (t >= 3) {
      const h = t >= 4 ? 70 : 62, base = 128;
      pole(P, cx, base - h + 6, base - h - 44, false);
      cone(P, cx, base, w + 18, h, t >= 4 ? C.felt : C.roof, t >= 4 ? C.feltShade : C.roofShade);
      if (t >= 5) { path(P, Pen.circle(cx, base - h - 2, 8), C.yarn, C.ink, SECONDARY); path(P, [['M', cx - 5, base - h - 5], ['Q', cx, base - h + 1, cx + 6, base - h - 3]], null, '#b85a4d', 1.8); }
    }
  }

  function keep(P, t) {
    // Cat-head gate notch stays exactly where it was; only the top grows.
    const top = 80, crenel = top + 14;   // the canvas top leaves no room to stack a box here
    const earTip = top - 40;
    const x0 = 254, x1 = 464;
    const d = [['M',x0,218],['L',x0,top + 6],['Q',x0 - 2,earTip + 8,x0 + 16,earTip],['Q',x0 + 40,earTip + 10,x0 + 52,top],
      ['L',298,top],['L',298,crenel],['L',331,crenel],['L',331,top],['L',354,top],['L',354,crenel],['L',387,crenel],['L',387,top],['L',410,top],['L',410,crenel],['L',x1 - 52,crenel],['L',x1 - 52,top],
      ['Q',x1 - 40,earTip + 10,x1 - 16,earTip],['Q',x1 + 2,earTip + 8,x1,top + 6],
      ['L',x1,218],['L',407,218],['L',407,181],['Q',407,166,399,157],['L',396,140],['Q',395,134,389,140],['L',375,148],['Q',360,144,345,148],['L',331,140],['Q',325,134,323,140],['L',320,157],['Q',313,166,313,181],['L',313,218],['Z']];
    // Keep flag pole stands behind the middle merlon.
    pole(P, 357, top + 10, top - 70, true);
    path(P, d, C.board, null, 0);
    for (const s of [-1, 1]) {   // inner ears
      const wx = s < 0 ? x0 : x1, k = -s;
      path(P, [['M', wx + k * 12, top + 4], ['Q', wx + k * 12, earTip + 18, wx + k * 19, earTip + 13], ['Q', wx + k * 33, earTip + 16, wx + k * 37, top + 4], ['Z']], t >= 5 ? C.gold : C.pink, null, 0);
    }
    path(P, [['M', x0 + 5, top + 26], ['L', x1 - 5, top + 26]], null, C.seam, SECONDARY);   // top flap fold
    path(P, d, null);
    if (t >= 2) tape(P, x0 + 6, top + 21, x1 - x0 - 12, 10);
    if (t >= 5) banner(P, 360, 114);
  }

  // Fish banner hanging on the keep between the gate ears (tier 5).
  function banner(P, x, y) {
    path(P, [['M', x - 18, y], ['L', x + 18, y], ['L', x + 18, y + 18], ['L', x, y + 13], ['L', x - 18, y + 18], ['Z']], C.teal, C.ink, 2.6);
    path(P, [['M', x - 10, y + 7], ['Q', x - 2, y + 1, x + 6, y + 7], ['Q', x - 2, y + 13, x - 10, y + 7], ['Z'],
      ['M', x + 6, y + 7], ['L', x + 11, y + 3], ['L', x + 11, y + 11], ['Z']], C.cream, C.ink, 1.8);
  }

  function wings(P) {
    const leftEdge = MAIN / 2, rightEdge = 720 - MAIN / 2;
    path(P,[['M',leftEdge,175],['L',leftEdge,160],['L',18,160],['L',18,175],['L',44,175],['L',44,160],['L',65,160],['L',65,175],['L',254,175],['L',254,218],['L',leftEdge,218],['Z']],C.board);
    path(P,[['M',464,175],['L',655,175],['L',655,160],['L',676,160],['L',676,175],['L',702,175],['L',702,160],['L',rightEdge,160],['L',rightEdge,218],['L',464,218],['Z']],C.board);
  }

  // rear: bare poles that stand behind units (low tiers' tower flags).
  // facade: the whole opaque wall, drawn in front of units.
  function draw(tier, name) {
    const P = new Pen(); ANCHORS = [];
    const back = new Pen(), front = new Pen();
    // Tower flags on battlemented tiers sit behind the wall (rear); roofed ones ride the roof (facade).
    if (tier < 3) { pole(back, 123, 134, 73, false); pole(back, 591, 134, 73, false); }
    wings(front);
    tower(front, 66, tier, false);
    tower(front, 510, tier, true);
    keep(front, tier);
    const ops = name === 'rear' ? back.ops : name === 'facade' ? front.ops : back.ops.concat(front.ops);
    return { ops, anchors: ANCHORS.slice() };
  }

  globalThis.CardboardCastle = {
    draw, layer: (name) => draw(1, name).ops,
    colors: C, main: MAIN, secondary: SECONDARY, width: 720, height: 240,
  };
})();
