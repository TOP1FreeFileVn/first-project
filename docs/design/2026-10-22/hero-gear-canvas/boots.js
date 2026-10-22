// Upright stat-only boot PAIR. Draw at final composition scale to retain line weight.
(function () {
  const C = {
    ink: '#583f21', steel: '#d9e0e8', steelPlane: '#a8b4c7',
    secondary: '#9b7f58',
  };
  const PROFILE = { main: 11.35, secondary: 7.41 };
  // Narrower boot construction leaves room for two full-height boots, without
  // shrinking a single-boot icon and accidentally thinning both line classes.
  const BODY = [
    ['M', 63, 15], ['Q', 94, 3, 126, 15],
    ['Q', 137, 19, 135, 29], ['L', 130, 163],
    ['Q', 129, 181, 116, 185], ['L', 27, 185],
    ['Q', 7, 181, 3, 165], ['L', 3, 149],
    ['Q', 3, 138, 25, 132], ['L', 51, 121],
    ['Q', 59, 117, 58, 102], ['L', 54, 28],
    ['Q', 53, 20, 63, 15], ['Z'],
  ];
  // An actual exposed cuff opening, rather than an ornamental line on a surface.
  const OPENING = [
    ['M', 70, 45], ['C', 70, 25, 118, 25, 118, 45],
    ['C', 118, 65, 70, 65, 70, 45], ['Z'],
  ];

  function boot(P, roles) {
    const main = roles ? '#d45d46' : C.ink;
    const secondary = roles ? '#168c91' : C.secondary;
    P.shape(BODY, { fill: C.steel });
    // Sole and heel form one broad steel material region, with no third fill or
    // inked line along its top boundary. It is not a cast shadow or glossy edge.
    P.shape([
      ['M', 3, 160], ['Q', 66, 174, 130, 158], ['L', 130, 163],
      ['Q', 129, 181, 116, 185], ['L', 27, 185],
      ['Q', 7, 181, 3, 165], ['Z'],
    ], { fill: C.steelPlane });
    // The shin plate ends above the instep. This subordinate construction seam
    // uses the latest user-requested secondary width, rather than main weight.
    P.shape([
      ['M', 58, 111], ['Q', 94, 122, 132, 112],
    ], { stroke: secondary, width: PROFILE.secondary });
    // One steel toe-cap seam. Its open curve follows the projecting toe instead
    // of adding a closed decorative panel or another material colour.
    P.shape([
      ['M', 32, 129], ['Q', 49, 140, 53, 166],
    ], { stroke: secondary, width: PROFILE.secondary });
    P.shape(OPENING, { fill: C.steelPlane, stroke: main, width: PROFILE.main });
    // Resolve the outside once after broad fills; no hidden contour is repeated.
    P.shape(BODY, { stroke: main, width: PROFILE.main });
  }

  function draw(P, roles = false) {
    // Back boot first. Front fill hides its occluded sole/contour; no line is
    // redrawn over the foreground boot and no artificial shadow separates them.
    for (const [x, y] of [[9, 10], [103, 40]]) {
      P.save();
      P.translate(x, y);
      boot(P, roles);
      P.restore();
    }
    return P.ops;
  }

  function icon(size, roles = false) {
    const P = new Pen();
    P.scale(size / 256);
    return draw(P, roles);
  }
  globalThis.GearBoots = {
    icon, draw, colors: C, strokeProfiles: PROFILE,
    brief: 'Upright pair of steel boots, back then front, with visible cuff openings and left-facing toes.',
  };
})();
