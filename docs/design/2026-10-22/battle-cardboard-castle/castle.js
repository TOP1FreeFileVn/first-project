// Battle adaptation of the approved lobby castle, authored with the shared Pen.
// Every exported layer keeps the complete 720 x 240 registration.
(function () {
  const C = {
    ink: '#583f21', seam: '#a57a48', board: '#e0b878', top: '#e8c080',
    side: '#cfa466', tape: '#f7dfad', dark: '#604820', inner: '#c09559',
    teal: '#77b3b3', tealDark: '#568f91', stamp: '#ac854b',
  };
  const MAIN = 4.6, SECONDARY = 2.6;
  const path = (P, d, fill, stroke = C.ink, width = MAIN) => P.shape(d, { fill, stroke, width });
  const line = (P, d, ink = C.seam, width = SECONDARY) => path(P, d, null, ink, width);

  function fish(P, cx, cy, s) {
    P.save(); P.translate(cx, cy); P.scale(s);
    path(P, [['M',-19,0],['Q',-6,-13,9,-7],['L',19,-14],['L',17,-1],['L',21,11],['L',8,6],['Q',-8,13,-19,0],['Z']], C.tape, null, 0);
    path(P, Pen.circle(-9,-1,1.8), C.tealDark, null, 0);
    P.restore();
  }

  function pennant(P, x, y, size = 1) {
    P.save(); P.translate(x, y); P.scale(size);
    path(P, [['M',0,61],['L',0,0]], null, C.ink, MAIN);
    path(P, [['M',3,3],['Q',21,7,39,14],['L',3,29],['Z']], C.teal);
    path(P, Pen.circle(0,0,3.2), C.tape, C.ink, 2.6);
    P.restore();
  }

  function rear(P) {
    // Flags and recessed floor are behind actors. The upper doorway is clear alpha,
    // not a painted dark gate: the battlefield can be seen through it.
    pennant(P, 123, 73, .9);
    pennant(P, 591, 73, .9);
    path(P, [['M',357,75],['L',357,7]], null, C.ink, MAIN);
    path(P, [['M',361,11],['Q',385,11,402,18],['L',399,29],['L',405,41],['Q',383,43,361,35],['Z']], C.teal);
    fish(P, 382, 25, .65);
    path(P, Pen.circle(357,7,3.4), C.tape, C.ink, 2.6);
    // The lower aperture opens onto a flat cardboard floor with no projecting ramp.
    path(P, [['M',311,193],['L',409,193],['L',409,218],['L',311,218],['Z']], C.top, null, 0);
    path(P, [['M',311,193],['L',409,193],['L',409,199],['L',311,199],['Z']], C.inner, null, 0);
    // Two slim wall returns make the sheet thickness visible beside the opening.
    path(P, [['M',307,162],['L',315,171],['L',315,218],['L',307,218],['Z']], C.side, null, 0);
    path(P, [['M',413,162],['L',405,171],['L',405,218],['L',413,218],['Z']], C.side, null, 0);
  }

  function tape(P, x, y, w, h) {
    path(P, [['M',x,y],['L',x+w,y],['L',x+w-1,y+h],['L',x+w-5,y+h-2],['L',x+w-9,y+h],['L',x+w-13,y+h-2],['L',x,y+h],['Z']], C.tape, null, 0);
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

  function tower(P, x, mirrored = false) {
    // Short box, real cat cut-out window, tape bridge, and folded side panel.
    P.save(); P.translate(x,0);
    const w = 141;
    path(P,[['M',w,130],['L',w+12,123],['L',w+12,210],['L',w,218],['Z']],C.side);
    path(P,[['M',0,130],['L',0,116],['L',20,116],['L',20,130],['L',42,130],['L',42,116],['L',62,116],['L',62,130],['L',84,130],['L',84,116],['L',104,116],['L',104,130],['L',123,130],['L',123,116],['L',w,116],['L',w,218],['L',0,218],['Z']],C.board);
    // The cap's flat light band is a material plane, with no decorative hairline.
    path(P,[['M',3,133],['L',w-3,133],['L',w-3,143],['L',3,143],['Z']],C.top,null,0);
    const cx = mirrored ? 79 : 63;
    path(P,[['M',cx-11,174],['L',cx-11,163],['Q',cx-11,149,cx,149],['Q',cx+11,149,cx+11,163],['L',cx+11,174],['Z']],C.dark,C.ink,3.6);
    paw(P,cx,196,.9);
    tape(P,mirrored ? 15 : 106,135,22,14);
    P.restore();
  }

  function facade(P) {
    // Broad low cardboard wings make a battle barrier without stretching the lobby bitmap.
    // Keep each exterior centerline half a main stroke inside the canvas, so its
    // full vertical outline remains visible instead of being clipped offscreen.
    const leftEdge = MAIN / 2, rightEdge = 720 - MAIN / 2;
    path(P,[['M',leftEdge,175],['L',leftEdge,160],['L',18,160],['L',18,175],['L',44,175],['L',44,160],['L',65,160],['L',65,175],['L',254,175],['L',254,218],['L',leftEdge,218],['Z']],C.board);
    path(P,[['M',464,175],['L',655,175],['L',655,160],['L',676,160],['L',676,175],['L',702,175],['L',702,160],['L',rightEdge,160],['L',rightEdge,218],['L',464,218],['Z']],C.board);
    tower(P,66,false);
    tower(P,510,true);
    // Box depth is one broad unlined plane; no stone blocks or tiny rivets.
    path(P,[['M',464,80],['L',477,72],['L',477,208],['L',464,218],['Z']],C.side);
    // The two triangular roof flaps were removed at the user's request.
    // Keep the box crenellation and cat-shaped doorway below unchanged.
    // The cat-head doorway is an open notch, not painted onto a solid front.
    path(P,[['M',254,80],['L',277,80],['L',277,94],['L',298,94],['L',298,78],['L',331,78],['L',331,94],['L',354,94],['L',354,78],['L',387,78],['L',387,94],['L',410,94],['L',410,78],['L',442,78],['L',442,94],['L',464,94],['L',464,218],['L',407,218],['L',407,181],['Q',407,166,399,157],['L',396,140],['Q',395,134,389,140],['L',375,148],['Q',360,144,345,148],['L',331,140],['Q',325,134,323,140],['L',320,157],['Q',313,166,313,181],['L',313,218],['L',254,218],['Z']],C.board);
    // The two tape patches and one crease say cardboard, without cluttering the silhouette.
    tape(P,336,99,27,24);
    tape(P,245,133,26,18);
    line(P,[['M',458,104],['L',458,198]]);
    // Folded outward against the jambs; neither leaf spans the passage.
    path(P,[['M',312,174],['L',300,164],['L',300,206],['L',312,218],['Z']],C.side);
    path(P,[['M',408,174],['L',420,164],['L',420,206],['L',408,218],['Z']],C.side);
  }

  function layer(name) {
    const P = new Pen();
    if (name === 'rear') rear(P);
    else if (name === 'facade') facade(P);
    else { rear(P); facade(P); }
    return P.ops;
  }
  globalThis.CardboardCastle = { layer, colors:C, main:MAIN, secondary:SECONDARY, width:720, height:240 };
})();
