---
page: docsSafety
lang: en
title: Safety & privacy
short: Safety & privacy
description: "Why Whowolf needs no account, tracking or ads, why nobody sees more than they should, and what the test version is still missing."
lead: "Werewolf is all about secrets. That is why Whowolf is built so your roles stay on your phone and your data stays at the table. Here is what that means, and where the test version still has limits."
figure: seherin
---

## In short

- **No account.** You only enter a name for the table, never an email address or phone number, and there is nothing to sign up for.
- **No tracking, no ads.** The app has no analytics, no ads and no purchases. Neither does this website.
- **Your data stays at the table.** In your Wi-Fi, the devices play directly with each other. Through the relay server only encrypted data travels, and it cannot read it.
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

## How the encryption works

Since version 0.0.3, **every connection is end-to-end encrypted**, in the Wi-Fi and through a relay server. Eavesdroppers, including whoever runs a server, only see equally sized packets of gibberish.

- **With the QR code:** the code at the table contains a key and a secret of this room. That is how your app recognises the real host; an impostor on the Wi-Fi cannot slip in between.
- **Without the QR code** (room found nearby or typed in): the connection is just as encrypted. So that no stranger slips in, your phone shows four symbols, and the host only lets you in when they match the ones on their screen. From 0.0.4 nobody in the middle can force matching symbols either, and once let in, you always come back over the checked way when you reconnect.
- **Equally sized messages:** every message is padded to fixed sizes, and everyone gets the same amount on every change. So not even the traffic reveals who has more to do at night as a werewolf.
- **A proven library:** since 0.0.4 all encryption comes from [libsodium](https://doc.libsodium.org/), a widely used and independently audited library (X25519 key exchange, XChaCha20-Poly1305, BLAKE2b). Whowolf computes none of it itself. How we put the pieces together has not had an outside review yet; that review is still pending.

## Where the protection ends

The host device necessarily knows every role, otherwise it couldn’t run the game. The normal app doesn’t show them to the host. But someone using a modified app as host could cheat. It’s like card games: whoever shuffles could stack the deck. So play with people you trust. Later, the idea is that a server can run the game too.

## Found a vulnerability?

Please don’t report security issues publicly; follow the [security policy](https://github.com/nurkert/whowolf/blob/main/SECURITY.md) instead.
