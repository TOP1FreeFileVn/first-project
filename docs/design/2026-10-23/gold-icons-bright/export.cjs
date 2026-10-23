const fs=require('fs'),path=require('path'),vm=require('vm');
const root=path.resolve(__dirname,'../../../..');
for(const file of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),path.join(__dirname,'icons.js')])vm.runInThisContext(fs.readFileSync(file,'utf8'));
fs.mkdirSync(path.join(__dirname,'svg'),{recursive:true});
for(const name of Object.keys(BrightGoldOptions.draw)){
 const pen=new Pen();BrightGoldOptions.draw[name](pen);
 for(const size of [24,32,96])fs.writeFileSync(path.join(__dirname,'svg',`gold-${name}-${size}.svg`),Pen.toSvg(pen.ops,96,96).replace('width="96" height="96"',`width="${size}" height="${size}"`));
}
console.log('Exported 3 bright gold variants at 24/32/96px.');
