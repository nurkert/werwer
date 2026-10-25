// What the puppet phones in the opening story show, kept apart from the stage markup.
// Each phone has a timeline: a screen is shown from its story beat until the next one.
// A screen is either drawn in HTML (close to the real app) or a real app screenshot
// (`kind: 'shot'`), so screens can be swapped for captures of the app once it exists.
import type { ImageMetadata } from 'astro';

import dorfbewohner from '../../../design/source/figures/dorfbewohner.png';
import hexe from '../../../design/source/figures/hexe.png';
import magd from '../../../design/source/figures/magd.png';
import seherin from '../../../design/source/figures/seherin.png';
import schaf from '../../../design/source/sheep/schaf_2.png';
import type { Copy } from '../i18n/locales/de';

export type PhoneScreen =
  | { kind: 'role'; label: string; role: string; portrait: ImageMetadata; side: string; hint: string; button: string }
  | { kind: 'night'; title: string; hint: string }
  | { kind: 'vote'; title: string; faces: ImageMetadata[]; picked: number; button: string }
  | { kind: 'sheep'; title: string; sheep: ImageMetadata; count: number; unit: string }
  | { kind: 'shot'; src: ImageMetadata; alt: string };

export interface PhoneStep {
  /** First story beat (0–5) that shows this screen. */
  from: number;
  screen: PhoneScreen;
}

export interface StoryPhone {
  frame: 'island' | 'edge';
  time: string;
  timeline: PhoneStep[];
}

const suspects = [dorfbewohner, magd, hexe, seherin];

/** The two phones of the opening story, in the visitor's language. */
export function storyPhones(t: Copy): StoryPhone[] {
  const u = t.unbox;
  const vote: PhoneScreen = { kind: 'vote', title: u.vote, faces: suspects, picked: 1, button: u.voteButton };
  return [
    {
      frame: 'island',
      time: '23:47',
      timeline: [
        {
          from: 0,
          screen: { kind: 'role', label: u.youAre, role: u.role, portrait: seherin, side: t.cast.village, hint: u.roleHint, button: u.next },
        },
        { from: 4, screen: { kind: 'night', title: u.night, hint: u.nightHint } },
        { from: 5, screen: vote },
      ],
    },
    {
      frame: 'edge',
      time: '23:47',
      timeline: [
        { from: 0, screen: { kind: 'sheep', title: t.sheep.title, sheep: schaf, count: 7, unit: t.sheep.score } },
        { from: 5, screen: vote },
      ],
    },
  ];
}
