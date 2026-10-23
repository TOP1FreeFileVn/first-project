const fs=require('fs');
const path=require('path');
const {chromium}=require('C:/Users/dangp/AppData/Local/OpenAI/Codex/runtimes/cua_node/b2c4f0c90eadfac4/bin/node_modules/playwright-core');
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
 const page=await browser.newPage({viewport:{width:760,height:880},deviceScaleFactor:2});
 const errors=[];page.on('pageerror',e=>{errors.push(e.message);console.error('PAGE_ERROR: '+e.message)});
 await page.goto('file:///'+path.join(__dirname,'preview.html').replaceAll('\\','/'));
 const frame=page.frames().find(f=>f!==page.mainFrame());
 await frame.waitForSelector('.eq-phone');
 await frame.evaluate(()=>document.fonts.ready);
 const results={errors,variants:[],interactions:[],responsive:[]};
 for(const design of ['paperboard']){
  const phone=frame.locator(`.eq-phone[data-design="${design}"]`);
  await phone.screenshot({path:path.join(__dirname,design+'.png')});
  results.variants.push(await phone.evaluate(el=>({design:el.dataset.design,width:el.clientWidth,height:el.clientHeight,bag:el.querySelector('.eq-grid').clientHeight,card:el.querySelector('.eq-grid .eq-gear').clientWidth,overflow:el.scrollWidth>el.clientWidth,nativeNavPresent:!!el.querySelector('.eq-native-bottom>img'),nativeNavTabs:el.querySelectorAll('.eq-native-hit').length,headerWidth:el.querySelector('.eq-game-header').clientWidth,brokenImages:[...el.querySelectorAll('img')].filter(i=>i.getClientRects().length&&(!i.complete||!i.naturalWidth)).length})));
  const first=phone.locator('.eq-grid .eq-gear').first();await first.click();
  const opened=await phone.locator('.eq-overlay').isVisible();
  await phone.screenshot({path:path.join(__dirname,'paperboard-detail.png')});
  await phone.locator('[data-action="equip"]').click();
  console.log('EQUIP_RESULT',await phone.locator('.eq-overlay').getAttribute('hidden'),JSON.stringify(errors));
  const changed=await phone.locator('.eq-current-skill').textContent();
  await phone.locator('[data-filter="weapon"]').click();
  const filtered=await phone.locator('.eq-grid .eq-gear').count();
  await phone.locator('[data-filter="all"]').click();
  await phone.locator('.eq-sort').click();
  results.interactions.push({design,opened,equippedSkill:changed,weaponFilterCount:filtered,sortLabel:await phone.locator('.eq-sort').textContent()});
 }
 for(const width of [320,360,450,736]){
  await page.setViewportSize({width,height:850});
  await page.waitForTimeout(180);
  for(const design of ['paperboard']){
   results.responsive.push(await frame.locator(`.eq-phone[data-design="${design}"]`).evaluate(el=>({design:el.dataset.design,hostWidth:innerWidth,phoneWidth:el.clientWidth,overflow:document.documentElement.scrollWidth>innerWidth,gearCount:el.querySelectorAll('.eq-doll .eq-gear').length,navVisible:el.querySelector('.eq-native-bottom').getBoundingClientRect().bottom<=el.getBoundingClientRect().bottom})));
  }
 }
 fs.writeFileSync(path.join(__dirname,'review.json'),JSON.stringify(results,null,2));
 console.log(JSON.stringify(results));await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
