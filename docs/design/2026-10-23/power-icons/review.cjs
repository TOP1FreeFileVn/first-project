const fs=require('fs'),path=require('path');
const {chromium}=require('C:/Users/dangp/AppData/Local/OpenAI/Codex/runtimes/cua_node/b2c4f0c90eadfac4/bin/node_modules/playwright-core');
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
 const page=await browser.newPage({viewport:{width:760,height:890},deviceScaleFactor:2});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto('file:///'+path.join(__dirname,'preview.html').replaceAll('\\','/'));
 const frame=page.frames().find(f=>f!==page.mainFrame());await frame.waitForSelector('.eq-phone');await frame.evaluate(()=>document.fonts.ready);
 const report={errors,options:[]};
 for(const name of ['Hai kiếm chéo']){
  const phone=frame.locator('.eq-phone');
  await phone.screenshot({path:path.join(__dirname,name==='Hai kiếm chéo'?'crossed-context.png':'fist-context.png')});
  report.options.push(await phone.evaluate(el=>({icon:'Hai kiếm chéo',svgIcon:el.querySelector('.eq-power img').src.startsWith('data:image/svg+xml'),brokenImages:[...el.querySelectorAll('img')].filter(i=>i.getClientRects().length&&(!i.complete||!i.naturalWidth)).length,bottomTabs:el.querySelectorAll('.eq-native-hit').length,gearSlots:el.querySelectorAll('.eq-doll .eq-gear').length,overflow:el.scrollWidth>el.clientWidth,plaqueText:getComputedStyle(el.querySelector('.eq-power')).color,plaqueFill:getComputedStyle(el.querySelector('.eq-power'),'::before').backgroundColor})));
  await phone.locator('.eq-center').screenshot({path:path.join(__dirname,'selected-contrast.png')});
 }
 fs.writeFileSync(path.join(__dirname,'review.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
