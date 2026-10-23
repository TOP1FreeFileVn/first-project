const path = require('node:path');
const {chromium} = require('C:/Users/dangp/AppData/Local/OpenAI/Codex/runtimes/cua_node/b2c4f0c90eadfac4/bin/node_modules/playwright-core');
(async () => {
  const browser = await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
  const page = await browser.newPage({viewport:{width:920,height:510}});
  page.on('pageerror', error => {throw error;});
  await page.goto('file:///' + path.join(__dirname,'preview.html').replaceAll('\\','/'));
  await page.evaluate(async () => {await document.fonts.load('26px Game'); await document.fonts.ready;});
  await page.locator('canvas').screenshot({path:path.join(__dirname,process.argv[2] || 'round-1.png')});
  await browser.close();
})();
