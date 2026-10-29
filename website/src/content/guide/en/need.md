---
page: docsNeed
lang: en
title: What you need
short: What you need
description: "What you need for a round of Whowolf: 3 to 20 people, one device each with the app or a browser, the same Wi-Fi or internet through the server."
lead: "A table, a few people and a device for everyone. You don’t need an account, cards or even internet."
figure: dorfbewohner
---

## People

Whowolf starts from **3 players**, so you can try out how everything works with just a few people. It gets really exciting from about **5 players**, and up to **20** fit in one room. You don’t need a game master: everyone plays.

## One device per person

Everyone needs their own device: a phone, a tablet or a laptop, with the Whowolf app or simply in the browser. Whoever opens the room needs the app.

| Device | Requirement | Status |
|---|---|---|
| iPhone and iPad | iOS 15 or later | in the browser (Safari); the app follows via TestFlight |
| Android | Android 7 or later | APK download |
| Mac | macOS 12 or later | download |
| Windows | Windows 10 or 11, 64-bit | download |
| Linux | Debian, Ubuntu or similar, 64-bit | Debian package |

All downloads and installation steps are on the [download page](/en/download/). iPhone, Android and Mac can scan the QR code; on Windows and Linux you join via “Rooms nearby” or by hand.

## Playing in the browser

If you’d rather not install anything, play in the browser: the game leader shows the QR code in their invitation, you scan it with the camera, enter your name and you’re at the table. On the same Wi-Fi the page comes straight from their phone, otherwise from play.whowolf.de. The first time it loads about 5 MB.

For a smooth evening:

- **A current browser:** a recent Safari, Chrome, Firefox or Edge.
- **Sound on:** the narrator and the sounds also play on your device. Turn off the mute switch and turn the volume up.
- **Screen on:** keep the page open and in front. If the device goes to sleep you may miss your turn; reloading brings you back to your seat.
- **At the table, not from afar:** Whowolf is a game for people sitting together. Joining over the internet is for those without the table’s Wi-Fi, not a replacement for game night.

The browser can’t open a room; for that, one person at the table needs the app.

## The same Wi-Fi

The easiest way is for everyone to be on the **same Wi-Fi**, at home for example. You don’t need internet for that: the devices talk to each other directly, and your game never leaves the room.

What you need to allow the first time:

- **iPhone and iPad** ask for access to the **local network**. Without it, the devices can’t find each other.
- **Mac, Windows and Linux** may ask whether the firewall should allow connections.

Some guest networks, in cafés or hotels for example, don’t let devices talk to each other. In that case, one phone can open a hotspot and everyone else joins it.

## Players who aren’t at the table

Anyone not on the same Wi-Fi can join through a **relay server**. By default the app uses the official server play.whowolf.de, which only passes on encrypted messages. By default the app opens the room there only when the game leader shows the QR code. Under “Online play” in the settings you can switch it off completely (“No online server”) or enter [your own server](https://github.com/nurkert/whowolf/tree/main/server/deploy). More in [How the app works](/en/docs/how-it-works/).

## Good to know: this is a developer beta

Whowolf is a **developer beta**. A full round is playable, and all connections are **end-to-end encrypted**. Still:

- **Expect bugs.** Rounds may get stuck or break off.
- **Everyone needs the same version.** New versions often don’t work with old ones; update every device before game night.
- **Play with people you trust.** An independent security review is still due.

Tell us when something doesn’t work: [report a bug](https://github.com/nurkert/whowolf/issues). More about safety in [Safety & privacy](/en/docs/safety/).
