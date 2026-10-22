// Gear proposals D/E/F, in the shared 128 px art frame, centered at (0,0).
// Root's combined Canvas preview and SVG exporter both replay these same paths.
(function () {
  const MAIN = 3.2;
  const SECONDARY = 1.9;
  const INK = '#583f21';
  const SEAM = '#9b784b';
  const ROOT = 36.5, SHOULDER = 43, OUTER = 54, TEETH = 8;

  const polar = (angle, radius) => {
    const a = angle * Math.PI / 180;
    return [Math.cos(a) * radius, Math.sin(a) * radius];
  };
  // Lateral/radial coordinates of a tooth, with lateral increasing clockwise.
  const toothPoint = (angle, lateral, radial) => {
    const a = angle * Math.PI / 180;
    return [Math.cos(a) * radial - Math.sin(a) * lateral,
      Math.sin(a) * radial + Math.cos(a) * lateral];
  };
  const command = (op, ...points) => [op, ...points.flat()];
  const contour = (P, commands, fill) => P.shape(commands, {
    fill: fill || '#ead5ac', stroke: INK, width: MAIN,
  });

  // Two ledges on each die-cut tab, rather than one ordinary block tooth.
  function carton(P, fill) {
    const shape = [];
    for (let i = 0; i < TEETH; i++) {
      const a = -90 + i * 45;
      const points = [
        polar(a - 22.5, ROOT), polar(a - 15.5, ROOT),
        toothPoint(a, -11.5, SHOULDER), toothPoint(a, -7.8, SHOULDER),
        toothPoint(a, -7.8, OUTER - 0.57), toothPoint(a, 7.8, OUTER - 0.57),
        toothPoint(a, 7.8, SHOULDER), toothPoint(a, 11.5, SHOULDER),
        polar(a + 15.5, ROOT), polar(a + 22.5, ROOT),
      ];
      points.forEach((point,j) => shape.push(command(i === 0 && j === 0 ? 'M' : 'L',point)));
    }
    shape.push(['Z']);
    contour(P, shape, fill);
    // Functional folds live on the tabs; the cat/progress area stays unmarked.
    for (let i = 0; i < TEETH; i++) {
      const a = -90 + i * 45;
      P.shape([command('M',toothPoint(a,-4.7,44.7)), command('L',toothPoint(a,4.7,44.7))],
        {stroke:SEAM,width:SECONDARY});
    }
  }

  // A broad, softened mechanical tooth with genuine see-through rim windows.
  function windowRim(P, fill) {
    const shape = [];
    for (let i = 0; i < TEETH; i++) {
      const a = -90 + i * 45;
      if (i === 0) shape.push(command('M',polar(a - 22.5,ROOT)));
      shape.push(command('L',polar(a - 16,ROOT)));
      shape.push(command('L',toothPoint(a,-11.5,SHOULDER)));
      shape.push(command('L',toothPoint(a,-11.5,49.7)));
      shape.push(command('Q',toothPoint(a,-11.5,52.7),toothPoint(a,-8.5,52.7)));
      shape.push(command('L',toothPoint(a,8.5,52.7)));
      shape.push(command('Q',toothPoint(a,11.5,52.7),toothPoint(a,11.5,49.7)));
      shape.push(command('L',toothPoint(a,11.5,SHOULDER)));
      shape.push(command('L',polar(a + 16,ROOT)));
      shape.push(command('L',polar(a + 22.5,ROOT)));
    }
    shape.push(['Z']);
    // Each elliptical subpath winds opposite the exterior (nonzero-fill hole).
    // Radial extent35..42, tangential width12, at each diagonal tooth's root.
    const K = .5523, r = 38.5, halfT = 6, halfR = 3.5;
    for (const a of [-45,45,135,225]) {
      const p = (t, radial) => toothPoint(a,t,radial);
      shape.push(command('M',p(0,r-halfR)));
      shape.push(command('C',p(halfT*K,r-halfR),p(halfT,r-halfR*K),p(halfT,r)));
      shape.push(command('C',p(halfT,r+halfR*K),p(halfT*K,r+halfR),p(0,r+halfR)));
      shape.push(command('C',p(-halfT*K,r+halfR),p(-halfT,r+halfR*K),p(-halfT,r)));
      shape.push(command('C',p(-halfT,r-halfR*K),p(-halfT*K,r-halfR),p(0,r-halfR)));
      shape.push(['Z']);
    }
    // All hole boundaries are structural, so they use MAIN, not a decorative line.
    contour(P,shape,fill);
  }

  // Eight capsule-ended lobes, with broad rounded U valleys between them.
  function roundTeeth(P, fill) {
    const shape = [];
    for (let i = 0; i < TEETH; i++) {
      const a = -90 + i * 45;
      const p = (t,r) => toothPoint(a,t,r);
      if (i === 0) shape.push(command('M',polar(a-22.5,ROOT)));
      shape.push(command('C',polar(a-16.5,ROOT),p(-10.5,39.5),p(-10.5,43.5)));
      shape.push(command('C',p(-10.5,49.3),p(-5.8,OUTER),p(0,OUTER)));
      shape.push(command('C',p(5.8,OUTER),p(10.5,49.3),p(10.5,43.5)));
      shape.push(command('C',p(10.5,39.5),polar(a+16.5,ROOT),polar(a+22.5,ROOT)));
    }
    shape.push(['Z']);
    contour(P,shape,fill);
  }

  globalThis.GearDetail = {
    D:{title:'Carton bế',subtitle:'Răng hai bậc như tai bìa gấp; lòng trơn',draw:carton},
    E:{title:'Vòng có khe',subtitle:'Răng dày, bốn khe xuyên thật ở vành chéo',draw:windowRim},
    F:{title:'Răng tròn',subtitle:'Đầu răng viên nhộng, hõm chữ U mềm',draw:roundTeeth},
  };
})();
