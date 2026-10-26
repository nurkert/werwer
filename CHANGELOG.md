# Changelog

All notable changes to Whowolf. Versions follow [Semantic Versioning](https://semver.org/);
0.0.x are test versions, 0.1.0 is the first release (developer beta).

## Unreleased

### Added
- The classic night: everyone closes their eyes and the narrator calls the
  roles one by one (cupid, the werewolves, the seer, the witch); only
  whoever is called picks up their phone. It is the night of the "Classic"
  level and can be switched on in the settings.
- Shared sounds (the gong, the morning yawn, the rooster) play at the same
  instant on every phone: the phones keep their clocks in step with the
  host.
- Players in the same Wi-Fi always connect locally; only those who need it
  go through the online server.
- Join in the browser without installing anything: in the same Wi-Fi,
  scan the host's QR code with the phone's camera. The host's phone serves
  the web app itself, no internet needed.
- A short privacy notice on first start, the full privacy notice in the
  settings, and a switch to play Wi-Fi only without the online server.

## 0.1.1 – 2026-10-26

### Added
- If the host's phone goes away (closed app, empty battery) or the host
  leaves, another player's phone takes over the room within seconds and the
  same game goes on; that player runs the table from then on. No phone
  alone ever holds the game's secrets for this: one keeps the room sealed,
  another the key.
- Short drop-outs no longer show the pause screen at once.
- New wordless sounds: nightfall with a gong and a yawn, a distant rooster
  in the morning, the vote bell, a drum for the dead, a wolf's howl or a
  harp at the end, and soft taps by day (never at night, so no sound gives
  anyone away).
- Players on mobile data can join through the official relay server
  play.whowolf.de.

### Changed
- The game adapts to phones, tablets and wide windows (two columns), and
  content scrolls softly beneath the header.
- Cards and buttons are cut from corrugated board.
- The narrator's voice is off unless the host turns it on.

### Security
- Joining without the QR code now asks you to confirm that the host's screen
  shows your symbols before anything from the host counts; someone on the
  same Wi-Fi could otherwise pose as the room. Waiting for the host no longer
  drops the connection (and changes the symbols) after 8 seconds.
- Door signs, flocks and the mark's coin come from a 256-bit game secret via
  HMAC-SHA256; before, a player could work out everyone's signs from their own.
- WebSocket compression is off everywhere and the relay checks its room
  limits again after the upgrade.
- Names may not contain control or invisible direction characters; the CLI
  filters its output and reads the join link from input instead of the
  command line. Every host message is padded to the same size.

### Changed
- Figures stand on corrugated board with a visible edge and a kraft back,
  and rock gently so the thickness shows.

## 0.1.0 – 2026-10-26

The first release: a developer beta you can play with friends.

### Added
- **Roles:** witch (healing potion and poison, decides after the werewolves),
  hunter (takes someone along when he falls) and cupid (binds two lovers; a
  mixed couple wins as the last two). Every role is playable in the app.
- **Game settings** for the host, starting from three presets: Classic (like
  the card game), Whowolf (sheep counting, atmosphere) and Full stage; then
  roles, number of werewolves, phase times, revealing roles of the dead, what
  the seer sees, and every extra one by one.
- **Night sounds and a morning yawn** (synthesised, not recorded); the same on
  every phone and independent of any role. One button mutes a phone.
- **20 figures**, ten women and ten men, all ordinary villagers, so everyone
  at a full table has their own; each one also exists in every role's
  costume, and your own figure turns around in it when you see your role.
- **The moon stage in the app:** cardboard cards, a curtain valance, stamps,
  Manrope text; your role stands as your figure seen from behind and turns
  around, cut edge and all. The website's figures turn the same way.
- **Door signs:** at night every phone shows a secret sign; a werewolf who
  spotted yours may try it once a night, and a right sign gives the pack a
  fair chance at you. Now everyone has a reason to hide their screen.
- Anyone may set their own sheep count at night, so the morning tally is
  something to argue about, not proof.

### Changed
- **The network forgives:** every state carries a version, every action a
  number that the host confirms and applies exactly once, even across
  reconnects and host restarts. A missing host is a calm pause, not an error;
  the app finds a moved host by itself and tries Wi-Fi and relay at once.
- **Seamless return:** after a restart the app goes straight back to the
  table (players and host); a phase timer resumes with the time that was
  left; an absent phone no longer holds up the role reveal.
- Every phone looks the same at night: the sheep meadow is always in front,
  your night task folds away once it is done.
- Android keeps a hosted room alive with a quiet notification; iOS asks the
  host to keep the app open and hosts again on return.

### Security
- Handshake version 3: the host adds a fresh random value to every
  connection, mixed into the keys and the check code. Without the QR code a
  man in the middle could otherwise compute a matching check code, and a
  recorded connection could be played again to kick a player out. Joins
  without the QR code are limited per minute, the waiting list is capped,
  and the relay allows only a few rooms per address. Test versions 0.0.x
  cannot connect to 0.1.

### Fixed
- Lost or late messages could leave a player who had a seat unable to rejoin,
  or rewind the count of confirmed actions; found and fixed with chaos tests
  that play hundreds of games over a lossy network with host crashes.

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
