// Small progressive enhancements shared by every page.
document.documentElement.classList.add('js');

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
