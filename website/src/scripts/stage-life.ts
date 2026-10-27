// The life of the stage sets (task 015), as in the app: the lights painted
// into each set breathe or flicker, stars twinkle with a shooting star now
// and then, glints sway on the water, fireflies, mist and dust drift. One
// canvas per scene, drawn only while the scene is on screen, about 30 times
// a second; with reduced motion a calm, lit still.
import data from '../data/lights.json';

type Light = [number, number, number, number];
type Lights = { lights: Light[]; stars: Light[]; ripples: Light[] };
type Rect = [number, number, number, number]; // x0, y0, x1, y1
type Drift = { count: number; area: Rect; color: string; size: number; vx: number; vy: number; sway: number };
type Life = {
  flames?: boolean;
  sky?: Rect;
  shooting?: boolean;
  fireflies?: number;
  fireflyArea?: Rect;
  mist?: Rect[];
  mistColor?: string;
  drift?: Drift;
  moths?: number;
  bulbs?: boolean;
  water?: Rect;
};

const warm = '#ffb45a';
const lives: Record<string, Life> = {
  village: { sky: [0.04, 0.02, 0.96, 0.27], water: [0.2, 0.625, 0.96, 0.7], shooting: true, fireflies: 14, fireflyArea: [0.02, 0.6, 0.98, 0.76] },
  theatre: {
    flames: true,
    drift: { count: 26, area: [0.08, 0.5, 0.92, 0.84], color: '#ffe2a8', size: 3, vx: 0.002, vy: -0.006, sway: 0.02 },
  },
  nightlake: {
    flames: true,
    water: [0, 0.6, 1, 0.74],
    sky: [0.02, 0.02, 0.98, 0.3],
    shooting: true,
    fireflies: 16,
    fireflyArea: [0.02, 0.62, 0.98, 0.82],
    mist: [[0, 0.56, 1, 0.66]],
    mistColor: '#9fb4d8',
  },
  morning: {
    mist: [
      [0, 0.5, 1, 0.62],
      [0, 0.6, 1, 0.7],
    ],
    mistColor: '#ffffff',
    drift: { count: 24, area: [0, 0.2, 1, 0.9], color: '#fff4d2', size: 3.4, vx: 0.006, vy: -0.002, sway: 0.03 },
  },
  dusk: { sky: [0.05, 0.02, 0.95, 0.14], fireflies: 6, fireflyArea: [0.05, 0.7, 0.95, 0.86], moths: 3 },
  hunt: {
    flames: true,
    fireflies: 22,
    fireflyArea: [0.05, 0.55, 0.95, 0.9],
    mist: [
      [0, 0.5, 1, 0.62],
      [0, 0.58, 1, 0.68],
    ],
    mistColor: '#a9b6d2',
  },
  finale: { fireflies: 10, fireflyArea: [0.05, 0.58, 0.95, 0.76] },
  backstage: {
    flames: true,
    bulbs: true,
    drift: { count: 22, area: [0.02, 0.15, 0.98, 0.8], color: '#ffe2a8', size: 2.6, vx: 0.002, vy: -0.004, sway: 0.02 },
  },
  curtain: {
    flames: true,
    drift: { count: 20, area: [0.1, 0.1, 0.9, 0.86], color: '#ffe2a8', size: 2.6, vx: 0.001, vy: -0.004, sway: 0.02 },
  },
};

const hash = (i: number, salt: number) => {
  const x = Math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - Math.floor(x);
};

