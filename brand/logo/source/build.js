// Generates the Amour Partage logo concept SVGs (text outlined to paths).
// Visual language follows the reference shot: aurora glow on near-black, golden-hour sand, script + editorial serif.
const fs = require('fs');
const path = require('path');
const opentype = require('opentype.js');

const OUT = process.argv[2];
fs.mkdirSync(OUT, { recursive: true });

const load = (pkg, file) => {
  const b = fs.readFileSync(path.join(__dirname, 'node_modules/@fontsource', pkg, 'files', file));
  return opentype.parse(b.buffer.slice(b.byteOffset, b.byteOffset + b.byteLength));
};
const script = load('pinyon-script', 'pinyon-script-latin-400-normal.woff');
const serif = load('instrument-serif', 'instrument-serif-latin-400-normal.woff');

const C = {
  night: '#0B0A0C',
  magenta: '#F27BEA', pink: '#FF3E9A', red: '#E8322E', coral: '#FF6A4D',
  white: '#FFFFFF', ink: '#141216',
};

// Heart centred near the origin: 104 wide, 92 tall.
const HEART = 'M0 40C-6 34-52 4-52-22C-52-40-39-52-24-52C-12-52-4-45 0-36C4-45 12-52 24-52C39-52 52-40 52-22C52 4 6 34 0 40Z';
const SPARKLE = (r) =>
  `M0 ${-r}C${r * 0.11} ${-r * 0.29} ${r * 0.29} ${-r * 0.11} ${r} 0C${r * 0.29} ${r * 0.11} ${r * 0.11} ${r * 0.29} 0 ${r}` +
  `C${-r * 0.11} ${r * 0.29} ${-r * 0.29} ${r * 0.11} ${-r} 0C${-r * 0.29} ${-r * 0.11} ${-r * 0.11} ${-r * 0.29} 0 ${-r}Z`;

const LEFT = 'translate(214 276) rotate(-12) scale(2)';
const RIGHT = 'translate(298 276) rotate(12) scale(2)';

// Two hearts overlap; the space they share glows white — "amour partagé".
function hearts(id) {
  return `
  <defs>
    <linearGradient id="${id}-a" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${C.magenta}"/><stop offset="1" stop-color="${C.pink}"/>
    </linearGradient>
    <linearGradient id="${id}-b" x1="1" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${C.coral}"/><stop offset="1" stop-color="${C.red}"/>
    </linearGradient>
    <radialGradient id="${id}-core" cx="0.5" cy="0.45" r="0.6">
      <stop offset="0" stop-color="${C.white}"/><stop offset="1" stop-color="#FFE3EE"/>
    </radialGradient>
    <clipPath id="${id}-clip"><path transform="${LEFT}" d="${HEART}"/></clipPath>
    <filter id="${id}-soft" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="22"/></filter>
  </defs>
  <g filter="url(#${id}-soft)" opacity="0.7">
    <path transform="${LEFT}" d="${HEART}" fill="${C.pink}"/>
    <path transform="${RIGHT}" d="${HEART}" fill="${C.red}"/>
  </g>
  <path transform="${LEFT}" d="${HEART}" fill="url(#${id}-a)"/>
  <path transform="${RIGHT}" d="${HEART}" fill="url(#${id}-b)"/>
  <g clip-path="url(#${id}-clip)"><path transform="${RIGHT}" d="${HEART}" fill="url(#${id}-core)"/></g>
  <path transform="translate(388 126)" d="${SPARKLE(28)}" fill="${C.white}"/>
  <path transform="translate(420 174)" d="${SPARKLE(11)}" fill="${C.white}" opacity="0.8"/>`;
}

// App-icon tile: near-black with an aurora bloom, like the dark onboarding screen.
function tile(id) {
  return `
  <defs>
    <filter id="${id}-aurora" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="48"/></filter>
    <filter id="${id}-grain"><feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" stitchTiles="stitch"/>
      <feColorMatrix values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 0.07 0"/></filter>
    <clipPath id="${id}-tile"><rect width="512" height="512" rx="112"/></clipPath>
  </defs>
  <g clip-path="url(#${id}-tile)">
    <rect width="512" height="512" fill="${C.night}"/>
    <g filter="url(#${id}-aurora)">
      <ellipse cx="170" cy="120" rx="170" ry="120" fill="${C.magenta}" opacity="0.75"/>
      <ellipse cx="360" cy="190" rx="170" ry="130" fill="${C.red}" opacity="0.7"/>
      <ellipse cx="250" cy="250" rx="120" ry="90" fill="${C.pink}" opacity="0.6"/>
    </g>
    <rect width="512" height="512" filter="url(#${id}-grain)"/>
  </g>`;
}

function glyphPath(font, text, x, y, size) {
  let d = '';
  let cx = x;
  const glyphs = [...text].map((ch) => font.charToGlyph(ch));
  glyphs.forEach((g, i) => {
    d += g.getPath(cx, y, size).toPathData(2);
    cx += g.advanceWidth * (size / font.unitsPerEm);
    if (i < glyphs.length - 1) cx += font.getKerningValue(g, glyphs[i + 1]) * (size / font.unitsPerEm);
  });
  return { d, width: cx - x };
}

// Wordmark: "Amour" in script (the accent colour, like "you" in the shot) + "Partage" in the editorial serif.
function lockup(theme) {
  const dark = theme === 'dark';
  const amour = glyphPath(script, 'Amour', 0, 0, 132);
  const partage = glyphPath(serif, 'Partage', 0, 0, 118);
  const icon = 168;
  const textX = icon + 36;
  const gap = 22;
  const width = Math.ceil(textX + amour.width + gap + partage.width + 32);
  const height = 220;
  const baseline = 146;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" width="${width}" height="${height}">
  <title>Amour Partage</title>
  <desc>Two overlapping hearts; the space they share glows white. The sparkle marks the AI privacy layer.</desc>
  <defs>
    <linearGradient id="word-${theme}" x1="0" y1="0" x2="${amour.width}" y2="0" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="${C.coral}"/><stop offset="1" stop-color="${C.pink}"/>
    </linearGradient>
  </defs>
  ${dark ? `<rect width="100%" height="100%" fill="${C.night}"/>` : ''}
  <svg x="0" y="${(height - icon) / 2}" width="${icon}" height="${icon}" viewBox="0 0 512 512">${tile('lk-' + theme)}${hearts('lk-' + theme)}</svg>
  <path transform="translate(${textX} ${baseline})" d="${amour.d}" fill="url(#word-${theme})"/>
  <path transform="translate(${textX + amour.width + gap} ${baseline})" d="${partage.d}" fill="${dark ? C.white : C.ink}"/>
</svg>
`;
}

const icon = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <title>Amour Partage app icon</title>${tile('ic')}${hearts('ic')}
</svg>
`;
const mark = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="80 60 380 380" width="380" height="380">
  <title>Amour Partage mark</title>${hearts('mk')}
</svg>
`;

fs.writeFileSync(path.join(OUT, 'amour-partage-icon.svg'), icon);
fs.writeFileSync(path.join(OUT, 'amour-partage-mark.svg'), mark);
fs.writeFileSync(path.join(OUT, 'amour-partage-lockup-light.svg'), lockup('light'));
fs.writeFileSync(path.join(OUT, 'amour-partage-lockup-dark.svg'), lockup('dark'));
console.log('wrote', fs.readdirSync(OUT));
