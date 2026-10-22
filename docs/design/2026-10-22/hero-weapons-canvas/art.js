// Shared fit/pose definitions for the Canvas review and native SVG exports.
(function () {
  const definitions={
    bow:{api:WeaponBow,title:'CUNG',old:'cung',iconAngle:-135,hand:'left',pose:{angle:-10,scale:.65}},
    staff:{api:WeaponStaff,title:'TRƯỢNG',old:'gay_phep',iconAngle:45,hand:'right',pose:{angle:32,scale:.76}},
    axe:{api:WeaponAxe,title:'RÌU',old:'riu',iconAngle:45,hand:'right',pose:{angle:28,scale:.60}},
    katana:{api:WeaponKatana,title:'KATANA',old:'katana',iconAngle:45,hand:'right',pose:{angle:32,scale:.76}},
  };
  // Sample the actual path curves to fit geometry, rather than a rotated empty
  // source rectangle. Widths are compensated after this uniform fit.
  function bounds(ops) {
    let loX=Infinity,loY=Infinity,hiX=-Infinity,hiY=-Infinity;
    function add(x,y){loX=Math.min(loX,x);loY=Math.min(loY,y);hiX=Math.max(hiX,x);hiY=Math.max(hiY,y);}
    for(const op of ops){
      let x=0,y=0,sx=0,sy=0;
      for(const match of op.d.matchAll(/([MLQCZ])([^MLQCZ]*)/gi)){
        const kind=match[1].toUpperCase(),a=(match[2].match(/-?\d+(?:\.\d+)?/g)||[]).map(Number);
        if(kind==='M'||kind==='L'){[x,y]=a;add(x,y);if(kind==='M'){sx=x;sy=y;}}
        else if(kind==='Z'){x=sx;y=sy;add(x,y);}
        else {
          const start=[x,y];
          for(let i=1;i<=24;i++){const t=i/24,u=1-t;
            if(kind==='Q')add(u*u*start[0]+2*u*t*a[0]+t*t*a[2],u*u*start[1]+2*u*t*a[1]+t*t*a[3]);
            else add(u*u*u*start[0]+3*u*u*t*a[0]+3*u*t*t*a[2]+t*t*t*a[4],u*u*u*start[1]+3*u*u*t*a[1]+3*u*t*t*a[3]+t*t*t*a[5]);
          }
          [x,y]=a.slice(-2);
        }
      }
    }
    return {x:loX,y:loY,width:hiX-loX,height:hiY-loY,cx:(loX+hiX)/2,cy:(loY+hiY)/2};
  }
  function fit(slug){
    const d=definitions[slug],P=new Pen();P.rotate(d.iconAngle);
    d.api.draw(P,{main:0,secondary:0,string:0});
    const b=bounds(P.ops),s=195/Math.max(b.width,b.height);
    return {...b,scale:s,angle:d.iconAngle};
  }
  function icon(slug,size,roles=false){
    const d=definitions[slug],f=fit(slug),P=new Pen();
    P.scale(size/256);P.translate(128,128);P.translate(-f.cx*f.scale,-f.cy*f.scale);P.scale(f.scale);P.rotate(f.angle);
    d.api.draw(P,{main:13/f.scale,secondary:6.5/f.scale,string:4.4/f.scale,roles});
    return P.ops;
  }
  function held(slug,roles=false){
    const d=definitions[slug],P=new Pen(),socket=d.hand==='left'?[94,166]:[160,166],s=d.pose.scale;
    P.translate(...socket);P.rotate(d.pose.angle);P.scale(s);
    d.api.draw(P,{main:9/s,secondary:4.5/s,string:3/s,roles});
    const palm=new Pen(),[x,y]=socket;
    palm.shape([['M',x-9,y],['C',x-9,y-13,x+9,y-13,x+9,y],['C',x+9,y+13,x-9,y+13,x-9,y],['Z']],{fill:'#f5a25d'});
    return {weapon:P.ops,palm:palm.ops,socket};
  }
  globalThis.HeroWeaponArt={definitions,icon,held,fit,bounds};
})();