// Soft sprites, drawn once per colour and stamped many times.
const sprites = new Map<string, HTMLCanvasElement>();
function sprite(kind: 'glow' | 'star' | 'streak' | 'mist', color: string): HTMLCanvasElement {
  const key = `${kind}${color}`;
  const cached = sprites.get(key);
  if (cached) return cached;
  const [w, h] = kind === 'streak' ? [128, 32] : kind === 'mist' ? [256, 64] : [64, 64];
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  const g = c.getContext('2d')!;
  g.save();
  g.translate(w / 2, h / 2);
  g.scale(w / Math.min(w, h), h / Math.min(w, h));
  const r = Math.min(w, h) / 2;
  const grad = g.createRadialGradient(0, 0, 0, 0, 0, r);
  const rgb = color;
  const stops: [number, number][] =
    kind === 'glow' ? [[0, 1], [0.12, 0.75], [0.4, 0.22], [1, 0]] : kind === 'star' ? [[0, 1], [0.1, 0.6], [0.3, 0.08], [1, 0]] : [[0, 0.9], [0.4, 0.35], [1, 0]];
  for (const [at, a] of stops) grad.addColorStop(at, withAlpha(rgb, a));
  g.fillStyle = grad;
  g.fillRect(-r, -r, 2 * r, 2 * r);
  g.restore();
  if (kind === 'star') {
    g.strokeStyle = withAlpha(rgb, 0.7);
    g.lineWidth = 1.4;
    g.beginPath();
    g.moveTo(4, 32);
    g.lineTo(60, 32);
    g.moveTo(32, 4);
    g.lineTo(32, 60);
    g.stroke();
  }
  sprites.set(key, c);
  return c;
}

