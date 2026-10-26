# Contributing to Whowolf

Thanks for wanting to help! Whowolf is a Werewolf party game where everyone plays on their own phone and the app is the narrator. Bug reports from real game nights are the most valuable contribution right now.

## Reporting bugs and ideas

- **Bugs:** open an issue with the *Bug report* form. Say which version and devices were at the table, who hosted, and what happened. Never paste session tokens, QR links or room secrets.
- **Ideas:** open an issue with the *Idea* form. Rules ideas are welcome, but all names, texts and artwork must be original (no material from commercial Werewolf editions, see [docs/LEGAL.md](docs/LEGAL.md)).
- **Security problems:** please do not open a public issue; follow [SECURITY.md](SECURITY.md).

## Working on the code

Everything is Dart, in one pub workspace:

| Path | What lives there |
|---|---|
| `packages/game_core` | The rules, pure Dart: no Flutter, no I/O, no clock, randomness passed in |
| `packages/protocol` | Versioned messages with strict parsing and size limits |
| `packages/game_host` | The host: sessions, timers, snapshots, and `PlayerLink` (the player side) |
| `packages/secure_channel` | End-to-end encryption with libsodium constructions only |
| `app/` | The Flutter app |
| `server/` | The relay server (forwards only, no game logic) |
| `website/` | whowolf.de (Astro) |

```bash
tool/doctor.sh        # checks your toolchain and says what is missing
flutter pub get       # at the repo root, resolves the whole workspace
tool/check.sh         # exactly what CI runs: format, analyze, all tests
```

Ground rules (the long version is in [CLAUDE.md](CLAUDE.md) and `docs/`):

- Game rules live only in `game_core`; the app and the server never duplicate them.
- The host is authoritative and sends every player only what that player may know. Identity comes from the session, never from a message.
- No custom crypto, and no secrets or hidden game state in logs.
- New dependencies need a reason (maintainer, licence, activity); GitHub Actions stay pinned to commit SHAs.
- Prefer tests that play whole games through the public API. `packages/game_host/test/chaos_test.dart` plays hundreds of games over a lossy network with host crashes; keep it green.
- Small commits with short imperative English messages. Code, comments and the README are in English; the planning documents in `docs/` are in German.

## Licence

By contributing you agree that your contribution is licensed under the [Apache License 2.0](LICENSE).
