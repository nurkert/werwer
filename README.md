<p align="center">
  <a href="https://whowolf.de"><img src=".github/assets/wordmark.png" alt="Whowolf" width="420"></a>
</p>

<p align="center">
  Werewolf at the table. Everyone on their own phone. The app is the narrator.<br>
  <a href="https://whowolf.de">whowolf.de</a> · <a href="https://whowolf.de/docs/">Docs</a> · <a href="docs/ROADMAP.md">Roadmap</a>
</p>

---

> [!NOTE]
> Whowolf is a concept in active development. There is nothing to play yet.

Whowolf is an open-source take on the classic social deduction party game. You sit together in one room and talk, accuse and lie face to face. Every player holds their own phone, so roles stay secret, nobody has to sit out as game master, and no rule is ever forgotten.

## The idea

- **Everyone has a phone.** Scan the host's QR code and you're in. Your role appears on your screen only.
- **The app narrates.** Night and day, votes and rules run automatically.
- **Nobody gives themselves away.** At night every player taps something. Villagers count sheep while the wolves hunt.
- **The wolf trail.** Phones on the table whisper at night, and sometimes a quiet growl hints at where a werewolf sits. A suspicion, never proof.
- **Local first.** One phone hosts the game over your Wi-Fi. No server, no account, no ads, no tracking.

## Platforms

One Flutter codebase. iPhone and Mac come first, followed by Android, Windows and Linux.

## Repository

```
packages/game_core/   Game rules (pure Dart)
website/              whowolf.de (Astro)
design/               Art direction, figures, prompts, credits
docs/                 Planning documents (German)
tool/                 Developer and asset scripts
```

## Documentation

The planning documents live in [`docs/`](docs/) and are published at [whowolf.de/docs](https://whowolf.de/docs/): vision, game design, architecture, security design, roadmap and the decision log. They are written in German.

## Contributing and security

Ideas and pull requests are welcome once the foundation is in place. Please report security issues privately as described in [SECURITY.md](SECURITY.md).

## License

Code under the [Apache License 2.0](LICENSE). Artwork in `design/` is original to this project, see [design credits](design/CREDITS.md).
