// Upright stat-only armor. One shared geometry, explicit two-stroke profile.
(function () {
  const C = {
    ink: '#583f21', steel: '#d9e0e8', steelPlane: '#a8b4c7',
    secondary: '#9b7f58',
  };
  const PROFILE = { main: 11.35, secondary: 7.41 };
  const BODY = [
    ['M', 94, 35], ['L', 94, 45], ['Q', 94, 73, 128, 73],
    ['Q', 162, 73, 162, 45], ['L', 162, 35], ['Q', 165, 29, 172, 31],
    ['L', 203, 41], ['Q', 215, 45, 220, 58], ['L', 230, 84],
    ['Q', 232, 91, 225, 94], ['L', 208, 102], ['L', 206, 169],
    ['Q', 205, 203, 179, 217], ['Q', 128, 237, 77, 217],
    ['Q', 51, 203, 50, 169], ['L', 48, 102], ['L', 31, 94],
    ['Q', 24, 91, 26, 84], ['L', 36, 58], ['Q', 41, 45, 53, 41],
    ['L', 84, 31], ['Q', 91, 29, 94, 35], ['Z'],
  ];

  function draw(P, roles = false) {
    const main = roles ? '#d45d46' : C.ink;
    const secondary = roles ? '#168c91' : C.secondary;
    // Broad steel regions. Their shared edge is a fill boundary, not a stroke.
    P.shape(BODY, { fill: C.steel });
    P.shape([
      ['M', 50, 153], ['Q', 128, 183, 206, 153], ['L', 206, 169],
      ['Q', 205, 203, 179, 217], ['Q', 128, 237, 77, 217],
      ['Q', 51, 203, 50, 169], ['Z'],
    ], { fill: C.steelPlane });
    // Figma Armor0113: one steel family. No brass collar/hem or third shoulder fill.
    for (const mirror of [false, true]) {
      P.save();
      if (mirror) { P.translate(256, 0); P.transform(-1, 0, 0, 1, 0, 0); }
      // The user classified this shoulder/armpit join as SECONDARY, not main.
      P.shape([['M', 95, 56], ['Q', 77, 66, 71, 89], ['Q', 66, 103, 48, 102]],
        { stroke: secondary, width: PROFILE.secondary });
      P.restore();
    }
    // Single silhouette pass, including the exposed neck opening.
    P.shape(BODY, { stroke: main, width: PROFILE.main });
    return P.ops;
  }

  function icon(size, roles = false) {
    const P = new Pen();
    P.scale(size / 256);
    return draw(P, roles);
  }
  globalThis.Item = { icon, draw, colors: C, strokeProfiles: PROFILE };
})();
