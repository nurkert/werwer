import { glob } from 'astro/loaders';
import { defineCollection } from 'astro:content';
import { z } from 'astro/zod';

import { guidePages, langs } from './i18n/ui';

// The developer wiki is the repo's docs/ folder, read as-is at build time.
const docs = defineCollection({
  loader: glob({ pattern: '**/*.md', base: '../docs' }),
});

const figure = z.enum([
  'amor',
  'dorfbewohner',
  'faehrtenleger',
  'grossvater',
  'hexe',
  'jaeger',
  'lauscherin',
  'magd',
  'seherin',
  'spielmann',
  'stille_pfote',
  'tueftler',
  'werwolf',
  'wirtin',
]);

// The player guide: one file per page and language, src/content/guide/<lang>/<page>.md.
// Slugs and hreflang come from the page config in src/i18n/ui.ts.
const guide = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/guide' }),
  schema: z.object({
    page: z.enum(guidePages),
    lang: z.enum(langs as [string, ...string[]]),
    title: z.string(),
    /** Short name for the sidebar and the chapter cards. */
    short: z.string(),
    description: z.string(),
    lead: z.string(),
    figure,
    /** Optional cast cards shown between the lead and the text (roles page). */
    cast: z
      .array(
        z.object({
          figure,
          name: z.string(),
          side: z.enum(['village', 'wolves']),
          status: z.enum(['now', 'planned', 'idea']),
          text: z.string(),
        }),
      )
      .optional(),
    /** Questions and answers shown after the text, also as schema.org FAQPage (FAQ page). */
    faq: z.array(z.object({ q: z.string(), a: z.string() })).optional(),
  }),
});

export const collections = { docs, guide };
