---
page: docsHow
lang: en
title: How the app works
short: How the app works
description: "How Whowolf works, in plain words: one phone is the host, the others connect over Wi-Fi, and a relay server brings in remote players."
lead: "In Whowolf, one phone at the table runs the game, without a data centre or a cloud. Here is how that works, in plain words."
figure: lauscherin
---

## One phone is the host

Whoever opens the room turns their device into the **host**. The actual game runs on it: it deals the roles, collects night actions and votes, applies the rules and announces the results. All other devices connect to it over the Wi-Fi.

The host is still a completely normal player. Its app connects to the game just like everyone else’s and only receives its own view. Running the game on your phone does not let you see more.

## How the others get in

- **Rooms nearby:** the host announces its room in the Wi-Fi, and the other apps find it by themselves.
- **QR code:** the code is a link to whowolf.de that contains the host’s address in the Wi-Fi and the room code. The Whowolf app reads it directly. Scanned with a normal camera, it opens a page that explains what to do next; the details from the link never leave your browser.
- **By hand:** type in address and room code if nothing else works.

## Everyone only sees their part

The host never sends the whole game state around. Instead it builds a separate, filtered view for every player: your role, your pack, your visions as seer, plus everything that everyone knows anyway. What you may not know never reaches your device.

## When the connection drops

Every device gets a secret session key when joining and stores it safely. If the connection drops because the screen turns off or the Wi-Fi hiccups, the app signs back in with it and returns with exactly its role. That even works after restarting the app. The host also saves the game state as it goes, so a round survives a crash or a restart of the host app.

## Players from elsewhere: the relay server

Anyone not on the same Wi-Fi can play through a **relay server**:

1. The host connects to the server.
2. Remote players connect to the same server with an online code.
3. The server only passes messages along. It knows no game rules and keeps no game state.

Players at the table stay connected directly through the Wi-Fi, the others come in through the server. For the game, it makes no difference.

By default the app uses the official server `wss://play.whowolf.de`, run by the project owner. It only passes on end-to-end encrypted messages and cannot read them. If you don’t want that, pick “No online server (Wi-Fi only)” in the settings; then nothing goes to a server, and only devices in the same Wi-Fi can play.

You can also run **your own server**. What it needs and how to set it up is in the [guide in the repository](https://github.com/nurkert/whowolf/tree/main/server/deploy). Enter its address in the app under Settings, “Server for online players” (it starts with `ws://` or `wss://`).

## One codebase for everything

Whowolf is written entirely in Dart and Flutter. The same app runs on iPhone, Android, Mac, Windows and Linux. The game rules live in exactly one place and are tested automatically, so every round is equally fair.

## What is coming

- **Play in the browser** without installing anything, just via QR code.
- **Synchronised sounds** on every phone for the wolf trail, conducted by the host.

If you want every detail, the plans are in the [for developers](/docs/dev/) area (in German).
