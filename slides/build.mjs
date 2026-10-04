// Kopiert das Deck und reveal.js (ohne CDN, funktioniert offline) nach out/
import { cpSync, mkdirSync, rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const out = join(here, 'out');
rmSync(out, { recursive: true, force: true });
mkdirSync(join(out, 'vendor'), { recursive: true });
cpSync(join(here, 'index.html'), join(out, 'index.html'));
cpSync(join(here, 'theme.css'), join(out, 'theme.css'));
cpSync(join(here, 'node_modules/reveal.js/dist'), join(out, 'vendor/reveal'), { recursive: true });
cpSync(join(here, 'node_modules/reveal.js/plugin/highlight'), join(out, 'vendor/highlight'), { recursive: true });
cpSync(join(here, 'node_modules/reveal.js/plugin/notes'), join(out, 'vendor/notes'), { recursive: true });
console.log('slides ->', out);
