const fs=require('fs'),path=require('path');
const {chromium}=require('C:/Users/dangp/AppData/Local/OpenAI/Codex/runtimes/cua_node/b2c4f0c90eadfac4/bin/node_modules/playwright-core');
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
 const page=await browser.newPage({viewport:{width:760,height:1010},deviceScaleFactor:2});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto('file:///'+path.join(__dirname,'preview.html').replaceAll('\\','/'));
 const frame=page.frames().find(f=>f!==page.mainFrame());await frame.waitForSelector('.eq-phone');await frame.evaluate(()=>document.fonts.ready);
 const report={errors,options:[]};
 for(const [i,name] of ['Xu dập bánh răng','Xu viền bánh răng','Cặp xu gear'].entries()){
  const phone=frame.locator(`[data-variant="${name}"] .eq-phone`);await phone.waitFor({state:'visible'});
  await frame.locator(`[data-variant="${name}"]`).screenshot({path:path.join(__dirname,['coin','gear','pair'][i]+'-context.png')});
  await phone.locator('.eq-top').screenshot({path:path.join(__dirname,['coin','gear','pair'][i]+'-header.png')});
  report.options.push(await phone.evaluate(el=>({icon:el.closest('[data-variant]').dataset.variant,goldLoaded:el.querySelector('.eq-gold-swatch').naturalWidth>0,gemLoaded:el.querySelector('.eq-diamond-swatch').naturalWidth>0,brokenImages:[...el.querySelectorAll('img')].filter(i=>i.getClientRects().length&&(!i.complete||!i.naturalWidth)).length,bottomTabs:el.querySelectorAll('.eq-native-hit').length,gearSlots:el.querySelectorAll('.eq-doll .eq-gear').length,overflow:el.scrollWidth>el.clientWidth})));
  if(i<2)await frame.locator('.viz-carousel-next').click();
 }
 await page.setViewportSize({width:340,height:1010});
 report.narrow=await frame.evaluate(()=>({viewport:innerWidth,scroll:document.documentElement.scrollWidth,phone:document.querySelector('[data-variant]:not([hidden]) .eq-phone').getBoundingClientRect().width}));
 fs.writeFileSync(path.join(__dirname,'review.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
