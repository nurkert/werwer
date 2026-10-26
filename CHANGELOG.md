# Changelog

All notable changes to Whowolf. Versions follow [Semantic Versioning](https://semver.org/);
0.0.x are test versions, 0.1.0 will be the first release ("MVP").

## 0.0.3 – 2026-10-26

### Added
- End-to-end encryption of every remote connection (Noise NKpsk2 with the key and
  secret from the QR code; Noise NN with a check code the host compares before
  letting someone in), padded to fixed message sizes.
- Rooms nearby are found automatically (mDNS/Bonjour); connection details only on demand.
- Table circle from each player's seat; the host can swap seats.
- The host saves the room continuously and restores it after a crash.
- Help for common network problems; reconnect as soon as the app is back in front.
- Command-line client (`packages/cli`) to host or join from a terminal.
- Website: layered cardboard stage in the hero, player guide in eight chapters.

### Changed
- The .deb declares all runtime libraries (libsecret, EGL, GLES).

## 0.0.2 – 2026-10-25

### Added
- First playable test version: villager, werewolf and seer; night, morning, day, vote.
- Personas (pick your cardboard figure), narrator with speech on the host device.
- Counting sheep at night, with game-decided flock sizes and the morning tally.
- QR join, relay server with Docker Compose, rejoin after an app restart.
- Join page `whowolf.de/join`.

## 0.0.1 – 2026-10-25

### Added
- Walking skeleton: start screen, pre-release pipeline for all platforms.
