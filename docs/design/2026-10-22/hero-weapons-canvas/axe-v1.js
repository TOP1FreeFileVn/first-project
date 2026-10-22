// Archived first axe proposal, before the user's request to redraw its head.
(function () {
  const colors = {
    ink: '#583f21', secondary: '#9b7f58', wood: '#c88e51',
    steel: '#d9e0e8', steelPlane: '#a8b4c7',
  };
  const strokeProfiles = { main: 13, secondary: 6.5 };
  const SHAFT = [
    ['M', -11, -123], ['L', 11, -123], ['L', 11, 36],
    ['Q', 11, 46, 0, 46], ['Q', -11, 46, -11, 36], ['Z'],
  ];
  const HEAD = [
    ['M', -26, -140], ['Q', -33, -140, -33, -133], ['L', -33, -115],
    ['Q', -33, -108, -26, -108], ['L', -12, -108], ['L', -12, -96],
    ['Q', -12, -91, -6, -91], ['L', 17, -91],
    ['Q', 19, -73, 8, -54], ['Q', 43, -60, 60, -86],
    ['Q', 72, -105, 66, -132], ['Q', 44, -125, 26, -139],
    ['Q', 24, -141, 19, -141], ['Z'],
  ];
  function draw(P, options = {}) {
    const { main = strokeProfiles.main, secondary = strokeProfiles.secondary, roles = false } = options;
    const mainInk = roles ? '#d45d46' : colors.ink;
    const secondaryInk = roles ? '#168c91' : colors.secondary;
    P.shape(SHAFT, { fill: colors.wood });
    P.shape([
      ['M', -11, -91], ['L', -11, 36], ['Q', -11, 46, 0, 46],
      ['Q', 11, 46, 11, 36], ['L', 11, -91],
    ], { stroke: mainInk, width: main });
    P.shape([['M', -10, 7], ['Q', 0, 12, 10, 7]],
      { stroke: secondaryInk, width: secondary });
    P.shape([['M', -10, 23], ['Q', 0, 28, 10, 23]],
      { stroke: secondaryInk, width: secondary });
    P.shape(HEAD, { fill: colors.steel });
    P.shape([
      ['M', 19, -141], ['L', 26, -139], ['Q', 44, -125, 66, -132],
      ['Q', 72, -105, 60, -86], ['Q', 43, -60, 8, -54],
      ['Q', 34, -75, 37, -99], ['Q', 38, -124, 19, -141], ['Z'],
    ], { fill: colors.steelPlane });
    P.shape([['M', 5, -130], ['L', 5, -107]],
      { stroke: secondaryInk, width: secondary });
    P.shape(HEAD, { stroke: mainInk, width: main });
    return P.ops;
  }
  globalThis.WeaponAxe = { draw, colors, strokeProfiles, grip: [0, 0], bounds: [-33, -141, 72, 46] };
})();
