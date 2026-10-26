import type { CollectionEntry } from 'astro:content';

export const repoUrl = 'https://github.com/nurkert/whowolf';

/** The developer area: the planning documents from docs/, kept apart from the player guide. */
export const devBase = '/docs/dev/';
export const devHref = (id: string) => `${devBase}${id}/`;

/** Sidebar groups; documents not listed here land in "Weiteres". */
const groups: { title: string; ids: string[] }[] = [
  { title: 'Projekt', ids: ['vision', 'roadmap', 'decisions'] },
  { title: 'Spiel', ids: ['game_design', 'night_sounds'] },
  { title: 'Technik', ids: ['architecture', 'security_design', 'tooling'] },
  { title: 'Gestaltung', ids: ['design'] },
  { title: 'Hintergrund', ids: ['market', 'legal'] },
];

/** The first level-1 heading is the page title, as on GitHub. */
export function docTitle(entry: CollectionEntry<'docs'>): string {
  const match = entry.body?.match(/^#\s+(.+)$/m);
  return match ? match[1].replace(/[*_`]/g, '').trim() : entry.id;
}

/** First real paragraph, used as summary on the overview page. */
export function docSummary(entry: CollectionEntry<'docs'>): string {
  const lines = (entry.body ?? '').split('\n');
  // First real sentence: skip headings and lead-ins that end in a colon.
  const paragraph = lines.find(
    (line) => /^[A-ZÄÖÜa-zäöü*]/.test(line.trim()) && !line.startsWith('#') && !line.trim().endsWith(':'),
  );
  const plain = (paragraph ?? '').replace(/[*_`[\]]/g, '').replace(/\(([^)]*)\)/g, '').trim();
  return plain.length > 160 ? `${plain.slice(0, 157)}…` : plain;
}

export function groupDocs(entries: CollectionEntry<'docs'>[]) {
  const byId = new Map(entries.map((entry) => [entry.id, entry]));
  const used = new Set<string>();
  const result = groups.map((group) => ({
    title: group.title,
    items: group.ids.flatMap((id) => {
      const entry = byId.get(id);
      if (!entry) return [];
      used.add(id);
      return [entry];
    }),
  }));
  const rest = entries.filter((entry) => !used.has(entry.id)).sort((a, b) => a.id.localeCompare(b.id));
  if (rest.length) result.push({ title: 'Weiteres', items: rest });
  return result.filter((group) => group.items.length);
}

export function sourcePath(entry: CollectionEntry<'docs'>): string {
  return `docs/${entry.filePath?.split('/docs/').pop() ?? `${entry.id}.md`}`;
}

/** Sidebar entry of the shared docs layout. */
export interface NavItem {
  href: string;
  label: string;
  current?: boolean;
}

export interface NavGroup {
  title: string;
  items: NavItem[];
}

/** Sidebar of the developer area. */
export function devNav(entries: CollectionEntry<'docs'>[], currentId?: string): NavGroup[] {
  return groupDocs(entries).map((group) => ({
    title: group.title,
    items: group.items.map((entry) => ({ href: devHref(entry.id), label: docTitle(entry), current: entry.id === currentId })),
  }));
}
