// Rear mechanism silhouettes only. The parent preview supplies cat, front crank
// and the shared output arm. Local origin is the rear/output axis at (0,0).
(function () {
  const INK = '#583f21', MAIN = 2.9;
  const BLUE = '#91aaae', LIGHT = '#adc6c7';
  const SECONDARY_INK = '#5e7c82', SECONDARY = 1.6;

  const polar = (angle, radius) => [Math.cos(angle)*radius,Math.sin(angle)*radius];
  const radial = (angle, lateral, length) => [
    Math.cos(angle)*length-Math.sin(angle)*lateral,
    Math.sin(angle)*length+Math.cos(angle)*lateral,
  ];
  const cmd = (op,...points) => [op,...points.flat()];
  const body = (P,path) => P.shape(path,{fill:BLUE,stroke:INK,width:MAIN});
  const rotating = (P,a,draw) => {P.save();P.rotate(a*180/Math.PI);draw();P.restore();};

  function threeLobes(P,a) {
    rotating(P,a,()=>{
      const path=[];
      // Deep concave roots distinguish this solid clover from a triangular cam.
      for(let i=0;i<3;i++) {
        const t=-Math.PI/2+i*Math.PI*2/3;
        if(!i) path.push(cmd('M',polar(t-Math.PI/3,15)));
        path.push(cmd('C',polar(t-38*Math.PI/180,14),polar(t-35*Math.PI/180,35),polar(t,36)));
        path.push(cmd('C',polar(t+35*Math.PI/180,35),polar(t+38*Math.PI/180,14),polar(t+Math.PI/3,15)));
      }
      path.push(['Z']);body(P,path);
    });
  }

  function broadDumbbell(P,a) {
    rotating(P,a,()=>{
      // Two broad counterweights are joined by one thick integral neck.
      body(P,[['M',-8,-8],['C',-13,-8,-11,-19,-21,-19],
        ['C',-31,-19,-36,-10,-36,0],['C',-36,10,-31,19,-21,19],
        ['C',-11,19,-13,8,-8,8],['L',8,8],
        ['C',13,8,11,19,21,19],['C',31,19,36,10,36,0],
        ['C',36,-10,31,-19,21,-19],['C',11,-19,13,-8,8,-8],['Z']]);
    });
  }

  function roundedTriangle(P,a) {
    rotating(P,a,()=>{
      const vertices=Array.from({length:3},(_,i)=>polar(-Math.PI/2+i*Math.PI*2/3,37));
      const cut=.13;
      const near=(v,toward)=>[v[0]+(toward[0]-v[0])*cut,v[1]+(toward[1]-v[1])*cut];
      const path=[cmd('M',near(vertices[0],vertices[2]))];
      for(let i=0;i<3;i++) {
        const v=vertices[i],next=vertices[(i+1)%3];
        path.push(cmd('Q',v,near(v,next)));
        path.push(cmd('L',near(next,v)));
      }
      path.push(['Z']);body(P,path);
    });
  }

  function softPaddles(P,a) {
    rotating(P,a,()=>{
      const path=[];
      // Four broad, swept fins form one rotor. Each tip is rounded and the
      // concave root curls toward the following fin, like a toy pinwheel.
      for(let i=0;i<4;i++) {
        const t=-Math.PI/2+i*Math.PI/2;
        const p=(l,r)=>radial(t,l,r);
        if(!i) path.push(cmd('M',polar(t-Math.PI/4,12)));
        path.push(cmd('C',p(-8,13),p(-14,23),p(-12,31)));
        path.push(cmd('Q',p(-11,36),p(-5,36)));
        path.push(cmd('C',p(7,36),p(15,25),p(10,20)));
        path.push(cmd('Q',p(4,15),polar(t+Math.PI/4,12)));
      }
      path.push(['Z']);body(P,path);
    });
  }

  // Keep the two-role profile explicit. These solid silhouettes need no surface
  // seams; LIGHT / SECONDARY are reserved rather than adding decorative lines.
  void LIGHT; void SECONDARY_INK; void SECONDARY;
  globalThis.MachineVariants ||= {};
  Object.assign(globalThis.MachineVariants,{
    A:{title:'Cam ba múi',idea:'Ba vai tròn lớn, hõm sâu; một khối cam đồ chơi quay sau mèo.',draw:threeLobes},
    B:{title:'Tạ đôi quay',idea:'Hai đối trọng mập nối bằng cổ liền; dáng hai đầu đối xứng dễ đọc.',draw:broadDumbbell},
    C:{title:'Cam tam giác bo',idea:'Tấm cam đặc ba góc bo, cạnh rộng; hình gọn và rõ chất cơ khí.',draw:roundedTriangle},
    D:{title:'Chong chóng mềm',idea:'Bốn cánh bè cong cùng chiều, đầu bo; máy đồ chơi vui và nhẹ.',draw:softPaddles},
  });
})();
