// Reads GitHub releases at build time, so visitors never contact a third party.
// The site is rebuilt whenever a release is published (see .github/workflows/website.yml).

export type Platform = 'android' | 'ios' | 'macos' | 'windows' | 'linux';

export interface Download {
  platform: Platform;
  name: string;
  url: string;
  sizeMb: number;
  /** The exact size in bytes (AltStore checks it). */
  size: number;
  /** How often GitHub has served this file. */
  count: number;
}

export interface Release {
  version: string;
  name: string;
  url: string;
  publishedAt: Date;
  prerelease: boolean;
  downloads: Download[];
  checksumsUrl?: string;
  /** What AltStore checks the iPhone .ipa against (tool/package_ipa.sh). */
  altstoreUrl?: string;
  /** Downloads of every file of the release, as GitHub counts them. */
  totalDownloads: number;
}

const api = 'https://api.github.com/repos/nurkert/whowolf/releases?per_page=10';

const patterns: [Platform, RegExp][] = [
  ['android', /\.apk$/i],
  ['ios', /\.ipa$/i],
  ['macos', /(\.dmg$|mac(os)?.*\.zip$)/i],
  ['windows', /(\.msix$|\.exe$|windows.*\.zip$)/i],
  ['linux', /(\.deb$|\.appimage$|linux.*\.tar\.gz$|\.flatpak$)/i],
];

interface ApiAsset {
  name: string;
  browser_download_url: string;
  size: number;
  download_count?: number;
}
interface ApiRelease {
  tag_name: string;
  name: string | null;
  html_url: string;
  published_at: string;
  prerelease: boolean;
  draft: boolean;
  assets: ApiAsset[];
}

export async function loadReleases(): Promise<Release[]> {
  const headers: Record<string, string> = { Accept: 'application/vnd.github+json' };
  if (process.env.GITHUB_TOKEN) headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
  try {
    const response = await fetch(api, { headers, signal: AbortSignal.timeout(10_000) });
    if (!response.ok) return [];
    const data = (await response.json()) as ApiRelease[];
    return data
      .filter((release) => !release.draft)
      .map((release) => ({
        version: release.tag_name,
        name: release.name || release.tag_name,
        url: release.html_url,
        publishedAt: new Date(release.published_at),
        prerelease: release.prerelease,
        totalDownloads: release.assets.reduce((sum, asset) => sum + (asset.download_count ?? 0), 0),
        checksumsUrl: release.assets.find((asset) => /sha256/i.test(asset.name))?.browser_download_url,
        altstoreUrl: release.assets.find((asset) => /-ios-altstore\.json$/i.test(asset.name))?.browser_download_url,
        downloads: release.assets.flatMap((asset) => {
          const match = patterns.find(([, pattern]) => pattern.test(asset.name));
          return match
            ? [
                {
                  platform: match[0],
                  name: asset.name,
                  url: asset.browser_download_url,
                  sizeMb: Math.round((asset.size / 1_048_576) * 10) / 10,
                  size: asset.size,
                  count: asset.download_count ?? 0,
                },
              ]
            : [];
        }),
      }))
      // Newest first, whatever order the API returns.
      .sort((a, b) => b.publishedAt.getTime() - a.publishedAt.getTime());
  } catch {
    // Offline build or API hiccup: the page shows the "coming soon" state.
    return [];
  }
}
