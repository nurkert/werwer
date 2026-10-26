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

// Cardboard figures are flat (just their print) while they face the audience. The board's
// edge layers are switched on (`.is-3d`) only while a figure turns or leans, and off again
// once it faces front (or fully away) again.
const tilted = (element: Element) => {
  const match = /^matrix3d\(([^,]+)/.exec(getComputedStyle(element).transform);
  // a 2D transform cannot turn a figure around its upright
  return match ? Math.abs(Number(match[1])) < 0.995 : false;
};
document.addEventListener('transitionrun', (event) => {
  const target = event.target as Element;
  if (event.propertyName === 'transform' && target.matches?.('[data-turn]')) target.classList.add('is-3d');
});
for (const type of ['transitionend', 'transitioncancel'] as const) {
  document.addEventListener(type, (event) => {
    const target = event.target as Element;
    if (event.propertyName === 'transform' && target.matches?.('[data-turn]') && !tilted(target)) {
      target.classList.remove('is-3d');
    }
  });
}

// Now and then one figure on screen leans halfway round (25–40 degrees) so you see it is
// made of board, holds a moment and eases back (sin² over five seconds). Each figure waits
// 8–18 s between leans, never two at once, none off screen, none with reduced motion.
if (!calm && 'IntersectionObserver' in window && 'animate' in Element.prototype) {
  const figures = [...document.querySelectorAll<HTMLElement>('.cardboard')];
  const visible = new Set<HTMLElement>();
  const due = new Map<HTMLElement, number>();
  const random = (from: number, to: number) => from + Math.random() * (to - from);
  let leaning = false;
  let quietUntil = 0;
  let timer = 0;

  const plan = () => {
    window.clearTimeout(timer);
    if (!visible.size || document.hidden) return;
    const next = Math.min(...[...visible].map((figure) => due.get(figure) ?? Infinity));
    timer = window.setTimeout(fire, Math.max(250, next - performance.now()));
  };
  const lean = (figure: HTMLElement) => {
    leaning = true;
    figure.classList.add('is-3d');
    const degrees = random(25, 40) * (Math.random() < 0.5 ? -1 : 1);
    const steps = 24;
    const frames = Array.from({ length: steps + 1 }, (_, i) => {
      const s = Math.sin((Math.PI * i) / steps);
      return { transform: `rotateY(${(degrees * s * s).toFixed(2)}deg)` };
    });
    const animation = figure.animate(frames, { duration: 5000, easing: 'linear' });
    const done = () => {
      leaning = false;
      // a pause after every lean, so the stage is mostly still
      quietUntil = performance.now() + random(2500, 6000);
      figure.classList.remove('is-3d');
    };
    animation.onfinish = done;
    animation.oncancel = done;
  };
  const fire = () => {
    const now = performance.now();
    // a figure that is being turned by hand or by the story waits its turn
    const ready = [...visible].filter((figure) => (due.get(figure) ?? Infinity) <= now + 50);
    const free = ready.filter((figure) => !figure.closest('.is-3d'));
    if (leaning || now < quietUntil || !free.length) {
      for (const figure of ready) due.set(figure, Math.max(now, quietUntil) + random(500, 3000));
    } else {
      const figure = free[Math.floor(Math.random() * free.length)];
      for (const other of ready) if (other !== figure) due.set(other, now + random(2000, 4500));
      due.set(figure, now + 5000 + random(8000, 18000));
      lean(figure);
    }
    plan();
  };

  const watcher = new IntersectionObserver(
    (entries) => {
      const now = performance.now();
      for (const entry of entries) {
        const figure = entry.target as HTMLElement;
        if (entry.isIntersecting) {
          visible.add(figure);
          if (!due.has(figure)) due.set(figure, now + random(6000, 14000));
        } else {
          visible.delete(figure);
          figure.getAnimations().forEach((animation) => animation.cancel());
        }
      }
      plan();
    },
    { threshold: 0.6 },
  );
  figures.forEach((figure) => watcher.observe(figure));
  document.addEventListener('visibilitychange', plan);
}
