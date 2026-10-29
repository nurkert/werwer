// Whether this is the official whowolf.de build. Only that build shows the owner's
// privacy policy and terms; a fork shows its operator's (if configured) or a short note,
// so nobody publishes the owner's details for a site he does not run.
// Set by .github/workflows/website.yml from the repository name.
export const officialSite = process.env.OFFICIAL_SITE === 'true';

/** An operator's own page (repository variables PRIVACY_URL, TERMS_URL in a fork): https only. */
export function operatorPage(name: 'PRIVACY_URL' | 'TERMS_URL'): string | null {
  const value = process.env[name]?.trim();
  if (!value || value.length > 300) return null;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && !url.username && !url.password ? url.toString() : null;
  } catch {
    return null;
  }
}
