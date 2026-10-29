// Builds the site the way a fork would (no OFFICIAL_SITE, no IMPRINT_URL) into dist-fork/
// and fails if a legal page shows the owner's details: a fork must never publish the
// owner's imprint, privacy policy or terms for a site he does not run (task 029).
import { execFileSync } from 'node:child_process';
import { readFileSync, rmSync } from 'node:fs';

const out = 'dist-fork';
const env = { ...process.env };
for (const name of ['OFFICIAL_SITE', 'IMPRINT_URL', 'PRIVACY_URL', 'TERMS_URL']) delete env[name];
execFileSync('npx', ['astro', 'build', '--outDir', out], { env, stdio: 'inherit' });

// What only the owner's own pages say.
const owner = [/ZAP-Hosting/, /nurkert\.de\/impressum/, /Produkthaftungsgesetz/, /Product Liability Act/];
const pages = ['impressum', 'datenschutz', 'nutzungsbedingungen', 'en/imprint', 'en/privacy', 'en/terms'];
const found = pages.flatMap((page) => {
  const html = readFileSync(`${out}/${page}/index.html`, 'utf8');
  return owner.filter((pattern) => pattern.test(html)).map((pattern) => `${page}: ${pattern}`);
});
rmSync(out, { recursive: true, force: true });
if (found.length > 0) {
  console.error(`A fork build shows the owner's legal details:\n${found.join('\n')}`);
  process.exit(1);
}
console.log('Fork build: no owner legal details on the legal pages.');
