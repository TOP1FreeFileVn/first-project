const fs=require('fs'),path=require('path'),vm=require('vm');
const root=path.resolve(__dirname,'../../../..');
for(const file of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),path.join(__dirname,'icons.js')])vm.runInThisContext(fs.readFileSync(file,'utf8'));
fs.mkdirSync(path.join(__dirname,'svg'),{recursive:true});
for(const name of Object.keys(PowerIconOptions.draw)){
 const pen=new Pen();PowerIconOptions.draw[name](pen);
 for(const size of [21,24,32,96]){
  const svg=Pen.toSvg(pen.ops,96,96).replace('width="96" height="96"',`width="${size}" height="${size}"`);
  fs.writeFileSync(path.join(__dirname,'svg',`power-${name}-${size}.svg`),svg);
 }
}
console.log('Exported two combat-power candidates at 21,24,32,96px.');
