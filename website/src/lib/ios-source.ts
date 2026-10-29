// The iPhone source for AltStore Classic and SideStore: players add it once
// and get every iPhone release from then on. Built from the GitHub releases at
// build time (the site is rebuilt on every release); each version's metadata
// comes from the file tool/package_ipa.sh wrote next to its .ipa, read from
// the built app, so it always matches what the stores check. Served twice
// with the same content: /altstore.json and the neutral /ios-source.json.
import { loadReleases } from './releases';

interface Meta {
  bundleIdentifier: string;
  version: string;
  buildVersion: string;
  minOSVersion: string;
  appPermissions: { entitlements: string[]; privacy: Record<string, string> };
}

const id = /^[A-Za-z0-9.-]{1,100}$/;
const version = /^\d+\.\d+\.\d+$/;

/** The metadata of one release, or nothing if it is missing or looks wrong. */
async function meta(url: string): Promise<Meta | undefined> {
  try {
    const response = await fetch(url, { signal: AbortSignal.timeout(10_000) });
    if (!response.ok) return undefined;
    const m = (await response.json()) as Meta;
    const ok =
      id.test(m.bundleIdentifier) &&
      version.test(m.version) &&
      /^\d{1,10}$/.test(m.buildVersion) &&
      /^\d+(\.\d+){0,2}$/.test(m.minOSVersion) &&
      Array.isArray(m.appPermissions?.entitlements) &&
      typeof m.appPermissions?.privacy === 'object';
    return ok ? m : undefined;
  } catch {
    return undefined;
  }
}

async function build(site: URL | undefined): Promise<string> {
  const url = (href: string) => new URL(href, site).toString();
  const releases = await loadReleases();
  // Newest first, as AltStore expects; only releases with an .ipa and its
  // matching metadata.
  const versions = (
    await Promise.all(
      releases.map(async (release) => {
        const ipa = release.downloads.find((file) => file.platform === 'ios');
        if (!ipa || !release.altstoreUrl) return undefined;
        const m = await meta(release.altstoreUrl);
        if (!m || `v${m.version}` !== release.version) return undefined;
        return { release, ipa, meta: m };
      }),
    )
  ).filter((v) => v !== undefined);
  const newest = versions[0]?.meta;
  const source = {
    name: 'Whowolf',
    identifier: 'de.whowolf.source',
    subtitle: 'Werewolf at the table, everyone on their own phone.',
    description:
      'The official source of Whowolf, the open-source Werewolf party game. Every iPhone release lands here as soon as it is published.',
    iconURL: url('/app-icon.png'),
    website: url('/'),
    tintColor: '#f2a93b',
    nsfw: false,
    apps: newest
      ? [
          {
            name: 'Whowolf',
            bundleIdentifier: newest.bundleIdentifier,
            developerName: 'Whowolf',
            subtitle: 'Werewolf at the table.',
            localizedDescription:
              'Whowolf is a Werewolf party game for people sitting together: everyone plays on their own phone and the app is the narrator, with its voice wandering around the table. No account, no ads, no tracking; games stay on your Wi-Fi and are end-to-end encrypted. Open source under Apache 2.0.',
            iconURL: url('/app-icon.png'),
            tintColor: '#f2a93b',
            category: 'games',
            versions: versions.map(({ release, ipa, meta: m }) => ({
              version: m.version,
              buildVersion: m.buildVersion,
              date: release.publishedAt.toISOString(),
              localizedDescription: `${release.name}. Release notes: ${release.url}`,
              downloadURL: ipa.url,
              size: ipa.size,
              minOSVersion: m.minOSVersion,
            })),
            appPermissions: newest.appPermissions,
          },
        ]
      : [],
    news: [],
  };
  return JSON.stringify(source, null, 2);
}

// Built once per site build, however many addresses serve it.
let built: Promise<string> | undefined;

/** The source as AltStore and SideStore read it (same format: SideStore is an AltStore fork). */
export async function iosSource(site: URL | undefined): Promise<Response> {
  built ??= build(site);
  return new Response(await built, {
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
  });
}
