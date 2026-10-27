// What the puppet phones in the opening story show, kept apart from the stage markup.
// Each phone has a timeline: a screen is shown from its story beat until the next one.
// The phones show real screenshots of the app (`kind: 'shot'`, rendered by
// app/test/screens_test.dart); the HTML screens remain for drafts.
import type { ImageMetadata } from 'astro';

import deCalled from '../assets/screens/de-called.webp';
import deEyes from '../assets/screens/de-eyes.webp';
import deRole from '../assets/screens/de-role.webp';
import deSheep from '../assets/screens/de-sheep.webp';
import enCalled from '../assets/screens/en-called.webp';
import enEyes from '../assets/screens/en-eyes.webp';
import enRole from '../assets/screens/en-role.webp';
import enSheep from '../assets/screens/en-sheep.webp';

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

/** Real screenshots of the app (task 012), per language. */
const shots = {
  de: { role: deRole, eyes: deEyes, called: deCalled, sheep: deSheep },
  en: { role: enRole, eyes: enEyes, called: enCalled, sheep: enSheep },
};

/** The two phones of the opening story, in the visitor's language. */
export function storyPhones(t: Copy): StoryPhone[] {
  const u = t.unbox;
  const s = shots[u.screens === 'en' ? 'en' : 'de'];
  const shot = (src: ImageMetadata, alt: string): PhoneScreen => ({ kind: 'shot', src, alt });
  const called = shot(s.called, u.shotCalled);
  return [
    {
      frame: 'island',
      time: '23:47',
      timeline: [
        { from: 0, screen: shot(s.role, u.shotRole) },
        { from: 4, screen: shot(s.eyes, u.shotEyes) },
        { from: 5, screen: called },
      ],
    },
    {
      frame: 'edge',
      time: '23:47',
      timeline: [
        { from: 0, screen: shot(s.sheep, u.shotSheep) },
        { from: 5, screen: called },
      ],
    },
  ];
}
