// Second axe design: broad curved cutting face, rounded poll, substantial haft.
// Grip is (0, 0), functional head is towards -Y.
(function () {
  const colors = {
    ink: '#583f21', wood: '#c88e51',
    steel: '#d9e0e8', steelPlane: '#a8b4c7',
  };
  const strokeProfiles = { main: 13 };
  const SHAFT = [
    ['M', -15, -135], ['L', 15, -135], ['L', 20, -12], ['L', 20, 33],
    ['Q', 20, 46, 0, 46], ['Q', -20, 46, -20, 33], ['L', -20, -12], ['Z'],
  ];
  const HEAD = [
    ['M', -17, -141], ['Q', -28, -140, -28, -127],
    ['Q', -28, -113, -15, -111], ['L', 11, -111],
    ['Q', 26, -106, 29, -93], ['Q', 31, -82, 24, -69],
    ['Q', 20, -60, 30, -61],
    ['C', 65, -65, 90, -95, 88, -133],
    ['Q', 88, -146, 80, -141],
    ['Q', 54, -126, 28, -137], ['Q', 7, -146, -17, -141], ['Z'],
  ];
  function draw(P, options = {}) {
    const { main = strokeProfiles.main, roles = false } = options;
    const mainInk = roles ? '#d45d46' : colors.ink;
    // Shaft's hidden top lies behind the solid head. Its visible contour is open.
    P.shape(SHAFT, { fill: colors.wood });
    // Smooth, slightly flared wooden grip; no added wrap marks.
    P.shape([
      ['M', -15.98, -111], ['L', -20, -12], ['L', -20, 33], ['Q', -20, 46, 0, 46],
      ['Q', 20, 46, 20, 33], ['L', 20, -12], ['L', 16.06, -109],
    ], { stroke: mainInk, width: main });
    P.shape(HEAD, { fill: colors.steel });
    // Broad steel face, unlined at its shared boundary. The outer blade is one
    // long smooth cutting arc rather than a stepped neck and thin hooked fang.
    P.shape([
      ['M', 28, -137], ['Q', 54, -126, 80, -141],
      ['Q', 88, -146, 88, -133],
      ['C', 90, -95, 65, -65, 30, -61],
      ['Q', 20, -60, 24, -69],
      ['Q', 54, -85, 57, -107], ['Q', 57, -125, 28, -137], ['Z'],
    ], { fill: colors.steelPlane });
    // The two broad steel fills describe the head without an extra surface mark.
    P.shape(HEAD, { stroke: mainInk, width: main });
    return P.ops;
  }
  globalThis.WeaponAxe = { draw, colors, strokeProfiles, grip: [0, 0], bounds: [-28, -146, 90, 46] };
})();
