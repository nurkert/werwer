# Whowolf – Notes for Claude

Open-source Werewolf party game: players sit together, each on their own device, the app is the narrator.

## Start here

1. Read `docs/` (German): VISION, GAME_DESIGN, NIGHT_SOUNDS, ARCHITECTURE, SECURITY_DESIGN, TOOLING, DESIGN, ROADMAP, LEGAL, DECISIONS.
2. The current task is described in `docs/tasks/` — pick the lowest-numbered task that is not marked done.
3. Talk to the user in German. Code, comments, commit messages and the public README are in English.

## Project rules

- Monorepo, all Dart: `app/` (Flutter, all platforms incl. web), `packages/game_core/` (pure Dart rules, shared), `server/` (relay server, no game logic; built last, after the MVP), `website/` (GitHub Pages + docs).
- Use a Dart pub workspace: root `pubspec.yaml` with `workspace:` listing the members; each member has `resolution: workspace`.
- Game rules live only in `game_core`; never duplicate rule logic in app or server.
- `game_core` is pure Dart: no Flutter, no `dart:io`, no network, no clock. Randomness is injected (`Random` passed in) so games are reproducible in tests.
- The **host device** (game leader's app) is authoritative and runs the game; every client, including the host player's own UI, receives only per-player filtered state.
- **MVP first:** follow `docs/ROADMAP.md`. The MVP is LAN-only and ships as a GitHub release + website; do not build server features before that, but never design something that makes attaching the server later hard (see the roadmap section "Von Anfang an mitdenken").
- **Local-first:** for now there is no server. One device hosts the game over the local Wi-Fi (LAN WebSocket); later a server is added **only as a relay** (room codes, forwarding, web app hosting) so remote players can join a host; the server does not run game logic for now, but keep in mind it may later act as a headless host running the same host logic. Keep host logic in pure Dart and transports behind an interface (host serves several transports at once) so this works without rework. Players are identified by a session token, not the connection: they can rejoin with their exact state and can join mid-game. See `docs/ARCHITECTURE.md` ("Ausbaustufen").
- Never use third-party trademarks, artwork or rule texts from commercial Werewolf editions (see `docs/LEGAL.md`). All names and texts are original.
- License: Apache 2.0.
- Record new project decisions in `docs/DECISIONS.md` (German, newest on top) and tick off items in `docs/ROADMAP.md`.

## Security & tooling (non-negotiable)

- Follow `docs/SECURITY_DESIGN.md`: never send a client data it may not know; never trust identity or fields from a message (identity comes from the session); validate and size-limit all input; no custom crypto: only documented libsodium constructions (`sodium` package: crypto_kx, keyed generichash, secretstream) in `packages/secure_channel`; never write primitives, KDFs, MACs or nonce handling yourself; no secrets or hidden game state in logs.
- Every new network or storage feature gets a short "security" note in its task (what can go wrong, what prevents it, which test proves it), and security tests block merging.
- New dependencies need a reason (maintainer, license, activity); pin GitHub Actions to commit SHAs with minimal `permissions`.
- Follow `docs/TOOLING.md`: one command per job, `tool/check.sh` is exactly what CI runs, scripts fail fast with actionable messages.

## Toolchain

- Flutter 3.44.8 (stable), Dart 3.12.2 — SDK constraint `^3.12.0`.
- Lints: `very_good_analysis` with `strict-casts`, `strict-inference`, `strict-raw-types`; `public_member_api_docs` stays on for `game_core` (it is a library).

## Commands

```bash
flutter pub get                     # at repo root, resolves the whole workspace
tool/check.sh                       # exactly what CI runs: signing guard, format, analyze, tests
tool/deploy_ios.sh                  # build + install + launch on the paired iPhone
git tag v0.0.N && git push --tags   # pre-release: builds all platforms (.github/workflows/prerelease.yml)
```

## Running on real devices

- iOS: `tool/deploy_ios.sh` (to be added with the app in M3) builds a profile build and installs/launches it via `xcrun devicectl` without attaching a debugger (`flutter run` can leave the app paused in lldb on recent iOS). It finds the first connected or Wi-Fi-paired iPhone.
- Android: install the APK via `flutter install` / `adb`; release signing via a git-ignored `android/key.properties`.
- **Signing stays local:** the Apple team ID goes into a git-ignored `ios/Flutter/Signing.xcconfig` (`DEVELOPMENT_TEAM = …`), pulled in by `Debug.xcconfig`/`Release.xcconfig` via `#include? "Signing.xcconfig"`. Never commit team IDs, provisioning profiles, keystores, `key.properties` or device IDs; `project.pbxproj` must not contain `DEVELOPMENT_TEAM`.
- **Public repo:** never copy code, assets, texts or identifiers from the owner's other (private) projects into this repo. Patterns may be reused, content not.

## Workflow

- Work in small, logical steps; run `dart analyze` and the tests before each commit.
- Commit to `main` with short imperative English messages (e.g. `Add seer night action`).
- Do not push without asking the user.
- Prefer tests that play whole games through the public API over testing internals.
