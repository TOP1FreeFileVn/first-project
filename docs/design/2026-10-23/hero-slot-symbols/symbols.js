(function () {
  const INK = '#66766c';
  const line = (P, d) => P.shape(d, {stroke:INK, width:6});
  function weapon(P) {
    line(P,[['M',33,54],['L',64,23],['L',79,17],['L',73,32],['L',42,63]]);
    line(P,[['M',25,49],['L',47,71]]);
    line(P,[['M',29,60],['L',16,73],['Q',12,77,17,81],['Q',21,85,25,81],['L',38,68]]);
  }
  function helmet(P) {
    line(P,[['M',24,63],['L',24,46],['Q',24,22,48,22],['Q',72,22,72,46],
      ['L',72,63],['L',59,70],['L',59,51],['L',37,51],['L',37,70],['Z']]);
  }
  function armor(P) {
    line(P,[['M',35,24],['L',26,28],['L',17,45],['L',30,51],['L',30,76],
      ['L',66,76],['L',66,51],['L',79,45],['L',70,28],['L',61,24],
      ['Q',58,35,48,35],['Q',38,35,35,24],['Z']]);
  }
  function boots(P) {
    for (const x of [21,65]) line(P,[['M',x,23],['L',x+18,23],['L',x+18,73],
      ['L',x-10,73],['L',x-10,62],['Q',x-10,56,x,56],['Z']]);
  }
  globalThis.HeroSlotSymbols = {draw:{weapon,helmet,armor,boots},ink:INK};
})();
