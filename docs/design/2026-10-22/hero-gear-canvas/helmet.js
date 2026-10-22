// Stat-only open steel helmet, authored once for Canvas + SVG.
(function () {
  const colors = {
    ink: '#583f21', steel: '#d9e0e8', steelPlane: '#a8b4c7',
    secondary: '#9b7f58',
  };
  const strokeProfiles = { main: 11.35, secondary: 7.41 };
  const BODY = [
    ['M', 31, 147], ['Q', 24, 114, 45, 87],
    ['L', 45, 43], ['Q', 45, 32, 56, 38], ['L', 85, 59],
    ['Q', 128, 42, 171, 59], ['L', 200, 38], ['Q', 211, 32, 211, 43],
    ['L', 211, 87], ['Q', 232, 114, 225, 147],
    ['L', 225, 188], ['Q', 225, 204, 211, 208], ['L', 195, 213],
    ['Q', 185, 216, 183, 205], ['L', 180, 143],
    ['Q', 128, 125, 76, 143], ['L', 73, 205],
    ['Q', 71, 216, 61, 213], ['L', 45, 208],
    ['Q', 31, 204, 31, 188], ['Z'],
  ];
  function draw(P, roles = false) {
    const main = roles ? '#d45d46' : colors.ink;
    const secondary = roles ? '#168c91' : colors.secondary;
    P.shape(BODY, { fill: colors.steel });
    // Broad lower protection band, not a stroked ornament or lighting effect.
    P.shape([
      ['M', 31, 147], ['Q', 128, 86, 225, 147], ['L', 225, 188],
      ['Q', 225, 204, 211, 208], ['L', 195, 213],
      ['Q', 185, 216, 183, 205], ['L', 180, 143],
      ['Q', 128, 125, 76, 143], ['L', 73, 205],
      ['Q', 71, 216, 61, 213], ['L', 45, 208],
      ['Q', 31, 204, 31, 188], ['Z'],
    ], { fill: colors.steelPlane });
    // Ear cups reuse the same material colour, with no extra ink ring.
    for (const mirrored of [false, true]) {
      P.save();
      if (mirrored) { P.translate(256, 0); P.transform(-1, 0, 0, 1, 0, 0); }
      P.shape([['M', 58, 53], ['L', 76, 66], ['Q', 65, 74, 58, 84], ['Z']],
        { fill: colors.steelPlane });
      P.restore();
    }
    // One subordinate join between the two crown plates, clear of the brow.
    P.shape([['M', 128, 66], ['L', 128, 96]],
      { stroke: secondary, width: strokeProfiles.secondary });
    // Includes the open face edge; background openings retain main weight.
    P.shape(BODY, { stroke: main, width: strokeProfiles.main });
    return P.ops;
  }
  function icon(size, roles = false) {
    const P = new Pen();
    P.scale(size / 256);
    return draw(P, roles);
  }
  globalThis.GearHelmet = { icon, draw, colors, strokeProfiles };
})();
