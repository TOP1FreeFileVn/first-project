const fs=require('fs'),path=require('path');
const {chromium}=require('C:/Users/dangp/AppData/Local/OpenAI/Codex/runtimes/cua_node/b2c4f0c90eadfac4/bin/node_modules/playwright-core');
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
 const page=await browser.newPage({viewport:{width:710,height:350},deviceScaleFactor:2});const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto('file:///'+path.join(__dirname,'canvas.html').replaceAll('\\','/'));await page.evaluate(()=>document.fonts.ready);
 await page.screenshot({path:path.join(__dirname,process.argv[2]||'round-1.png')});
 const report=await page.evaluate(()=>({broken:[...document.images].filter(i=>!i.complete||!i.naturalWidth).length,overflow:document.documentElement.scrollWidth>innerWidth}));
 fs.writeFileSync(path.join(__dirname,'canvas-review.json'),JSON.stringify({errors,...report},null,2));console.log(JSON.stringify({errors,...report}));await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
