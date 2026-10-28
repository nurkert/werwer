// Small progressive enhancements shared by every page.
document.documentElement.classList.add('js');

// First visit from outside the site with a browser that does not ask for German:
// switch to the English version of the same page. Internal navigation (including a
// deliberate click on "DE") keeps the chosen language. Crawlers are left alone so
// both language versions stay indexed.
(() => {
  const html = document.documentElement;
  if (html.lang !== 'de') return;
  if (document.referrer && new URL(document.referrer).host === location.host) return;
  if (/bot|crawl|spider|slurp|preview/i.test(navigator.userAgent)) return;
  const wantsGerman = (navigator.languages ?? [navigator.language]).some((l) => l.toLowerCase().startsWith('de'));
  if (wantsGerman) return;
  const english = document.querySelector<HTMLLinkElement>('link[rel="alternate"][hreflang="en"]');
  if (english) location.replace(new URL(english.href).pathname + location.search + location.hash);
})();

// Cookie notice: shown once; the dismissal is the only thing stored (strictly necessary).
(() => {
  const notice = document.querySelector<HTMLElement>('[data-consent]');
  if (!notice) return;
  const key = 'whowolf-notice-seen';
  let seen = false;
  try {
    seen = localStorage.getItem(key) === '1';
  } catch {
    seen = false;
  }
  if (seen) return;
  notice.hidden = false;
  notice.querySelector('[data-consent-ok]')?.addEventListener('click', () => {
    try {
      localStorage.setItem(key, '1');
    } catch {
      /* storage blocked: the notice simply shows again next time */
    }
    notice.hidden = true;
  });
})();


// The developer beta slip: closed for good with its X. (It fades in late,
// so hiding it here never shows a flash.)
const betaSlip = document.querySelector<HTMLElement>('[data-beta]');
try {
  if (betaSlip && localStorage.getItem('whowolf-beta-closed') === '1') betaSlip.hidden = true;
} catch {
  /* storage blocked: the slip shows */
}
document.querySelector('[data-beta-close]')?.addEventListener('click', () => {
  if (betaSlip) betaSlip.hidden = true;
  try {
    localStorage.setItem('whowolf-beta-closed', '1');
  } catch {
    /* storage blocked: the slip simply shows again next time */
  }
});

// Reveal section parts as they enter, once. Content is visible without this script.
const calm = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const parts = document.querySelectorAll<HTMLElement>('[data-reveal]');
if (calm || !('IntersectionObserver' in window)) {
  parts.forEach((part) => part.classList.add('is-in'));
} else {
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add('is-in');
        observer.unobserve(entry.target);
      }
    },
    { rootMargin: '0px 0px -8% 0px' },
  );
  parts.forEach((part) => observer.observe(part));
}

// Close the mobile menu after choosing a link on the same page.
const menu = document.querySelector<HTMLDetailsElement>('[data-menu]');
menu?.addEventListener('click', (event) => {
  if ((event.target as HTMLElement).closest('a')) menu.open = false;
});
document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape' && menu?.open) {
    menu.open = false;
    menu.querySelector('summary')?.focus();
  }
});

// Overlay header turns solid once the hero has scrolled under it.
const header = document.querySelector<HTMLElement>('.site-header--overlay');
if (header) {
  let threshold = window.innerHeight * 0.35;
  let state: boolean | undefined;
  const solid = () => {
    const next = window.scrollY > threshold;
    if (next === state) return;
    state = next;
    header.classList.toggle('is-solid', next);
  };
  window.addEventListener('scroll', solid, { passive: true });
  window.addEventListener('resize', () => {
    threshold = window.innerHeight * 0.35;
    solid();
  });
  solid();
}

// Animations in sections that are off screen stand still (see `.is-offscreen` in global.css).
if ('IntersectionObserver' in window) {
  const zones = document.querySelectorAll<HTMLElement>('[data-story], main > section');
  const zoneObserver = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) entry.target.classList.toggle('is-offscreen', !entry.isIntersecting);
    },
    { rootMargin: '120px 0px' },
  );
  zones.forEach((zone) => zoneObserver.observe(zone));
}
