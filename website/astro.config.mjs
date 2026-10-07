// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightLinksValidator from 'starlight-links-validator';

export default defineConfig({
  site: 'https://powershell.philiplorenz.com',
  integrations: [
    starlight({
      title: 'PowerShell in 3 Tagen',
      description:
        'Praxisnahe PowerShell-Schulung für Windows-Administratoren: drei Tage, ein echtes Lab, Übungen mit Lösungen.',
      defaultLocale: 'root',
      locales: { root: { label: 'Deutsch', lang: 'de' } },
      logo: { src: './src/assets/logo.svg', alt: 'PowerShell in 3 Tagen' },
      favicon: '/favicon.svg',
      customCss: ['./src/styles/custom.css'],
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/philiplorenz-code/powershell-kurs' },
      ],
      plugins: [starlightLinksValidator({ errorOnLocalLinks: false })],
      expressiveCode: {
        themes: ['github-dark-dimmed', 'github-light'],
        styleOverrides: { borderRadius: '0.5rem' },
      },
      sidebar: [
        { label: 'Start', link: '/' },
        {
          label: 'Kurs',
          items: [
            { label: 'Kursübersicht', slug: 'kurs' },
            { label: 'Für Teilnehmer', slug: 'kurs/teilnehmer' },
            { label: 'Umgang mit Übungen', slug: 'kurs/uebungen-und-ki' },
            { label: 'Lab-Umgebung', slug: 'kurs/lab' },
            { label: 'Lab selbst deployen', slug: 'kurs/lab-selbst-deployen' },
          ],
        },
        { label: 'Tag 1 · Fundament', collapsed: true, items: [{ autogenerate: { directory: 'tag-1' } }] },
        { label: 'Tag 2 · Logik & Administration', collapsed: true, items: [{ autogenerate: { directory: 'tag-2' } }] },
        { label: 'Tag 3 · Skripte & Praxis', collapsed: true, items: [{ autogenerate: { directory: 'tag-3' } }] },
        { label: 'Übungen', collapsed: true, items: [{ autogenerate: { directory: 'uebungen' } }] },
        { label: 'PowerShell + KI (optional)', collapsed: true, items: [{ autogenerate: { directory: 'ki' } }] },
        { label: 'Ressourcen', collapsed: true, items: [{ autogenerate: { directory: 'ressourcen' } }] },
      ],
    }),
  ],
});
