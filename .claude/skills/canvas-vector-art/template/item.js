// Template item. Copy into docs/design/<date>/<name>/ and replace draw().
// Local frame: origin = grip centre, functional head toward -y, ~200 units long.
(function () {
  const C = { ink: '#583f21', main: '#e8f0f2', mainDark: '#b3c6ce', grip: '#e2775c', gold: '#f2bb57' };
  const PALM = '#f5a25d';

  function draw(P, w) {
    const head = Pen.rrect(-20, -150, 40, 120, 16);
    P.shape(head, { fill: C.main });                                    // 1. fill
    P.shape(Pen.rrect(0, -150, 20, 120, 0), { fill: C.mainDark });     // 2. darker flat plane, no line
    P.shape(head, { stroke: C.ink, width: w });                         // 3. contour last
    P.shape(Pen.rrect(-10, -24, 20, 48, 7), { fill: C.grip, stroke: C.ink, width: w });
  }

  function icon(size) {
    const P = new Pen();
    P.translate(size / 2, size / 2); P.scale(size / 256); P.rotate(45); P.scale(1.1); P.translate(0, 62);
    draw(P, 10);
    return P.ops;
  }

  // Remove held() for stat-only gear (helmet, armor, gloves, boots, amulet).
  function held() {
    const P = new Pen();
    P.translate(160, 166); P.rotate(42); P.scale(0.82);   // right-paw socket; bow uses (94, 166)
    draw(P, 10);
    const palm = new Pen();
    palm.shape([['M', 150, 157], ['Q', 163, 156, 166, 166], ['Q', 166, 175, 155, 176], ['Q', 146, 170, 150, 157], ['Z']], { fill: PALM });
    return { weapon: P.ops, palm: palm.ops };
  }

  globalThis.Item = { draw, icon, held, colors: C };
})();
