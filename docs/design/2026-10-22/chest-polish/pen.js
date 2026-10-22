// Records shapes once, then plays them back on a canvas (fast preview) or as SVG
// (the deliverable). Both use the same absolute path data, so the preview and the
// exported SVG cannot drift apart. Works as a classic browser script and under Node.
(function () {
  const f = (n) => +n.toFixed(2);

  class Pen {
    constructor() { this.ops = []; this.m = [1, 0, 0, 1, 0, 0]; this.stack = []; }
    save() { this.stack.push(this.m.slice()); }
    restore() { this.m = this.stack.pop(); }
    transform(a, b, c, d, e, g) {
      const m = this.m;
      this.m = [m[0] * a + m[2] * b, m[1] * a + m[3] * b, m[0] * c + m[2] * d,
        m[1] * c + m[3] * d, m[0] * e + m[2] * g + m[4], m[1] * e + m[3] * g + m[5]];
    }
    translate(x, y) { this.transform(1, 0, 0, 1, x, y); }
    rotate(deg) { const r = deg * Math.PI / 180; this.transform(Math.cos(r), Math.sin(r), -Math.sin(r), Math.cos(r), 0, 0); }
    scale(k) { this.transform(k, 0, 0, k, 0, 0); }
    get k() { return Math.hypot(this.m[0], this.m[1]); }
    pt(x, y) { const m = this.m; return [f(m[0] * x + m[2] * y + m[4]), f(m[1] * x + m[3] * y + m[5])]; }

    // cmds: [['M',x,y],['L',x,y],['Q',cx,cy,x,y],['C',c1x,c1y,c2x,c2y,x,y],['Z']] in local units.
    d(cmds) {
      return cmds.map(([op, ...a]) => {
        const out = [];
        for (let i = 0; i < a.length; i += 2) out.push(...this.pt(a[i], a[i + 1]));
        return op + out.join(' ');
      }).join(' ');
    }
    // fill: colour or null; stroke: colour or null; width in local units (scaled with the pen).
    shape(cmds, { fill = null, stroke = null, width = 0 } = {}) {
      this.ops.push({ d: this.d(cmds), fill, stroke, width: f(width * this.k) });
    }
  }

  Pen.circle = (cx, cy, r) => {
    const c = r * 0.5523;
    return [['M', cx, cy - r], ['C', cx + c, cy - r, cx + r, cy - c, cx + r, cy],
      ['C', cx + r, cy + c, cx + c, cy + r, cx, cy + r], ['C', cx - c, cy + r, cx - r, cy + c, cx - r, cy],
      ['C', cx - r, cy - c, cx - c, cy - r, cx, cy - r], ['Z']];
  };
  Pen.rrect = (x, y, w, h, r) => [['M', x + r, y], ['L', x + w - r, y], ['Q', x + w, y, x + w, y + r],
    ['L', x + w, y + h - r], ['Q', x + w, y + h, x + w - r, y + h], ['L', x + r, y + h],
    ['Q', x, y + h, x, y + h - r], ['L', x, y + r], ['Q', x, y, x + r, y], ['Z']];

  Pen.toCanvas = (ops, ctx) => {
    ctx.lineJoin = 'round'; ctx.lineCap = 'round';
    for (const o of ops) {
      const p = new Path2D(o.d);
      if (o.fill) { ctx.fillStyle = o.fill; ctx.fill(p); }
      if (o.stroke && o.width) { ctx.strokeStyle = o.stroke; ctx.lineWidth = o.width; ctx.stroke(p); }
    }
  };
  Pen.toSvgBody = (ops) => ops.map((o) => `<path d="${o.d}" fill="${o.fill || 'none'}"` +
    (o.stroke && o.width ? ` stroke="${o.stroke}" stroke-width="${o.width}" stroke-linejoin="round" stroke-linecap="round"` : '') +
    ' />').join('\n');
  Pen.toSvg = (ops, w, h, extra = '') =>
    `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">\n${extra}${Pen.toSvgBody(ops)}\n</svg>\n`;

  globalThis.Pen = Pen;
})();
