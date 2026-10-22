// Template item. Copy into docs/design/<date>/<name>/ and replace draw().
// Local frame: origin = grip centre, functional head toward -y, ~200 units long.
(function () {
  const C = { ink: '#583f21', steel: '#e8f0f2', steelPlane: '#b3c6ce', grip: '#e2775c', gold: '#f2bb57' };
  const PALM = '#f5a25d';
  // Weights in fitted 256px artwork, BEFORE the final icon-resolution reduction.
  // 4px is only this demo's leather seam. Choose each item's secondary weight/ink
  // in its brief. Calibrate the icon profile beside the accepted sword in its slot.
  const STROKES = {
    held: { main: 9, secondary: 4, secondaryInk: '#a64d3c' },
    icon: { main: 9, secondary: 4, secondaryInk: '#a64d3c' },
  };
  const FIT = { held: 0.82, icon: 1.1 };

  function localStrokes(profile, fit) {
    return { ...profile, main: profile.main / fit, secondary: profile.secondary / fit };
  }

  function draw(P, lines) {
    // Back grip: fill, subordinate seam, then silhouette. The head occludes its top.
    const grip = Pen.rrect(-10, -37, 20, 61, 7);
    P.shape(grip, { fill: C.grip });
    for (const y of [-8, 8]) {
      P.shape([['M', -6, y + 3], ['L', 6, y - 3]], { stroke: lines.secondaryInk, width: lines.secondary });
    }
    P.shape(grip, { stroke: C.ink, width: lines.main });
    const head = Pen.rrect(-20, -150, 40, 120, 16);
    P.shape(head, { fill: C.steel });
    P.shape([['M', 0, -150], ['L', 4, -150], ['Q', 20, -150, 20, -134],
      ['L', 20, -46], ['Q', 20, -30, 4, -30], ['L', 0, -30], ['Z']], { fill: C.steelPlane });
    P.shape(head, { stroke: C.ink, width: lines.main });
  }

  function icon(size) {
    const P = new Pen();
    P.translate(size / 2, size / 2); P.scale(size / 256); P.rotate(45); P.scale(FIT.icon); P.translate(0, 62);
    draw(P, localStrokes(STROKES.icon, FIT.icon));
    return P.ops;
  }

  // Remove held() for active stat-only gear (helmet, armor, boots).
  function held() {
    const P = new Pen();
    P.translate(160, 166); P.rotate(42); P.scale(FIT.held);   // right-paw socket; bow uses (94, 166)
    draw(P, localStrokes(STROKES.held, FIT.held));
    const palm = new Pen();
    palm.shape([['M', 150, 157], ['Q', 163, 156, 166, 166], ['Q', 166, 175, 155, 176], ['Q', 146, 170, 150, 157], ['Z']], { fill: PALM });
    return { weapon: P.ops, palm: palm.ops };
  }

  globalThis.Item = { draw, icon, held, colors: C, strokeProfiles: STROKES };
})();
