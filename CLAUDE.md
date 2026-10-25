# Werwer – Notes for Claude

Open-source Werewolf party game: players sit together, each on their own device, the app is the narrator.

- Read `docs/` first: VISION, GAME_DESIGN, ARCHITECTURE, ROADMAP, LEGAL, DECISIONS.
- Monorepo, all Dart: `app/` (Flutter, all platforms incl. web), `packages/game_core/` (pure Dart rules, shared), `server/` (authoritative WebSocket server), `website/` (GitHub Pages + docs).
- Game rules live only in `game_core`; never duplicate rule logic in app or server.
- Server is authoritative; clients receive only per-player filtered state.
- Never use third-party trademarks, artwork or rule texts from commercial Werewolf editions (see `docs/LEGAL.md`). All content is original.
- License: Apache 2.0.
- Planning docs are in German; code, comments and the public README are in English.
- Record new project decisions in `docs/DECISIONS.md`.
