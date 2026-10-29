// Sitemap of the pages for players (incl. the player guide), with hreflang alternates. The German
// developer area stays reachable through its links but is left out, so search engines see the
// players' pages first.
import type { APIRoute } from 'astro';

import { alternates, defaultLang, pages, path, type Page } from '../i18n/ui';

export const GET: APIRoute = ({ site }) => {
  const url = (href: string) => new URL(href, site).toString();
  // The join page only makes sense with a room in the link, so it is not listed.
  const listed = (Object.keys(pages) as Page[]).filter((page) => page !== 'join');
  const localized = listed.flatMap((page) => {
    const versions = alternates(page);
    const links = [
      ...versions.map((v) => `<xhtml:link rel="alternate" hreflang="${v.lang}" href="${url(v.href)}"/>`),
      `<xhtml:link rel="alternate" hreflang="x-default" href="${url(path(page, defaultLang))}"/>`,
    ].join('');
    return versions.map((v) => `<url><loc>${url(v.href)}</loc>${links}</url>`);
  });
  const body = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
${localized.join('\n')}
</urlset>`;
  return new Response(body, { headers: { 'Content-Type': 'application/xml; charset=utf-8' } });
};
