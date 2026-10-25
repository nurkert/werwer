# Werwer

*Wer? Wer? Werwolf.*

**An open-source Werewolf party game — together at one table, every player on their own phone, and the app as the narrator.**

> 🚧 Early planning stage. Nothing playable yet — see the [roadmap](docs/ROADMAP.md).

## The idea

Werewolf (a.k.a. Mafia) lives from secret information. Werwer moves that information onto each player's own device:

- 🎭 **Secret roles** – everyone sees only their own role, on their own phone.
- 🌙 **No game master needed** – the app narrates the night and day, so everybody gets to play.
- 🤫 **No tells** – at night *every* player taps something, so nobody gives themselves away.
- 📱 **Join in seconds** – scan a QR code and play in the browser, or use the native app.
- 🏠 **Self-hostable** – run your own server with a single `docker compose up`.

It is **not** an online game with strangers: you sit together in the same room and talk, accuse and lie face to face. The app just handles roles, night actions, votes and the narration.

## Platforms

One Flutter codebase for **Android, iOS, Web, Windows, macOS and Linux**.

## Repository layout (planned)

```
werwer/
├── app/                 Flutter client (all platforms)
├── packages/game_core/  Game rules, roles and phases (pure Dart, shared)
├── server/              Dart WebSocket server (authoritative)
├── website/             GitHub Pages site + docs/wiki
├── docker-compose.yml   Self-hosting
└── docs/                Planning documents
```

## Documentation

| Document | Content |
|---|---|
| [Vision](docs/VISION.md) | What Werwer is and what makes it different |
| [Game design](docs/GAME_DESIGN.md) | Game flow, phases and starting roles |
| [Architecture](docs/ARCHITECTURE.md) | Tech stack, structure, networking, self-hosting |
| [Roadmap](docs/ROADMAP.md) | Phases and next steps |
| [Legal notes](docs/LEGAL.md) | License, trademarks, app store notes |
| [Decisions](docs/DECISIONS.md) | Log of project decisions |

The planning documents are currently written in German.

## License

[Apache License 2.0](LICENSE)
