// Crystal staff: authored around the real grip at (0, 0), head towards -Y.
// Canvas and SVG consume these same paths. Placement belongs to the caller.
(function () {
  const colors = {
    ink: '#583f21', secondary: '#9b7f58',
    wood: '#c88e51', socket: '#d7b36e',
    crystal: '#a2ded4', crystalPlane: '#69b9af',
  };
  const strokeProfiles = { main: 13, secondary: 6.5 };
  // One continuous contour keeps the shaft, socket and crystal coaxial.
  const BODY = [
    ['M', 0, -147], ['Q', 2, -148, 5, -145], ['L', 27, -126],
    ['Q', 29, -124, 28, -119], ['L', 23, -103], ['L', 19, -98],
    ['L', 17, -82], ['Q', 17, -77, 11, -75], ['L', 11, 37],
    ['Q', 11, 46, 0, 46], ['Q', -11, 46, -11, 37], ['L', -11, -75],
    ['Q', -17, -77, -17, -82], ['L', -19, -98], ['L', -23, -103],
    ['L', -28, -119], ['Q', -29, -124, -27, -126], ['L', -5, -145],
    ['Q', -2, -148, 0, -147], ['Z'],
  ];
  function draw(P, options = {}) {
    const { main = strokeProfiles.main, secondary = strokeProfiles.secondary, roles = false } = options;
    const mainInk = roles ? '#d45d46' : colors.ink;
    const secondaryInk = roles ? '#168c91' : colors.secondary;
    P.shape(BODY, { fill: colors.wood });
    // Crystal planes meet without ink. This is material colour, not gloss.
    P.shape([
      ['M', 0, -147], ['Q', 2, -148, 5, -145], ['L', 27, -126],
      ['Q', 29, -124, 28, -119], ['L', 23, -103], ['L', 19, -98],
      ['L', -19, -98], ['L', -23, -103], ['L', -28, -119],
      ['Q', -29, -124, -27, -126], ['L', -5, -145],
      ['Q', -2, -148, 0, -147], ['Z'],
    ], { fill: colors.crystal });
    P.shape([
      ['M', 0, -147], ['L', 27, -126], ['Q', 29, -124, 28, -119],
      ['L', 23, -103], ['L', 19, -98], ['L', 0, -98], ['Z'],
    ], { fill: colors.crystalPlane });
    // Broad collar sits over the gem base and shaft; no double outlined ring.
    P.shape([
      ['M', -23, -103], ['Q', 0, -94, 23, -103], ['L', 19, -98],
      ['L', 17, -82], ['Q', 17, -77, 11, -75], ['L', -11, -75],
      ['Q', -17, -77, -17, -82], ['L', -19, -98], ['Z'],
    ], { fill: colors.socket });
    P.shape([['M', -18, -94], ['Q', 0, -88, 18, -94]],
      { stroke: secondaryInk, width: secondary });
    // Two broad construction seams survive reduction; no woodgrain hairlines.
    P.shape([['M', -10, 7], ['Q', 0, 12, 10, 7]],
      { stroke: secondaryInk, width: secondary });
    P.shape([['M', -10, 23], ['Q', 0, 28, 10, 23]],
      { stroke: secondaryInk, width: secondary });
    P.shape(BODY, { stroke: mainInk, width: main });
    return P.ops;
  }
  globalThis.WeaponStaff = { draw, colors, strokeProfiles, grip: [0, 0], bounds: [-29, -148, 29, 46] };
})();
