// Upright stat-only boot proposal. Canvas and SVG replay the same paths.
(function () {
  const C = {
    ink: '#583f21', steel: '#d9e0e8', steelPlane: '#a8b4c7',
    secondary: '#9b7f58',
  };
  const PROFILE = { main: 11.35, secondary: 7.41 };
  // One sturdy three-quarter boot. The toe projects left; the ankle stays upright.
  const BODY = [
    ['M', 120, 36], ['Q', 160, 22, 199, 36],
    ['Q', 211, 40, 210, 54], ['L', 205, 198],
    ['Q', 205, 217, 183, 221], ['L', 54, 221],
    ['Q', 29, 219, 27, 200], ['L', 27, 182],
    ['Q', 27, 167, 47, 161], ['L', 100, 145],
    ['Q', 112, 141, 112, 126], ['L', 108, 55],
    ['Q', 107, 41, 120, 36], ['Z'],
  ];
  // An actual exposed cuff opening, rather than an ornamental line on a surface.
  const OPENING = [
    ['M', 131, 60], ['C', 141, 50, 177, 50, 187, 59],
    ['C', 186, 72, 142, 77, 131, 65], ['Q', 129, 62, 131, 60], ['Z'],
  ];

  function draw(P, roles = false) {
    const main = roles ? '#d45d46' : C.ink;
    const secondary = roles ? '#168c91' : C.secondary;
    P.shape(BODY, { fill: C.steel });
    // Sole and heel form one broad steel material region, with no third fill or
    // inked line along its top boundary. It is not a cast shadow or glossy edge.
    P.shape([
      ['M', 27, 195], ['Q', 108, 210, 205, 193], ['L', 205, 198],
      ['Q', 205, 217, 183, 221], ['L', 54, 221],
      ['Q', 29, 219, 27, 200], ['Z'],
    ], { fill: C.steelPlane });
    // The shin plate ends above the instep. This subordinate construction seam
    // uses the latest user-requested secondary width, rather than main weight.
    P.shape([
      ['M', 112, 130], ['Q', 149, 142, 205, 132],
    ], { stroke: secondary, width: PROFILE.secondary });
    // One steel toe-cap seam. Its open curve follows the projecting toe instead
    // of adding a closed decorative panel or another material colour.
    P.shape([
      ['M', 77, 152], ['Q', 103, 166, 107, 202],
    ], { stroke: secondary, width: PROFILE.secondary });
    P.shape(OPENING, { fill: C.steelPlane, stroke: main, width: PROFILE.main });
    // Resolve the outside once after broad fills; no hidden contour is repeated.
    P.shape(BODY, { stroke: main, width: PROFILE.main });
    return P.ops;
  }

  function icon(size, roles = false) {
    const P = new Pen();
    P.scale(size / 256);
    return draw(P, roles);
  }
  globalThis.GearBoots = {
    icon, draw, colors: C, strokeProfiles: PROFILE,
    brief: 'Upright steel boot with a flared open cuff, broad toe and broad sole plane.',
  };
})();
