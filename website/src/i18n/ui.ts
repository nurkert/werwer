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
  // The player guide (the "Docs"); its texts live in src/content/guide/<lang>/<page>.md.
  docs: { de: 'docs', en: 'docs' },
  docsWhat: { de: 'docs/was-ist-whowolf', en: 'docs/what-is-whowolf' },
  docsPlay: { de: 'docs/so-spielt-ihr', en: 'docs/how-to-play' },
  docsRoles: { de: 'docs/rollen', en: 'docs/roles' },
  docsNeed: { de: 'docs/was-ihr-braucht', en: 'docs/what-you-need' },
  docsSafety: { de: 'docs/sicherheit', en: 'docs/safety' },
  docsHow: { de: 'docs/wie-die-app-funktioniert', en: 'docs/how-it-works' },
  docsOrigin: { de: 'docs/woher-kommt-whowolf', en: 'docs/where-it-comes-from' },
  // Around the game: what people search for before an evening of Werwolf.
  docsRules: { de: 'docs/werwolf-regeln', en: 'docs/werewolf-rules' },
  docsEvening: { de: 'docs/spieleabend', en: 'docs/game-night' },
  docsFaq: { de: 'docs/faq', en: 'docs/faq' },
  docsHalloween: { de: 'docs/halloween', en: 'docs/halloween' },
  // One page per role.
  roleWerewolf: { de: 'docs/rollen/werwolf', en: 'docs/roles/werewolf' },
  roleVillager: { de: 'docs/rollen/dorfbewohner', en: 'docs/roles/villager' },
  roleSeer: { de: 'docs/rollen/seherin', en: 'docs/roles/seer' },
  roleWitch: { de: 'docs/rollen/hexe', en: 'docs/roles/witch' },
  roleHunter: { de: 'docs/rollen/jaeger', en: 'docs/roles/hunter' },
  roleCupid: { de: 'docs/rollen/amor', en: 'docs/roles/cupid' },
  roleMayor: { de: 'docs/rollen/buergermeister', en: 'docs/roles/mayor' },
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

/** The guide's chapters in reading order (the index first). */
export const chapterPages = ['docs', 'docsWhat', 'docsPlay', 'docsRoles', 'docsNeed', 'docsSafety', 'docsHow', 'docsOrigin'] as const;
/** Pages around the game (rules, an evening, questions, Halloween). */
export const topicPages = ['docsRules', 'docsEvening', 'docsFaq', 'docsHalloween'] as const;
/** One page per role, in the order of the roles page. */
export const rolePages = ['roleVillager', 'roleWerewolf', 'roleSeer', 'roleWitch', 'roleHunter', 'roleCupid', 'roleMayor'] as const;
/** Every page drawn by the guide, texts in src/content/guide/<lang>/. */
export const guidePages = [...chapterPages, ...topicPages, ...rolePages] as const;
export type GuidePage = (typeof guidePages)[number];
export const isGuidePage = (page: Page): page is GuidePage => (guidePages as readonly string[]).includes(page);
