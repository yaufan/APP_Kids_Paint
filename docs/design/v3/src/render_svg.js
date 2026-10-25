// node render_svg.js in.svg out.png width height: one SVG to a PNG at 1x.
const { chromium } = require('playwright');
(async () => {
  const [inp, out, w, h] = process.argv.slice(2);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 1 });
  await page.goto('file://' + inp);
  await page.screenshot({ path: out });
  await browser.close();
})();
