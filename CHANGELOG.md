# Changelog

All notable changes to Whowolf. Versions follow [Semantic Versioning](https://semver.org/);
0.0.x are test versions, 0.1.0 will be the first release ("MVP").

## 0.0.4 – 2026-10-26

### Changed
- Encryption is now built from libsodium only (key exchange, keyed BLAKE2b,
  secretstream) instead of an own Noise implementation. Handshake version 2:
  older test versions cannot connect to this one.
- Joining without the QR code: the check code has 4 symbols and can no longer be
  forged by someone in the middle (commitment before the key exchange). Players
  let in this way receive the room secret and always come back over a checked
  channel; a token over an unchecked channel is refused.

### Fixed
- A waiting joiner who showed a session token no longer stays on the host's
  waiting list, and letting them in can no longer create a second player.
- Sending on a closing LAN connection no longer throws.

### Added
- Simulation tests for the host: random games with dropouts, rejoins, timers
  and host crashes in the middle of night and vote.
- Website: clear notice that Whowolf is in an early developer beta.

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
