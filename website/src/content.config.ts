import { glob } from 'astro/loaders';
import { defineCollection } from 'astro:content';

// The wiki is the repo's docs/ folder, read as-is at build time.
const docs = defineCollection({
  loader: glob({ pattern: '**/*.md', base: '../docs' }),
});

export const collections = { docs };
