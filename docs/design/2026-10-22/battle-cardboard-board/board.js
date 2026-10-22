// Shared Canvas/SVG geometry for the shallow cardboard gear work tray.
// The complete 720 x 480 registration is placed at world (0, 720).
(function () {
  const C = {
    ink:'#583f21', seam:'#a57a48', board:'#e0b878', top:'#e8c080',
    side:'#cfa466', tape:'#f7dfad',
  };
  const MAIN = 4.6, SECONDARY = 2.6;
  // Keep the outer stroke inside the canvas while its visible edge reaches
  // both screen edges. Gear/cell registration and the inner deck stay fixed.
  const LEFT = MAIN / 2, RIGHT = 720 - MAIN / 2;
  const shape = (P, d, fill, stroke = null, width = 0) => P.shape(d,{fill,stroke,width});

  function draw(P) {
    // The backing is opaque over the complete former rounded board well.
    // Broad flat folds describe the tray; there is no cast shadow or inner UI frame.
    const contour = [
      ['M',LEFT+13,14],['L',RIGHT-13,14],['Q',RIGHT,14,RIGHT,27],
      ['L',RIGHT,460],['Q',RIGHT,474,RIGHT-14,474],['L',LEFT+14,474],
      ['Q',LEFT,474,LEFT,460],['L',LEFT,27],['Q',LEFT,14,LEFT+13,14],['Z'],
    ];
    shape(P,contour,C.board);
    shape(P,[['M',49,28],['L',671,28],['L',671,450],['L',49,450],['Z']],C.top);
    shape(P,[['M',LEFT,27],['L',49,28],['L',49,450],['L',LEFT,460],['Z']],C.side);
    shape(P,[['M',671,28],['L',RIGHT,27],['L',RIGHT,460],['L',671,450],['Z']],C.side);
    shape(P,[['M',LEFT,460],['L',49,450],['L',671,450],['L',RIGHT,460],['L',RIGHT,461],['Q',RIGHT,474,RIGHT-14,474],['L',LEFT+14,474],['Q',LEFT,474,LEFT,461],['Z']],C.board);

    // Material joins use a quiet crease, once each. The front edge stays low
    // enough not to cover a fourth-row gear or its drag destination.
    shape(P,[['M',49,34],['L',49,443]],null,C.seam,SECONDARY);
    shape(P,[['M',671,34],['L',671,443]],null,C.seam,SECONDARY);
    shape(P,[['M',57,450],['L',663,450]],null,C.seam,SECONDARY);

    // Two torn tape patches repeat the castle's construction language.
    shape(P,[['M',21,77],['L',48,77],['L',48,110],['L',43,107],['L',38,111],['L',33,108],['L',27,111],['L',21,108],['Z']],C.tape);
    shape(P,[['M',673,329],['L',699,329],['L',699,361],['L',694,358],['L',688,362],['L',683,359],['L',678,362],['L',673,359],['Z']],C.tape);
    shape(P,contour,null,C.ink,MAIN);
  }

  function layer() { const P = new Pen(); draw(P); return P.ops; }
  globalThis.CardboardBoard = {layer,colors:C,main:MAIN,secondary:SECONDARY,width:720,height:480};
})();
