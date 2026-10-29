# Running the Whowolf relay

The relay lets players who are not in the same Wi-Fi (mobile data, another
place) join a host. It forwards end-to-end encrypted messages between the
host's phone and the players and nothing else: no game logic, no game state,
no message contents in logs. The game itself keeps running on the host's
phone. `play.whowolf.de` runs exactly this setup.

## What it needs

A small Linux server with Docker (Compose v2), a domain pointing at it, and
ports 80 and 443 free. One vCPU and 512 MB of RAM carry hundreds of tables:
the relay only copies bytes.

## Setup

```sh
sudo mkdir -p /opt/whowolf
sudo cp server/deploy/* /opt/whowolf/
cd /opt/whowolf
echo "RELAY_DOMAIN=play.example.org" | sudo tee domain.env
sudo ./update.sh                       # pulls, verifies, starts relay + Caddy
sudo cp whowolf-update.service whowolf-update.timer /etc/systemd/system/
sudo systemctl enable --now whowolf-update.timer
```

Then enter `wss://play.example.org` in the app's settings. Caddy fetches the
TLS certificate by itself.

## Updates without an open door

`update.sh` runs every five minutes from the systemd timer. It pulls the
`stable` tag from `ghcr.io/nurkert/whowolf-relay` and checks its keyless
Sigstore signature: only an image signed by this repository's release
workflow (`.github/workflows/prerelease.yml`, on a version tag) is accepted.
Then it runs that exact digest. A new release is live within minutes. The
server opens no webhook or other endpoint for this; it asks.

### When a release does not start

After `docker compose up -d` the script waits for the relay's healthcheck
(up to `WHOWOLF_HEALTH_TIMEOUT` seconds, default 120). If the new container
turns unhealthy, stops or restarts instead, it writes the previous digest
back to `.env`, starts that again and exits non-zero with
`rolled back from <new> to <old>`, so `journalctl -u whowolf-update` shows
it. No images are pruned after a rollback.

The broken digest is kept in `.failed-image` next to `update.sh`; the timer
skips it and only deploys the next digest on `stable`. To try it once more
(say after fixing `domain.env`), delete the file and run `./update.sh`. On a
first install there is nothing to go back to: the script only reports the
error.

Forks set `WHOWOLF_IMAGE` and `WHOWOLF_REPO` in the service's environment.

## The web app for players without the app

With `WEB_APP_DIR: /webapps` (set in `docker-compose.yml`) the relay also
serves the web app, so someone who scans a room's QR code with the camera
and has no app plays in the browser, also without the table's Wi-Fi. The
image carries every build listed in `server/webapps.lock` plus the release
it was built with, each checked against its checksum and this repository's
build attestation. Everything is read into memory once at start (about
40 MB for the first build, identical files shared between builds,
`WEB_APP_MAX_MB` caps it) and served with long caching, so a page load is a
handful of map lookups and almost all later visits are `304`s.

Players trust whoever serves the page: a modified page could read the room
key. Switch it off by removing `WEB_APP_DIR` if you do not want that role;
the app then still works through your relay, browsers only on the Wi-Fi.

With the web app on, the server's start page (`https://<your domain>/`)
asks for a door code. The host's invitation shows a six-character code
that changes every five minutes; typing it leads to that room's page
without the room's key, so the game leader compares a few symbols with
the newcomer before letting them in (like joining without the QR code in
the app). Codes die with their room and are never logged; each address may
try 10 per minute (`MAX_DOOR_LOOKUPS_PER_MINUTE`).

To let a QR code open the installed app instead of the browser, add to
`domain.env` (never to the repository):

```
APPLE_APP_ID=<TEAMID>.de.whowolf.app
ANDROID_CERT_SHA256=<AA:BB:… fingerprint of the release signing key>
```

## Your own legal pages (optional)

You run your relay, so you are responsible for it, not the Whowolf project.
A relay for your own table at home usually needs nothing here. If you run one
publicly and the law asks you for an imprint or privacy policy (in Germany for
example § 5 DDG and Art. 13 GDPR; this is not legal advice), link your own
pages by adding to `domain.env`:

```
IMPRINT_URL=https://example.org/imprint
PRIVACY_URL=https://example.org/privacy
# Optional, if the pages also exist in English:
IMPRINT_URL_EN=https://example.org/en/imprint
PRIVACY_URL_EN=https://example.org/en/privacy
```

Only `https` addresses are taken (others are ignored with a line in the log).
The code page and the page for a missing build then show the links, and the
web app reads them from `/legal.json` on your server. Without them the
relay's pages show no legal links at all, and the web app never shows the
official site's privacy notice on your server. Restart the relay after a
change (`sudo ./update.sh` or `docker compose up -d`).

## Limits

The relay protects itself and the machine:
- **Per connection:** a byte budget. A connection that sends too much at
  once is cut off before a large frame is complete, so no single message can
  fill the memory.
- **Per address:** at most a few rooms, connections and new connections per
  minute. Behind Caddy the address comes from `X-Forwarded-For`
  (`TRUST_PROXY=1`, safe because only Caddy can reach the relay).
- **Totals:** rooms, connections and players per room are capped.
- **Container:** read-only, no capabilities, no new privileges, 256 MB of
  memory and one CPU at most.

All limits are environment variables in `docker-compose.yml` (see
`server/bin/server.dart`).

## Already running a reverse proxy?

Drop the `caddy` service and publish the relay on the loopback interface
only, e.g. `ports: ["127.0.0.1:8080:8080"]`. Proxy WebSocket requests for
your domain to it, and keep `TRUST_PROXY=1` only if your proxy overwrites
`X-Forwarded-For` with the client's address.
