const { chromium } = require('playwright');
const fs = require('fs'); const path = require('path');
const [svgPath, outDir] = process.argv.slice(2);
const svg = fs.readFileSync(svgPath, 'utf8');
const sizes = { 'mipmap-mdpi': 48, 'mipmap-hdpi': 72, 'mipmap-xhdpi': 96, 'mipmap-xxhdpi': 144, 'mipmap-xxxhdpi': 192 };
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage();
  for (const [dir, s] of Object.entries(sizes)) {
    await p.setViewportSize({ width: s, height: s });
    await p.setContent(`<html><body style="margin:0;background:transparent">${svg.replace(/width="512" height="512"/, `width="${s}" height="${s}"`)}</body></html>`);
    for (const name of ['ic_launcher.png', 'ic_launcher_round.png']) {
      fs.mkdirSync(path.join(outDir, dir), { recursive: true });
      await p.screenshot({ path: path.join(outDir, dir, name), omitBackground: true });
    }
  }
  await p.setViewportSize({ width: 512, height: 512 });
  await p.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);
  await p.screenshot({ path: path.join(process.argv[4], 'play-store-icon-512.png'), omitBackground: false });
  await b.close();
})();
