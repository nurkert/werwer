# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

(The game itself is a Flutter app for iOS, macOS, Android, Windows and Linux; this record covers the website whowolf.de.)

## Users

**Primary: game groups.** Circles of friends who play Werewolf (or similar party games) at the table and are curious about a better way to play. They visit while Whowolf is still a concept; the site has to make them want it and follow it until there is something to play.

Secondary: open-source contributors and testers who find the project through GitHub.

## Product Purpose

Whowolf is an open-source Werewolf party game in development: everyone sits together, every player uses their own phone, and the app is the narrator. The website presents the idea honestly while it is a concept, documents it in the open (docs wiki generated from `docs/`), and later delivers the downloads.

Success today: a game group understands the idea within seconds, enjoys the playful touches, and **follows the project on GitHub**. Once releases are playable, downloading becomes the primary action.

## Positioning

- Everyone on their own phone, at the same table, with the app as narrator: no game master needed.
- At night everyone taps something (decoy tasks such as counting sheep), so nobody gives themselves away.
- **The wolf trail:** phones on the table whisper at night; a quiet growl from a phone means a werewolf sits close by (within a radius that scales with the group). A suspicion, never proof. Only possible because everyone has their own device; no other Werewolf app was found doing this (see docs/MARKET.md).
- Local first (one phone hosts over Wi-Fi), no account, no ads, no tracking, open source (Apache 2.0).

## Operating Context

- Played in person at a table, phones lying face down at night; the website is read on phones as often as on desktops.
- The project is built in the open on GitHub (`nurkert/whowolf`); pre-release builds `0.0.x` are published as GitHub releases.
- iPhone and Mac are the primary development and test platforms.

## Capabilities and Constraints

- Static site (Astro) on GitHub Pages at whowolf.de; no backend, no forms, no third-party requests, strict CSP.
- Languages: German leads at `/`, English at `/en/`; more languages are added as files in `website/src/i18n/locales/`.
- Functions to keep: docs wiki from `docs/`, download page from GitHub releases (build time), imprint pulled from nurkert.de at build time (official repo only), privacy page, SEO (hreflang, sitemap, JSON-LD), the playable counting-sheep teaser.
- Status must be visible: Whowolf is a concept in development; nothing is playable yet.

## Brand Commitments

- Name **Whowolf**, domain whowolf.de, app ID `de.whowolf.app`.
- Art direction "Mondbühne": flat cardboard cut-out puppets on sticks, night village, moon; all artwork original (AI-generated with documented prompts, see `design/CREDITS.md`).
- Logo: the hand-lettered wordmark and the round emblem (`design/source/brand/`).
- No third-party trademarks, artwork or rule texts from commercial Werewolf editions.

## Evidence on Hand

- Artwork: night backdrop, village props, eleven role figures, sheep set, wordmark, emblem (`design/source/`).
- Real documents: vision, game design, wolf trail, architecture, security design, market analysis, roadmap, decisions (`docs/`).
- A running walking-skeleton app and pre-release pipeline.
- **No** players, reviews, testimonials, press, download counts or partner logos exist; none may be invented.

## Product Principles

1. Honest about the stage: a concept in development, shown with pride, never oversold.
2. The table comes first: everything serves playing together face to face.
3. Fair by design: no account, no ads, no tracking, open source.
4. Playful, never silly: the puppets bring the charm, the information stays clear.

## Accessibility & Inclusion

WCAG 2.1 AA contrast and keyboard access; `prefers-reduced-motion` respected (no parallax, static sheep); every interactive toy usable by keyboard and touch.
