// Erzeugt QR-Codes (SVG für die Folien, PNG für den Test) und prüft sie anschließend per Dekodierung.
import QRCode from 'qrcode';
import jsQR from 'jsqr';
import { PNG } from 'pngjs';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const out = join(here, '..', 'assets');
mkdirSync(out, { recursive: true });

const codes = {
  'qr-website': 'https://me.philiplorenz.com',
  'qr-linkedin': 'https://www.linkedin.com/in/philip-lorenz',
};

let failed = 0;
for (const [name, url] of Object.entries(codes)) {
  // Hoher Kontrast, Fehlerkorrektur M, vier Module Ruhezone
  const opts = { errorCorrectionLevel: 'M', margin: 4, color: { dark: '#0b2a4a', light: '#ffffff' } };
  writeFileSync(join(out, `${name}.svg`), await QRCode.toString(url, { ...opts, type: 'svg' }));
  const png = await QRCode.toBuffer(url, { ...opts, type: 'png', width: 600 });
  writeFileSync(join(out, `${name}.png`), png);

  // Validierung: PNG wieder dekodieren und mit der Soll-URL vergleichen
  const img = PNG.sync.read(png);
  const res = jsQR(new Uint8ClampedArray(img.data), img.width, img.height);
  const ok = res && res.data === url;
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${name}: ${res ? res.data : 'nicht dekodierbar'}`);
  if (!ok) failed++;
}
process.exit(failed ? 1 : 0);
