const fs=require('node:fs');
const path=require('node:path');
const runtimeRoot=path.join(process.env.LOCALAPPDATA,'OpenAI/Codex/runtimes/cua_node');
const packagePath=fs.readdirSync(runtimeRoot).map(version=>path.join(runtimeRoot,version,'bin/node_modules/playwright-core')).find(candidate=>fs.existsSync(candidate));
if(!packagePath)throw new Error('Installed Codex Playwright runtime not found.');
const {chromium}=require(packagePath);
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true,args:['--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1050,height:710}});
 page.on('pageerror',error=>{throw error});
 await page.goto('file:///'+path.join(__dirname,'preview.html').replaceAll('\\','/'));
 await page.waitForFunction(()=>window.reviewReady===true);
 await page.locator('canvas').screenshot({path:path.join(__dirname,process.argv[2]||'round-1.png')});
 await page.screenshot({path:path.join(__dirname,'native-size-sample.png'),clip:{x:840,y:126,width:180,height:510}});
 fs.writeFileSync(path.join(__dirname,'geometry.json'),JSON.stringify(await page.evaluate(()=>window.reviewGeometry),null,2)+'\n');
 await browser.close();
})();
