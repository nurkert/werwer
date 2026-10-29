// The imprint is not stored in this repo. The official build (nurkert/whowolf) sets
// IMPRINT_URL and pulls the owner's single source of truth at build time; forks set
// their own URL or show a notice. Fetched markup is reduced to a small tag whitelist.

const allowedTags = new Set(['p', 'br', 'strong', 'b', 'em', 'i', 'h2', 'h3', 'ul', 'li']);

function escapeText(text: string): string {
  return text.replace(/&(?!(?:[a-z]+|#\d+|#x[\da-f]+);)/gi, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

/** Keeps only whitelisted tags, drops every attribute, escapes everything else. */
export function sanitize(html: string): string {
  const withoutBlocks = html.replace(/<(script|style|iframe|object|template)[\s\S]*?<\/\1>/gi, '');
  return withoutBlocks
    .split(/(<[^>]*>)/)
    .map((part) => {
      const tag = part.match(/^<\s*(\/?)\s*([a-z0-9]+)[^>]*>$/i);
      if (!tag) return part.startsWith('<') ? '' : escapeText(part);
      const name = tag[2].toLowerCase();
      if (!allowedTags.has(name)) return '';
      if (name === 'br') return '<br>';
      return `<${tag[1]}${name}>`;
    })
    .join('')
    .replace(/\n\s+/g, '\n')
    .trim();
}

/**
 * The imprint page, tried a few times with growing pauses: a short outage of the owner's
 * site must not fail the release build, but the site is never published without an imprint.
 */
async function fetchWithRetry(url: URL, attempts = 4): Promise<string> {
  let last: unknown;
  for (let attempt = 0; attempt < attempts; attempt++) {
    if (attempt > 0) await new Promise((done) => setTimeout(done, 2_000 * 2 ** (attempt - 1)));
    try {
      const response = await fetch(url, { signal: AbortSignal.timeout(15_000), redirect: 'error' });
      if (response.ok) return await response.text();
      last = new Error(`Imprint could not be loaded (${response.status}) from ${url}`);
      // A missing page will not come back by waiting.
      if (response.status === 404) break;
    } catch (error) {
      last = error;
    }
  }
  throw last instanceof Error ? last : new Error(`Imprint could not be loaded from ${url}`);
}

export interface Imprint {
  html: string;
  source: string;
}

export async function loadImprint(): Promise<Imprint | null> {
  const source = process.env.IMPRINT_URL?.trim();
  if (!source) return null;
  const url = new URL(source);
  if (url.protocol !== 'https:') throw new Error('IMPRINT_URL must use https');

  const page = await fetchWithRetry(url);

  // Content of the page after its <h1> heading, up to the end of the body.
  const afterHeading = page.split(/<\/h1>/i)[1] ?? '';
  const body = afterHeading.split(/<\/body>/i)[0];
  const html = sanitize(body);
  if (html.replace(/<[^>]+>/g, '').trim().length < 40) {
    throw new Error(`Imprint at ${url} looks empty; refusing to publish without an imprint`);
  }
  return { html, source: url.toString() };
}
