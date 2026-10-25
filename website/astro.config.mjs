import { fileURLToPath } from 'node:url';
import { defineConfig } from 'astro/config';

const repoRoot = fileURLToPath(new URL('..', import.meta.url));

export default defineConfig({
  site: 'https://whowolf.de',
  build: {
    // Keep CSS and JS in files so the Content-Security-Policy needs no inline exceptions.
    inlineStylesheets: 'never',
  },
  vite: {
    build: { assetsInlineLimit: 0 },
    // Artwork lives in design/ at the repo root.
    server: { fs: { allow: [repoRoot] } },
  },
});
