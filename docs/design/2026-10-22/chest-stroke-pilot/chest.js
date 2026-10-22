// Chest proposal: one path list for canvas review and SVG delivery.
// Local origin is the centre of the fixed rear seam; the lid alone pivots here.
(function () {
  const C = {ink:'#583f21', wood:'#eca966', end:'#d88f4f', grain:'#b87941',
    brass:'#f3c56b', brassInk:'#ba853c', inside:'#956337', cavity:'#704c2c'};
  const MAIN = 9;
  function chest(P, open = 0, small = false) {
    const body = [['M',-104,0],['L',104,0],['L',104,65],['Q',104,88,82,88],
      ['L',-82,88],['Q',-104,88,-104,65],['Z']];
    const lid = [['M',-104,0],['L',-104,-32],['Q',-104,-42,-95,-47],['L',-80,-58],
      ['Q',-75,-62,-68,-62],['L',68,-62],['Q',75,-62,80,-58],['L',95,-47],
      ['Q',104,-42,104,-32],['L',104,0],['Z']];
    // The cavity is an exposed opening, so its border keeps main ink.
    if (open > 0) P.shape(Pen.rrect(-104,-18,208,37,13),{fill:C.cavity,stroke:C.ink,width:MAIN});
    P.shape(body,{fill:C.wood});
    // A separate end-board is a broad material plane, not a darker outline.
    P.shape([['M',77,0],['L',104,0],['L',104,65],['Q',104,88,82,88],['L',77,88],['Z']],{fill:C.end});
    // Brass corner shoes: broad unlined fills; a quiet contact edge explains joinery.
    for (const side of [-1,1]) {
      P.save(); P.transform(side,0,0,1,0,0);
      P.shape([['M',82,49],['L',104,49],['L',104,65],['Q',104,88,82,88],['L',65,88],
        ['L',65,70],['Q',65,65,70,65],['L',82,65],['Z']],{fill:C.brass});
      if(!small) {
        P.shape([['M',84,50],['L',84,65],['Q',84,68,80,68],['L',68,68]],{stroke:C.brassInk,width:3});
        P.shape(Pen.circle(94,60,3.5),{fill:C.brassInk});
      }
      P.restore();
    }
    if(!small) {
      P.shape([['M',-78,33],['Q',-59,29,-40,33]],{stroke:C.grain,width:3});
      P.shape([['M',37,54],['Q',54,58,72,54]],{stroke:C.grain,width:3});
    }
    // No top edge here: the closed lid supplies the shared seam once.
    P.shape([['M',-104,0],['L',-104,65],['Q',-104,88,-82,88],['L',82,88],
      ['Q',104,88,104,65],['L',104,0]],{stroke:C.ink,width:MAIN});
    if(open>0) P.shape([['M',-101,0],['L',101,0]],{stroke:C.ink,width:MAIN});
    P.save();
    P.translate(12*open,-53*open); P.rotate(-15*open);
    P.shape(lid,{fill:C.wood});
    for(const side of [-1,1]) {
      P.save(); P.transform(side,0,0,1,0,0);
      P.shape([['M',72,-61],['Q',77,-61,80,-58],['L',95,-47],['Q',104,-42,104,-32],
        ['L',104,-4],['L',84,-4],['L',84,-31],['Q',84,-34,81,-37],['L',66,-49],['Z']],{fill:C.brass});
      if(!small) P.shape([['M',84,-6],['L',84,-30],['Q',84,-36,78,-40]],{stroke:C.brassInk,width:3});
      P.restore();
    }
    P.shape(lid,{stroke:C.ink,width:MAIN});
    if(!small) P.shape([['M',-47,-36],['Q',-26,-39,-7,-36]],{stroke:C.grain,width:3});
    P.restore();
    // A cat-head latch is a real foreground shape, so its silhouette is main ink.
    // Its broad fill remains readable at reward-symbol size.
    const latch = [['M',-23,13],['L',-23,-12],['Q',-23,-19,-17,-15],['L',-7,-8],
      ['Q',0,-10,7,-8],['L',17,-15],['Q',23,-19,23,-12],['L',23,13],
      ['Q',23,31,0,31],['Q',-23,31,-23,13],['Z']];
    P.shape(latch,{fill:C.brass,stroke:C.ink,width:MAIN});
    P.shape(Pen.circle(0,7,5.5),{fill:C.ink});
    P.shape([['M',-3,10],['L',3,10],['L',4,19],['L',-4,19],['Z']],{fill:C.ink});
  }
  function icon(size, open = 0, detail = true) {
    const P=new Pen(); P.translate(size/2,size*(0.48+0.10*open)); P.scale(size/256);
    chest(P,open,!detail || size<48); return P.ops;
  }
  globalThis.ChestPilot={chest,icon,colors:C,mainWidth:MAIN};
})();
