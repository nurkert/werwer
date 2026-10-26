import { readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { defineConfig } from 'astro/config';

import remarkRepoLinks from './src/lib/remark-repo-links.mjs';

const repoRoot = fileURLToPath(new URL('..', import.meta.url));

// The planning documents moved from /docs/<id>/ to /docs/dev/<id>/ when /docs/ became the player guide.
const devRedirects = Object.fromEntries(
  readdirSync(new URL('../docs', import.meta.url))
    .filter((file) => file.endsWith('.md'))
    .map((file) => file.slice(0, -3).toLowerCase())
    .map((id) => [`/docs/${id}/`, `/docs/dev/${id}/`]),
);

export default defineConfig({
  site: 'https://whowolf.de',
  trailingSlash: 'always',
  redirects: devRedirects,
  build: {
    // Keep CSS and JS in files so the Content-Security-Policy needs no inline scripts.
    inlineStylesheets: 'never',
  },
  markdown: {
    remarkPlugins: [remarkRepoLinks],
    shikiConfig: { theme: 'github-dark-dimmed' },
  },
  vite: {
    build: { assetsInlineLimit: 0 },
    // Artwork lives in design/ and the wiki in docs/ at the repo root.
    server: { fs: { allow: [repoRoot] } },
  },
});
