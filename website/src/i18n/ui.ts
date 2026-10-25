// Languages and localized routes. To add a language:
//   1. create src/i18n/locales/<code>.ts (typed against de.ts, so nothing can be missing),
//   2. add it to `languages` below with its slugs.
// Every page, the language switch, hreflang links and the sitemap pick it up automatically.
import type { Copy } from './locales/de';
import de from './locales/de';
import en from './locales/en';

export const defaultLang = 'de';

export const languages = {
  de: { label: 'Deutsch', locale: 'de-DE', og: 'de_DE', copy: de },
  en: { label: 'English', locale: 'en-GB', og: 'en_GB', copy: en },
} satisfies Record<string, { label: string; locale: string; og: string; copy: Copy }>;

export type Lang = keyof typeof languages;
export const langs = Object.keys(languages) as Lang[];

/** Pages built for every language, with their URL slug per language ('' = home). */
export const pages = {
  home: { de: '', en: '' },
  download: { de: 'download', en: 'download' },
  privacy: { de: 'datenschutz', en: 'privacy' },
  imprint: { de: 'impressum', en: 'imprint' },
  join: { de: 'join', en: 'join' },
} satisfies Record<string, Record<Lang, string>>;

export type Page = keyof typeof pages;

export const repoUrl = 'https://github.com/nurkert/whowolf';

export const ui = Object.fromEntries(langs.map((lang) => [lang, languages[lang].copy])) as Record<Lang, Copy>;

/** URL path of a page in a language: default language at the root, others under /<lang>/. */
export function path(page: Page, lang: Lang): string {
  const prefix = lang === defaultLang ? '' : `/${lang}`;
  const slug = pages[page][lang];
  return `${prefix}/${slug ? `${slug}/` : ''}`;
}

/** The route parameter for Astro's [...route] page (undefined for the default home). */
export function routeParam(page: Page, lang: Lang): string | undefined {
  return path(page, lang).replace(/^\/|\/$/g, '') || undefined;
}

/** All language versions of a page, for hreflang links and the language switch. */
export function alternates(page: Page): { lang: Lang; href: string }[] {
  return langs.map((lang) => ({ lang, href: path(page, lang) }));
}
