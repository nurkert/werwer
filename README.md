<p align="center">
  <a href="https://whowolf.de"><img src=".github/assets/banner.jpg" alt="Whowolf: a moonlit cardboard village stage with the Whowolf wordmark, two phones showing the app, a maid and a werewolf puppet" width="100%"></a>
</p>

<h3 align="center">The werewolf game for your table, narrated by the app.</h3>

<p align="center">
  <a href="https://whowolf.de">Website</a> ·
  <a href="https://github.com/nurkert/whowolf/releases">Download</a> ·
  <a href="https://whowolf.de/docs/">Player guide</a> ·
  <a href="docs/ROADMAP.md">Roadmap</a>
</p>

<p align="center">
  <a href="https://github.com/nurkert/whowolf/releases"><img src="https://img.shields.io/github/v/release/nurkert/whowolf?include_prereleases&amp;label=release&amp;color=e8a33d" alt="Latest release"></a>
  <a href="https://github.com/nurkert/whowolf/actions/workflows/ci.yml"><img src="https://github.com/nurkert/whowolf/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/nurkert/whowolf/releases"><img src="https://img.shields.io/github/downloads/nurkert/whowolf/total?label=downloads&amp;color=3b5b8c" alt="Downloads"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/nurkert/whowolf?color=6b8e4e" alt="License: Apache 2.0"></a>
</p>

> [!NOTE]
> **Developer beta.** Whowolf is playable on your own Wi-Fi, end-to-end encrypted, on Android, iPhone, Mac, Windows and Linux. Give every device at the table the same version, and until the independent security review is done, play with people you know.

## How it plays

You sit together and play Werewolf the way you always have: you talk, accuse and lie to each other's faces. The difference is that everyone holds their own phone. It shows your role and, at night, your move. The app deals the roles, runs the night, counts the votes and knows every rule, so nobody has to sit out as game master.

- **Your role stays on your phone.** One phone opens a room, the others scan its QR code. No account, no sign-up.
- **Two kinds of night.** In the *classic* night everyone closes their eyes and a recorded narrator calls the roles one by one. In *Whowolf's* night everyone keeps their phone in hand and taps: while the wolves choose, the villagers count sheep, so nobody stands out.
- **Local first.** One phone hosts the game over your Wi-Fi. Every connection is end-to-end encrypted with libsodium. No ads, no tracking.
- **Built for a real evening.** A dropped connection, a locked screen, even a host who leaves: the game carries on and everyone returns to exactly where they were.
- **A stage by moonlight.** Every phase is a painted cardboard stage set, with puppets, curtains and lanterns that flicker.

<p align="center">
  <img src=".github/assets/app-screens.jpg" alt="Five app screens on the cardboard stage: picking your figure, your secret role, the werewolves' pick at night, the classic night with eyes closed, and the witch's potions" width="100%">
</p>

## The cast

<p align="center">
  <img src=".github/assets/cast.webp" alt="Twenty villagers as cardboard puppets: maid, farmer, baker, smith, fisher, miller, seamstress, minstrel, goose girl, beekeeper, innkeeper, shepherd, washerwoman, carpenter, spinner, cobbler, flower girl, mayor, grandmother and grandfather" width="100%">
</p>

Everyone picks one of twenty villagers, ten women and ten men. The figure says nothing about your role: only when you look at your phone does it turn around, dressed as werewolf, seer, witch, hunter, cupid or plain villager. Start with werewolves and a seer, or switch on every role there is.

## Download

Get the latest build from the [releases](https://github.com/nurkert/whowolf/releases): an APK for Android, a disk image (`.dmg`) for macOS, an installer (or a ZIP to run without installing) for Windows, and for Linux a `.deb`, an `.rpm`, a Flatpak, an AppImage and a plain archive. The iPhone version follows via TestFlight. Every release is built by GitHub Actions from this repository, with SHA-256 checksums and build provenance. The builds are not signed by Apple or Microsoft yet; the release notes say how to open them.

## Build from source

You need Flutter 3.44.8 (Dart 3.12).

```bash
flutter pub get        # resolves the whole workspace
tool/check.sh          # what CI runs: format, analyze, tests
cd app && flutter run  # on a device or desktop of your choice
```

## Repository

| Path | Content |
|---|---|
| `app/` | The Flutter app for every platform |
| `packages/game_core/` | The rules in pure Dart, shared and fully tested |
| `packages/` | Host logic, protocol, the encrypted channel and a command-line client |
| `server/` | Relay server for playing beyond one Wi-Fi (in progress) |
| `website/` | [whowolf.de](https://whowolf.de) (Astro), with the player guide and downloads |
| `design/` | Art direction, figures, prompts and credits |
| `docs/` | Vision, game design, architecture and security design (German) |
| `tool/` | Check, release and asset scripts |

## Contributing and security

Playing helps most: tell us what got stuck at your game night. Bug reports, ideas and pull requests are welcome, see [CONTRIBUTING.md](CONTRIBUTING.md). Please report security issues privately as described in [SECURITY.md](SECURITY.md).

## No warranty, self-hosting

Whowolf is a free hobby project. The software is provided as is under the Apache License 2.0, without warranty of any kind (sections 7 and 8 of the license). The official services (whowolf.de, play.whowolf.de, the releases in this repository) may change, pause or end at any time; their [terms of use](https://whowolf.de/en/terms/) apply.

Anyone may run their own relay, website or build. Whoever does is responsible for that deployment and for its own imprint, privacy policy and terms where the law asks for them; copies never show the official site's legal pages. See [server/deploy/README.md](server/deploy/README.md) for the optional legal links of a relay.

## License

Code under the [Apache License 2.0](LICENSE). All artwork in `design/` was made for this project, see the [design credits](design/CREDITS.md).
