(function () {
  // A category glyph, not the detailed item: two same-facing, staggered boots.
  // Back-left sits high; front-right overlaps it. Resolve the hidden edge once.
  const MAIN = 16;
  const FRONT = [
    ['M', 137, 96], ['Q', 164, 88, 191, 96],
    ['L', 190, 115], ['L', 186, 122], ['L', 186, 194],
    ['Q', 186, 210, 171, 211], ['L', 119, 211],
    ['Q', 103, 210, 102, 196], ['L', 102, 186],
    ['Q', 103, 170, 125, 165], ['L', 136, 153],
    ['L', 138, 123], ['L', 134, 116], ['Z'],
  ];
  const BACK_VISIBLE = [
    ['M', 117, 143], ['L', 117, 94], ['L', 122, 86], ['L', 123, 67],
    ['Q', 96, 59, 69, 67], ['L', 66, 87], ['L', 70, 95],
    ['L', 67, 128], ['L', 57, 139], ['Q', 34, 144, 33, 160],
    ['L', 33, 170], ['Q', 34, 184, 51, 184], ['L', 81, 184],
  ];
  function icon(size) {
    const P = new Pen(); P.scale(size / 256);
    P.shape(BACK_VISIBLE, {stroke: '#ffffff', width: MAIN});
    P.shape(FRONT, {stroke: '#ffffff', width: MAIN});
    return P.ops;
  }
  globalThis.BootsBadge = {icon, main: MAIN};
})();
