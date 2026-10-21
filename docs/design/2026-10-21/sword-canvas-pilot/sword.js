// Sword in the cat style: flat fills, one warm-brown contour, steel split into two
// unlined planes (accepted-spear treatment). Local origin = grip centre, tip toward -y.
(function () {
  const C = {
    ink: '#583f21', steel: '#e8f0f2', steelDark: '#b3c6ce',
    gold: '#f2bb57', goldDark: '#c98a35', leather: '#e2775c', wrap: '#a64d3c', gem: '#5fc4bd',
  };
  const PALM = '#f5a25d';

  function sword(P, w) {
    const { ink } = C;
    // Leaf blade: a little wider near the tip so it reads chunky and friendly.
    const blade = [['M', -18, -24], ['L', -24, -108], ['Q', -25, -136, 0, -158],
      ['Q', 25, -136, 24, -108], ['L', 18, -24], ['Z']];
    P.shape(blade, { fill: C.steel });
    P.shape([['M', 0, -158], ['Q', 25, -136, 24, -108], ['L', 18, -24], ['L', 0, -24], ['Z']], { fill: C.steelDark });
    P.shape(blade, { stroke: ink, width: w });

    // Grip: leather with two wraps, drawn before its own outline so caps stay inside.
    const grip = Pen.rrect(-11, -20, 22, 44, 7);
    P.shape(grip, { fill: C.leather });
    for (const y of [-3, 11]) P.shape([['M', -11, y + 5], ['L', 11, y - 5]], { stroke: C.wrap, width: w * 0.5 });
    P.shape(grip, { stroke: ink, width: w });

    // Round pommel with one rivet.
    P.shape(Pen.circle(0, 34, 13), { fill: C.gold, stroke: ink, width: w });
    P.shape(Pen.circle(0, 34, 4.5), { fill: C.goldDark });

    // Chunky bow-tie guard: one soft mass, lower half a darker flat gold plane (not a line).
    const guard = [['M', -38, -40], ['Q', -24, -36, -12, -38], ['L', 12, -38], ['Q', 24, -36, 38, -40],
      ['Q', 46, -40, 44, -30], ['Q', 42, -20, 34, -16], ['Q', 24, -18, 12, -16], ['L', -12, -16],
      ['Q', -24, -18, -34, -16], ['Q', -42, -20, -44, -30], ['Q', -46, -40, -38, -40], ['Z']];
    P.shape(guard, { fill: C.gold });
    P.shape([['M', -44, -27], ['Q', -42, -20, -34, -16], ['Q', -24, -18, -12, -16], ['L', 12, -16],
      ['Q', 24, -18, 34, -16], ['Q', 42, -20, 44, -27], ['Z']], { fill: C.goldDark });
    P.shape(guard, { stroke: ink, width: w });
    P.shape(Pen.circle(0, -27, 6.5), { fill: C.gem, stroke: ink, width: w * 0.5 });
  }

  // Standalone icon, square canvas.
  function icon(size) {
    const P = new Pen();
    P.translate(size / 2, size / 2); P.scale(size / 256); P.rotate(45); P.scale(1.12); P.translate(0, 62);
    sword(P, 10);
    return P.ops;
  }

  // Weapon layer on the fixed 256x240 hero canvas: grip centred on the right-paw socket.
  function held() {
    const P = new Pen();
    P.translate(160, 166); P.rotate(42); P.scale(0.82);
    sword(P, 10);
    // Palm: local ginger fill inside the paw's C so the grip shows above and below it.
    const palm = new Pen();
    palm.shape([['M', 150, 157], ['Q', 163, 156, 166, 166], ['Q', 166, 175, 155, 176], ['Q', 146, 170, 150, 157], ['Z']], { fill: PALM });
    return { weapon: P.ops, palm: palm.ops };
  }

  globalThis.SwordArt = { sword, icon, held, colors: C };
})();
