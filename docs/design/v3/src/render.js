// Renders html/<name>.html to screens/<name>.png at 2x (390 x 844 points).
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const root = path.resolve(__dirname, '..');
const names = process.argv.slice(2).length ? process.argv.slice(2)
  : fs.readdirSync(path.join(root, 'html')).filter(f => f.endsWith('.html')).map(f => f.slice(0, -5));
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  for (const n of names) {
    const big = n.startsWith('99');
    await page.setViewportSize(big ? { width: 860, height: 1420 } : { width: 390, height: 844 });
    await page.goto('file://' + path.join(root, 'html', n + '.html'), { waitUntil: 'load' });
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(150);
    await page.screenshot({ path: path.join(root, 'screens', n + '.png') });
    console.log(n);
  }
  await browser.close();
})();
