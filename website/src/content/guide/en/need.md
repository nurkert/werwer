---
page: docsNeed
lang: en
title: What you need
short: What you need
description: "What you need for a round of Whowolf: 3 to 20 people, one device each, the same Wi-Fi or your own server, and the app."
lead: "A table, a few people and a device for everyone. That is all: no account, no cards, not even internet."
figure: dorfbewohner
---

## People

Whowolf starts from **3 players**, so you can try out how everything works with just a few people. It gets really exciting from about **5 players**, and up to **20** fit in one room. You don’t need a game master: everyone plays.

## One device per person

Everyone needs their own device with the Whowolf app. That can be a phone, but a tablet or laptop works too:

| Device | Requirement | Status |
|---|---|---|
| iPhone and iPad | iOS 15 or later | via TestFlight, once the invitation is published |
| Android | Android 7 or later | APK download |
| Mac | macOS 12 or later | download |
| Windows | Windows 10 or 11, 64-bit | download |
| Linux | Debian, Ubuntu or similar, 64-bit | Debian package |

All downloads and installation steps are on the [download page](/en/download/). Joining in the browser without installing anything is planned, but not possible yet. iPhone, Android and Mac can scan the QR code; on Windows and Linux you join via “Rooms nearby” or by hand.

## The same Wi-Fi

The easiest way is for everyone to be on the **same Wi-Fi**, at home for example. You don’t need internet for that: the devices talk to each other directly, and your game never leaves the room.

What you need to allow the first time:

- **iPhone and iPad** ask for access to the **local network**. Without it, the devices can’t find each other.
- **Mac, Windows and Linux** may ask whether the firewall should allow connections.

Some guest networks, in cafés or hotels for example, don’t let devices talk to each other. In that case, one phone can open a hotspot and everyone else joins it.

## Players who aren’t at the table

Anyone not on the same Wi-Fi can join through a **relay server**. There is no official server yet, but you can run your own: it is part of the repository and starts with a single command (`docker compose up -d`). Enter its address in the app under Settings, “Server for online players”. More in [How the app works](/en/docs/how-it-works/).

## Good to know: this is a test version

The current versions (0.0.x) are **test versions**. A full round is playable, and since 0.0.3 all connections are **end-to-end encrypted**. Things may still be rough around the edges: tell us when something doesn’t work. More about safety in [Safety & privacy](/en/docs/safety/).
