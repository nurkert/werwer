# Changelog

All notable changes to Whowolf. Versions follow [Semantic Versioning](https://semver.org/);
0.0.x are test versions, 0.1.0 is the first release (developer beta).

## Unreleased

Every device at the table needs this version (protocol 12).

### Added
- "My role": hold the button at the top to see your role, any time.
- Narrator "Essentials": the voice only says what a table with closed
  eyes needs (falling asleep, who wakes, the village waking up).
- Join by code: without a camera or on a computer, type the code from the
  invitation on play.whowolf.de. It changes every few minutes, and the
  game leader compares a few symbols with whoever joins this way.

### Changed
- On a computer the gear opens all of the app's settings, like the
  page to the right on a phone.
- Picks are confirmed: every night card, the vote and the hunter's shot
  first select, then a button sends. The witch's potions are her main
  action, "brew nothing" the quiet one.
- Werewolves keep their choice open until the whole pack names the same
  prey; the called night says "The pack is awake".
- Cards, quick picks and role switches work with the keyboard (Tab,
  Enter, Space) and show a focus ring; large system text fits.
- Phase times follow the number of players in the lobby until the game
  leader sets them; picking a preset keeps them.
- At night every phone first shows the same lit card with a question,
  werewolf or not; in the called night the card no longer glows.
- The quick picks in the lobby settings keep their title on one line
  (the tick sits on the corner) and centre their text.
- "Open a room" without the arrow.
- Whowolf's hunt lasts at least 25 seconds, so a quick pack shows nowhere.
- The talk starts after the last words, not during them.
- "Talk on after all" during the vote warning.
- The game leader can pause at night and during the hunter's shot too.
- Night screens without a task read "All quiet" instead of "done".
- Cards that cannot be chosen in a runoff carry a small lock.
- Ending the vote early asks once more.
- A player whose app speaks another version than the host's is told
  which one is newer instead of waiting for a timeout.
- The join dialog says "Over your Wi-Fi" instead of showing an address.
- Let in without the QR code: once the host admits you, one big
  "They match, let’s go" finishes the symbol check.
- The invitation says plainly when the code works in the app only.
- The invitation page on an iPhone explains how to play in the browser
  instead of offering an app that is not in the App Store yet.
- On the desktop, the page arrows sit in their own lane, centred beside
  the content.

## 0.1.9 – 2026-10-28

### Fixed
- The relay's updater rolls a release back when it does not start: it
  waits for the healthcheck, puts the previous version back, says so in
  the log and does not try the broken one again until a newer release
  is out.
- The Mac app keeps its settings (they no longer depend on the
  keychain).
- The seer has time to see what she found; tasks at night open only
  after the narrator calls a role.

### Changed
- On the desktop: lobby pages with arrows, columns centred and standing
  on the stage floor, the invitation folded into one button.
- A new figure turns in like a card; long names fit on the cards.

## 0.1.8 – 2026-10-28

### Fixed
- The relay image could not start with the web app switched on: the web
  app's folders were readable only by root, and the relay runs
  unprivileged. Builds are now packed and unpacked readable, the image
  copies them so, and an unreadable build is skipped instead of stopping
  the relay.

### Added
- On Android, the browser join page suggests the app (closable).

## 0.1.7 – 2026-10-28

Every device at the table needs this version (protocol 11).

### Added
- What really happened: at the end, the game tells night by night whom
  the werewolves chose, whom the seer looked at, what the witch did and
  who voted for whom.
- Open voting as a setting: everyone sees the votes as they come in and,
  the day after, how yesterday's vote went.
- Last words: whoever dies stands in the spotlight for seven seconds on
  every phone.
- "We're ready": with more than half of the living ready, the vote
  follows after a five-second warning.
- The game leader's clock: pause and resume, thirty seconds more, end
  the vote.
- By day the table sees whose device is not connected.
- A seat can go to another device with a one-time QR code, for a phone
  whose battery died.
- Phase times suited to the number of players, with one tap.
- The app tells you when a new version is out (you can switch this off).

### Changed
- On the website, Linux users can install from the signed apt archive
  and get updates automatically.

## 0.1.6 – 2026-10-28

0.1.5 was tagged but not published (the Linux build lacked ALSA for the
volume watch). This release carries all of 0.1.5 and:

### Added
- The seer's vision: the looked-at player's figure turns around large in
  the costume of what they are, with name and role, then stays as a small
  card to see again.
- Time to close your eyes: at the start of each night step every phone
  shows the same moon for a few seconds before any task appears.

### Changed
- Too many roles for a small table no longer block the start: the last
  special roles stay out (cupid, hunter, witch, then the seer), and the
  lobby says which; they come back when more people join.

## 0.1.5 – 2026-10-28

Every device at the table needs this version (protocol 9).

### Added
- Play in the browser without the Wi-Fi: whoever sits at the table but
  is not on the Wi-Fi (guest or hotel networks, no Wi-Fi at all) scans
  the code with the camera and plays over mobile data through the
  server, which serves the web app. One QR code for everyone: with the
  app it opens the app, without it the browser.
- The server only when needed: a room goes online only when the host
  shows the QR code; players on the same Wi-Fi find it without the
  server. Settings: on demand, always ready, never.
- The narrator tells the story with modes: off, big moments (the
  default: nightfall, the morning's news, the vote and the end; in the
  classic night it still calls every role) or everything.
- The narrator walks like a storyteller: slowly or quickly round the
  table, back and forth across it, leaping to far seats, standing still,
  and only sometimes walking to someone whose fate is already public.
  Planned from public values only, so it never gives anyone away; while
  the voice moves on, one phone always plays almost at full volume.
- Sound on the phones the table picks: everyone, only the game leader,
  a group, or one player (e.g. with a speaker).
- A shared mute: muted phones, and phones with the volume at zero, drop
  out of the narrator's walk from the next phase on.
- Browser players are marked in the lobby.

### Changed
- The in-app scanner is framed like the stage.

### Fixed
- Under "Join a room" only rooms whose host really answers show up; a
  closed room disappears on every device, and a tap on one that just
  closed says so instead of waiting.
- Players let in without the QR code can come back after a dropped
  connection.
- Leaving a room no longer leaves its stars over the start screen.

### Security
- The relay and the host phone guard every connection on the raw
  socket: a message is capped over all its fragments, an unfinished one
  times out, and a peer that stops reading is dropped. A malformed
  request can no longer stop the relay. Found in an independent review.
- Compressed web app files are never unpacked on request; every plain
  request counts against the per-address limit; Caddy drops slow
  headers.

## 0.1.4 – 2026-10-28

### Added
- The stage comes alive: windows glow and waver like candlelight, lanterns
  flicker, painted stars twinkle with shooting stars now and then, the
  lake's water sways with the village's reflections, cloud veils drift,
  fireflies, moths, mist and embers in the scenes that have them. When
  the system asks for reduced motion, the stage holds still.
- "How it works" on the start screen explains a round in eight steps,
  each a little scene of the village's figures: opening a room, the
  secret role, the werewolves' night, seer and witch, the morning, the
  talk, the vote and who wins.
- The host's game settings start with two quick picks, Classic and
  Whowolf; everything else stays right below to set by hand, in two
  columns on tablets and desktops.

### Changed
- On phones the start screen is framed by a branch, a lantern and a
  signpost with a cat instead of half-cut trees and houses; the theatre
  hangs velvet swags with tassels, and its moon no longer sits behind the
  headline.
- The start title turns slowly and irregularly.
- Switches, sliders and buttons in the settings match the stage, and the
  roles fill even rows.
- Subtitle: "The werewolf game for your table."

### Fixed
- A room you closed no longer shows up on your own start screen as one to
  join.

## 0.1.3 – 2026-10-27

### Added
- A new look: every moment of the evening is a painted stage set by
  moonlight, framed by wings that shift as you tilt your phone. The moon
  tells the time, players are puppet cards in villager poses that change,
  the curtain falls between phases, and the end is a curtain call in
  costume.
- Swipe instead of scroll: the start screen and the lobby are pages, like
  a home screen. A short "How it works" sits on the start screen.
- The figure choice is a page of big cards: the picked figure flies up
  to your place with a turn, and the one it replaces slides back into its
  card.
- The host sets up the game on its own page in the lobby, no sheet to
  open; the lobby opens on the table with the invitation and QR code.
- A new app icon: the werewolf under the full moon over the village, with
  the wordmark.
- The start screen remembers your name and offers the tables open nearby
  in one tap, the last one first; "Restore room" only shows when a game
  was really under way.
- On the start screen the werewolf and the wordmark turn as corrugated
  board, each in its own time, and the werewolf's paw reaches over the
  letters. Swiping the pages pans the stage set; the scenery is one
  panorama, so what reaches in at a page's edge passes over into the next.
- The app's settings (online server, about) sit on the start screen's
  right page, no dialog to open; the language is a flag in the corner.
- Menus and side-by-side choices are brass-edged plaques throughout, and
  every text standing on a painted set has a soft patch of night behind
  it.
- Ghosts: the dead can watch, holding a button to see every role and, if
  the table allows it, what happens at night and who votes for whom.
- A tied vote leads to a runoff between the tied.

### Changed
- In the lobby everyone picks their own figure among the free ones, at
  every level (Classic used to switch this off).
- Phones play upright only.
- A room you closed yourself no longer shows up to join.
- Tilting the phone moves the stage set only a little, and smoothly.
- Website: the scenes melt into each other instead of meeting at hard
  edges, the download page shows how often Whowolf was downloaded, and the
  texts read more plainly.

## 0.1.2 – 2026-10-27

### Added
- Every morning another rooster greets the village (five recordings, CC0),
  the same on every phone.
- The recorded narrator, in German and English: a story with an arc from the first night to the
  endgame, at least five variants of every line, and lines that name a
  detail only when it is true at this table. It opens the game with a short
  welcome, which the game leader can skip; sounds and voice follow each
  other like one scene, with natural pauses between sentences.

### Fixed
- In the classic night the werewolves' turn waits until they agree.
- The classic night no longer gives away, through counts or timing, how
  many werewolves there are or whether the seer or witch is still alive.
- Browser players hear the same night sounds and narrator as everyone else,
  and come back to their seat after the page reloads.
- "Wi-Fi only" also applies when joining by link or coming back to a game.

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
- The walking narrator: with recordings in the app, the narrator's voice
  walks around the table from phone to phone, with several variants of
  every line and a little more tension each round. The host picks one
  narrator language for the whole table.
- Pick German or English per app in the system settings (iOS, macOS,
  Android 13+) or in the app's settings.
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
