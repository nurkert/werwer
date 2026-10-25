import { fileURLToPath } from 'node:url';
import { defineConfig } from 'astro/config';

import remarkRepoLinks from './src/lib/remark-repo-links.mjs';

const repoRoot = fileURLToPath(new URL('..', import.meta.url));

export default defineConfig({
  site: 'https://whowolf.de',
  trailingSlash: 'always',
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
