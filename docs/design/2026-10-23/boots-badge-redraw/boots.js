(function () {
  // Category-symbol profile: one 18/256 main contour, no surface decoration.
  // Two short boots with a flared cuff, rounded toe and a clear central gap.
  const MAIN = 18;
  const BOOT = [
    ['M', 55, 54], ['Q', 70, 50, 86, 54],
    ['Q', 93, 55, 92, 63], ['L', 89, 108],
    ['Q', 89, 116, 97, 125], ['Q', 104, 135, 101, 151],
    ['Q', 100, 164, 88, 164], ['L', 29, 164],
    ['Q', 18, 164, 18, 153], ['Q', 17, 140, 30, 135],
    ['L', 48, 126], ['Q', 55, 122, 55, 112], ['L', 50, 65],
    ['Q', 48, 57, 55, 54], ['Z'],
  ];
  function icon(size) {
    const P = new Pen();
    P.scale(size / 256);
    for (const [x, y] of [[0, 0], [128, 27]]) {
      P.save(); P.translate(x, y);
      P.shape(BOOT, {stroke: '#ffffff', width: MAIN});
      P.restore();
    }
    return P.ops;
  }
  globalThis.BootsBadge = {icon, main: MAIN};
})();
