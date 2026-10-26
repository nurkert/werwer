---
page: docsSafety
lang: en
title: Safety & privacy
short: Safety & privacy
description: "Why Whowolf needs no account, tracking or ads, why nobody sees more than they should, and what the test version is still missing."
lead: "Werewolf is all about secrets. That is why Whowolf is built so your roles stay on your phone and your data stays at the table. Here is what that means, and where the test version still has limits."
figure: beschuetzer
---

## In short

- **No account.** You only enter a name for the table. No email, no phone number, no sign-up.
- **No tracking, no ads.** The app has no analytics, no ads and no purchases. Neither does this website.
- **Your data stays at the table.** In your Wi-Fi, the devices play directly with each other. Nothing goes to us or to anyone else.
- **Open source.** Anyone can check the source code to see that this is true.

## Nobody sees more than they should

The game runs on the host’s device. Every other device receives **only what its owner is allowed to know**: their own role, the pack for a werewolf, her own visions for the seer. Other players’ roles are never sent at all, not even hidden.

That goes for the host too: the host’s app also shows only the host’s own view. Running the game on your phone gives you no advantage.

Nothing should give anything away from the outside either: at night everyone taps, every night screen looks alike, and no phone vibrates or sounds different because of its owner’s role.

## What is already protected

- **Nobody can pose as someone else.** The host recognises you by your session, not by what a message claims.
- **Rejoining needs your key.** Every device gets a random session key when joining, kept in the device’s secure storage. Only with it can you get back to your seat.
- **The QR code is checked closely.** The app only follows Whowolf links, connects only to private addresses in your Wi-Fi, and asks before connecting.
- **The host protects itself.** Messages are strictly checked and limited in size and number. In the Wi-Fi, the host only accepts connections from the local network.
- **Permissions only when needed.** The camera only for scanning, the local network only when opening or joining a room. No location, no contacts, no microphone.
- **Verifiable downloads.** Every version is built automatically from the public source code, with checksums and proof of origin. How to check a file is explained on the [download page](/en/download/).

## What is still missing (honestly)

The test version is **not end-to-end encrypted yet**. That means: someone on the same Wi-Fi with the right tools, or whoever runs a relay server, could read the game’s messages, roles included. For now, play only in your own Wi-Fi or with your own server, among people you trust.

Planned before the first official release:

- **Encryption of every connection** using an established method (a so-called Noise handshake). The key is in the QR code, which can only be scanned at the table. Eavesdroppers, the server included, would then see only gibberish.
- **The same rhythm for everyone:** at night, every device gets the same number of equally sized messages, so not even the amount of traffic gives the werewolves away.
- **Confirmation for manual joins:** whoever joins without the QR code has to be confirmed by the host, and both devices show a short check picture to compare.

## An honest limit

The host device necessarily knows every role, otherwise it couldn’t run the game. The normal app doesn’t show them to the host. But someone using a modified app as host could cheat. It’s like card games: whoever shuffles could stack the deck. So play with people you trust. Later, the idea is that a server can run the game too.

## Found a vulnerability?

Please don’t report security issues publicly; follow the [security policy](https://github.com/nurkert/whowolf/blob/main/SECURITY.md) instead.