function withAlpha(hex: string, a: number) {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${a})`;
}

class SceneLife {
  readonly canvas: HTMLCanvasElement;
  private readonly ctx: CanvasRenderingContext2D;
  private readonly life: Life;
  private readonly lights: Lights;
  private w = 0;
  private h = 0;
  visible = false;

  constructor(
    private readonly section: HTMLElement,
    name: string,
  ) {
    this.life = lives[name] ?? {};
    this.lights = ((data as Record<string, Lights>)[name] ?? { lights: [], stars: [], ripples: [] }) as Lights;
    this.canvas = document.createElement('canvas');
    this.canvas.className = 'scene__life';
    this.canvas.setAttribute('aria-hidden', 'true');
    section.insertBefore(this.canvas, section.querySelector('.scene__content'));
    this.ctx = this.canvas.getContext('2d')!;
    this.resize();
  }

  resize() {
    const dpr = Math.min(1.5, window.devicePixelRatio || 1);
    this.w = this.section.clientWidth;
    this.h = this.section.clientHeight;
    this.canvas.width = Math.round(this.w * dpr);
    this.canvas.height = Math.round(this.h * dpr);
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  draw(t: number) {
    const { ctx, life, lights } = this;
    const W = this.w;
    const H = this.h;
    ctx.clearRect(0, 0, W, H);
    ctx.globalCompositeOperation = 'lighter';
    // The set's picture: object-fit cover, object-position 50% 80%.
    const side = Math.max(W, H);
    const pw = side;
    const left = (W - pw) * 0.5;
    const top = (H - pw) * 0.8;
    const at = (x: number, y: number) => [left + x * pw, top + y * pw] as const;
    const stamp = (img: HTMLCanvasElement, x: number, y: number, width: number, alpha: number) => {
      if (alpha <= 0.01) return;
      const height = (width * img.height) / img.width;
      ctx.globalAlpha = Math.min(1, alpha);
      ctx.drawImage(img, x - width / 2, y - height / 2, width, height);
    };

    for (const [b, band] of (life.mist ?? []).entries()) {
      const mist = sprite('mist', life.mistColor ?? '#9fb4d8');
      for (let i = 0; i < 3; i++) {
        const speed = 0.008 + 0.004 * hash(i, b + 40);
        const x = ((t * speed + i / 3 + hash(i, b)) % 1.6) - 0.3;
        const y = band[1] + (band[3] - band[1]) * (0.3 + 0.4 * hash(i, b + 7));
        const [px, py] = at(x, y);
        stamp(mist, px, py, pw * 0.8, 0.07 + 0.04 * Math.sin(t * 0.2 + i * 2.1 + b));
      }
    }

    // Water: the reflections of the lights break into swaying strips, and
    // moonlight glints come and go on the waves.
    const streak = sprite('streak', warm);
    lights.ripples.forEach(([x, y, r, s], i) => {
      for (let k = 0; k < 3; k++) {
        const ky = y + (k - 1) * r * 0.9;
        const dx = Math.sin(t * (1.1 + 0.3 * k) + ky * 140 + i) * r * 1.1;
        const [px, py] = at(x + dx, ky);
        stamp(streak, px, py, Math.max(10, r * pw * (7 + 3 * Math.sin(t * 1.7 + k + i))), s * (0.22 + 0.2 * Math.sin(t * 2.3 + x * 50 + i * 1.7 + k * 2)));
      }
    });
    if (life.water) {
      const [x0, y0, x1, y1] = life.water;
      const glint = sprite('streak', '#cfe0ff');
      for (let i = 0; i < 46; i++) {
        const depth = Math.pow(hash(i, 61), 0.8);
        const y = y0 + (y1 - y0) * depth;
        const x = x0 + (x1 - x0) * ((hash(i, 62) + t * (0.004 + 0.006 * depth)) % 1);
        const on = Math.pow(0.5 + 0.5 * Math.sin(t * (0.8 + hash(i, 63)) + i * 2.3), 6);
        const [px, py] = at(x, y);
        stamp(glint, px, py, 6 + 22 * depth, 0.5 * on);
      }
    }

    const star = sprite('star', '#fff4d6');
    lights.stars.forEach(([x, y, r, s], i) => {
      const pace = 0.7 + 2 * hash(i, 3);
      const tw = Math.pow(0.5 + 0.5 * Math.sin(t * pace + i * 2.4), 3);
      const [px, py] = at(x, y);
      stamp(star, px, py, Math.max(20, r * pw * 14) * (0.7 + 0.5 * tw), 0.25 + 0.6 * tw * s);
    });

    const glow = sprite('glow', warm);
    const blink = life.bulbs ? (Math.floor(t / 6) * 7) % Math.max(1, lights.lights.length) : -1;
    lights.lights.forEach(([x, y, r, s], i) => {
      const ph = hash(i, 11) * 6.28;
      const lantern = r >= 0.02;
      let a =
        life.flames || lantern
          ? 0.78 + 0.1 * Math.sin(t * 7.3 + ph) + 0.07 * Math.sin(t * 11.1 + ph * 1.7) + 0.05 * Math.sin(t * 17.3 + ph * 3)
          : 0.62 + 0.24 * Math.sin(t * 0.45 + ph) + 0.12 * Math.sin(t * 1.3 + ph * 2.1);
      if (i === blink && (t / 6) % 1 < 0.05) a *= 0.15;
      const strength = 0.5 + 0.5 * s;
      const core = Math.max(18, r * pw * 8) * (0.92 + 0.12 * a);
      const [px, py] = at(x, y);
      stamp(glow, px, py, core, 0.85 * a * strength);
      stamp(glow, px, py, core * 3.2, 0.2 * a * strength);
      if (lantern) stamp(glow, px, py, r * pw * 18, 0.24 * a);
    });

    const moth = sprite('glow', '#fff0d0');
    for (let m = 0; m < (life.moths ?? 0) && m < lights.lights.length; m++) {
      const [x, y] = lights.lights[m];
      const ang = t * (2.4 + m) + m * 2;
      const rr = 14 + 6 * Math.sin(t * 1.7 + m);
      const [px, py] = at(x, y);
      stamp(moth, px + Math.cos(ang) * rr, py + Math.sin(ang * 1.3) * rr * 0.6, 7, 0.8);
    }

    if (life.sky) {
      const [x0, y0, x1, y1] = life.sky;
      // Many stars of our own: most faint and small, a few bright ones;
      // neighbours share a slow swell, so the sky twinkles together.
      for (let i = 0; i < 90; i++) {
        const x = x0 + (x1 - x0) * hash(i, 21);
        const y = y0 + (y1 - y0) * Math.pow(hash(i, 22), 1.4);
        const big = hash(i, 24) > 0.88;
        const swell = 0.6 + 0.4 * Math.sin(t * 0.35 + x * 6 + y * 4);
        const tw = Math.pow(0.5 + 0.5 * Math.sin(t * (0.6 + 1.8 * hash(i, 23)) + i), 3) * swell;
        const [px, py] = at(x, y);
        stamp(star, px, py, (big ? 28 : 14) + (big ? 20 : 8) * tw, (big ? 0.3 : 0.15) + 0.6 * tw);
      }
    }

    if (life.fireflies && life.fireflyArea) {
      const [x0, y0, x1, y1] = life.fireflyArea;
      const halo = sprite('glow', '#d8f07a');
      const core = sprite('glow', '#f6ffc8');
      for (let i = 0; i < life.fireflies; i++) {
        const sp = 0.6 + 0.8 * hash(i, 31);
        const ph = hash(i, 32) * 6.28;
        const x = x0 + (x1 - x0) * hash(i, 33) + Math.sin(t * 0.23 * sp + ph) * 0.05 + Math.sin(t * 0.61 + ph * 2) * 0.012;
        const y = y0 + (y1 - y0) * hash(i, 34) + Math.cos(t * 0.19 * sp + ph) * 0.03;
        const on = Math.max(0, Math.min(1, (Math.sin(t * 0.9 * sp + ph) - 0.15) / 0.85));
        const g = Math.pow(on, 1.5);
        const [px, py] = at(x, y);
        stamp(halo, px, py, 26, 0.35 * g);
        stamp(core, px, py, 7, 0.95 * g);
      }
    }

    const drift = life.drift;
    if (drift) {
      const [x0, y0, x1, y1] = drift.area;
      const dot = sprite('glow', drift.color);
      for (let i = 0; i < drift.count; i++) {
        const ph = hash(i, 41) * 6.28;
        const fx = (((hash(i, 42) + (t * drift.vx) / (x1 - x0)) % 1) + 1) % 1;
        const fy = (((hash(i, 43) + (t * drift.vy) / (y1 - y0)) % 1) + 1) % 1;
        const [px, py] = at(x0 + (x1 - x0) * fx + Math.sin(t * 0.7 + ph) * drift.sway, y0 + (y1 - y0) * fy);
        stamp(dot, px, py, drift.size * 3.2, 0.7 * Math.sin(Math.PI * fy) * (0.55 + 0.45 * Math.sin(t * 1.9 + ph)));
      }
    }

    if (life.shooting) this.shootingStar(t, at, pw);
    ctx.globalAlpha = 1;
  }

  private shootingStar(t: number, at: (x: number, y: number) => readonly [number, number], pw: number) {
    const period = 9;
    const cycle = Math.floor(t / period);
    const phase = t - cycle * period;
    const run = 0.9;
    if (phase > run || hash(cycle, 51) < 0.35) return;
    const [x0, y0, x1, y1] = this.life.sky ?? [0, 0, 1, 0.3];
    const [sx, sy] = at(x0 + (x1 - x0) * hash(cycle, 52), y0 + (y1 - y0) * 0.6 * hash(cycle, 53));
    const dx = hash(cycle, 54) < 0.5 ? -1 : 1;
    const p = phase / run;
    const travel = pw * 0.28;
    const hx = sx + dx * travel * p;
    const hy = sy + 0.45 * travel * p;
    const tx = hx - dx * travel * 0.35;
    const ty = hy - 0.45 * travel * 0.35;
    const fade = Math.sin(Math.PI * p);
    const ctx = this.ctx;
    const grad = ctx.createLinearGradient(tx, ty, hx, hy);
    grad.addColorStop(0, 'rgba(255,244,214,0)');
    grad.addColorStop(1, `rgba(255,244,214,${0.9 * fade})`);
    ctx.globalAlpha = 1;
    ctx.strokeStyle = grad;
    ctx.lineWidth = 1.8;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(tx, ty);
    ctx.lineTo(hx, hy);
    ctx.stroke();
  }
}

function start() {
  const sections = [...document.querySelectorAll<HTMLElement>('[data-life]')];
  if (!sections.length) return;
  const still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const scenes = sections.map((s) => new SceneLife(s, s.dataset.life ?? ''));
  const resize = new ResizeObserver((entries) => {
    for (const e of entries) {
      const scene = scenes.find((s) => s.canvas.parentElement === e.target);
      scene?.resize();
      if (still) scene?.draw(3);
    }
  });
  scenes.forEach((s) => resize.observe(s.canvas.parentElement!));
  if (still) {
    scenes.forEach((s) => s.draw(3));
    return;
  }
  const seen = new IntersectionObserver((entries) => {
    for (const e of entries) {
      const scene = scenes.find((s) => s.canvas.parentElement === e.target);
      if (scene) scene.visible = e.isIntersecting;
    }
  });
  scenes.forEach((s) => seen.observe(s.canvas.parentElement!));
  let last = 0;
  const frame = (now: number) => {
    if (now - last > 32 && !document.hidden) {
      last = now;
      const t = 3 + now / 1000;
      for (const s of scenes) if (s.visible) s.draw(t);
    }
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);
}

start();
