// Renders a preview sheet of the logo concept: icon sizes, splash on both themes, lockups.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const dir = process.argv[2];
const out = process.argv[3];
const svg = (f, size) => {
  const s = fs.readFileSync(path.join(dir, f), 'utf8');
  return size ? s.replace(/width="\d+" height="\d+"/, `width="${size}" height="${size}"`) : s;
};

const html = `<html><body style="margin:0;background:#EDE6DD;font-family:sans-serif">
<div style="display:flex;gap:36px;align-items:center;padding:40px 40px 24px">
  ${svg('amour-partage-icon.svg', 220)}
  ${svg('amour-partage-icon.svg', 96)}
  ${svg('amour-partage-icon.svg', 48)}
  <div style="width:150px;height:150px;border-radius:50%;overflow:hidden">${svg('amour-partage-icon.svg', 150)}</div>
  <div style="width:150px;height:150px;border-radius:24px;display:grid;place-items:center;
    background:linear-gradient(170deg,#F6E25A 0%,#E9D6BC 35%,#C49A6C 100%)">${svg('amour-partage-mark.svg', 120)}</div>
</div>
<div style="padding:8px 40px">${svg('amour-partage-lockup-light.svg').replace(/width="(\d+)" height="(\d+)"/, (m, w, h) => `width="${w * 0.8}" height="${h * 0.8}"`)}</div>
<div style="padding:8px 40px 40px">${svg('amour-partage-lockup-dark.svg').replace(/width="(\d+)" height="(\d+)"/, (m, w, h) => `width="${w * 0.8}" height="${h * 0.8}"`)}</div>
</body></html>`;

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1000, height: 700 } });
  await page.setContent(html);
  await page.screenshot({ path: out, fullPage: true });
  await browser.close();
})();
